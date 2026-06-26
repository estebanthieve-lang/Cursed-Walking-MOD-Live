local M = {}

function M.shoot(api)
        if(api:getFireMode() == AUTO)then
            api:shootOnce(api:isShootingNeedConsumeAmmo())
        end
    if(api:getFireMode() == SEMI)then
        api:shootOnce(api:isShootingNeedConsumeAmmo())
        api:removeAmmoFromMagazine(5)
    end
end

return M