local BasePanel = require("UI.BasePanel")
local LoginPanel = Class("LoginPanel", BasePanel)
LoginPanel.Layer = "Popup"

function LoginPanel:OnCreate()
    self.BtnStart = self:GetComponent("BtnStart")
    self.BtnNotice = self:GetComponent("BtnNotice")
    self.BtnClearCache = self:GetComponent("BtnClearCache")
    self.BtnSwitch = self:GetComponent("BtnSwitch")
end

-- 由 BasePanel:OnEnable 调用
function LoginPanel:BindEvents(params)
    self:AddListener("BtnStart", self.OnClickBtnStart)
end

function LoginPanel:OnClickBtnStart()
    print("OnClickBtnStart")
    local UIMgr = require("UI.UIMgr")
    UIMgr.ShowPanel("RoleSelectPanel")
end

-- 可选的“显示”逻辑
function LoginPanel:OnShow(params)
    print("[LoginPanel] OnShow 可选钩子")
end

-- 隐藏时
function LoginPanel:OnHide()
    print("[LoginPanel] OnHide")
end

-- 销毁时
function LoginPanel:OnDestroy()
    print("[LoginPanel] OnDestroy")
end

return LoginPanel