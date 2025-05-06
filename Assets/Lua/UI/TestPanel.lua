-- Assets/Lua/UI/TestPanel.lua
-- 一个示例面板，继承自 BasePanel
local BasePanel = require("UI.BasePanel")
local TestPanel = Class("TestPanel", BasePanel)
TestPanel.Layer = "Popup"

function TestPanel:Init()
    -- 缓存特有组件
    self.BtnTest  = self.transform:Find("BtnTest"):GetComponent(typeof(CS.UnityEngine.UI.Button))
    self.TextTitle = self.transform:Find("TextTitle"):GetComponent(typeof(CS.UnityEngine.UI.Text))
    -- 初始化显示
    self.TextTitle.text = "这是 TestPanel"
end

-- 面板显示后钩子
function TestPanel:OnShow()
    print("[TestPanel] 已显示，实例ID:", self.gameObject:GetInstanceID())
    -- 例如自动绑定关闭按钮
    if self.components.BtnClose then
        self.components.BtnClose.onClick:AddListener(function() self:Destroy() end)
    end
end

-- 对外注册按钮回调
function TestPanel:SetClickCallback(cb)
    if self.BtnTest then
        CS.XLuaHelper.AddClick(self.BtnTest.gameObject, function()
            print("[TestPanel] 按钮被点击")
            if cb then pcall(cb) end
        end)
    end
end

return TestPanel
