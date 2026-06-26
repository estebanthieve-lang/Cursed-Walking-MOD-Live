local default = require("bf1_movement_state_machine")

local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local BOLT_CAUGHT_TRACK = default.BOLT_CAUGHT_TRACK
local main_track_states = default.main_track_states
local MAIN_TRACK = default.MAIN_TRACK
local BLENDING_TRACK_LINE = default.BLENDING_TRACK_LINE
local SLIDE_TRACK = default.SLIDE_TRACK
local ADS_TRACK = default.ADS_TRACK
local ADS_states = default.ADS_states
local idle_state = setmetatable({}, {__index = main_track_states.idle})
local ads_state = setmetatable({}, {__index = ADS_states.aiming})
local bolt_caught_states = default.bolt_caught_states
local normal_state = setmetatable({}, {__index = bolt_caught_states.normal})

local crawl_states = {
    draw = {},
    normal = {},
    crawl = {},
    played_animation = 0
}

-- 检查当前是否还有弹药
local function isNoAmmo(context)
    -- 这里同时检查了枪管和弹匣
    return (not context:hasBulletInBarrel()) and (context:getAmmoCount() <= 0)
end

-- 更新"不空挂"状态
function normal_state.update(this, context)
    -- 如果弹药数量是 0 了,那么立刻手动触发一次转到"空挂"状态的输入
    if (isNoAmmo(context)) then
        context:stopAnimation(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK))
        context:trigger(this.INPUT_BOLT_CAUGHT)
    else
        local a = context:getAmmoCount()
        if (a < 16) then
            context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK),0.1+(15-a)*0.5,false)
        else
            context:setAnimationProgress(context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK),0.1,false)
        end
    end
end

-- 进入"不空挂"状态
function normal_state.entry(this, context)
    context:runAnimation("static_ammo_display", context:getTrack(STATIC_TRACK_LINE, BOLT_CAUGHT_TRACK), false, PLAY_ONCE_STOP, 0)
    this.bolt_caught_states.normal.update(this, context)
end
-- 转出"不空挂"状态
function normal_state.transition(this, context, input)
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

-- 重写 idle 状态的 transition 函数
function idle_state.transition(this, context, input)
    if (input == INPUT_RELOAD) then
        local ext = context:getMagExtentLevel()
        local track = context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)
        if (isNoAmmo(context)) then
            if (ext == 3) then
            context:runAnimation("reload_empty_xmag", track, false, PLAY_ONCE_STOP, 0.2)
            else
            context:runAnimation("reload_empty", track, false, PLAY_ONCE_STOP, 0.2)
            end
        else
            if (ext == 3) then
            context:runAnimation("reload_tactical_xmag", track, false, PLAY_ONCE_STOP, 0.2)
            else
            context:runAnimation("reload_tactical", track, false, PLAY_ONCE_STOP, 0.2)
            end
        end
        return this.main_track_states.idle
    end
    return main_track_states.idle.transition(this, context, input)
end

-- 进入瞄准状态
function ads_state.entry(this, context)
    -- 开始瞄准时播放瞄准动画，并且将其挂起
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (context:isCrawl() or context:isCrouching()) then
    context:runAnimation("aim2", track, false, PLAY_ONCE_HOLD, 0.2)
    else
    context:runAnimation("aim_start", track, false, PLAY_ONCE_HOLD, 0.2)
    end
    -- 打断检视动画
    context:trigger(this.INPUT_INSPECT_RETREAT)
end

