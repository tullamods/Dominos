--------------------------------------------------------------------------------
-- Adds support for showing custom Dominos action buttons via the builtin quick
-- binding mode
--------------------------------------------------------------------------------

local ActionButtonUtil = _G.ActionButtonUtil
if not ActionButtonUtil then
    return
end

local _, Addon = ...
local ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND = 2048

hooksecurefunc(
    ActionButtonUtil,
    'ShowAllActionButtonGrids',
    function()
        Addon.Frame:ForEach("ShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND)
    end
)

hooksecurefunc(
    ActionButtonUtil,
    'HideAllActionButtonGrids',
    function()
        Addon.Frame:ForEach("HideGrid", ACTION_BUTTON_SHOW_GRID_REASON_KEYBOUND)
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