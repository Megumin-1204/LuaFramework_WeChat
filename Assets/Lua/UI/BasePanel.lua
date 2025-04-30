-- UI/BasePanel.lua
local BasePanel = class("BasePanel")

function BasePanel:ctor(go)
    self.gameObject = go
    self.transform = go.transform
    self:CacheComponents() -- 自动缓存组件
    self:Init()            -- 虚方法
end

-- 自动绑定组件（需在预制体规范命名）
function BasePanel:CacheComponents()
    self.components = {}
    local function cache(childName)
        local child = self.transform:Find(childName)
        if child then
            self.components[childName] = child:GetComponent(typeof(CS.UnityEngine.Component))
        end
    end

    cache("BtnClose")
    cache("TxtTitle")
    -- 其他通用组件...
end

-- 虚方法：子类实现
function BasePanel:Init() end
function BasePanel:OnShow() end
function BasePanel:OnHide() end

function BasePanel:Destroy()
    CS.UnityEngine.Object.Destroy(self.gameObject)
end

return BasePanel