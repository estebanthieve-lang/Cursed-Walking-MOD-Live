local M = {}

-- 当开始换弹的时候会调用一次
function M.start_reload(api)
    -- cache 相当于一个缓存，这里面可以存一些数据
    -- 这里在开始换弹时定义缓存是在做初始化
    local cache = {
        -- 这是一个判断弹量的数值是否已经发生了变化的标志位， 0 是还没有装填， 1 是已经装填
        reloaded = 0,
        -- 这是判断当前这把枪需要装多少发
        needed_count = api:getNeededAmmoAmount(),
        ammo_amount = api:getAmmoAmount()
    }
    api:cacheScriptData(cache)
    -- 这里必须返回 true 了之后才会开启之后的 tick_reload 方法，因此必须写
    return true
end

-- 这是个 lua 函数，用来从枪 data 文件里获取装弹相关的动画时间点，由于 lua 内的时间是毫秒，所以要和 1000 做乘算
local function getReloadTimingFromParam(param)
    local reload_tactical_feed = param.reload_tactical_feed * 1000
    local reload_tactical_cooldown = param.reload_tactical_cooldown * 1000
    local reload_empty_feed = param.reload_empty_feed * 1000
    local reload_empty_cooldown = param.reload_empty_cooldown * 1000
    if (reload_tactical_feed == nil or reload_tactical_cooldown == nil or reload_empty_feed == nil or reload_empty_cooldown == nil) then
        return nil
    end
    return reload_tactical_feed, reload_tactical_cooldown, reload_empty_feed, reload_empty_cooldown
end

-- 在换弹过程中每一帧都会执行的事，注意这里的帧不是 mc 的 tick
function M.tick_reload(api)
    local param = api:getScriptParams();
    local reload_time = api:getReloadTime()
    local reload_tactical_feed, reload_tactical_cooldown, reload_empty_feed, reload_empty_cooldown = getReloadTimingFromParam(param)
    -- 从玩家身上获取脚本开头缓存的数据
    local cache = api:getCachedScriptData()
    -- 照例检查是否有参数缺失
    if (reload_tactical_feed == nil or reload_tactical_cooldown == nil or reload_empty_feed == nil or reload_empty_cooldown == nil) then
        return nil
    end
    -- 战术换弹
    if (cache.ammo_amount > 0) then
        -- 当换弹时间还不到战术装填时间时返回 FEEDING 和距离装填时间节点的剩余时间
        if (reload_time < reload_tactical_feed) then
            return TACTICAL_RELOAD_FEEDING, reload_tactical_feed - reload_time
        -- 当换弹时间达到了战术装填时间但是又没有完成整个流程时返回 FINISHING 和距离结束时间节点的剩余时间
        elseif (reload_time >= reload_tactical_feed and reload_time < reload_tactical_cooldown) then
            -- 因为装填动作只进行一次而脚本却每一帧都在跑，所以需要一个标志位告诉我“装填”这一动作是否已经执行过了
            if (cache.reloaded ~= 1) then
                if (api:isReloadingNeedConsumeAmmo()) then
                    api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count))
                else
                    api:putAmmoInMagazine(cache.needed_count)
                end
                cache.reloaded = 1
            end
            return TACTICAL_RELOAD_FINISHING, reload_tactical_cooldown - reload_time
        else
            return NOT_RELOADING, -1
        end
    -- 空仓换弹
    else
        -- 当换弹时间还不到战术装填时间时返回 FEEDING 和距离装填时间节点的剩余时间
        if (reload_time < reload_empty_feed) then
            return TACTICAL_RELOAD_FEEDING, reload_empty_feed - reload_time
        elseif (reload_time >= reload_empty_feed and reload_time < reload_empty_cooldown) then
            if (cache.reloaded ~= 1) then
                if (not api:isReloadingNeedConsumeAmmo()) then
                api:putAmmoInMagazine(cache.needed_count)
                api:setAmmoInBarrel(true)
                elseif(not api:hasAmmoInBarrel())then
                api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count + 1) - 1)
                api:setAmmoInBarrel(true)
                else
                api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count))
                end
                cache.reloaded = 1
            end
            return TACTICAL_RELOAD_FINISHING, reload_empty_cooldown - reload_time
        else
            return NOT_RELOADING, -1
        end
    end
end

return M

-- Special thanks 辉师傅