-- 更新瞄准状态
function ads_state.update(this, context)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (context:isHolding(track)) then
        -- 循环播放瞄准时的动画
        if (context:isCrawl() or context:isCrouching()) then
        context:runAnimation("aim2", track, false, PLAY_ONCE_HOLD, 0.2)
        else
        context:runAnimation("aim", track, false, PLAY_ONCE_HOLD, 0.2)
        end
    end
    -- 当瞄准进度正在减小时转到不瞄准状态，也即取消瞄准
    if (context:getAimingProgress() < this.ADS_states.aiming_progress or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        context:trigger(this.INPUT_AIM_RETREAT)
    else
        -- 如果没有减小，则记录当前瞄准进度
        this.ADS_states.aiming_progress = context:getAimingProgress()
    end
end

-- 转出瞄准状态
function ads_state.transition(this, context, input)
    local track = context:getTrack(STATIC_TRACK_LINE, ADS_TRACK)
    if (input == this.INPUT_AIM_RETREAT) then
        --播放瞄准结束动画，并调整动画进度使开镜动画与当前的开镜进度相对应
        if (context:isCrawl() or context:isCrouching()) then
        context:runAnimation("aim2", track, false, PLAY_ONCE_HOLD, 0.2)
        else
        context:runAnimation("aim_end", track, false, PLAY_ONCE_HOLD, 0.2)
        end
        context:setAnimationProgress(track, 1 - context:getAimingProgress(), true)
        return this.ADS_states.normal
    end
end

function crawl_states.normal.transition(this, context, input)
    -- 趴下时切到趴下状态
    if (context:isCrawl() and not context:isAiming()) then
        return this.crawl_states.crawl
    end
end

function crawl_states.crawl.entry(this, context)
    -- 重置主轨道动画标志位
    crawl_states.played_animation = 0
end

function crawl_states.crawl.update(this, context)
    -- 主轨道正在播放动画 且 趴下轨道无动画 时播放脚架单独展开
    if ((not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) and context:isStopped(context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK))) then
        context:runAnimation("crawl_bipod", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.5)
        crawl_states.played_animation = 1
    end
    -- 主轨道无动画 且 趴下轨道无动画 时播放趴下的起手式
    if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)) and context:isStopped(context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK))) then
        context:runAnimation("slide", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.5)
    end
    -- 主轨道无动画 且 趴下轨道被挂起（其实就是起手式播放完了） 时播放趴下的持续动作
    if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK)) and context:isHolding(context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK))) then
        -- 主轨道没有播放过动画 持续播放趴下动作
        if (crawl_states.played_animation == 0) then
            context:runAnimation("slide_idle", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.4)
        --主轨道播放过动画 用单独的手臂归为动画回到趴下状态并重置标志位
        elseif (crawl_states.played_animation == 1) then
            context:runAnimation("crawl_handup", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.4)
            crawl_states.played_animation = 0
        end
    end
    -- 主轨道正在播放动画 且 趴下轨道被挂起 时将趴下的叠加层清除掉并将标志位置1
    if ((not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) and context:isHolding(context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK))) then
        if (crawl_states.played_animation == 0) then
            context:runAnimation("crawl_handdown", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_HOLD, 0.4)
            crawl_states.played_animation = 1
        end
    end
end

function crawl_states.crawl.transition(this, context, input)
    if(not context:isCrawl() or this.main_track_states.final.isfinal == 1 or context:isAiming()) then
        if (not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
            context:runAnimation("crawl_bipod_end", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_STOP, 0.2)
        else
            context:runAnimation("slide_back", context:getTrack(BLENDING_TRACK_LINE, SLIDE_TRACK), true, PLAY_ONCE_STOP, 0.2)
        end
        print("exit")
        return this.crawl_states.normal
    end
end

-- 用元表的方式继承默认状态机的属性
local M = setmetatable({
    main_track_states = setmetatable({
        idle = idle_state,
    }, {__index = main_track_states}),
    bolt_caught_states = setmetatable({
        normal = normal_state,
    }, {__index = bolt_caught_states}),
    ADS_states = setmetatable({
        aiming = ads_state,
    }, {__index = ADS_states}),
    crawl_states = crawl_states
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
end

function M:states()
    return {
        self.base_track_state,
        self.bolt_caught_states.normal,
        self.main_track_states.start,
        self.over_heat_states.normal,
        self.gun_kick_state,
        self.movement_track_states.idle,
        self.ADS_states.aiming,
        self.slide_states.normal,
        self.crawl_states.normal
    }
end

return M