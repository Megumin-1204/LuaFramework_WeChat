-- Assets/Lua/UI/BasePanel.lua
-- 基础面板类，所有 Lua 面板继承自它
local BasePanel = Class("BasePanel")

function BasePanel:ctor(go)
    self.gameObject = go
    self.transform  = go.transform
    -- 缓存通用组件
    self:CacheComponents()
    -- 调用子类 Init（如果有）
    if self.Init then self:Init() end
    -- 面板显示后钩子
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
