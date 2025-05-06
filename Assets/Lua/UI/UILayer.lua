-- Assets/Lua/UI/UILayer.lua
local UILayer = {
    Background = "BackgroundLayer",
    Common     = "CommonLayer",
    Popup      = "PopupLayer",
    Tips       = "TipsLayer",
    System     = "SystemLayer",
}

function UILayer.SetPanelLayer(panelGo, layerKey)
    local layerName = UILayer[layerKey] or UILayer.Common
    local rootGO = CS.UnityEngine.GameObject.Find(layerName)
    if not rootGO then
        error("UILayer 根节点不存在: " .. layerName)
    end
    panelGo.transform:SetParent(rootGO.transform, false)
end

return UILayer
