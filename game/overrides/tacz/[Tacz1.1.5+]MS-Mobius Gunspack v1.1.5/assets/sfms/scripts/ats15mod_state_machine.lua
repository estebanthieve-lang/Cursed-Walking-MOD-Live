local track_line_top = {value = 0}
local static_track_top = {value = 0}
local blending_track_top = {value = 0}
local function increment(obj)
    obj.value = obj.value + 1
    return obj.value - 1
end

local STATIC_TRACK_LINE = increment(track_line_top)
local BASE_TRACK = increment(static_track_top)
local BOLT_CAUGHT_TRACK = increment(static_track_top)
local MAIN_TRACK = increment(static_track_top)
local ADS_TRACK = increment(static_track_top)

local GUN_KICK_TRACK_LINE = increment(track_line_top)

local BLENDING_TRACK_LINE = increment(track_line_top)
local MOVEMENT_TRACK = increment(blending_track_top)

local function runPutAwayAnimation(context)
    local put_away_time = context:getPutAwayTime()
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (context:getFireMode() == AUTO) then
        context:runAnimation("put_away_auto", track, false, PLAY_ONCE_HOLD, put_away_time * 0.75)
    elseif (context:getFireMode() == BURST) then
        context:runAnimation("put_away_burst", track, false, PLAY_ONCE_HOLD, put_away_time * 0.75)
    end
    context:setAnimationProgress(track, 1, true)
    context:adjustAnimationProgress(track, -put_away_time, false)
end

local function isNoAmmo(context)
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

local function runReloadAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (isNoAmmo(context)) then
        if (context:getFireMode() == BURST) then
            context:runAnimation("reload_empty_burst", track, false, PLAY_ONCE_STOP, 0.2)
        elseif (context:getFireMode() == AUTO) then
            context:runAnimation("reload_empty_auto", track, false, PLAY_ONCE_STOP, 0.2)
        end
    else
        if (context:getFireMode() == BURST) then
            context:runAnimation("reload_tactical_burst", track, false, PLAY_ONCE_STOP, 0.2)
        elseif (context:getFireMode() == AUTO) then
            context:runAnimation("reload_tactical_auto", track, false, PLAY_ONCE_STOP, 0.2)
        end
    end
end

local function runInspectAnimation(context)
    local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
    if (isNoAmmo(context)) then
        if (context:getFireMode() == BURST) then
            context:runAnimation("inspect_empty_burst", track, false, PLAY_ONCE_STOP, 0.2)
        elseif (context:getFireMode() == AUTO) then
            context:runAnimation("inspect_empty_auto", track, false, PLAY_ONCE_STOP, 0.2)
        end
    else
        if (context:getFireMode() == BURST) then
            context:runAnimation("inspect_burst", track, false, PLAY_ONCE_STOP, 0.2)
        elseif (context:getFireMode() == AUTO) then
            context:runAnimation("inspect_auto", track, false, PLAY_ONCE_STOP, 0.2)
        end
    end
end

local base_track_state = {
    mode = 0
}

function base_track_state.entry(this, context)
    if (context:getFireMode() == BURST) then
        base_track_state.mode = 0
        context:runAnimation("static_idle_burst", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, PLAY_ONCE_HOLD, 0)
    elseif (context:getFireMode() == AUTO) then
        base_track_state.mode = 1
        context:runAnimation("static_idle_auto", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, PLAY_ONCE_HOLD, 0)
    end
end

function base_track_state.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, BASE_TRACK)
    if (context:isHolding(track)) then
        if (context:getFireMode() == BURST) then
            if (base_track_state.mode == 1) then
                context:runAnimation("change_to_auto", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, PLAY_ONCE_HOLD, 0)
                base_track_state.mode = 0
            else
                context:runAnimation("static_idle_burst", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, PLAY_ONCE_HOLD, 0)
            end
        elseif (context:getFireMode() == AUTO) then
            if (base_track_state.mode == 0) then
                context:runAnimation("change_to_burst", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, PLAY_ONCE_HOLD, 0)
                base_track_state.mode = 1
            else
                context:runAnimation("static_idle_auto", context:getTrack(STATIC_TRACK_LINE, BASE_TRACK), false, PLAY_ONCE_HOLD, 0)
            end
        end
    end
