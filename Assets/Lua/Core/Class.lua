-- Core/Class.lua
local Class = {}

-- 类定义方法
function Class.Define(className, baseClass)
    local cls = {
        __className = className,
        __baseClass = baseClass
    }

    -- 设置继承关系
    if baseClass then
        setmetatable(cls, { __index = baseClass })
    end

    cls.__index = cls

    -- 构造器
    function cls.New(...)
        local instance = setmetatable({}, cls)
        if cls.Constructor then
            cls.Constructor(instance, ...)
        end
        return instance
    end

    return cls
end

-- 导出方式（不污染全局）
return Class