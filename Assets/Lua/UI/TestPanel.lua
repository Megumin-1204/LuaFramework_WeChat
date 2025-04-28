local BasePanel = require("UI.BasePanel")
local TestPanel = Class("TestPanel", BasePanel)

function TestPanel:OnInit()
    -- 绑定UI组件
    self.btnTest = self.transform:Find("BtnTest"):GetComponent(typeof(CS.Button))
    self.txtTitle = self.transform:Find("TxtTitle"):GetComponent(typeof(CS.Text))

    -- 初始化显示
    self.txtTitle.text = "Test Panel"
end

function TestPanel:SetClickCallback(callback)
    CS.XLuaHelper.AddClick(self.btnTest.gameObject, function()
        print("[UI] Test button clicked")
        if callback then callback() end
    end)
end

return TestPanel