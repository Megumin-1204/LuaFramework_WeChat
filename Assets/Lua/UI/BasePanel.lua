-- Assets/Lua/UI/BasePanel.lua
local Class = Class        -- 全局已注册
local UILayer = require("UI.UILayer")

local BasePanel = Class("BasePanel")

function BasePanel:ctor(go)
    -- 1. 挂载层级
    --    面板类上可声明： MyPanel.Layer = "Popup"
    local layerKey = self.class and self.class.Layer or nil
    UILayer.SetPanelLayer(go, layerKey)

    -- 2. 基础初始化
    self.gameObject = go
    self.transform  = go.transform

    -- 3. 缓存通用组件
    self:CacheComponents()

    -- 4. 子类 Init
    if self.Init then self:Init() end

    -- 5. 面板显示后钩子
    if self.OnShow then self:OnShow() end
end

-- 自动缓存常用组件，可根据项目需求扩展
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

-- 虚方法，子类实现
function BasePanel:Init()    end
function BasePanel:OnShow()  end
function BasePanel:OnHide()  end

function BasePanel:Destroy()
    if self.gameObject then
        CS.UnityEngine.Object.Destroy(self.gameObject)
        self.gameObject = nil
        self.transform  = nil
    end
end

return BasePanel
