-- Assets/Lua/Core/ModuleManager.lua
-- 商业级模块管理：核心模块 vs 业务模块，带日志

local ModuleManager = {
    coreModules  = {},   -- name -> mod
    businessMods = {},   -- name -> mod
    current      = nil,  -- 当前活跃的业务模块
}

local function dbg(fmt, ...)
    print(string.format("[ModuleManager] " .. fmt, ...))
end

--- 注册核心模块（只记录不执行）
function ModuleManager:RegisterCore(name, mod)
    assert(type(name)=="string" and type(mod)=="table", "RegisterCore 参数错误")
    self.coreModules[name] = mod
    dbg("Registered CORE module '%s'", name)
end

--- 启动所有核心模块，调用它们的 OnStart
function ModuleManager:StartCore()
    dbg("Starting CORE modules...")
    for name, mod in pairs(self.coreModules) do
        if mod.OnStart then
            dbg("Core OnStart '%s'", name)
            mod:OnStart()
        else
            dbg("Core module '%s' has no OnStart, skipping", name)
        end
    end
    dbg("CORE modules started")
end

--- 注册业务模块（游戏流程用）
function ModuleManager:RegisterBusiness(name, mod)
    assert(type(name)=="string" and type(mod)=="table", "RegisterBusiness 参数错误")
    self.businessMods[name] = mod
    dbg("Registered BUSINESS module '%s'", name)
end

--- 切换到某个业务模块：先退出上一个，再启动新模块
function ModuleManager:StartModule(name, ...)
    dbg("StartModule called for '%s'", name)
    local mod = self.businessMods[name]
    if not mod then error("Business module not found: " .. name) end

    if self.current then
        dbg("Stopping current module")
        if self.current.Exit then self.current:Exit() end
        if self.current.OnStop then self.current:OnStop() end
    end

    self.current = mod
    dbg("Calling OnStart of '%s'", name)
    if mod.OnStart then mod:OnStart(...) end

    dbg("Calling Enter of '%s'", name)
    if mod.Enter then
        mod:Enter(...)
    else
        dbg("Module '%s' has no Enter()", name)
    end

    dbg("Module '%s' is now active", name)
end

--- 停止当前业务模块
function ModuleManager:StopCurrent()
    if not self.current then return end
    for nm, m in pairs(self.businessMods) do
        if m == self.current then
            dbg("Stopping BUSINESS module '%s'", nm)
            if m.Exit   then m:Exit()   end
            if m.OnStop then m:OnStop() end
            self.current = nil
            return
        end
    end
end

return ModuleManager
