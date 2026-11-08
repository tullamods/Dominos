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
end

-- events
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
