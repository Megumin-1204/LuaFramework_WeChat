-- Core/ModuleManager.lua
-- 简化的商业级模块管理：支持注册、启动、停止

local ModuleManager = {
    modules = {},   -- name -> module table
    current = nil,  -- 当前活跃模块
}

--- 注册模块
-- moduleTable 可实现 OnStart(params...), OnStop(), Enter(params...), Exit()
function ModuleManager:RegisterModule(name, moduleTable)
    assert(type(name) == "string",    "RegisterModule: name must be string")
    assert(type(moduleTable) == "table","RegisterModule: module must be table")
    self.modules[name] = moduleTable
    print(string.format("[ModuleManager] Registered module '%s'", name))
end

--- 启动（或切换到）模块
function ModuleManager:StartModule(name, ...)
    local mod = self.modules[name]
    if not mod then error("Module not found: " .. name) end

    -- 如果已有当前模块，先退出
    if self.current and self.current.Exit then
        self.current:Exit()
    end
    if self.current and self.current.OnStop then
        self.current:OnStop()
    end

    -- 切换并启动
    self.current = mod
    if mod.OnStart then mod:OnStart(...) end
    if mod.Enter   then mod:Enter(...)   end

    print(string.format("[ModuleManager] Started module '%s'", name))
end

--- 停止（退出）指定模块
function ModuleManager:StopModule(name)
    local mod = self.modules[name]
    if not mod then return end
    if mod.Exit   then mod:Exit()   end
    if mod.OnStop then mod:OnStop() end
    if self.current == mod then self.current = nil end
    print(string.format("[ModuleManager] Stopped module '%s'", name))
end

--- 一次性批量注册并启动核心模块（可在 Entry.Main 调用）
function ModuleManager:BootCoreModules()
    -- 举例：请根据项目实际模块列表修改
    self:RegisterModule("Event", require("Core.EventManager"))
    self:RegisterModule("Timer", require("Core.TimerManager"))
    self:RegisterModule("UI",    require("UI.UIMgr"))
    self:RegisterModule("Net",   require("Core.NetManager"))
    --self:RegisterModule("Res",   require("Core.ResourceManager"))
    -- … 继续注册 Login、Main、Audio、Data 模块等

    -- 按顺序启动：先走全局逻辑，再进业务
    self:StartModule("Event")
    self:StartModule("Timer")
    self:StartModule("UI")
    self:StartModule("Net")
    --self:StartModule("Res")
    -- … 最后启动 Login 流程
    self:StartModule("Login")
end

return ModuleManager
