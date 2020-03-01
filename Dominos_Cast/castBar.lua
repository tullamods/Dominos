local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local LSM = LibStub("LibSharedMedia-3.0")


-- local aliaes for some globals
local GetSpellInfo = _G.GetSpellInfo
local GetTime = _G.GetTime

local UnitCastingInfo = _G.UnitCastingInfo or _G.CastingInfo
local UnitChannelInfo = _G.UnitChannelInfo or _G.ChannelInfo

local IsHarmfulSpell = _G.IsHarmfulSpell
local IsHelpfulSpell = _G.IsHelpfulSpell

local ICON_OVERRIDES = {
	-- replace samwise with cog
	[136235] = 136243
}

local LATENCY_BAR_ALPHA = 0.7

local function GetSpellReaction(spellID)
	local name = GetSpellInfo(spellID)
	if not name then
		return "neutral"
	end

	if IsHelpfulSpell(name) then
		return "help"
	elseif IsHarmfulSpell(name) then
		return "harm"
	end
	return "neutral"
end


local CastBar = Dominos:CreateClass("Frame", Dominos.Frame)

function CastBar:New(id, units, ...)
	local bar = CastBar.proto.New(self, id, ...)

	bar.units = type(units) == "table" and units or {units}
	bar:Layout()
	bar:RegisterEvents()

	return bar
end

function CastBar:OnCreate()
	CastBar.proto.OnCreate(self)

	self:SetFrameStrata("HIGH")
	self:SetScript("OnEvent", self.OnEvent)

	self.props = {}
	self.timer = CreateFrame("Frame", nil, self, "DominosTimerBarTemplate")
end

function CastBar:OnFree()
	CastBar.proto.OnFree(self)

	self:UnregisterAllEvents()
	LSM.UnregisterAllCallbacks(self)
end

function CastBar:OnLoadSettings()
	if not self.sets.display then
		self.sets.display = {
			icon = false,
			time = true,
			border = true,
			latency = true,
		}
	end

	self:SetProperty("font", self:GetFontID())
	self:SetProperty("texture", self:GetTextureID())
	self:SetProperty("reaction", "neutral")
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
		display = {
			icon = false,
			time = true,
			border = true,
			latency = true,
			spark = true
		}
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
	local registerUnitEvents = function(...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", ...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_UPDATE", ...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", ...)

		self:RegisterUnitEvent("UNIT_SPELLCAST_START", ...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_STOP", ...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED", ...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET", ...)

		self:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", ...)
		self:RegisterUnitEvent("UNIT_SPELLCAST_DELAYED", ...)
	end

	registerUnitEvents(unpack(self.units))
	LSM.RegisterCallback(self, "LibSharedMedia_Registered")
end

-- channeling events
function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit, castID, spellID)
	self:SetProperty("castID", castID)
	self:SetProperty("unit", unit)

	self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, castID, spellID)
	if castID ~= self:GetProperty("castID") then
		return
	end

	self:UpdateChanneling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, castID, spellID)
	if castID ~= self:GetProperty("castID") then
		return
	end

	self:SetProperty("state", "stopped")
end

function CastBar:UNIT_SPELLCAST_START(event, unit, castID, spellID)
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

	self:SetProperty("label", _G.FAILED)
	self:SetProperty("state", "failed")
end

CastBar.UNIT_SPELLCAST_FAILED_QUIET = CastBar.UNIT_SPELLCAST_FAILED

function CastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit, castID, spellID)
	if castID ~= self:GetProperty("castID") then
		return
	end

	self:SetProperty("label", _G.INTERRUPTED)
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

function CastBar:icon_update(texture)
	self.timer:SetIcon(texture and ICON_OVERRIDES[texture] or texture)
end

function CastBar:reaction_update(reaction)
	self:UpdateColor()
end

function CastBar:spell_update(spellID)
	self:SetProperty("reaction", GetSpellReaction(spellID))
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

	self.timer:SetShowSpark(self:Displaying("spark"))
end

function CastBar:UpdateChanneling()
	local name, text, texture, startTimeMS, endTimeMS, _, notInterruptible, spellID = UnitChannelInfo(self:GetProperty("unit"))

	if name then
		self:SetProperty("state", "channeling")
		self:SetProperty("label", name or text)
		self:SetProperty("icon", texture)
		self:SetProperty("spell", spellID)
		self:SetProperty("uninterruptible", notInterruptible)

		self.timer:SetShowLatency(false)
		self.timer:Start(GetTime(), startTimeMS / 1000, endTimeMS / 1000)

		return true
	end

	return false
end

