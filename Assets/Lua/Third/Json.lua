-- 使用极简Json实现
local Json = {}

function Json.encode(data)
    -- 简单实现，仅处理基础类型
    local type = type(data)
    if type == "table" then
        local s = "{"
        for k,v in pairs(data) do
            if type(k) ~= "number" then k = '"'..k..'"' end
            s = s .. "["..k.."]=" .. Json.encode(v) .. ","
        end
        return s:sub(1, -2) .. "}"
    elseif type == "string" then
        return '"' .. data .. '"'
    else
        return tostring(data)
    end
end

return Json