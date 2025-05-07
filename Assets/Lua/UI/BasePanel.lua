-- Assets/Lua/UI/BasePanel.lua
-- 商用级 UI 面板基类

local UILayer = require("UI.UILayer")

local BasePanel = Class("BasePanel")

function BasePanel:ctor(go)
    self.gameObject = go
    self.transform  = go.transform

    -- 缓存常用表
    self._listeners = {}    -- 存 { go, event, handler } 记录
    self._cache      = {}   -- 存 子节点 & 组件，避免重复查找

    -- 先做一次基础查找
    self:CacheRootComponents()

    -- 生命周期：构造完成后只调用一次
    if self.Init then self:Init() end
end

-- 每次面板被显示时由外部 UIMgr 负责调用
function BasePanel:OnShow()
    -- 子类可覆盖
end

-- 每次面板被隐藏/关闭前由外部 UIMgr 负责调用
function BasePanel:OnHide()
    -- 子类可覆盖
    self:ClearListeners()
end

-- 析构，销毁 GameObject
function BasePanel:Destroy()
    self:ClearListeners()
    if self.gameObject then
        CS.UnityEngine.Object.Destroy(self.gameObject)
        self.gameObject = nil
        self.transform  = nil
    end
end

-- ===============================
-- 缓存 & 查找工具
-- ===============================

-- 首次初始化时绑定默认节点（如 BtnClose、TxtTitle）
function BasePanel:CacheRootComponents()
    -- 可以在子类重载扩展
    self:Find("BtnClose")
    self:Find("TxtTitle")
end

-- 查找子节点并缓存 GameObject
function BasePanel:Find(name)
    if not self._cache[name] then
        local tf = self.transform:Find(name)
        self._cache[name] = tf and tf.gameObject or nil
    end
    return self._cache[name]
end

-- 获取子节点的组件并缓存
function BasePanel:Get(name, compType)
    local key = name.."#"..tostring(compType)
    if not self._cache[key] then
        local go = self:Find(name)
        if go then
            self._cache[key] = go:GetComponent(compType)
        end
    end
    return self._cache[key]
end

-- ===============================
-- 事件监听工具
-- ===============================

-- 添加一个监听，并自动记录到 self._listeners
--   go: GameObject or Component
--   event: 比如 "onClick", "onValueChanged"
--   handler: Lua function
function BasePanel:AddListener(go, event, handler)
    if not go or not handler then return end
    local comp = go[event]
    if comp and comp.AddListener then
        comp:AddListener(handler)
        table.insert(self._listeners, {go=go, ev=event, fn=handler})
    end
end

-- 移除一个监听（如果底层支持 RemoveListener）
function BasePanel:RemoveListener(go, event, handler)
    if go and handler then
        local comp = go[event]
        if comp and comp.RemoveListener then
            comp:RemoveListener(handler)
        end
    end
    -- 同时从 self._listeners 中清理
    for i=#self._listeners,1,-1 do
        local info=self._listeners[i]
        if info.go==go and info.ev==event and info.fn==handler then
            table.remove(self._listeners,i)
        end
    end
end

-- 清理所有已注册的监听
function BasePanel:ClearListeners()
    for _,info in ipairs(self._listeners) do
        local go,ev,fn = info.go,info.ev,info.fn
        local comp = go and go[ev]
        if comp and comp.RemoveListener then
            comp:RemoveListener(fn)
        end
    end
    self._listeners = {}
end

-- ===============================
-- 分层挂载方法
-- ===============================

-- 如果想在 Init 里就挂层，也可调用：
function BasePanel:SetLayer(layerKey)
    local go = self.gameObject
    if go then UILayer.SetPanelLayer(go, layerKey) end
end

return BasePanel
