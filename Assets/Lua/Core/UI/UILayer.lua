local UILayer = {
    Background = 0,    -- 背景层（如Loading界面）
    Common = 10,       -- 普通层（主界面）
    Popup = 20,        -- 弹出层（弹窗）
    Tips = 30,         -- 提示层（飘字提示）
    System = 100       -- 系统层（调试面板）
}

local layerRoots = {}  -- 各层级根节点缓存

function UILayer.Init(uiRoot)
    for name, order in pairs(UILayer) do
        local go = CS.UnityEngine.GameObject(name .. "Layer")
        go.transform:SetParent(uiRoot)
        local canvas = go:AddComponent(typeof(CS.UnityEngine.Canvas))
        canvas.overrideSorting = true
        canvas.sortingOrder = order
        layerRoots[name] = go.transform
    end
end

function UILayer.SetPanelLayer(panel, layerName)
    panel.transform:SetParent(layerRoots[layerName])
end

return UILayer