local M = {}

function M.shoot(api)
    api:safeAsyncTask(function ()
        api:shootOnce(api:isShootingNeedConsumeAmmo())
        return false
    end,0.58*10000,0,1)
end

return M

-- Special thanks 辉师傅