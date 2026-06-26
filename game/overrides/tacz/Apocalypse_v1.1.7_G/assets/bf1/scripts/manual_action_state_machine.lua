local default = require("bf1_movement_state_machine")
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local BOLT_CAUGHT_TRACK = default.BOLT_CAUGHT_TRACK
local main_track_states = default.main_track_states
-- main_track_states.idle 是我们要重写的状态。
local idle_state = setmetatable({}, {__index = main_track_states.idle})
-- bolt_state 是定义的新状态，用于执行定时抛壳
local bolt_state = {
    timestamp = -1,
    ejection_time = 0,
    popped = false
}
local function isNoAmmo(context)
    -- 这里同时检查了枪管和弹匣
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

-- 重写 idle 状态的 transition 函数，讲输入 INPUT_RELOAD 重定向到 bolt_state 状态
function idle_state.transition(this, context, input)
    local state = this.main_track_states.bolt
    if (input == INPUT_BOLT) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        context:runAnimation("bolt", context:findIdleTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        state.ejection_time = context:getStateMachineParams().bolt_shell_ejecting_time * 1000
        return this.main_track_states.bolt
    end
    if (input == INPUT_SHOOT) then
        -- 绕过抛壳，因为手动上膛的枪不会自动抛壳
        context:runAnimation("static_bolt_caught", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, LOOP, 0)
        return this.main_track_states.idle
    end
    if (input == INPUT_RELOAD) then
        if (isNoAmmo(context)) then
            context:runAnimation("reload_empty", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
            state.ejection_time = context:getStateMachineParams().reload_shell_ejecting_time * 1000
            return this.main_track_states.bolt
        else
            context:runAnimation("reload_tactical", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
        end
        return this.main_track_states.idle
    end
    return main_track_states.idle.transition(this, context, input)
end
-- 进入 bolt 状态，初始化时间戳和参数
function bolt_state.entry(this, context)
    local state = this.main_track_states.bolt
    state.timestamp = context:getCurrentTimestamp()
    state.popped = false
end
-- 在恰当的时候执行抛壳逻辑，然后退出状态
function bolt_state.update(this, context)
    local state = this.main_track_states.bolt
    if (state.popped) then
        return
    end
    local base_timestamp = state.timestamp
    local current_timestamp = context:getCurrentTimestamp()
    if (current_timestamp - base_timestamp > state.ejection_time) then
        context:popShellFrom(0)
        state.popped = true
        context:trigger(this.INPUT_BOLT_RETREAT)
    end
end
function bolt_state.transition(this, context, input)
    if (input == this.INPUT_BOLT_RETREAT) then
        return this.main_track_states.idle
    end
    return this.main_track_states.idle.transition(this, context, input)
end
-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    main_track_states = setmetatable({
        -- 自定义的 idle 状态需要覆盖掉父级状态机的对应状态，新建的 bolt 状态也要加进来
        idle = idle_state,
        bolt = bolt_state,
    }, {__index = main_track_states}),
    INPUT_BOLT_RETREAT = "bolt_retreat"
}, {__index = default})
-- 导出状态机
return M