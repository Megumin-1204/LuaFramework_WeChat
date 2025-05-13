-- Assets/Lua/UI/LoginPanel.lua
local BasePanel    = require("UI.BasePanel")
local EventManager = require("Core.EventManager")
local Class        = require("Core.Class")
local LoginPanel   = Class("LoginPanel", BasePanel)

-- 挂在 Popup 层
LoginPanel.Layer = "Popup"

function LoginPanel:OnCreate()
    -- 拿到输入框和按钮
    self.inputUser = self:GetComponent("InputUser", typeof(CS.UnityEngine.UI.InputField))
    self.inputPass = self:GetComponent("InputPass", typeof(CS.UnityEngine.UI.InputField))
    self.btnLogin  = self:GetComponent("BtnLogin",  typeof(CS.UnityEngine.UI.Button))

    -- 绑定点击事件
    if self.btnLogin then
        self.btnLogin.onClick:AddListener(function()
            self:OnLoginClicked()
        end)
    end
end

function LoginPanel:OnEnable(params)
    -- 每次显示清空输入框
    if self.inputUser then self.inputUser.text = "" end
    if self.inputPass then self.inputPass.text = "" end
end

function LoginPanel:OnLoginClicked()
    local u = self.inputUser and self.inputUser.text or ""
    local p = self.inputPass and self.inputPass.text or ""
    if u == "" or p == "" then
        print("请输入用户名和密码")
        return
    end

    -- 派发登录成功事件
    EventManager.Dispatch("LOGIN_SUCCESS", { user = u })
end

return LoginPanel
