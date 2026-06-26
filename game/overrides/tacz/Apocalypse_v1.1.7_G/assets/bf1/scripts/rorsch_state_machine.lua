local default = require("bf1_movement_state_machine")
local BLENDING_TRACK_LINE = default.BLENDING_TRACK_LINE
local OVER_HEAT_TRACK = default.OVER_HEAT_TRACK
local main_track_states = default.main_track_states
local GUN_KICK_TRACK_LINE = default.GUN_KICK_TRACK_LINE
local bolt_caught_states = default.bolt_caught_states
local normal_states = setmetatable({
    proc = 0,
}, {__index = bolt_caught_states.normal})

local gun_kick_state = setmetatable({
    is_charging = false,
    charging_time = 0,
}, {__index = default.gun_kick_states})

local function isNoAmmo(context)
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

local function get_chargeing_animation_time(context)
    local charge_animation_duration = context:getStateMachineParams().charge_time
    if (charge_animation_duration) then
        charge_animation_duration = charge_animation_duration * 1000
    else
        charge_animation_duration = 0
    end
    return charge_animation_duration
end

function gun_kick_state.transition(this, context, input)
    local charge_animation_duration = get_chargeing_animation_time(context)
    if (input == INPUT_SHOOT) then
        if (gun_kick_state.charging_time < charge_animation_duration) then
            gun_kick_state.charging_time = gun_kick_state.charging_time + 50
            if (gun_kick_state.is_charging == false) then
                gun_kick_state.is_charging = true
                context:runAnimation("charge", context:getTrack(BLENDING_TRACK_LINE, OVER_HEAT_TRACK), true, PLAY_ONCE_STOP, 0)
            end
        else
        context:runAnimation("shoot", context:findIdleTrack(GUN_KICK_TRACK_LINE, false), true, PLAY_ONCE_STOP, 0)
        gun_kick_state.charging_time = 0
        end
    end
    return nil
end

function normal_states.update(this, context)
    local last_shoot_timestamp = context:getLastShootTimestamp()
    local current_timestamp = context:getCurrentTimestamp()
    local shoot_interval = context:getShootInterval()
    if (gun_kick_state.is_charging == true) then
        normal_states.proc = normal_states.proc + 1
        if ((normal_states.proc > 20) and (current_timestamp - last_shoot_timestamp > shoot_interval + 100)) then
        context:stopAnimation(context:getTrack(BLENDING_TRACK_LINE, OVER_HEAT_TRACK))
        context:runAnimation("charge_cancel", context:findIdleTrack(GUN_KICK_TRACK_LINE, false), true, PLAY_ONCE_STOP, 0)
        gun_kick_state.is_charging = false
        gun_kick_state.charging_time = 0
        normal_states.proc = 0
        end
    end
    if (isNoAmmo(context)) then
        gun_kick_state.is_charging = false
        normal_states.proc = 0
        context:trigger(this.INPUT_BOLT_CAUGHT)
    end
end

local M = setmetatable({
    main_track_states = setmetatable({
    }, {__index = main_track_states}),
    gun_kick_state = gun_kick_state,
    bolt_caught_states = setmetatable({
    normal = normal_states,
    }, {__index = bolt_caught_states}),
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
    gun_kick_state.charging_time = 0
    gun_kick_state.is_charging = false
    normal_states.proc = 0
end

return M