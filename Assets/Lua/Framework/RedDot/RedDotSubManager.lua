---------------------------
-- RedDotSubManager.lua (子管理器基类)
---------------------------
local RedDotSubManager = {}
RedDotSubManager.__index = RedDotSubManager

function RedDotSubManager.New(manager)
    return setmetatable({
        manager = manager,
        nodes = {},             -- 本模块管理的节点
        uiBindings = {},        -- UI绑定记录 [ui] = {key, callback}
        bindingDictionary = {}  -- 绑定字典 [ui] = {bindings}
    }, RedDotSubManager)
end

-- 初始化子管理器（由具体模块实现）
function RedDotSubManager:Init()
    -- 子类应该实现此方法
    -- 注册本模块需要管理的节点
end

-- 注册节点
function RedDotSubManager:RegisterNode(key, parentKey)
    local node = self.manager:RegisterNode(key, parentKey)
    self.nodes[key] = true
    return node
end

-- 设置节点状态
function RedDotSubManager:SetNodeActive(key, active)
    self.manager:SetNodeActive(key, active)
end

-- 绑定UI到红点（核心方法）
-- handler 可选，如果不传则只确保节点存在
function RedDotSubManager:BindUI(uiElement, key, handler)
    if not uiElement or not key then
        return nil
    end

    -- 确保节点存在
    if not self.manager.nodes[key] then
        self:RegisterNode(key)
    end

    -- 如果没有提供处理函数，只确保节点存在
    if not handler then
        return nil
    end

    -- 创建回调函数
    local callback = function(_, active)
        -- 第一个参数就是绑定的UI元素
        -- 第二个参数是红点状态
        handler(uiElement, active)
    end

    -- 注册回调
    self.manager:RegisterCallback(key, callback)

    -- 记录绑定关系
    local binding = {
        key = key,
        callback = callback,
        handler = handler
    }

    -- 添加到UI绑定列表
    if not self.uiBindings[uiElement] then
        self.uiBindings[uiElement] = {}
    end
    table.insert(self.uiBindings[uiElement], binding)

    -- 添加到绑定字典（用于快速查找）
    self.bindingDictionary[uiElement] = self.bindingDictionary[uiElement] or {}
    self.bindingDictionary[uiElement][key] = binding

    -- 返回绑定ID（用于手动解绑）
    return {uiElement = uiElement, key = key}
end

-- 手动移除特定绑定
function RedDotSubManager:UnbindUI(bindingId)
    if not bindingId then return end

    local uiElement = bindingId.uiElement
    local key = bindingId.key

    if self.bindingDictionary[uiElement] and self.bindingDictionary[uiElement][key] then
        local binding = self.bindingDictionary[uiElement][key]

        -- 从管理器移除回调
        self.manager:UnregisterCallback(key, binding.callback)

        -- 从绑定字典移除
        self.bindingDictionary[uiElement][key] = nil

        -- 从UI绑定列表移除
        for i, b in ipairs(self.uiBindings[uiElement]) do
            if b.key == key then
                table.remove(self.uiBindings[uiElement], i)
                break
            end
        end

        -- 如果UI元素没有其他绑定，清理资源
        if not next(self.bindingDictionary[uiElement]) then
            self.bindingDictionary[uiElement] = nil
            self.uiBindings[uiElement] = nil
        end
    end
end

-- 手动移除UI元素的所有绑定
function RedDotSubManager:RemoveBindingsForUI(uiElement)
    if not uiElement then return end

    -- 获取所有绑定
    local bindings = self.uiBindings[uiElement]
    if not bindings then return end

    -- 移除所有回调
    for _, binding in ipairs(bindings) do
        self.manager:UnregisterCallback(binding.key, binding.callback)
    end

    -- 清理绑定记录
    self.uiBindings[uiElement] = nil
    self.bindingDictionary[uiElement] = nil
end

-- 清理子管理器
function RedDotSubManager:Unload()
    -- 清理所有UI绑定
    for uiElement, bindings in pairs(self.uiBindings) do
        for _, binding in ipairs(bindings) do
            self.manager:UnregisterCallback(binding.key, binding.callback)
        end
    end

    self.uiBindings = {}
    self.bindingDictionary = {}

    -- 清除节点引用（节点本身由管理器管理）
    self.nodes = {}
end

return RedDotSubManager