-- Opens the action book beside the spellbook, so spells can be dragged
-- straight onto any slot. Not on the gamepad interface, whose spellbook differs
if C_InputInterfaceStyle and C_InputInterfaceStyle.GetCurrentStyle() == Enum.InputDeviceInterfaceType.Gamepad then
    return
end

local _, Addon = ...
local ActionBook = Addon:NewModule('ActionBook', 'AceEvent-3.0')

-- frame: what it sits beside. tab: what shows and hides with the spellbook,
-- when it's one tab of frame. each client has one or the other
local SPELLBOOKS = {
    -- retail and Forever, shared with talents
    { addon = 'Blizzard_PlayerSpells', frame = 'PlayerSpellsFrame', tab = 'SpellBookFrame' },
    -- Mists, Wrath, TBC and Vanilla
    { frame = 'SpellBookFrame' }
}

local function hook(spellbook)
    local frame = _G[spellbook.frame]
    local tab = frame and (spellbook.tab and frame[spellbook.tab] or frame)

    if not tab then
        return
    end

    tab:HookScript('OnShow', function()
        if Addon:ShowingActionBookWithSpellbook() and not InCombatLockdown() then
            Addon:ShowActionBook(frame)
        end
    end)

    tab:HookScript('OnHide', function()
        Addon:HideActionBook(frame)
    end)
end

-- load on demand spellbooks, by addon. only ones this client has
local pending = {}

function ActionBook:OnEnable()
    for _, spellbook in ipairs(SPELLBOOKS) do
        local addon = spellbook.addon

        if not addon or C_AddOns.IsAddOnLoaded(addon) then
            hook(spellbook)
        elseif C_AddOns.DoesAddOnExist(addon) then
            pending[addon] = spellbook
            self:RegisterEvent('ADDON_LOADED')
        end
    end
end

function ActionBook:ADDON_LOADED(_, addonName)
    local spellbook = pending[addonName]
    if not spellbook then
        return
    end

    hook(spellbook)
    pending[addonName] = nil

    if not next(pending) then
        self:UnregisterEvent('ADDON_LOADED')
    end
end
