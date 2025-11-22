local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local LSM = LibStub("LibSharedMedia-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-CastBar")

local ICON_OVERRIDES = {
    -- replace samwise with cog (usually indicative of a trade skill)
    [136235] = 136243
}

local CAST_BAR_COLORS = {
    default = {1, 0.7, 0},
    failed = {1, 0, 0},
    harm = {0.63, 0.36, 0.94},
    help = {0.31, 0.78, 0.47},
    spell = {0, 1, 0},
    uninterruptible = {0.63, 0.63, 0.63}
}

local LATENCY_BAR_ALPHA = 0.5

local function getSpellInfo(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    if info then
        return info.name, info.iconID, info.castTime
    end
end

local getRandomSpellID
if C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
    getRandomSpellID = function()
        local line = C_SpellBook.GetSpellBookSkillLineInfo(C_SpellBook.GetNumSpellBookSkillLines())
        local offset = line.itemIndexOffset
        local numSlots = line.numSpellBookItems
        local spellID

        repeat
            local spell = C_SpellBook.GetSpellBookItemInfo(math.random(1, offset + numSlots), Enum.SpellBookSpellBank.Player)
            spellID = spell.spellID
        until spellID

        return spellID
    end
else
    getRandomSpellID = function()
        local _, _, offset, numSlots = GetSpellTabInfo(GetNumSpellTabs())
        for i = 1, 100 do
            local _, spellID = GetSpellBookItemInfo(math.random(1, offset + numSlots), BOOKTYPE_SPELL)
            if spellID then
                return spellID
            end
        end
    end
end

local function getSpellReaction(spellID)
    if spellID then
        if C_Spell.IsSpellHelpful(spellID) then
            return "help"
        end

        if C_Spell.IsSpellHarmful(spellID) then
            return "harm"
        end
    end

    return "default"
end

local CastBar = Dominos:CreateClass("Frame", Dominos.Frame)

function CastBar:New(id, units, ...)
    local bar = CastBar.proto.New(self, id, ...)

    bar.units = type(units) == "table" and units or {units}
    bar:Layout()
    bar:RegisterEvents()

    return bar
end

CastBar:Extend("OnCreate", function(self)
    self:SetScript("OnEvent", self.OnEvent)

    self.props = {}

    self.timer = CreateFrame("Frame", nil, self, "DominosTimerBarTemplate")
end)

CastBar:Extend("OnRelease", function(self)
    self:UnregisterAllEvents()
    LSM.UnregisterAllCallbacks(self)
end)

CastBar:Extend("OnLoadSettings", function(self)
    if not self.sets.display then
        self.sets.display = {icon = false, time = true, border = true, latency = true}
    end

    self:SetProperty("font", self:GetFontID())
    self:SetProperty("texture", self:GetTextureID())
    self:SetProperty("reaction", "neutral")
end)

function CastBar:GetDisplayName()
    local L = LibStub("AceLocale-3.0"):GetLocale("Dominos-CastBar")

    return L.CastBarDisplayName
end

function CastBar:GetDefaults()
    return {
        point = "CENTER",
        x = 0,
        y = 30,
        padW = 1,
        padH = 1,
        texture = "blizzard",
        font = "Friz Quadrata TT",

        useSpellReactionColors = true,

        -- default to the spell queue window for latency padding
        latencyPadding = tonumber(GetCVar("SpellQueueWindow")),

        displayLayer = 'HIGH',

        display = {icon = false, time = true, border = true, latency = true, spark = true}
    }
end

--------------------------------------------------------------------------------
-- Game Events
--------------------------------------------------------------------------------

function CastBar:OnEvent(event, ...)
    local func = self[event]

    if func then
        func(self, event, ...)
    end
end

function CastBar:RegisterEvents()
    local function registerUnitEvents(...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_START", ...)
        self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", ...)

        if Dominos:IsBuild("retail") then
            self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_START', ...)
            self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_STOP', ...)
            self:RegisterUnitEvent('UNIT_SPELLCAST_EMPOWER_UPDATE', ...)
        end
    end

    registerUnitEvents(unpack(self.units))
    LSM.RegisterCallback(self, "LibSharedMedia_Registered")
end

-- channeling events
-- Channel cast GUIDs can sometimes be nil, so we use "nil" as a default to
-- identify those casts. I would prefer using spellID, but that value is secret
-- post Midnight
function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit, castID, spellID)

    if castID == nil then
        castID = "nil"
    end

    self:SetProperty("unit", unit)
    self:SetProperty("castID", castID)

    self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, castID, spellID)
    if castID == nil then
        castID = "nil"
    end

    -- castID shouldn't be secret, so this comparision should be safe
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, castID, spellID)
    if castID == nil then
        castID = "nil"
    end

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("state", "stopped")
end

