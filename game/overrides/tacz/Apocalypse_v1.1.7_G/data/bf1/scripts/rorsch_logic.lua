--AmengyLoad的恩情还不完
local M = {}
local max = 19  -- 满蓄力进度需求
local step =1 -- 一次伪射击进度增幅
local edge =50 --宽限，松手多久时触发，单位ms

function M.shoot(api)
        local t1 = api:getLastShootTimestamp()
        local t2 = api:getCurrentTimestamp()
        local itv = api:getShootInterval()
        local cache = api:getCachedScriptData()
        -- 别忘：时间单位是ms
        if (t2 - t1 <= itv+edge) then
            -- 没有松手（宽限为edge/ms）
            if cache.proc>=max then
                cache.overCharge = true
                api:shootOnce(api:isShootingNeedConsumeAmmo())
                cache.timer = 8
                cache.overCharge = false
                cache.trigger = false
                cache.proc = 0
            else
                cache.proc = cache.proc+step
                cache.trigger = true
            end
        else
            cache.proc = 0
            cache.trigger = false
        end
        cache.procd = cache.proc
        api:cacheScriptData(cache)
end

function M.handle_shoot_heat(api)
end

function M.tick_heat(api,heatTimestamp)
    local cache = api:getCachedScriptData()
    if (cache == nil) then --如果没有就先初始化
            cache = {
                proc = 0, -- 初始值(蓄力进度)
                procd = 0, --处理后值
                trigger = false, -- 是否正在连按
                overCharge = false, --是否过蓄
                x_spread = 0,
                y_spread = 0,
                timer = 0 -- 计时器，用于在过蓄后手动冷却
        }
    end
    if (cache.timer)>0 then
        local delay_timer = cache.timer
        cache.timer = math.max(delay_timer -1,0)
        api:setOverheatLocked(true)
    else
        api:setOverheatLocked(false)
    end
    local t1 = api:getLastShootTimestamp()
    local t2 = api:getCurrentTimestamp()
    local itv = api:getShootInterval()
    if ((cache.trigger)and(t2 - t1 > 2*itv+edge)and(api:getAmmoCountInMagazine()>=1)) then
        --松手且有蓄力进度,则按照蓄力进度执行复数次发射逻辑，清除蓄力进度
        cache.trigger = false
        if cache.procd>=0 then
            if cache.procd>=24 then
                api:shootOnce(api:isShootingNeedConsumeAmmo())
                cache.timer = 5
            end
        end
        cache.procd=0
        --哈？
    end
    api:cacheScriptData(cache)
end
return M