local default = require("bf1_movement_state_machine")

local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local BOLT_CAUGHT_TRACK = default.BOLT_CAUGHT_TRACK

local bolt_caught_states = {
    -- normal 是不空挂的正常状态
    normal = {},
    -- bolt_caught 是空挂时的状态
    bolt_caught = {}
}
-- 检查当前是否还有弹药
local function isNoAmmo(context)
    -- 这里同时检查了枪管和弹匣
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

-- 更新"不空挂"状态
function bolt_caught_states.normal.update(this, context)
    -- 如果弹药数量是 0 了,那么立刻手动触发一次转到"空挂"状态的输入
    if (isNoAmmo(context)) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        context:trigger(this.INPUT_BOLT_CAUGHT)
    else
        local a = context:getAmmoCount()
        if (a < 21) then
            context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK),0.1+(20-a)*0.5,false)
        else
            context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK),0.1,false)
        end
    end
end

-- 进入"不空挂"状态
function bolt_caught_states.normal.entry(this, context)
    context:runAnimation("static_ammo_display", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, PLAY_ONCE_STOP, 0)
    this.bolt_caught_states.normal.update(this, context)
end
-- 转出"不空挂"状态
function bolt_caught_states.normal.transition(this, context, input)
    -- 如果收到了"空挂"的输入,那么直接转到"空挂"状态,"'空挂'的输入"是在上文 update 方法中出现的
    if (input == this.INPUT_BOLT_CAUGHT) then
        return this.bolt_caught_states.bolt_caught
    end
end

-- 进入"空挂"状态
function bolt_caught_states.bolt_caught.entry(this, context)
    -- 进入空挂时在主轨道行的空挂轨道播放空挂的动画
    context:runAnimation("static_bolt_caught", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, LOOP, 0)
end

-- 更新"空挂"状态
function bolt_caught_states.bolt_caught.update(this, context)
    -- 如果检测到子弹数不为 0 了(此时是换弹了),那么手动触发一次转到"不空挂"状态的输入
    if (not isNoAmmo(context)) then
        context:trigger(this.INPUT_BOLT_NORMAL)
    end
end

-- 转出"空挂"状态
function bolt_caught_states.bolt_caught.transition(this, context, input)
    -- 如果收到了来自上文 update 方法的输入,则转到"不空挂"状态
    if (input == this.INPUT_BOLT_NORMAL) then
        -- 由于并没有一个"不空挂"的动画,因此必须在这里把空挂动画停止了才能转到"不空挂"状态,否则你会在换完弹之后发现依旧处于空挂状态
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        return this.bolt_caught_states.normal
    end
end
-- 结束空挂部分

-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    bolt_caught_states = bolt_caught_states
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
    return {
        self.base_track_state,
        self.bolt_caught_states.normal,
        self.main_track_states.start,
        self.gun_kick_state,
        self.movement_track_states.idle
    }
end

return M