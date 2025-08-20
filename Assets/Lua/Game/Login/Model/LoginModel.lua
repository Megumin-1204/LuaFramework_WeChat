local Class = Class

local LoginModel = Class("LoginModel")

function LoginModel:Login(user, pass, callback)
    -- 假设 HttpService 归 Game/Common
    local http = require("Game.Common.HttpService")
    http:Post("/login", { user=user, pass=pass }, function(response)
        callback(response.code == 200)
    end)
end

return LoginModel
