-- Assets/Lua/Game/Login/LoginController.lua
local Class        = require("Core.Class")
local EventManager = require("Core.EventManager")
local ModuleManager= require("Core.ModuleManager")
local UIMgr        = require("UI.UIMgr")

local LoginModule = Class("LoginModule")

function LoginModule:OnStart()
    print("[LoginModule] OnStart 被调用")
    EventManager.AddListener("LOGIN_SUCCESS", function()
        ModuleManager:StartModule("Test")
    end)
end

function LoginModule:Enter()
    print("[LoginModule] ==> Enter() 被调用，下面尝试弹出 LoginPanel")
    local ok, err = pcall(function()
        UIMgr.ShowPanel("LoginPanel", {
            onLoaded = function(panel) print("[LoginModule] onLoaded 回调", panel) end,
            onFailed = function(e)     print("[LoginModule] onFailed 回调", e)   end,
        })
    end)
    print("[LoginModule] pcall 结果：", ok, err)
end

function LoginModule:Exit()
    print("[LoginModule] Exit() 被调用")
    UIMgr.ClosePanel("LoginPanel")
end

return LoginModule
