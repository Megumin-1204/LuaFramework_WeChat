local ModuleManager = {
    modules = {},     -- 已注册模块
    current = nil     -- 当前模块
}

function ModuleManager.Register(name, module)
    ModuleManager.modules[name] = module
    print("[Module] Registered:", name)
end

function ModuleManager.Switch(name, ...)
    if ModuleManager.current then
        ModuleManager.current:Exit()
    end
    
    local module = ModuleManager.modules[name]
    if not module then
        error("Module not found: " .. name)
    end
    
    ModuleManager.current = module
    module:Enter(...)
end

return ModuleManager