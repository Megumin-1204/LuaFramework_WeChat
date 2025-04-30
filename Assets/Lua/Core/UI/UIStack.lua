local UIStack = {
    stack = {},
    maxDepth = 5       -- 最大堆栈深度
}

function UIStack.Push(panel)
    table.insert(UIStack.stack, panel)
    if #UIStack.stack > UIStack.maxDepth then
        UIStack.stack[1]:Destroy()
        table.remove(UIStack.stack, 1)
    end
end

function UIStack.Pop()
    if #UIStack.stack > 0 then
        local panel = table.remove(UIStack.stack)
        panel:Destroy()
    end
end

function UIStack.Clear()
    for _, panel in ipairs(UIStack.stack) do
        panel:Destroy()
    end
    UIStack.stack = {}
end

return UIStack