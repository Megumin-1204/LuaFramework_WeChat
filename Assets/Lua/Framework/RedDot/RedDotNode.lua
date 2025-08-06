local RedDotNode = {}
RedDotNode.__index = RedDotNode

function RedDotNode.New(key)
    return setmetatable({
        key = key,             -- 节点唯一标识
        active = false,        -- 红点状态值 (布尔值)
        children = {},         -- 子节点列表
        parent = nil,          -- 父节点
        callbacks = {},        -- 回调函数列表
        dirty = false,         -- 脏标记
        isLeaf = true          -- 是否为叶子节点
    }, RedDotNode)
end

-- 设置红点状态
function RedDotNode:SetActive(active)
    if self.active == active then return end

    self.active = active
    self.dirty = true

    if self.parent then
        self.parent:MarkDirty()
    end

    -- 叶子节点立即通知
    if self.isLeaf then
        self:NotifyCallbacks()
    end
end

-- 标记为脏节点
function RedDotNode:MarkDirty()
    if self.dirty then return end
    self.dirty = true
    if self.parent then self.parent:MarkDirty() end
end

-- 添加子节点
function RedDotNode:AddChild(child)
    table.insert(self.children, child)
    child.parent = self
    self.isLeaf = false
end

-- 更新节点值（递归更新子节点）
function RedDotNode:UpdateValue()
    if not self.dirty then return end

    -- 非叶子节点计算子节点状态
    if not self.isLeaf then
        local anyChildActive = false
        for _, child in ipairs(self.children) do
            child:UpdateValue()  -- 确保子节点先更新
            if child.active then
                anyChildActive = true
            end
        end

        -- 状态变化时更新
        if self.active ~= anyChildActive then
            self.active = anyChildActive
            self:NotifyCallbacks()
        end
    end

    -- 清除脏标记
    self.dirty = false
end

-- 通知所有回调函数
function RedDotNode:NotifyCallbacks()
    for _, callback in ipairs(self.callbacks) do
        callback(self.key, self.active)
    end
end

-- 添加回调函数
function RedDotNode:AddCallback(callback)
    table.insert(self.callbacks, callback)
    -- 添加时立即通知当前状态
    callback(self.key, self.active)
end

-- 移除回调函数
function RedDotNode:RemoveCallback(callback)
    for i = #self.callbacks, 1, -1 do
        if self.callbacks[i] == callback then
            table.remove(self.callbacks, i)
        end
    end
end

-- 获取节点状态字符串
function RedDotNode:GetStateString(prefix)
    local state = prefix .. self.key .. ": " .. (self.active and "ON" or "OFF")
    local childPrefix = prefix .. "  "

    for _, child in ipairs(self.children) do
        state = state .. "\n" .. child:GetStateString(childPrefix)
    end

    return state
end

return RedDotNode