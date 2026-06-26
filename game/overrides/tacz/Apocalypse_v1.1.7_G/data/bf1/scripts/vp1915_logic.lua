local M = {}

function M.shoot(api)
        local num
        if ((api:getAmmoAmount() + 1) > 2) then
            num = 2
        else
            num = api:getAmmoAmount() + 1
        end
        for i = 1, num, 1 do
            api:shootOnce(api:isShootingNeedConsumeAmmo())
        end
--        api:getEntityUtil():hurt(2)
end

return M

-- Special thanks 辉师傅