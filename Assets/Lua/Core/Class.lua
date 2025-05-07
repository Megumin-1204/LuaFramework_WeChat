-- Assets/Lua/Core/Class.lua
-- 商业级 OOP 框架

local function Class(name, super, ...)
    assert(type(name) == "string", "Class name must be a string")

    -- 新类表
    local cls = {}
    cls.__name   = name
    cls.super    = super
    cls.static   = {}     -- 存放静态字段

    -- Mixins 支持：把额外的父表/mixin 合并到 cls
    local mixins = {...}
    for _, mix in ipairs(mixins) do
        for k, v in pairs(mix) do
            if cls[k] == nil then cls[k] = v end
        end
    end

    -- 元表：支持继承与 __call
    local mt = {}

    -- __index：实例/类查找时先查自己，再查父类
    mt.__index = cls.super

    -- __call：Class(...) == Class:New(...)
    mt.__call = function(self, ...)
        -- 创建实例
        local instance = setmetatable({}, { __index = cls })
        -- 记录类引用
        instance.class = cls
        -- 调用构造
        if instance.ctor then instance:ctor(...) end
        return instance
    end

    setmetatable(cls, mt)

    -- 构造器方法：可用 cls:New(...) 或者直接 cls(...)
    function cls:New(...)
        -- 走 __call 流程
        return cls(... )
    end

    -- super 方法调用，示例： self:super("MethodName", args...)
    function cls:super(methodName, ...)
        local fn = cls.super and cls.super[methodName]
        assert(type(fn) == "function",
                string.format("super method '%s' not found in class '%s'", methodName, name))
        -- 把 self 传回父类方法
        return fn(self, ...)
    end

    return cls
end

-- 导出到全局
rawset(_G, "Class", Class)
return Class
