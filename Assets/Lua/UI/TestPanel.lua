-- Assets/Lua/UI/TestPanel.lua
local BasePanel = require("UI.BasePanel")
local TestPanel = Class("TestPanel", BasePanel)
TestPanel.Layer = "Popup"

function TestPanel:OnCreate()
    local txt = self:GetComponent("TextTitle", typeof(CS.UnityEngine.UI.Text))
    txt.text = "示例面板"
end

-- 由 BasePanel:OnEnable 调用
function TestPanel:BindEvents(params)
    self:AddListener("BtnTest", function()
        print("[TestPanel] 按钮被点击, params.foo=", params.foo)
    end)
end

-- 可选的“显示”逻辑
function TestPanel:OnShow(params)
    print("[TestPanel] OnShow 可选钩子")
end

-- 隐藏时
function TestPanel:OnHide()
    print("[TestPanel] OnHide")
end

-- 销毁时
function TestPanel:OnDestroy()
    print("[TestPanel] OnDestroy")
end

return TestPanel
