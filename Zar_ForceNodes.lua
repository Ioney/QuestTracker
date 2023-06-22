local ADDON_NAME, ns = ...

local groupPins = WorldMapFrame.pinPools.GroupMembersPinTemplate

-- Listen for LCTRL + LALT when the map is open to force display nodes
local IQFrame = CreateFrame('Frame', ADDON_NAME .. 'IQ', WorldMapFrame)
IQFrame:SetPropagateKeyboardInput(true)

IQFrame:SetScript('OnKeyDown', function(_, key)
    if (key == 'LCTRL' or key == 'LALT') and IsLeftControlKeyDown() and IsLeftAltKeyDown() then
        IQFrame:SetPropagateKeyboardInput(false)
        for i, _ns in ipairs(_G['HandyNotes_ZarPlugins']) do
            if _ns and _ns.addon then
                _ns.dev_force = true
                _ns.addon:RefreshImmediate()
            end
        end
        -- Hide player pins on the map
        groupPins:GetNextActive():Hide()
    end
end)

IQFrame:SetScript('OnKeyUp', function(_, key)
    if key == 'LCTRL' or key == 'LALT' then
        IQFrame:SetPropagateKeyboardInput(true)
        for i, _ns in ipairs(_G['HandyNotes_ZarPlugins']) do
            if _ns and _ns.addon then
                _ns.dev_force = false
                _ns.addon:RefreshImmediate()
            end
        end
        -- Show player pins on the map
        groupPins:GetNextActive():Show()
    end
end)

