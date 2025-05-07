-- Assets/Lua/UI/TestPanel.lua
local BasePanel = require("UI.BasePanel")
local TestPanel = Class("TestPanel", BasePanel)

-- 默认层级
TestPanel.Layer = "Popup"

-- 一次性初始化（只调用一次）
function TestPanel:Init()
    -- 挂层级（也可在 UIMgr 里做）
    self:SetLayer(self.class.Layer)

    -- 缓存特有组件
    self.BtnTest    = self:Get("BtnTest",    typeof(CS.UnityEngine.UI.Button))
    self.TextTitle  = self:Get("TextTitle",  typeof(CS.UnityEngine.UI.Text))

    -- 初始化显示
    self.TextTitle.text = "欢迎使用测试面板"
end

-- 每次显示时调用
function TestPanel:OnShow()
    print("[TestPanel] OnShow 开始执行", self.BtnTest)
    print("[TestPanel] OnShow, 实例ID=", self.gameObject:GetInstanceID())

    -- 确认 BtnTest 拿到的是什么
    if self.BtnTest then
        print("[TestPanel] BtnTest 组件存在，name=", self.BtnTest.gameObject.name)
        print("[TestPanel] BtnTest targetGraphic=", tostring(self.BtnTest.targetGraphic))
        print("[TestPanel] BtnTest.interactable=", tostring(self.BtnTest.interactable))

        -- 清空旧 listener
        self.BtnTest.onClick:RemoveAllListeners()
        -- 重新绑定
        self.BtnTest.onClick:AddListener(function()
            print("[TestPanel] 按钮被点击（Unity 原生 onClick）")
        end)
    else
        print("[TestPanel] BtnTest 组件没有找到！")
    end
end


-- 每次隐藏前调用
function TestPanel:OnHide()
    print("[TestPanel] OnHide")
    -- 所有 listeners 已由基类清理
end

return TestPanel
