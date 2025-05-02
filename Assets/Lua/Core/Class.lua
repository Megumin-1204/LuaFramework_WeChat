-- Assets/Lua/Core/Class.lua
-- 功能：支持单继承、构造（ctor）、静态字段、super 调用、__call 别名
local function Class(name, super)
    assert(type(name) == "string", "Class name must be a string")
    -- 新类
    local cls = {}
    cls.__name   = name
    cls.__index  = cls
    cls.super    = super
    -- 静态字段表
    cls.static   = {}

    -- 继承：把父类方法放到 cls 的 metatable
    if super then
        setmetatable(cls, { __index = super })
        -- 静态字段继承
        setmetatable(cls.static, { __index = super.static or {} })
    end

    -- 构造 & 继承构造：可用 cls.New 或直接调用 cls(...)
    function cls.New(...)
        local instance = setmetatable({}, cls)
        -- 调用 ctor
        if instance.ctor then instance:ctor(...) end
        return instance
    end

    -- __call 语法糖：允许直接写 MyClass(...)
    setmetatable(cls, {
        __call = function(self, ...)
            return self.New(...)
        end
    })

    return cls
end

-- 注册到全局，之后任何地方都能直接 Class(...)
rawset(_G, "Class",  Class)
return Class