-- empower events
function CastBar:UNIT_SPELLCAST_EMPOWER_START(event, unit, castID, spellID)
    if castID == nil then
        castID = "nil"
    end

    self:SetProperty("castID", castID)
    self:SetProperty("unit", unit)

    self:UpdateEmpowering()
end

function CastBar:UNIT_SPELLCAST_EMPOWER_UPDATE(event, unit, castID, spellID)
    if castID == nil then
        castID = "nil"
    end

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:UpdateEmpowering()
end

function CastBar:UNIT_SPELLCAST_EMPOWER_STOP(event, unit, castID, spellID)
    if castID == nil then
        castID = "nil"
    end

    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("state", "stopped")
end

-- spellcast events
function CastBar:UNIT_SPELLCAST_START(event, unit, castID, spellID)
    if castID == nil then
        return
    end

    self:SetProperty("castID", castID)
    self:SetProperty("unit", unit)

    self:UpdateCasting()
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("state", "stopped")
end

function CastBar:UNIT_SPELLCAST_FAILED(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("label", FAILED)
    self:SetProperty("state", "failed")
end

CastBar.UNIT_SPELLCAST_FAILED_QUIET = CastBar.UNIT_SPELLCAST_FAILED

function CastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:SetProperty("label", INTERRUPTED)
    self:SetProperty("state", "interrupted")
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit, castID, spellID)
    if castID ~= self:GetProperty("castID") then
        return
    end

    self:UpdateCasting()
end

--------------------------------------------------------------------------------
-- Addon Events
--------------------------------------------------------------------------------

function CastBar:LibSharedMedia_Registered(event, mediaType, key)
    if mediaType == LSM.MediaType.STATUSBAR and key == self:GetTextureID() then
        self:texture_update(key)
    elseif mediaType == LSM.MediaType.FONT and key == self:GetFontID() then
        self:font_update(key)
    end
end

--------------------------------------------------------------------------------
-- Cast Bar Property Events
--------------------------------------------------------------------------------

function CastBar:state_update(state)
    if state == "interrupted" or state == "failed" then
        self:UpdateColor()
        self:Stop()
    elseif state == "stopped" then
        self:Stop()
    else
        self:UpdateColor()
    end
end

function CastBar:label_update(text)
    self.timer:SetLabel(text)
end

function CastBar:icon_update(textureID)
    self.timer:SetIcon(textureID and ICON_OVERRIDES[textureID] or textureID)
end

function CastBar:reaction_update(reaction)
    self:UpdateColor()
end

function CastBar:spell_update(spellID)
    local reaction = getSpellReaction(spellID)

    self:SetProperty("reaction", reaction)
end

function CastBar:uninterruptible_update(uninterruptible)
    self:UpdateColor()
end

function CastBar:font_update(fontID)
    self.timer:SetFont(fontID)
end

function CastBar:texture_update(textureID)
    self.timer:SetTexture(textureID)
end

--------------------------------------------------------------------------------
-- Cast Bar Methods
--------------------------------------------------------------------------------

