local M = {}

local function getReloadTimingFromParam(param)
    local auto_tactical_reload_cooldown = param.auto_tactical_reload_cooldown * 1000
    local auto_tactical_reload_feed = param.auto_tactical_reload_feed * 1000
    local auto_empty_reload_cooldown = param.auto_empty_reload_cooldown * 1000
    local auto_empty_reload_feed = param.auto_empty_reload_feed * 1000
    local burst_tactical_reload_cooldown = param.burst_tactical_reload_cooldown * 1000
    local burst_tactical_reload_feed = param.burst_tactical_reload_feed * 1000
    local burst_empty_reload_cooldown = param.burst_empty_reload_cooldown * 1000
    local burst_empty_reload_feed = param.burst_empty_reload_feed * 1000
    -- 这两个判断是用来检查以上 12 个参数是否有缺失的，若有缺失则不获取任何参数。其实是可以写进一个判断语句的，但是这样的话整个句子会过长影响阅读所以我就拆成 3 个了
    if (auto_tactical_reload_cooldown == nil or auto_tactical_reload_feed == nil or auto_empty_reload_cooldown == nil or auto_empty_reload_feed == nil) then
        return nil
    end
    if (burst_tactical_reload_cooldown == nil or burst_tactical_reload_feed == nil or burst_empty_reload_cooldown == nil or burst_empty_reload_feed == nil) then
        return nil
    end
    -- 顺序返回获取到的这 12 个参数
    return auto_tactical_reload_cooldown, auto_tactical_reload_feed, auto_empty_reload_cooldown, auto_empty_reload_feed, burst_tactical_reload_cooldown, burst_tactical_reload_feed, burst_empty_reload_cooldown, burst_empty_reload_feed
end

function M.start_reload(api)
    local cache = {
        reloaded = 0,
        needed_count = api:getNeededAmmoAmount(),
        is_tactical = api:getReloadStateType() == TACTICAL_RELOAD_FEEDING 
    }
    api:cacheScriptData(cache)
    return true
end

function M.tick_reload(api)
    local param = api:getScriptParams();
    local auto_tactical_reload_cooldown, auto_tactical_reload_feed, auto_empty_reload_cooldown, auto_empty_reload_feed, burst_tactical_reload_cooldown, burst_tactical_reload_feed, burst_empty_reload_cooldown, burst_empty_reload_feed = getReloadTimingFromParam(param)
    local reload_time = api:getReloadTime()
    local cache = api:getCachedScriptData()
    if (api:getFireMode() == AUTO) then
        if (cache.is_tactical) then
            if (reload_time < auto_tactical_reload_feed) then
                return TACTICAL_RELOAD_FEEDING, auto_tactical_reload_feed - reload_time
            elseif (reload_time >= auto_tactical_reload_feed and reload_time < auto_tactical_reload_cooldown) then
                if (cache.reloaded ~= 1) then
                    if (api:isReloadingNeedConsumeAmmo()) then
                        api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count))
                    else
                        api:putAmmoInMagazine(cache.needed_count)
                    end
                    cache.reloaded = 1
                end
                return TACTICAL_RELOAD_FINISHING, auto_tactical_reload_cooldown - reload_time
            else
                return NOT_RELOADING, -1
            end
        else
            if (reload_time < auto_empty_reload_feed) then
                return EMPTY_RELOAD_FEEDING, auto_empty_reload_feed - reload_time
            elseif (reload_time >= auto_empty_reload_feed and reload_time < auto_empty_reload_cooldown) then
                if (cache.reloaded ~= 1) then
                    if (api:isReloadingNeedConsumeAmmo()) then
                        api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count) - 1)
                    else
                        api:putAmmoInMagazine(cache.needed_count - 1)
                    end
                    api:setAmmoInBarrel(true)
                    cache.reloaded = 1
                end
                return EMPTY_RELOAD_FINISHING, auto_empty_reload_cooldown - reload_time
            else
                return NOT_RELOADING, -1
            end
        end
    elseif (api:getFireMode() == BURST) then
        if (cache.is_tactical) then
            if (reload_time < burst_tactical_reload_feed) then
                return TACTICAL_RELOAD_FEEDING, burst_tactical_reload_feed - reload_time
            elseif (reload_time >= burst_tactical_reload_feed and reload_time < burst_tactical_reload_cooldown) then
                if (cache.reloaded ~= 1) then
                    if (api:isReloadingNeedConsumeAmmo()) then
                        api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count))
                    else
                        api:putAmmoInMagazine(cache.needed_count)
                    end
                    cache.reloaded = 1
                end
                return TACTICAL_RELOAD_FINISHING, burst_tactical_reload_cooldown - reload_time
            else
                return NOT_RELOADING, -1
            end
        else
            if (reload_time < burst_empty_reload_feed) then
                return EMPTY_RELOAD_FEEDING, burst_empty_reload_feed - reload_time
            elseif (reload_time >= burst_empty_reload_feed and reload_time < burst_empty_reload_cooldown) then
                if (cache.reloaded ~= 1) then
                    if (api:isReloadingNeedConsumeAmmo()) then
                        api:putAmmoInMagazine(api:consumeAmmoFromPlayer(cache.needed_count) - 1)
                    else
                        api:putAmmoInMagazine(cache.needed_count - 1)
                    end
                    api:setAmmoInBarrel(true)
                    cache.reloaded = 1
                end
                return EMPTY_RELOAD_FINISHING, burst_empty_reload_cooldown - reload_time
            else
                return NOT_RELOADING, -1
            end
        end
    end
end

return M