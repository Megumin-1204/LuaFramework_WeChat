local BasePanel = require("UI.BasePanel")
local RoleSelectPanel = Class("RoleSelectPanel", BasePanel)
RoleSelectPanel.Layer = "Popup"

function RoleSelectPanel:OnCreate()
    self.BtnStart = self:GetComponent("BtnStart")
    self.BtnNotice = self:GetComponent("BtnNotice")
    self.BtnClearCache = self:GetComponent("BtnClearCache")
    self.BtnSwitch = self:GetComponent("BtnSwitch")
end

-- 由 BasePanel:OnEnable 调用
function RoleSelectPanel:BindEvents(params)
    self:AddListener("BtnStart", self.OnClickBtnStart)
end

function RoleSelectPanel:OnClickBtnStart()
    print("OnClickBtnStart")
    local UIMgr = require("UI.UIMgr")
    UIMgr.ShowPanel("RoleSelectPanel")
end

-- 可选的“显示”逻辑
function RoleSelectPanel:OnShow(params)
    print("[RoleSelectPanel] OnShow 可选钩子")
end

-- 隐藏时
function RoleSelectPanel:OnHide()
    print("[RoleSelectPanel] OnHide")
end

-- 销毁时
function RoleSelectPanel:OnDestroy()
    print("[RoleSelectPanel] OnDestroy")
end

return RoleSelectPanel