if type(canaccessvalue) == "function" then
    function CastBar:SetProperty(key, value)
        local prev = self.props[key]

        local shouldSet = not (
            canaccessvalue(value)
            and canaccessvalue(prev)
            and prev == value
        )

        if shouldSet then
            self.props[key] = value

            local func = self[key .. "_update"]
            if func then
                func(self, value, prev)
            end
        end
    end
else
    function CastBar:SetProperty(key, value)
        local prev = self.props[key]

        if prev ~= value then
            self.props[key] = value

            local func = self[key .. "_update"]
            if func then
                func(self, value, prev)
            end
        end
    end
end

function CastBar:GetProperty(key)
    return self.props[key]
end

function CastBar:Layout()
    self:TrySetSize(self:GetDesiredWidth(), self:GetDesiredHeight())

    self.timer:SetPadding(self:GetPadding())

    self.timer:SetShowIcon(self:Displaying("icon"))

    self.timer:SetShowText(self:Displaying("time"))

    self.timer:SetShowBorder(self:Displaying("border"))

    self.timer:SetShowLatency(self:Displaying("latency"))
    self.timer:SetLatencyPadding(self:GetLatencyPadding())

    self.timer:SetShowSpark(self:Displaying("spark"))
end

function CastBar:UpdateChanneling()
    local unit = self:GetProperty("unit")
    local name, _, textureID, startTimeMs, endTimeMs, _, notInterruptible, spellID = UnitChannelInfo(unit)
    if name then
        self:SetProperty("state", "channeling")
        self:SetProperty("label", name)
        self:SetProperty("icon", textureID)
        self:SetProperty("spell", spellID)
        self:SetProperty("uninterruptible", notInterruptible)

        self.timer:SetCountdown(true)
        self.timer:SetShowLatency(false)

        local time = GetTime()
        local startTime = startTimeMs / 1000
        local endTime = endTimeMs / 1000

        self.timer:Start(endTime - time, 0, endTime - startTime)

        return true
    end

    return false
end

function CastBar:UpdateCasting()
    local unit = self:GetProperty("unit")
    local name, displayName, textureID, startTimeMs, endTimeMs, _, _, notInterruptible, spellID = UnitCastingInfo(unit)

    if name then
        self:SetProperty("state", "casting")
        self:SetProperty("label", displayName)
        self:SetProperty("icon", textureID)
        self:SetProperty("spell", spellID)
        self:SetProperty("uninterruptible", notInterruptible)

        self.timer:SetCountdown(false)
        self.timer:SetShowLatency(self:Displaying("latency"))

        local time = GetTime()
        local startTime = startTimeMs / 1000
        local endTime = endTimeMs / 1000

        self.timer:Start(time - startTime, 0, endTime - startTime)

        return true
    end

    return false
end

function CastBar:UpdateEmpowering()
    local unit = self:GetProperty("unit")
    local name, _, textureID, startTimeMs, endTimeMs, _, notInterruptible, spellID, _, numEmpowerStages = UnitChannelInfo(unit)

    if name then
        numEmpowerStages = tonumber(numEmpowerStages) or 0

        self:SetProperty("state", "empowering")
        self:SetProperty("label", name)
        self:SetProperty("icon", textureID)
        self:SetProperty("spell", spellID)
        self:SetProperty("uninterruptible", notInterruptible)

        self.timer:SetCountdown(false)
        self.timer:SetShowLatency(false)

        local time = GetTime()
        local startTime = startTimeMs / 1000
        local endTime

        -- HACK: use hardcoded values in Midnight because the return of
        -- GetUnitEmpowerHoldAtMaxTime is currently a secret
		if numEmpowerStages > 0 then
            local holdTimeMs = GetUnitEmpowerHoldAtMaxTime(unit)
            if (issecretvalue and issecretvalue(holdTimeMs)) then
                local fakeHoldTimeMs = unit == "player" and 1000 or 0
                endTime = (endTimeMs + fakeHoldTimeMs) / 1000
            else
                endTime = (endTimeMs + holdTimeMs) / 1000;
            end
        else
            endTime = endTimeMs / 1000
		end

        self.timer:Start(time - startTime, 0, endTime - startTime)

        return true
    end

    return false
