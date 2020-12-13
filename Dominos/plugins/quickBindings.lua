--------------------------------------------------------------------------------
-- Adds support for showing custom Dominos action buttons via the builtin quick
-- binding mode
--------------------------------------------------------------------------------

local ActionButtonUtil = _G.ActionButtonUtil
if not ActionButtonUtil then
    return
end

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

hooksecurefunc(
    ActionButtonUtil,
    'ShowAllActionButtonGrids',
    function()
        for _, button in pairs(Addon.ActionButtons) do
            button:ShowGridInsecure(ACTION_BUTTON_SHOW_GRID_REASON_EVENT)
        end
    end
)

hooksecurefunc(
    ActionButtonUtil,
    'HideAllActionButtonGrids',
    function()
        for _, button in pairs(Addon.ActionButtons) do
            button:HideGridInsecure(ACTION_BUTTON_SHOW_GRID_REASON_EVENT)
        end
    end
)

hooksecurefunc(
    ActionButtonUtil,
    'SetAllQuickKeybindButtonHighlights',
    function(show)
        for _, button in pairs(Addon.ActionButtons) do
            button.QuickKeybindHighlightTexture:SetShown(show)
        end
    end
)

-- inject binding names
_G[('BINDING_CATEGORY_%s'):format(AddonName)] = AddonName

local addonActionBarName = AddonName .. ' ' .. L.ActionBarDisplayName
for id = 1, 12 do
    _G[('BINDING_HEADER_%sActionBar%d'):format(AddonName, id)] = addonActionBarName:format(id)
end

local addonActionButtonName = AddonName .. ' ' .. L.ActionButtonDisplayName
for id = 1, 60 do
    _G[('BINDING_NAME_CLICK:%sActionButton%d:HOTKEY'):format(AddonName, id)] = addonActionButtonName:format(id)
end
