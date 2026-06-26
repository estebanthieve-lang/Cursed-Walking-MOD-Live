local default = require("tacz_default_state_machine")
local BLENDING_TRACK_LINE = default.BLENDING_TRACK_LINE
local STATIC_TRACK_LINE = default.STATIC_TRACK_LINE
local MAIN_TRACK = default.MAIN_TRACK
local MOVEMENT_TRACK = default.MOVEMENT_TRACK
local movement_track_states =  default.movement_track_states
local LOOP_TRACK = default.LOOP_TRACK
local run_state = setmetatable({}, {__index = movement_track_states.run})
local walk_state = setmetatable({}, {__index = movement_track_states.walk})

-- 进入奔跑态
function run_state.entry(this, context)
    this.movement_track_states.run.mode = -1
    this.movement_track_states.run.time = context:getCurrentTimestamp()
    -- 此处播放的轨道是混合轨道行的移动轨道,播放的动画是奔跑的起手式,播放结束后是挂起动画而不是停止
    context:runAnimation("run_start", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.2)
end

-- 退出奔跑态
function run_state.exit(this, context)
    -- 此时播放的动画是奔跑结束回到 idle 的动画,同理播放完后挂起
    local isCrawl = context:isCrawl()
    context:runAnimation("run_end", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.3)
    context:runAnimation("run_add_hold", context:getTrack(BLENDING_TRACK_LINE, LOOP_TRACK) , true, PLAY_ONCE_STOP , 0.3)
    if (isCrawl) then
        context:runAnimation("sliding", context:findIdleTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.3)
    end
end

-- 更新奔跑态
function run_state.update(this, context)
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    local loop_track = context:getTrack(BLENDING_TRACK_LINE, LOOP_TRACK)
    local state = this.movement_track_states.run;
    -- 等待 run_start 结束,然后循环播放 run ,此处的判断准则是轨道是否挂起,也就是为什么 entry 里播放动画要选 PLAY_ONCE_HOLD 模式
    if (context:isHolding(track)) then
        context:anchorWalkDist() -- 打 walkDist 锚点，确保 run 动画的起点一致
        context:runAnimation("run", track, true, LOOP, 0.2)
        context:runAnimation("run_add", loop_track, true, LOOP, 0.2)
        -- 检测是否奔跑的标志位 0
        state.mode = 0
    end
    if (state.mode ~= -1) then
        if (not context:isOnGround()) then
            -- 如果玩家在空中，则播放 run_hold 动画以稳定枪身
            if (state.mode ~= 1) then
                state.mode = 1
                context:runAnimation("run_hold", track, true, LOOP, 0.6)
                context:runAnimation("run_add_hold", loop_track, true, LOOP, 0.6)
            end
        else
            -- 如果玩家在地面，则切换回 run 动画
            if (state.mode ~= 0) then
                state.mode = 0
                context:anchorWalkDist() -- 打 walkDist 锚点，确保 run 动画的起点一致
                context:runAnimation("run", track, true, LOOP, 0.2)
                context:runAnimation("run_add", loop_track, true, LOOP, 0.2)
            end
            -- 根据 walkDist 设置 run 动画的进度
            context:setAnimationProgress(track, (context:getWalkDist() % 2.0) / 2.0, true)
            context:setAnimationProgress(loop_track, (context:getWalkDist() % 8.0) / 8.0, true)
        end
    end
end

-- 转出奔跑态
function run_state.transition(this, context, input)
    -- 收到闲置输入则转去闲置态
    if (input == INPUT_IDLE) then
        return this.movement_track_states.idle
    -- 收到行走输入则转去行走态
    elseif (input == INPUT_WALK or not context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
        return this.movement_track_states.walk
    end
end
-- 进入行走态
function walk_state.entry(this, context)
    -- 此时给标志位置为 -1 相当于一个初始化
    this.movement_track_states.walk.mode = -1
end

-- 退出行走态
function walk_state.exit(this, context)
    -- 手动播放一次 idle 动画以打断 walk 动画的循环
    context:runAnimation("idle", context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK), true, PLAY_ONCE_HOLD, 0.4)
end

