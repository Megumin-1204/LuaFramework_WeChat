-- 面板配置表
-- 每个面板在此注册，包括路径、层级、资源路径等
local PanelConfig = {
    -- 示例：登录面板
    LoginPanel = {
        scriptPath = "Game.Login.View.LoginPanel",  -- Lua脚本路径
        layer = "Popup",                       -- 层级
        prefabPath = "UI/LoginPanel",          -- Prefab在Resources下的路径
        isSingleton = true,                    -- 是否为单例面板
        poolSize = 0,                          -- 对象池大小（0表示不使用对象池）
    },

    -- 示例：角色选择面板
    RoleSelectPanel = {
        scriptPath = "Game.Role.RoleSelectPanel",
        layer = "Popup",
        prefabPath = "UI/RoleSelectPanel",
        isSingleton = true,
    },

    -- 默认UI目录下的面板（不需要修改现有代码）
    TestPanel = {
        scriptPath = "UI.TestPanel",
        layer = "Common",
        prefabPath = "UI/TestPanel",
        isSingleton = false,
    },

    LoadingPanel = {
        scriptPath = "UI.LoadingPanel",
        layer = "Top",
        prefabPath = "UI/LoadingPanel",
        isSingleton = true,
    },
}

-- 获取面板配置（带错误处理）
function PanelConfig.GetConfig(panelName)
    local config = PanelConfig[panelName]
    if not config then
        local errMsg = string.format("[PanelConfig] 未找到面板配置: %s", panelName)
        print(errMsg)
        error(errMsg)
    end
    return config
end

-- 获取面板脚本路径
function PanelConfig.GetScriptPath(panelName)
    return PanelConfig.GetConfig(panelName).scriptPath
end

-- 获取面板Prefab路径
function PanelConfig.GetPrefabPath(panelName)
    return PanelConfig.GetConfig(panelName).prefabPath
end

-- 获取面板层级
function PanelConfig.GetLayer(panelName)
    return PanelConfig.GetConfig(panelName).layer
end

-- 是否是单例面板
function PanelConfig.IsSingleton(panelName)
    return PanelConfig.GetConfig(panelName).isSingleton
end

return PanelConfig