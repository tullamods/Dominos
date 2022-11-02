--------------------------------------------------------------------------------
-- work around the [cursor] conditional not detecting certain frames by force
-- showing grid when those frames are loaded
--------------------------------------------------------------------------------
local _, Addon = ...

if not Addon:IsBuild("retail") then return end

local ACTION_BUTTON_SHOW_GRID_REASON_COLLECTIONS = 512

local function onShowCollectionsJournal()
    if InCombatLockdown() then return end

    Addon.Frame:ForEach("ShowGrid", ACTION_BUTTON_SHOW_GRID_REASON_COLLECTIONS)
end

local function onHideCollectionsJournal()
    if InCombatLockdown() then return end

    Addon.Frame:ForEach("HideGrid", ACTION_BUTTON_SHOW_GRID_REASON_COLLECTIONS)
end

local Module = Addon:NewModule("ShowGridFixer", "AceEvent-3.0")

function Module:OnEnable()
    self:RegisterEvent("ADDON_LOADED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

function Module:ADDON_LOADED(event, addon)
    if addon == "Blizzard_Collections" then
        CollectionsJournal:HookScript("OnShow", onShowCollectionsJournal)
        CollectionsJournal:HookScript("OnHide", onHideCollectionsJournal)

        self:UnregisterEvent(event)
    end
end

function Module:PLAYER_REGEN_ENABLED()
    if not CollectionsJournal:IsVisible() then
        onHideCollectionsJournal()
    end
end
