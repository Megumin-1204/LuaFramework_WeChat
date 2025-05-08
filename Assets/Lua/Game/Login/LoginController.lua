local Class       = Class
local ModuleMgr   = require("Core.ModuleManager")
local LoginModel  = require("Game.Login.LoginModel")
local LoginView   = require("Game.Login.LoginView")

local LoginController = Class("LoginController")

function LoginController:ctor()
    self.model = LoginModel()
    self.view  = LoginView()
    self:BindEvents()
end

function LoginController:BindEvents()
    -- View 通过 BasePanel:AddListener 提供了通用事件接口
    self.view:AddListener("BtnLogin", function()
        local u = self.view:GetInput("Username")
        local p = self.view:GetInput("Password")
        self:OnLoginClicked(u, p)
    end)
end

function LoginController:OnLoginClicked(username, password)
    self.model:Login(username, password, function(success)
        if success then
            ModuleMgr.Switch("Main")
        else
            print("登录失败")
        end
    end)
end

return LoginController
