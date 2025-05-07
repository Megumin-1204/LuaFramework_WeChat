-- Assets/Lua/UI/BasePanel.lua
-- 注意：这里假定全局已经有 Class() 函数
local UILayer = require("UI.UILayer")

local BasePanel = Class("BasePanel")

function BasePanel:ctor(go)
    -- *** 调试用，确认 ctor 被调用 ***
    print("[BasePanel] ctor, go name:", go.name)

    -- 1. 挂载层级（读取子类的 .Layer 字段）
    local layerKey = self.class and self.class.Layer or nil
    UILayer.SetPanelLayer(go, layerKey)

    -- 2. 保存引用
    self.gameObject = go
    self.transform  = go.transform

    -- 3. 缓存通用组件
    self:CacheComponents()

    -- 4. 子类 Init
    if self.Init then
        self:Init()
    end

    -- 5. 子类 OnShow
    if self.OnShow then
        print("[BasePanel] 触发 OnShow")
        self:OnShow()
    end
end

function BasePanel:CacheComponents()
    self.components = {}
    local map = {
        BtnClose = typeof(CS.UnityEngine.UI.Button),
        TxtTitle = typeof(CS.UnityEngine.UI.Text),
    }
    for name, compType in pairs(map) do
        local child = self.transform:Find(name)
        if child then
            self.components[name] = child:GetComponent(compType)
        end
    end
end

-- 虚方法
function BasePanel:Init() end
function BasePanel:OnShow() end
function BasePanel:OnHide() end

function BasePanel:Destroy()
    if self.gameObject then
        CS.UnityEngine.Object.Destroy(self.gameObject)
        self.gameObject = nil
        self.transform  = nil
    end
end

return BasePanel