end

local function getLatencyColor(r, g, b)
    return 1 - r, 1 - g, 1 - b, LATENCY_BAR_ALPHA
end

function CastBar:GetColorID()
    local state = self:GetProperty("state")
    if state == "failed" or state == "interrupted" then
        return "failed"
    end

    local reaction = self:GetProperty("reaction")

    if self:UseSpellReactionColors() then
        if reaction == "help" then
            return "help"
        end

        if reaction == "harm" then
            if self:GetProperty("uninterruptible") then
                return "uninterruptible"
            end

            return "harm"
        end
    else
        if reaction == "help" then
            return "spell"
        end

        if reaction == "harm" then
            if self:GetProperty("uninterruptible") then
                return "uninterruptible"
            end

            return "spell"
        end
    end

    return "default"
end

function CastBar:UpdateColor()
    local color = self:GetColorID()
    local r, g, b = unpack(CAST_BAR_COLORS[self:GetColorID()])

    self.timer.statusBar:SetStatusBarColor(r, g, b)

    if color == "failed" then
        self.timer.latencyBar:SetColorTexture(0, 0, 0, 0)
    else
        self.timer.latencyBar:SetColorTexture(getLatencyColor(r, g, b))
    end
end

function CastBar:Stop()
    self.timer:Stop()
end

function CastBar:SetupDemo()
    local spellID = getRandomSpellID()
    local name, iconID, castTime = getSpellInfo(spellID)

    -- use the spell cast time if we have it, otherwise set a default one
    -- of a few seconds
    if not (castTime and castTime > 0) then
        castTime = 3
    else
        castTime = castTime / 1000
    end

    self:SetProperty("state", "demo")
    self:SetProperty("label", name)
    self:SetProperty("icon", iconID)
    self:SetProperty("spell", spellID)
    self:SetProperty("reaction", getSpellReaction(spellID))
    self:SetProperty("uninterruptible", nil)

    self.timer:SetCountdown(false)
    self.timer:SetShowLatency(self:Displaying("latency"))
    self.timer:Start(0, 0, castTime)

    -- loop the demo if it is still visible
    C_Timer.After(castTime, function()
        if self.menuShown and self:GetProperty("state") == "demo" then
            self:SetupDemo()
        end
    end)
end

--------------------------------------------------------------------------------
-- Cast Bar Configuration
--------------------------------------------------------------------------------

function CastBar:SetDesiredWidth(width)
    self.sets.w = tonumber(width)
    self:Layout()
end

function CastBar:GetDesiredWidth()
    return self.sets.w or 240
end

function CastBar:SetDesiredHeight(height)
    self.sets.h = tonumber(height)
    self:Layout()
end

function CastBar:GetDesiredHeight()
    return self.sets.h or 32
end

-- font
function CastBar:SetFontID(fontID)
    self.sets.font = fontID
    self:SetProperty("font", self:GetFontID())

    return self
end

function CastBar:GetFontID()
    return self.sets.font or "Friz Quadrata TT"
end

-- texture
function CastBar:SetTextureID(textureID)
    self.sets.texture = textureID
    self:SetProperty("texture", self:GetTextureID())

    return self
end

function CastBar:GetTextureID()
    return self.sets.texture or "blizzard"
end

-- display
function CastBar:SetDisplay(part, enable)
    self.sets.display[part] = enable
    self:Layout()
end

function CastBar:Displaying(part)
    return self.sets.display[part]
end

-- latency padding
function CastBar:SetLatencyPadding(value)
    self.sets.latencyPadding = value
    self:Layout()
end

function CastBar:GetLatencyPadding()
    return self.sets.latencyPadding or tonumber(GetCVar("SpellQueueWindow")) or 0
end

