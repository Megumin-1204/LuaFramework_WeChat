local RedDotNode = require("UI/RedDot/RedDotNode")
local RedDotConfig = require("UI/RedDot/RedDotConfig")  -- 引入配置文件

local RedDotManager = {
    instance = nil  -- 单例实例
}
RedDotManager.__index = RedDotManager

-- 初始化红点管理器
function RedDotManager.Init()
    if RedDotManager.instance then
        print("[RedDot] Manager already initialized")
        return RedDotManager.instance
    end

    -- 创建根节点
    local rootNode = RedDotNode.New("Root")

    local mgr = {
        root = rootNode,
        nodes = { ["Root"] = rootNode },  -- 节点字典 [key] = node
        subManagers = {},             -- 子管理器字典 [名称] = subManager
        updateQueue = {},
        scheduledUpdate = false,
        initialized = false,
        timer = nil                  -- 计时器引用
    }
    setmetatable(mgr, RedDotManager)

    -- 自动初始化所有子管理器
    mgr:InitializeSubManagers()

    mgr.initialized = true
    RedDotManager.instance = mgr

    print("[RedDot] Manager initialized successfully")
    return mgr
end

-- 获取管理器实例
function RedDotManager.GetInstance()
    if not RedDotManager.instance then
        error("[RedDot] Manager not initialized. Call RedDotManager.Init() first")
    end
    return RedDotManager.instance
end

-- 初始化所有子管理器
function RedDotManager:InitializeSubManagers()
    for name, path in pairs(RedDotConfig.SubManagers) do
        local success, subManager = pcall(function()
            local SubManagerClass = require(path)
            return SubManagerClass.New(self)
        end)

        if success and subManager then
            self.subManagers[name] = subManager

            -- 初始化子管理器
            if subManager.Init then
                subManager:Init()
            end

            print(string.format("[RedDot] SubManager '%s' initialized", name))
        else
            print(string.format("[RedDot] Failed to initialize submanager '%s' (%s): %s",
                    name, path, success and "invalid submanager" or subManager))
        end
    end
end

-- 注册节点
function RedDotManager:RegisterNode(key, parentKey)
    -- 默认父节点为Root
    parentKey = parentKey or "Root"

    -- 如果节点已存在，直接返回
    if self.nodes[key] then return self.nodes[key] end

    -- 获取或创建父节点
    local parent = self.nodes[parentKey]
    if not parent then
        -- 父节点不存在，自动创建（默认挂到根节点）
        parent = self:RegisterNode(parentKey)
    end

    -- 创建新节点
    local node = RedDotNode.New(key)
    self.nodes[key] = node

    -- 添加到父节点
    parent:AddChild(node)

    return node
end

-- 设置节点状态
function RedDotManager:SetNodeActive(key, active)
    local node = self.nodes[key]
    if not node then
        -- 节点不存在时自动注册（默认挂到根节点）
        node = self:RegisterNode(key)
    end

    -- 添加到更新队列
    table.insert(self.updateQueue, {
        node = node,
        active = active
    })

    -- 调度延迟更新
    self:ScheduleUpdate()
end

-- 延迟更新机制（使用计时器）
function RedDotManager:ScheduleUpdate()
    if self.scheduledUpdate then return end
    self.scheduledUpdate = true

    -- 取消之前的计时器（如果有）
    if self.timer then
        __gUpdateMgr:ClearTimer(self.timer)
        self.timer = nil
    end

    -- 创建新的计时器（延迟0秒，下一帧执行）
    self.timer = __gUpdateMgr:DoOnce(0,
            function()
                self:ProcessUpdateQueue()
                self.scheduledUpdate = false
                self.timer = nil
            end, self, 0, false)
end

-- 处理更新队列（关键修改）
function RedDotManager:ProcessUpdateQueue()
    if #self.updateQueue == 0 then return end

    -- 批量处理更新
    for _, update in ipairs(self.updateQueue) do
        update.node:SetActive(update.active)
    end

    -- 清空队列
    self.updateQueue = {}

    -- 从根节点开始递归更新整棵树
    self.root:UpdateValue()
end

-- 注册回调函数
function RedDotManager:RegisterCallback(key, callback)
    local node = self.nodes[key]
    if node then
        node:AddCallback(callback)
    else
        -- 节点不存在时自动注册
        node = self:RegisterNode(key)
        node:AddCallback(callback)
    end
end

-- 移除回调函数
function RedDotManager:UnregisterCallback(key, callback)
    local node = self.nodes[key]
    if node then
        node:RemoveCallback(callback)
    end
end

-- 获取节点状态
function RedDotManager:GetNodeActive(key)
    local node = self.nodes[key]
    return node and node.active or false
end

-- 打印节点状态树
function RedDotManager:PrintTree(key)
    key = key or "Root"
    local node = self.nodes[key]

    if not node then
        print("[RedDot] Node not found: " .. key)
        return
    end

    print("Red Dot Tree for [" .. key .. "]:")
    print(node:GetStateString(""))
end

-- 测试方法：打印完整红点树
function RedDotManager:PrintFullTree()
    self:PrintTree("Root")
end

-- 获取子管理器（使用名称）
function RedDotManager:GetSubManager(name)
    local subMgr = self.subManagers[name]
    if not subMgr then
        print(string.format("[RedDot] SubManager '%s' not found", name))
    end
    return subMgr
end

-- 手动移除UI控件的所有红点绑定
function RedDotManager:RemoveAllBindingsForUI(uiElement)
    for _, subManager in pairs(self.subManagers) do
        if subManager.RemoveBindingsForUI then
            subManager:RemoveBindingsForUI(uiElement)
        end
    end
end

-- 销毁管理器
function RedDotManager:Unload()
    -- 取消计时器
    if self.timer then
        __gUpdateMgr:ClearTimer(self.timer)
        self.timer = nil
    end

    -- 先卸载所有子管理器
    for _, subManager in pairs(self.subManagers) do
        if subManager.Unload then
            subManager:Unload()
        end
    end

    self.subManagers = {}
    self.nodes = {}
    self.root = nil
    self.initialized = false
    RedDotManager.instance = nil

    print("[RedDot] Manager unloaded")
end

return RedDotManager