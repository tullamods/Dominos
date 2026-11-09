-- Opens the action book beside the spellbook, so spells can be dragged
-- straight onto any slot

local _, Addon = ...
local ActionBook = Addon:NewModule('ActionBook')

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

function ActionBook:OnEnable()
    for _, spellbook in ipairs(SPELLBOOKS) do
        local addon = spellbook.addon

        if not addon then
            hook(spellbook)
        elseif C_AddOns.DoesAddOnExist(addon) then
            EventUtil.ContinueOnAddOnLoaded(addon, function()
                hook(spellbook)
            end)
        end
    end
end