function CastBar:SetUseSpellReactionColors(enable)
    if enable then
        self.sets.useSpellReactionColors = true
    else
        self.sets.useSpellReactionColors = false
    end

    self:UpdateColor()
end

function CastBar:UseSpellReactionColors()
    return self.sets.useSpellReactionColors
end

-- force the casting bar to show with the override ui/pet battle ui
function CastBar:ShowingInOverrideUI()
    return true
end

function CastBar:ShowingInPetBattleUI()
    return true
end

--------------------------------------------------------------------------------
-- Cast Bar Right Click Menu
--------------------------------------------------------------------------------

function CastBar:OnCreateMenu(menu)
    self:AddLayoutPanel(menu)
    self:AddDisplayPanel(menu)
    self:AddTexturePanel(menu)
    self:AddFontPanel(menu)

    menu:AddFadingPanel()

    menu:AddAdvancedPanel(true)

    menu:HookScript("OnShow", function()
        self.menuShown = true

        local state = self:GetProperty("state")
        if not (state == "casting" or state == "channeling" or state == "empowering") then
            self:SetupDemo()
        end
    end)

    menu:HookScript("OnHide", function()
        self.menuShown = nil

        if self:GetProperty("state") == "demo" then
            self:Stop()
        end
    end)
end

function CastBar:AddLayoutPanel(menu)
    local panel = menu:NewPanel(LibStub("AceLocale-3.0"):GetLocale("Dominos-Config").Layout)

    panel.widthSlider = panel:NewSlider{
        name = L.Width,
        min = 1,
        max = function()
            return math.ceil(UIParent:GetWidth() / panel.owner:GetScale())
        end,
        get = function()
            return panel.owner:GetDesiredWidth()
        end,
        set = function(_, value)
            panel.owner:SetDesiredWidth(value)
        end
    }

    panel.heightSlider = panel:NewSlider{
        name = L.Height,
        min = 1,
        max = function()
            return math.ceil(UIParent:GetHeight() / panel.owner:GetScale())
        end,
        get = function()
            return panel.owner:GetDesiredHeight()
        end,
        set = function(_, value)
            panel.owner:SetDesiredHeight(value)
        end
    }

    panel:AddBasicLayoutOptions()
end

function CastBar:AddDisplayPanel(menu)
    local panel = menu:NewPanel(L.Display)

    panel:NewCheckButton{
        name = L["UseSpellReactionColors"],
        tooltip = L["UseSpellReactionColorsTip"],
        get = function()
            return panel.owner:UseSpellReactionColors()
        end,
        set = function(_, enable)
            panel.owner:SetUseSpellReactionColors(enable)
        end
    }

    for _, part in ipairs {"border", "icon", "spark", "time", "latency"} do
        panel:NewCheckButton{
            name = L["Display_" .. part],
            get = function()
                return panel.owner:Displaying(part)
            end,
            set = function(_, enable)
                panel.owner:SetDisplay(part, enable)
            end
        }
    end

    panel.latencySlider = panel:NewSlider{
        name = L.LatencyPadding,
        min = 0,
        max = function()
            return 500
        end,
        get = function()
            return panel.owner:GetLatencyPadding()
        end,
        set = function(_, value)
            panel.owner:SetLatencyPadding(value)
        end
    }
end

function CastBar:AddFontPanel(menu)
    local panel = menu:NewPanel(L.Font)

    panel.fontSelector = Dominos.Options.FontSelector:New{
        parent = panel,
        get = function()
            return panel.owner:GetFontID()
        end,
        set = function(_, value)
            panel.owner:SetFontID(value)
        end
    }
end

function CastBar:AddTexturePanel(menu)
    local panel = menu:NewPanel(L.Texture)

    panel.textureSelector = Dominos.Options.TextureSelector:New{
        parent = panel,
        get = function()
            return panel.owner:GetTextureID()
        end,
        set = function(_, value)
            panel.owner:SetTextureID(value)
        end
    }
end

-- exports
Addon.CastBar = CastBar
