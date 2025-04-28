local EventManager = {
    listeners = {}
}

function EventManager.AddListener(eventName, callback)
    if not EventManager.listeners[eventName] then
        EventManager.listeners[eventName] = {}
    end
    table.insert(EventManager.listeners[eventName], callback)
end

function EventManager.Dispatch(eventName, ...)
    local callbacks = EventManager.listeners[eventName]
    if callbacks then
        for _, cb in ipairs(callbacks) do
            cb(...)
        end
    end
end

return EventManager