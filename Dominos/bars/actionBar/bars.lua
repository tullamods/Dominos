local _, Addon = ...
local ActionBarsModule = Addon:NewModule('ActionBars', 'AceEvent-3.0')

-- hide Blizzard's action bars
function ActionBarsModule:OnFirstLoad()
    -- the main bar keeps its events and buttons
    local bars = {
        'MainActionBar',
        'MultiBarBottomLeft',
        'MultiBarBottomRight',
        'MultiBarLeft',
        'MultiBarRight',
        'MultiBar5',
        'MultiBar6',
        'MultiBar7',
    }

    -- classic
    if MainMenuBar then
        tinsert(bars, 'MainMenuBar')
        tinsert(bars, 'MainMenuBarArtFrame')
    end

    for _, name in ipairs(bars) do
        local bar = _G[name]
        local isMainBar = name == 'MainActionBar'

        if bar then
            if not isMainBar then
                bar:UnregisterAllEvents()
            end

            (bar.HideBase or bar.Hide)(bar)
            bar:SetParent(Addon.ShadowUIParent)

            if type(bar.actionButtons) == 'table' then
                for _, button in pairs(bar.actionButtons) do
                    button:UnregisterAllEvents()
                    button:SetAttributeNoHandler('statehidden', true)
                    button:Hide()
                end

                if not isMainBar then
                    wipe(bar.actionButtons)
                end
            end
        else
            Addon:Printf('Could not find frame %q', name)
        end
    end
end

function ActionBarsModule:Load()
    self:SetBarCount(Addon:NumBars())

    self:RegisterEvent('UPDATE_SHAPESHIFT_FORMS')
    Addon.RegisterCallback(self, "ACTIONBAR_COUNT_UPDATED")
end

function ActionBarsModule:Unload()
    self:UnregisterAllEvents()
    self:ForActive('Free')
    self.active = nil
    self.length = nil
end

-- events
function ActionBarsModule:ACTIONBAR_COUNT_UPDATED(_, count)
    self:SetBarCount(count)

    -- bars were added, removed or recreated
    Addon.callbacks:Fire('ACTIONBARS_UPDATED')
end

function ActionBarsModule:UPDATE_SHAPESHIFT_FORMS()
    if InCombatLockdown() then
        return
    end

    self:ForActive('UpdateStateDriver')
end

-- only adds or removes bars, unless the length changed, which changes every
-- bar's buttons
function ActionBarsModule:SetBarCount(count)
    local length = Addon:GetActionBarLength()

    if length ~= self.length then
        self:ForActive('Free')
        self.active = nil
        self.length = length
    end

    local active = self.active or {}

    for i = #active, count + 1, -1 do
        active[i]:Free()
        active[i] = nil
    end

    for i = #active + 1, count do
        active[i] = Addon.ActionBar:New(i)
    end

    self.active = active

    -- paging wraps around the bar count
    self:ForActive('UpdateStateDriver')
end

function ActionBarsModule:ForActive(method, ...)
    if self.active then
        for _, bar in pairs(self.active) do
            bar:CallMethod(method, ...)
        end
    end
end
