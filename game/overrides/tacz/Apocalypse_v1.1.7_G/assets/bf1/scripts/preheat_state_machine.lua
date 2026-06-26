local default = require("bf1_movement_state_machine")
local BLENDING_TRACK_LINE = default.BLENDING_TRACK_LINE
local OVER_HEAT_TRACK = default.OVER_HEAT_TRACK
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local main_track_states = default.main_track_states
local GUN_KICK_TRACK_LINE = default.GUN_KICK_TRACK_LINE
-- main_track_states.idle 是我们要重写的状态。
local idle_state = setmetatable({}, {__index = main_track_states.idle})

local gun_kick_state = setmetatable({
    is_preheat = false,
    preheat_time = 0,
}, {__index = default.gun_kick_state})

local function get_preheat_animation_time(context)
    local preheat_animation_duration = context:getStateMachineParams().preheat_animation_time
    if (preheat_animation_duration) then
        preheat_animation_duration = preheat_animation_duration * 1000
    else
        preheat_animation_duration = 0
    end
    return preheat_animation_duration
end

function gun_kick_state.transition(this, context, input)
   local preheat_animation_duration = get_preheat_animation_time(context)
--   local track = context:getTrack(BLENDING_TRACK_LINE, OVER_HEAT_TRACK)
    if (input == INPUT_SHOOT) then
            -- 获取上次射击的 timestamp（系统时间，单位毫秒）
        local last_shoot_timestamp = context:getLastShootTimestamp()
        -- 获取当前系统时间
        local current_timestamp = context:getCurrentTimestamp()
        -- 获取枪械的射击间隔，单位毫秒。用于判断是否在连射，也用于调整射击间隔
        local shoot_interval = context:getShootInterval()
        -- 判断是否在连射，给 2 tick 宽容时间
        if (current_timestamp - last_shoot_timestamp > shoot_interval + 500) then
            gun_kick_state.preheat_time = 0
            gun_kick_state.is_preheat = false
            end
        if (gun_kick_state.preheat_time < preheat_animation_duration) then
            gun_kick_state.preheat_time = gun_kick_state.preheat_time + 100
            if (gun_kick_state.is_preheat == false) then
                context:runAnimation("preheat", context:getTrack(BLENDING_TRACK_LINE, OVER_HEAT_TRACK), true, PLAY_ONCE_STOP, 0)
                gun_kick_state.is_preheat = true
            end
        else
        context:runAnimation("shoot", context:findIdleTrack(GUN_KICK_TRACK_LINE, false), true, PLAY_ONCE_STOP, 0)
        context:runAnimation("spark", context:getTrack(GUN_KICK_TRACK_LINE, false), true, PLAY_ONCE_STOP, 0)
        end
    end
    return nil
end

-- 重写 idle 状态的 transition 函数
function idle_state.transition(this, context, input)
    if (input == INPUT_RELOAD) then
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        context:runAnimation("reload", track, false, PLAY_ONCE_STOP, 0.2)
        return this.main_track_states.idle
    end
    return main_track_states.idle.transition(this, context, input)
end

local M = setmetatable({
    main_track_states = setmetatable({
        idle = idle_state,
    }, {__index = main_track_states}),
    gun_kick_state = gun_kick_state
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
    gun_kick_state.preheat_time = 0
    gun_kick_state.is_preheat = false
end

return M