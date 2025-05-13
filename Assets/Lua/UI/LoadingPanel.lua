-- Assets/Lua/UI/LoadingPanel.lua
local BasePanel = require("UI.BasePanel")
local LoadingPanel = Class("LoadingPanel", BasePanel)
LoadingPanel.Layer = "Popup"

function LoadingPanel:OnCreate()
    -- 拿到 C# 组件
    self.view = self.transform:GetComponent(typeof(CS.LoadingPanel))
    assert(self.view, "请挂载 LoadingPanel.cs")
end

function LoadingPanel:OnEnable(params)
    self:SetProgress((params and params.initialProgress) or 0)
end

function LoadingPanel:SetProgress(p)
    p = math.clamp(p,0,1)
    pcall(function() self.view.progressBar.value = p end)
    local txt = math.floor(p*100).."%%"
    pcall(function() self.view.progressText.text = txt end)
end

return LoadingPanel
