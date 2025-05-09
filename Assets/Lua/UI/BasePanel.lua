-- Assets/Lua/UI/BasePanel.lua
-- 商用级 UI 面板基类，生命周期对齐 Unity

local UILayer = require("UI.UILayer")
local CS      = CS

local BasePanel = Class("BasePanel")

-- 构造：只调用一次
function BasePanel:ctor(go)
    assert(go and go.transform, "需要一个有效的 GameObject")
    self.gameObject = go
    self.transform  = go.transform
    self._cache     = {}   -- 缓存
    self._listeners = {}   -- 事件绑定记录

    -- 自动挂层
    local layerKey = self.class and self.class.Layer or "Common"
    UILayer.SetPanelLayer(go, layerKey)

    -- 自动绑定关闭按钮
    if self:HasComponent("BtnClose", CS.UnityEngine.UI.Button) then
        self:AddListener("BtnClose", function() self:Destroy() end)
    end

    -- Ctor 完成后钩子
    if self.OnCreate then
        pcall(function() self:OnCreate() end)
    end
end

--- Unity 风格：每次面板激活（显示）时调用
-- @param params table 由 UIMgr.ShowPanel 传入
function BasePanel:OnEnable(params)
    -- 1) 先绑定事件
    if self.BindEvents then
        pcall(function() self:BindEvents(params) end)
    end
    -- 2) 再执行 “显示逻辑”
    if self.OnShow then
        pcall(function() self:OnShow(params) end)
    end
end

--- Unity 风格：每次面板关闭（隐藏）前调用
function BasePanel:OnDisable()
    -- 清理所有注册的监听
    self:ClearListeners()
    if self.OnHide then
        pcall(function() self:OnHide() end)
    end
end

--- 析构前钩子
function BasePanel:OnDestroy()
    if self.OnDestroy then
        pcall(function() self:OnDestroy() end)
    end
end

--- 彻底销毁面板
function BasePanel:Destroy()
    pcall(function() self:OnDisable() end)
    pcall(function() self:OnDestroy() end)
    if self.gameObject then
        CS.UnityEngine.Object.Destroy(self.gameObject)
        self.gameObject = nil
        self.transform  = nil
    end
end

-- ========== 查找 & 缓存 ==========

function BasePanel:GetObject(name)
    if not self._cache[name] then
        local tf = self.transform:Find(name)
        self._cache[name] = tf and tf.gameObject or nil
    end
    return self._cache[name]
end

--- 可选 compType：
--- 如果传了就按类型找，否则自动在常用 UI 组件里扫一遍，找到就返回
function BasePanel:GetComponent(name, compType)
    local key = compType and (name .. "#" .. tostring(compType)) or name
    if not self._cache[key] then
        local go = self:GetObject(name)
        if go then
            if compType then
                self._cache[key] = go:GetComponent(compType)
            else
                -- 常见的 UI 组件列表，按需增删
                local tryTypes = {
                    CS.UnityEngine.UI.Button,
                    CS.UnityEngine.UI.Toggle,
                    CS.UnityEngine.UI.Slider,
                    CS.UnityEngine.UI.InputField,
                    CS.UnityEngine.UI.Text,
                    CS.UnityEngine.UI.Image,
                }
                for _, t in ipairs(tryTypes) do
                    local c = go:GetComponent(typeof(t))
                    if c then
                        self._cache[key] = c
                        break
                    end
                end
            end
        end
    end
    return self._cache[key]
end

function BasePanel:HasComponent(name, compType)
    if compType then
        return self:GetComponent(name, compType) ~= nil
    else
        return self:GetComponent(name) ~= nil
    end
end

-- ========== 通用事件绑定 ==========

function BasePanel:AddListener(name, handler)
    local go = self:GetObject(name)
    assert(go, "AddListener 找不到对象: " .. name)

    -- Button
    local btn = go:GetComponent(typeof(CS.UnityEngine.UI.Button))
    if btn then
        btn.onClick:AddListener(handler)
        table.insert(self._listeners, {comp = btn, method = "onClick", fn = handler})
        return
    end
    -- Toggle
    local tgl = go:GetComponent(typeof(CS.UnityEngine.UI.Toggle))
    if tgl then
        tgl.onValueChanged:AddListener(handler)
        table.insert(self._listeners, {comp = tgl, method = "onValueChanged", fn = handler})
        return
    end
    -- Slider
    local sld = go:GetComponent(typeof(CS.UnityEngine.UI.Slider))
    if sld then
        sld.onValueChanged:AddListener(handler)
        table.insert(self._listeners, {comp = sld, method = "onValueChanged", fn = handler})
        return
    end
    -- InputField
    local input = go:GetComponent(typeof(CS.UnityEngine.UI.InputField))
    if input then
        input.onValueChanged:AddListener(handler)
        table.insert(self._listeners, {comp = input, method = "onValueChanged", fn = handler})
        return
    end

    error("AddListener 不支持的控件类型: " .. name)
end

function BasePanel:ClearListeners()
    for _, info in ipairs(self._listeners) do
        local comp   = info.comp
        local method = comp[info.method]
        if method and method.RemoveListener then
            method:RemoveListener(info.fn)
        end
    end
    self._listeners = {}
end

return BasePanel