end

local ADS_states = {
    aiming_progress = 0,
    normal = {},
    aiming = {}
}

function ADS_states.normal.entry(this, context)
    this.ADS_states.normal.update(this, context)
end

function ADS_states.normal.update(this, context)
    if ((context:getAimingProgress() > this.ADS_states.aiming_progress or context:getAimingProgress() == 1) and context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_AIM)
    else
        this.ADS_states.aiming_progress = context:getAimingProgress()
    end
end

function ADS_states.normal.transition(this, context, input)
    if (input == this.INPUT_AIM) then
        return this.ADS_states.aiming
    end
end

function ADS_states.aiming.entry(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    context:runAnimation("aim_start", track, false, PLAY_ONCE_HOLD, 0.2)
    context:trigger(this.INPUT_INSPECT_RETREAT)
end

function ADS_states.aiming.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (context:isHolding(track)) then
        context:runAnimation("aim", track, false, PLAY_ONCE_HOLD, 0.2)
    end
    if (context:getAimingProgress() < this.ADS_states.aiming_progress or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_AIM_RETREAT)
    else
        this.ADS_states.aiming_progress = context:getAimingProgress()
    end
end

function ADS_states.aiming.transition(this, context, input)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (input == this.INPUT_AIM_RETREAT) then
        context:runAnimation("aim_end", track, false, PLAY_ONCE_STOP, 0.2)
        context:setAnimationProgress(track, 1 - context:getAimingProgress(), true)
        return this.ADS_states.normal
    end
end

local bolt_caught_states = {
    normal = {},
    bolt_caught = {}
}

function bolt_caught_states.normal.entry(this, context)
    this.bolt_caught_states.normal.update(this, context)
end

function bolt_caught_states.normal.update(this, context)
    if (isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_CAUGHT)
    end
end

function bolt_caught_states.normal.transition(this, context, input)
    if (input == this.INPUT_BOLT_CAUGHT) then
        return this.bolt_caught_states.bolt_caught
    end
end

function bolt_caught_states.bolt_caught.entry(this, context)
    context:runAnimation("static_bolt_caught", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, LOOP, 0)
end

function bolt_caught_states.bolt_caught.update(this, context)
    if (not isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_NORMAL)
    end
end

function bolt_caught_states.bolt_caught.transition(this, context, input)
    if (input == this.INPUT_BOLT_NORMAL) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        return this.bolt_caught_states.normal
    end
end

local main_track_states = {
    start = {},
    idle = {},
    inspect = {},
    final = {},
    bayonet_counter = 0
}

function main_track_states.start.transition(this, context, input)
    if (input == INPUT_DRAW) then
        if (context:getFireMode() == AUTO) then
            context:runAnimation("draw_auto", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0)
        elseif (context:getFireMode() == BURST) then
            context:runAnimation("draw_burst", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0)
        end
        return this.main_track_states.idle
    end
end

function main_track_states.idle.transition(this, context, input)
    if (input == INPUT_PUT_AWAY) then
        runPutAwayAnimation(context)
        return this.main_track_states.final
    end
    if (input == INPUT_RELOAD) then
        runReloadAnimation(context)
        return this.main_track_states.idle
    end
    if (input == INPUT_SHOOT) then
        context:popShellFrom(0)
        return this.main_track_states.idle
    end
    if (input == INPUT_BOLT) then
        context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_INSPECT) then
        runInspectAnimation(context)
        return this.main_track_states.inspect
    end
    if (input == INPUT_BAYONET_MUZZLE) then
        local counter = this.main_track_states.bayonet_counter
        local animationName = "melee_bayonet_" .. tostring(counter + 1)
        this.main_track_states.bayonet_counter = (counter + 1) % 3
        context:runAnimation(animationName, context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_BAYONET_STOCK) then
        context:runAnimation("melee_stock", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    if (input == INPUT_BAYONET_PUSH) then
        context:runAnimation("melee_push", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
end

function main_track_states.inspect.entry(this, context)
    context:setShouldHideCrossHair(true)
end

function main_track_states.inspect.exit(this, context)
    context:setShouldHideCrossHair(false)
end

function main_track_states.inspect.update(this, context)
    if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_INSPECT_RETREAT)
    end
end

function main_track_states.inspect.transition(this, context, input)
    if (input == this.INPUT_INSPECT_RETREAT) then
        return this.main_track_states.idle
    end
    if (input == INPUT_SHOOT) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end

local gun_kick_state = {}

function gun_kick_state.transition(this, context, input)
    if (input == INPUT_SHOOT) then
        local track = context:findIdleTrack(GUN_KICK_TRACK_LINE, false)
        if (context:getFireMode() == BURST) then
            context:runAnimation("shoot_burst", track, true, PLAY_ONCE_STOP, 0)
        elseif (context:getFireMode() == AUTO) then
            context:runAnimation("shoot_auto", track, true, PLAY_ONCE_STOP, 0)
        end
    end
    return nil
end

local movement_track_states = {
    idle = {},
    run = {
        mode = -1
    },
    walk = {
        mode = -1
    }
}

function movement_track_states.idle.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    if (context:isStopped(track) or context:isHolding(track)) then
        context:runAnimation("idle", track, true, LOOP, 0)
    end
end

function movement_track_states.idle.transition(this, context, input)
    if (input == INPUT_RUN) then
        return this.movement_track_states.run
    elseif (input == INPUT_WALK) then
        return this.movement_track_states.walk
    end
end

function movement_track_states.run.entry(this, context)
    this.movement_track_states.run.mode = -1
    if (context:getFireMode() == AUTO) then
        context:runAnimation("run_start", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.2)
    elseif (context:getFireMode() == BURST) then
        context:runAnimation("run_start_burst", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.2)
    end
end

function movement_track_states.run.exit(this, context)
    if (context:getFireMode() == AUTO) then
        context:runAnimation("run_end", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.3)
    elseif (context:getFireMode() == BURST) then
        context:runAnimation("run_end_burst", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.3)
    end
end

function movement_track_states.run.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local state = this.movement_track_states.run;
    if (context:isHolding(track)) then
        if (context:getFireMode() == AUTO) then
            context:runAnimation("run", track, true, LOOP, 0.2)
        elseif (context:getFireMode() == BURST) then
            context:runAnimation("run_burst", track, true, LOOP, 0.2)
        end
        state.mode = 0
        context:anchorWalkDist()
    end
    if (state.mode ~= -1) then
        if (not context:isOnGround()) then
            if (state.mode ~= 1) then
                state.mode = 1
                if (context:getFireMode() == AUTO) then
                    context:runAnimation("run_hold", track, true, LOOP, 0.6)
                elseif (context:getFireMode() == BURST) then
                    context:runAnimation("run_hold_burst", track, true, LOOP, 0.6)
                end
            end
        else
            if (state.mode ~= 0) then
                state.mode = 0
                if (context:getFireMode() == AUTO) then
                    context:runAnimation("run", track, true, LOOP, 0.2)
                elseif (context:getFireMode() == BURST) then
                    context:runAnimation("run_burst", track, true, LOOP, 0.2)
                end
            end
            context:setAnimationProgress(track, (context:getWalkDist() % 2.0) / 2.0, true)
        end
    end
end

function movement_track_states.run.transition(this, context, input)
    if (input == INPUT_IDLE) then
        return this.movement_track_states.idle
    elseif (input == INPUT_WALK) then
        return this.movement_track_states.walk
    end
end

function movement_track_states.walk.entry(this, context)
    this.movement_track_states.walk.mode = -1
end

function movement_track_states.walk.exit(this, context)
    context:runAnimation("idle", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.4)
end

function movement_track_states.walk.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local state = this.movement_track_states.walk
    if (context:getShootCoolDown() > 0) then
        if (state.mode ~= 0) then
            state.mode = 0
            context:runAnimation("idle", track, true, LOOP, 0.3)
        end
    elseif (not context:isOnGround()) then
        if (state.mode ~= 0) then
            state.mode = 0
            context:runAnimation("idle", track, true, LOOP, 0.6)
        end
    elseif (context:getAimingProgress() > 0.5) then
        if (state.mode ~= 1) then
            state.mode = 1
            context:runAnimation("walk_aiming", track, true, LOOP, 0.3)
        end
    elseif (context:isInputUp()) then
        if (state.mode ~= 2) then
            state.mode = 2
            context:runAnimation("walk_forward", track, true, LOOP, 0.4)
            context:anchorWalkDist()
        end
    elseif (context:isInputDown()) then
        if (state.mode ~= 3) then
            state.mode = 3
            context:runAnimation("walk_backward", track, true, LOOP, 0.4)
            context:anchorWalkDist()
        end
    elseif (context:isInputLeft() or context:isInputRight()) then
        if (state.mode ~= 4) then
            state.mode = 4
            context:runAnimation("walk_sideway", track, true, LOOP, 0.4)
            context:anchorWalkDist()
        end
    end
    if (state.mode >= 1 and state.mode <= 4) then
        context:setAnimationProgress(track, (context:getWalkDist() % 2.0) / 2.0, true)
    end
end

function movement_track_states.walk.transition(this, context, input)
    if (input == INPUT_IDLE) then
        return this.movement_track_states.idle
    elseif (input == INPUT_RUN) then
        return this.movement_track_states.run
    end
end

local M = {
    track_line_top = track_line_top,
    STATIC_TRACK_LINE = STATIC_TRACK_LINE,
    GUN_KICK_TRACK_LINE = GUN_KICK_TRACK_LINE,
    BLENDING_TRACK_LINE = BLENDING_TRACK_LINE,

    static_track_top = static_track_top,
    BASE_TRACK = BASE_TRACK,
    BOLT_CAUGHT_TRACK = BOLT_CAUGHT_TRACK,
    MAIN_TRACK = MAIN_TRACK,
    ADS_TRACK = ADS_TRACK,

    blending_track_top = blending_track_top,
    MOVEMENT_TRACK = MOVEMENT_TRACK,

    base_track_state = base_track_state,
    bolt_caught_states = bolt_caught_states,
    main_track_states = main_track_states,
    gun_kick_state = gun_kick_state,
    ADS_states = ADS_states,
    movement_track_states = movement_track_states,

    INPUT_BOLT_CAUGHT = "bolt_caught",
    INPUT_BOLT_NORMAL = "bolt_normal",
    INPUT_INSPECT_RETREAT = "inspect_retreat",
    INPUT_AIM = "aim",
    INPUT_AIM_RETREAT = "aim_retreat"
}

function M:initialize(context)
    context:ensureTrackLineSize(track_line_top.value)
    context:ensureTracksAmount(STATIC_TRACK_LINE, static_track_top.value)
    context:ensureTracksAmount(BLENDING_TRACK_LINE, blending_track_top.value)
    self.movement_track_states.run.mode = -1
    self.movement_track_states.walk.mode = -1
end

function M:exit(context)
end

function M:states()
    return {
        self.base_track_state,
        self.bolt_caught_states.normal,
        self.main_track_states.start,
        self.gun_kick_state,
        self.ADS_states.normal,
        self.movement_track_states.idle
    }
end

return M