function CastBar:UpdateCasting()
	local name, text, texture, startTimeMS, endTimeMS, _, _, notInterruptible, spellID = UnitCastingInfo(self:GetProperty("unit"))

	if name then
		self:SetProperty("state", "casting")
		self:SetProperty("label", text)
		self:SetProperty("icon", texture)
		self:SetProperty("spell", spellID)
		self:SetProperty("uninterruptible", notInterruptible)

		self.timer:SetShowLatency(self:Displaying("latency"))
		self.timer:Start(GetTime(), startTimeMS / 1000, endTimeMS / 1000)
		self.timer.latencyBar:SetWidth(self.timer.statusBar:GetWidth() * self:GetLatency() / (endTimeMS - startTimeMS))

		return true
	end

	return false
end

function CastBar:UpdateColor()
	local state = self:GetProperty("state")
	local reaction = self:GetProperty("reaction")
	local uninterruptible = self:GetProperty("uninterruptible")

	if state == "failed" or state == "interrupted" then
		self.timer.statusBar:SetStatusBarColor(1, 0, 0)
		self.timer.latencyBar:SetColorTexture(1, 0, 0, 0)
	elseif reaction == "harm" then
		if uninterruptible then
			self.timer.statusBar:SetStatusBarColor(0.63, 0.63, 0.63)
			self.timer.latencyBar:SetColorTexture(0.37, 0.37, 0.37, LATENCY_BAR_ALPHA)
		else
			self.timer.statusBar:SetStatusBarColor(0.63, 0.36, 0.94)
			self.timer.latencyBar:SetColorTexture(0.37, 0.64, 0.06, LATENCY_BAR_ALPHA)
		end
	elseif reaction == "help" then
		self.timer.statusBar:SetStatusBarColor(0.31, 0.78, 0.47)
		self.timer.latencyBar:SetColorTexture(0.69, 0.22, 0.53, LATENCY_BAR_ALPHA)
	else
		self.timer.statusBar:SetStatusBarColor(1, 0.7, 0)
		self.timer.latencyBar:SetColorTexture(0, 0.3, 1, LATENCY_BAR_ALPHA)
	end
end

-- the latency indicator in the castbar is meant to tell you when you can
-- safely cast a spell, so we
function CastBar:GetLatency()
	local lagHome, lagWorld = select(3, GetNetStats())

	return (max(lagHome, lagWorld) + self:GetLatencyPadding())
end


function CastBar:Stop()
	self.timer:Stop()
end

function CastBar:SetupDemo()
	local spellID = self:GetRandomSpellID()
	local name, _, icon = GetSpellInfo(spellID)

	self:SetProperty("state", "demo")
	self:SetProperty("label", name)
	self:SetProperty("icon", icon)
	self:SetProperty("spell", spellID)
	self:SetProperty("reaction", nil)
	self:SetProperty("uninterruptible", nil)

	self.timer:Start(GetTime(), GetTime(), GetTime() + 60)
end

function CastBar:GetRandomSpellID()
	local spells = {}

	for i = 1, GetNumSpellTabs() do
		local offset, numSpells = select(3, GetSpellTabInfo(i))
		local tabEnd = offset + numSpells

		for j = offset, tabEnd - 1 do
			local _, spellID = GetSpellBookItemInfo(j, "player")
			if spellID then
				table.insert(spells, spellID)
			end
		end
	end

	return spells[math.random(1, #spells)]
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

--latency padding
function CastBar:SetLatencyPadding(value)
	self.sets.latencyPadding = value
end

function CastBar:GetLatencyPadding()
	return self.sets.latencyPadding or 0
end

--------------------------------------------------------------------------------
-- Cast Bar Right Click Menu
--------------------------------------------------------------------------------

function CastBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)

	self:AddLayoutPanel(menu)
	self:AddTexturePanel(menu)
	self:AddFontPanel(menu)

	self.menu = menu

	self.menu:HookScript("OnShow", function()
		if not (self:GetProperty("state") == "casting" or self:GetProperty("state") == "channeling") then
			self:SetupDemo()
		end
	end)

	self.menu:HookScript("OnHide", function()
		if self:GetProperty("state") == "demo" then
			self:Stop()
		end
	end)

	return menu
end

function CastBar:AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub("AceLocale-3.0"):GetLocale("Dominos-Config").Layout)

	local l = LibStub("AceLocale-3.0"):GetLocale("Dominos-CastBar")

	for _, part in ipairs{"icon", "time", "border"} do
		panel:NewCheckButton{
			name = l["Display_" .. part],
			get = function()
				return panel.owner:Displaying(part)
			end,
			set = function(_, enable)
				panel.owner:SetDisplay(part, enable)
			end
		}
	end

	panel.widthSlider = panel:NewSlider{
		name = l.Width,
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
		name = l.Height,
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

	panel.paddingSlider = panel:NewPaddingSlider()

	panel.scaleSlider = panel:NewScaleSlider()

	panel.latencySlider = panel:NewSlider{
		name = l.LatencyPadding,
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
	local l = LibStub("AceLocale-3.0"):GetLocale("Dominos-CastBar")
	local panel = menu:NewPanel(l.Font)

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
	local l = LibStub("AceLocale-3.0"):GetLocale("Dominos-CastBar")
	local panel = menu:NewPanel(l.Texture)

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
