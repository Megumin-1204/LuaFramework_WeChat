-- Core/UI/UIPool.lua
local UIPool = {
    pools = {}
}

function UIPool.Get(panelName)
    if not UIPool.pools[panelName] then
        UIPool.pools[panelName] = {}
    end

    for i, panel in ipairs(UIPool.pools[panelName]) do
        if not panel.gameObject.activeSelf then
            panel:OnReuse()
            return panel
        end
    end

    return nil -- 需要新建
end

function UIPool.Release(panel)
    panel.gameObject:SetActive(false)
    table.insert(UIPool.pools[panel.__name], panel)
end