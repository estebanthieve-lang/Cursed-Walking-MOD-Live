-- 脚本的位置是 "{命名空间}:{路径}"，那么 require 的格式为 "{命名空间}_{路径}"
-- 注意！require 取得的内容不应该被修改，应仅调用
local default = require("bf1_manual_action_state_machine")
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local BOLT_CAUGHT_TRACK = default.BOLT_CAUGHT_TRACK
local main_track_states = default.main_track_states
local GUN_KICK_TRACK_LINE = default.GUN_KICK_TRACK_LINE
-- main_track_states.idle 是我们要重写的状态。
local idle_state = setmetatable({}, {__index = main_track_states.idle})

-- 重写 idle 状态的 transition 函数，讲输入 INPUT_RELOAD 重定向到 bolt_state 状态
function idle_state.transition(this, context, input)
    local ammo_amount = context:getAmmoCount()
    if (input == INPUT_BOLT) then
            context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
            context:runAnimation("bolt", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
            if(ammo_amount == 1)then
            local track = context:findIdleTrack(GUN_KICK_TRACK_LINE, false)
            context:runAnimation("bolt2", track, true, PLAY_ONCE_STOP, 0) -- 这里是混合动画，一般是可叠加的 gun kick
            end
            return this.main_track_states.bolt
        end
    if (input == INPUT_SHOOT) then
        -- 绕过抛壳，因为手动上膛的枪不会自动抛壳
        context:runAnimation("static_bolt_caught", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, LOOP, 0)
        return this.main_track_states.idle
    end
    if (input == INPUT_RELOAD) then
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        if (ammo_amount < 1) then
            context:runAnimation("reload_empty", track, false, PLAY_ONCE_STOP, 0.2)
        else
            context:runAnimation("reload_tactical", track, false, PLAY_ONCE_STOP, 0.2)
        end
        return this.main_track_states.idle
    end
--    if (input == INPUT_BAYONET_MUZZLE) then
--        if(ammo_amount == 0) then
--        context:runAnimation("melee_bayonet_charge", context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)    
--        else
--        local counter = this.main_track_states.bayonet_counter
--        local animationName = "melee_bayonet_" .. tostring(counter + 1)
--        this.main_track_states.bayonet_counter = (counter + 1) % 3
--        context:runAnimation(animationName, context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK), false, PLAY_ONCE_STOP, 0.2)
--        end
--        return this.main_track_states.idle
--    end
    return main_track_states.idle.transition(this, context, input)
end

-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    main_track_states = setmetatable({
        -- 自定义的 idle 状态需要覆盖掉父级状态机的对应状态，新建的 bolt 状态也要加进来
        idle = idle_state,
        bolt = bolt_state,
    }, {__index = main_track_states}),
}, {__index = default})
-- 导出状态机
return M