-- 更新行走态
function walk_state.update(this, context)
    -- 此处获取的是混合轨道行的移动轨道
    local track = context:getTrack(BLENDING_TRACK_LINE, MOVEMENT_TRACK)
    -- 这里的 state 代指自身,相当于一个简化写法
    local state = this.movement_track_states.walk
    if (not context:isOnGround()) then
        -- 如果玩家在空中，则播放 idle 动画以稳定枪身
        if (state.mode ~= 0) then
            state.mode = 0
            context:runAnimation("idle", track, true, LOOP, 0.6)
        end
    elseif (context:getAimingProgress() > 0.5) then
        -- 如果正在喵准，则需要播放 walk_aiming 动画
        if (state.mode ~= 1 or state.mode ~= 1.1 or state.mode ~= 1.2) then
            if (context:isInputLeft() and state.mode ~= 1.1) then
            state.mode = 1.1
            context:runAnimation("walk_aiming_left", track, true, LOOP, 0.5)
            context:anchorWalkDist()
            elseif (context:isInputRight() and state.mode ~= 1.2) then
            state.mode = 1.2
            context:runAnimation("walk_aiming_right", track, true, LOOP, 0.5)
            context:anchorWalkDist()
            elseif ((context:isInputUp() or context:isInputDown()) and state.mode ~= 1 and not (context:isInputLeft() or context:isInputRight())) then
            state.mode = 1
            context:runAnimation("walk_aiming", track, true, LOOP, 0.5)
            context:anchorWalkDist()
            end
        end
    elseif (context:isInputUp() and not (context:isInputLeft() or context:isInputRight())) then
        -- 如果正在向前走，则需要播放 walk_forward 动画
        if (state.mode ~= 2) then
            state.mode = 2
            context:runAnimation("walk_forward", track, true, LOOP, 0.5)
            context:anchorWalkDist() -- 打 walkDist 锚点，确保行走动画的起点一致
        end
    elseif (context:isInputDown() and not (context:isInputLeft() or context:isInputRight())) then
        -- 如果正在向后退，则需要播放 walk_backward 动画
        if (state.mode ~= 3) then
            state.mode = 3
            context:runAnimation("walk_backward", track, true, LOOP, 0.5)
            context:anchorWalkDist() -- 打 walkDist 锚点，确保行走动画的起点一致
        end
    elseif (context:isInputLeft()) then
        -- 如果正在向侧面，则需要播放 walk_sideway 动画
        if (state.mode ~= 4) then
            state.mode = 4
            context:runAnimation("walk_leftway", track, true, LOOP, 0.5)
            context:anchorWalkDist() -- 打 walkDist 锚点，确保行走动画的起点一致
        end
    elseif (context:isInputRight()) then
        -- 如果正在向侧面，则需要播放 walk_sideway 动画
        if (state.mode ~= 5) then
            state.mode = 5
            context:runAnimation("walk_rightway", track, true, LOOP, 0.5)
            context:anchorWalkDist() -- 打 walkDist 锚点，确保行走动画的起点一致
        end
    end
    -- 根据 walkDist 设置行走动画的进度
    if (state.mode >= 1 and state.mode <= 5) then
        context:setAnimationProgress(track, (context:getWalkDist() % 2.0) / 2.0, true)
    end
end

-- 转出行走态,这部分和转出奔跑态是一样的
function walk_state.transition(this, context, input)
    -- 收到闲置信号则转到闲置态
    if (input == INPUT_IDLE) then
        return this.movement_track_states.idle
    -- 收到奔跑信号则转到奔跑态
    elseif (input == INPUT_RUN) then
        if (context:isStopped(context:getTrack(STATIC_TRACK_LINE, MAIN_TRACK))) then
            return this.movement_track_states.run
        end
    end
end
-- 结束移动轨道的状态

local M = setmetatable({
    movement_track_states = setmetatable({
    run = run_state,
    walk = walk_state,
    }, {__index = movement_track_states}),
    LOOP_TRACK = LOOP_TRACK,
}, {__index = default})

function M:initialize(context)
    default.initialize(self, context)
    self.movement_track_states.run.mode = -1
    self.movement_track_states.walk.mode = -1
end

return M