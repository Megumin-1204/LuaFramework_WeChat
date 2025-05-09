-- Core/EventManager.lua
-- 商业级事件总线，支持优先级、一次性监听、延迟派发、事件池隔离、默认参数

local EventManager = {}

-- 引入 Lua 层的定时器管理
local Timer = require("Core.TimerManager")

-- 内部：所有事件池
local _eventPools = {}

-- 获取或创建一个事件池
-- @param poolName string?  池名称，不传或为 nil 则使用 "__global"
-- @return table            对应的事件池表
local function GetPool(poolName)
    poolName = poolName or "__global"
    if not _eventPools[poolName] then
        _eventPools[poolName] = {}
    end
    return _eventPools[poolName]
end

-- 添加监听器
-- @param eventName string         事件名
-- @param callback function        回调函数
-- @param opts table?              可选字段：{ once=bool, priority=number, pool=string }
-- @param ... any                  注册时绑定的“默认参数”
function EventManager.AddListener(eventName, callback, opts, ...)
    assert(type(eventName) == "string",   "EventManager.AddListener: eventName must be a string")
    assert(type(callback)  == "function", "EventManager.AddListener: callback must be a function")

    opts = opts or {}
    local pool = GetPool(opts.pool)
    pool[eventName] = pool[eventName] or {}

    -- 构造监听器对象
    local listener = {
        callback    = callback,
        once        = opts.once     or false,
        priority    = opts.priority or 0,
        defaultArgs = {...},
    }

    table.insert(pool[eventName], listener)
    -- 按优先级降序排序，优先级高的先执行
    table.sort(pool[eventName], function(a, b)
        return a.priority > b.priority
    end)
end

-- 移除监听器
-- @param eventName string
-- @param callback function
-- @param opts table?    可选字段：{ pool=string }
function EventManager.RemoveListener(eventName, callback, opts)
    assert(type(eventName) == "string",   "EventManager.RemoveListener: eventName must be a string")
    assert(type(callback)  == "function", "EventManager.RemoveListener: callback must be a function")

    local pool = GetPool(opts and opts.pool)
    local list = pool[eventName]
    if not list then return end

    for i = #list, 1, -1 do
        if list[i].callback == callback then
            table.remove(list, i)
        end
    end
end

-- 内部：在指定事件池中派发
-- @param poolName string?  池名称
-- @param eventName string  事件名
-- @param ... any           触发时参数
function EventManager.DispatchInPool(poolName, eventName, ...)
    assert(type(eventName) == "string", "EventManager.Dispatch: eventName must be a string")

    local pool = GetPool(poolName)
    local list = pool[eventName]
    if not list then return end

    local triggerArgs = {...}
    -- 反向遍历，以便安全地在回调中移除 once 类型的监听器
    for i = #list, 1, -1 do
        local lst = list[i]
        -- 合并默认参数 + 触发参数
        local allArgs = {}
        for _, v in ipairs(lst.defaultArgs) do table.insert(allArgs, v) end
        for _, v in ipairs(triggerArgs)    do table.insert(allArgs, v) end

        local ok, err = pcall(lst.callback, table.unpack(allArgs))
        if not ok then
            print(string.format("[EventManager] Error in '%s': %s", eventName, err))
        end

        if lst.once then
            table.remove(list, i)
        end
    end
end

-- 全局派发（默认池）
-- @param eventName string
-- @param ... any
function EventManager.Dispatch(eventName, ...)
    return EventManager.DispatchInPool(nil, eventName, ...)
end

-- 延迟派发（单位：秒），依赖 TimerManager
-- @param delay number     延迟秒数
-- @param eventName string
-- @param ... any
function EventManager.DispatchLater(delay, eventName, ...)
    assert(type(delay)     == "number",   "EventManager.DispatchLater: delay must be a number")
    assert(type(eventName) == "string",   "EventManager.DispatchLater: eventName must be a string")
    local args = { ... }
    Timer.ScheduleOnce(delay, function()
        EventManager.Dispatch(eventName, table.unpack(args))
    end)
end

-- 清除某个事件的所有监听
-- @param eventName string
-- @param opts table?    可选字段：{ pool=string }
function EventManager.Clear(eventName, opts)
    assert(type(eventName) == "string", "EventManager.Clear: eventName must be a string")
    local pool = GetPool(opts and opts.pool)
    pool[eventName] = nil
end

-- 清空整个事件池
-- @param poolName string?  池名称，不传则清空全局池
function EventManager.ClearAll(poolName)
    poolName = poolName or "__global"
    _eventPools[poolName] = {}
end

return EventManager
