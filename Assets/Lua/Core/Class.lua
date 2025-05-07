-- Assets/Lua/Core/Class.lua
-- 轻量级 OOP 支持：单继承、ctor 构造、super 调用、__call 语法糖
local function Class(name, super)
    assert(type(name) == "string", "Class name must be a string")
    local cls = {}
    cls.__name = name
    cls.super  = super

    -- 给 class 本身设置元表：__index 指向 super，__call 用于实例化
    setmetatable(cls, {
        -- 类方法查找：先从 cls 本身找，再从 super 找
        __index = super,
        -- 调用 Class(...) 时触发实例化
        __call = function(c, ...)
            -- 新实例的元表 __index 指回 cls
            local instance = setmetatable({}, { __index = cls })
            -- 执行构造函数
            if instance.ctor then instance:ctor(...) end
            return instance
        end
    })

    return cls
end

-- 注册到全局
rawset(_G, "Class", Class)
return Class
