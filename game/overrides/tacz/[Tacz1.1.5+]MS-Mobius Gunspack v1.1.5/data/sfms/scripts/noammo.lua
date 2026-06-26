-- 定义逻辑机模块 
local M = {}
 
-- 射击主函数（核心修改点）
function M.shoot(api) 
    -- 获取当前武器射击模式 
    local fire_mode = api:getFireMode()
    
    -- 执行基础射击逻辑（关键修改点）
    local shoot_success = false 
    if fire_mode == AUTO then 
        shoot_success = api:autoFire(false) -- 参数false表示不消耗弹药 
    elseif fire_mode == BURST then 
        shoot_success = api:burstFire(false)
    else 
        shoot_success = api:singleFire(false)
    end 
 
    -- 强制维持弹药量（双重保障）
    if shoot_success then 
        local current_ammo = api:getAmmoCountInMagazine()
        api:setAmmoCountInMagazine(current_ammo) -- 同步当前弹药量 
    end 
 
    -- 保留装填检测逻辑 
    if api:needManualReload() then 
        api:startManualReload()
    end 
    
    return true 
end 
 
-- 保留原版装填函数（无需修改）
function M.start_reload(api) 
    local cache = {
        reloaded = 0,
        needed_count = api:getNeededAmmoAmount(),
        is_tactical = api:getReloadStateType() == TACTICAL_RELOAD_FEEDING 
    }
    api:cacheScriptData(cache)
    return true 
end 
 
return M 