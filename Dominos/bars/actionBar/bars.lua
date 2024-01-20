local AddonName, Addon = ...
local ActionBarsModule = Addon:NewModule('ActionBars', 'AceEvent-3.0')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)

function ActionBarsModule:OnEnable()
    self.UpdateActionSlots = Addon:Debounce(self.UpdateActionSlots, 0.1, self)

    -- define action bar binding names
    _G['BINDING_HEADER_' .. AddonName] = AddonName

    local numActionBars = math.ceil(Addon.ACTION_BUTTON_COUNT / NUM_ACTIONBAR_BUTTONS)

    for barID = 1, numActionBars do
        local offset = NUM_ACTIONBAR_BUTTONS * (barID - 1)
        local headerKey = ('BINDING_HEADER_%sActionBar%d'):format(AddonName, barID)

        _G[headerKey] = L.ActionBarDisplayName:format(barID)

        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local bindingKey = ('BINDING_NAME_CLICK %sActionButton%d:HOTKEY'):format(AddonName, i + offset)

            _G[bindingKey] = L.ActionBarButtonDisplayName:format(barID, i)
        end
    end
end

function ActionBarsModule:Load()
    self.slotsToUpdate = {}

    self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
    self:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'OnOverrideBarUpdated')

    if OverrideActionBar then
        self:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR', 'OnOverrideBarUpdated')
        self:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR', 'OnOverrideBarUpdated')
    end

    self:SetBarCount(Addon:NumBars())
    Addon.RegisterCallback(self, "ACTIONBAR_COUNT_UPDATED")
end

function ActionBarsModule:Unload()
    self:UnregisterAllEvents()
    self:ForActive('Free')
    self.active = nil
end

-- events
function ActionBarsModule:OnOverrideBarUpdated()
    if InCombatLockdown() or not (Addon.OverrideController and Addon.OverrideController:OverrideBarActive()) then
        return
    end

    local bar = Addon:GetOverrideBar()
    if bar then
        bar:ForButtons('Update')
    end
end

function ActionBarsModule:ACTIONBAR_COUNT_UPDATED(_, count)
    self:SetBarCount(count)
end

function ActionBarsModule:UPDATE_SHAPESHIFT_FORMS()
    if InCombatLockdown() then
        return
    end

    self:ForActive('UpdateStateDriver')
end

function ActionBarsModule:SetBarCount(count)
    self:ForActive('Free')

    if count > 0 then
        self.active = {}

        for i = 1, count do
            self.active[i] = Addon.ActionBar:New(i)
        end
    else
        self.active = nil
    end
end

function ActionBarsModule:ForActive(method, ...)
    if self.active then
        for _, bar in pairs(self.active) do
            bar:CallMethod(method, ...)
        end
    end
end