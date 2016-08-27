
local AddonName, Addon = ...
local Dominos = _G.Dominos

--[[ global references ]]--

local _G = _G
local min = math.min
local max = math.max

local GetSpellInfo = _G.GetSpellInfo
local GetTime = _G.GetTime
local GetNetStats = _G.GetNetStats

local UnitCastingInfo = _G.UnitCastingInfo
local UnitChannelInfo = _G.UnitChannelInfo

local IsHarmfulSpell = _G.IsHarmfulSpell
local IsHelpfulSpell = _G.IsHelpfulSpell

--[[ casting bar ]]--

local CastBar = Dominos:CreateClass('Frame', Dominos.Frame)

function CastBar:New(id, unit, ...)
	local bar = CastBar.proto.New(self, id, ...)

	bar.unit = unit
	bar:Layout()
	bar:RegisterEvents()

	return bar
end

function CastBar:OnCreate()
	self:SetFrameStrata('HIGH')
	self:SetScript('OnEvent', self.OnEvent)

	local container = CreateFrame('Frame', nil, self)
	container:SetAllPoints(container:GetParent())
	container:SetAlpha(0)
	self.container = container

	local fout = container:CreateAnimationGroup()
	fout:SetLooping('NONE')
	fout:SetScript('OnFinished', function() container:SetAlpha(0); self:OnFinished() end)

		local a = fout:CreateAnimation('Alpha')
		a:SetFromAlpha(1)
		a:SetToAlpha(0)
		a:SetDuration(0.5)

	self.fout = fout

	local fin = container:CreateAnimationGroup()
	fin:SetLooping('NONE')
	fin:SetScript('OnFinished', function() container:SetAlpha(1) end)

		local a = fin:CreateAnimation('Alpha')
		a:SetFromAlpha(0)
		a:SetToAlpha(1)
		a:SetDuration(0.2)

	self.fin = fin

	local bg = container:CreateTexture(nil, 'BACKGROUND')
	bg:SetColorTexture(0, 0, 0, 0.5)
	bg:SetAllPoints(bg:GetParent())
	self.bg = bg

	local icon = container:CreateTexture(nil, 'ARTWORK')
	icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
	self.icon = icon

	local lb = CreateFrame('StatusBar', nil, container)
	self.latencyBar = lb

	local sb = CreateFrame('StatusBar', nil, lb)
	sb:SetScript('OnValueChanged', function(s, value) self:OnValueChanged(value) end)
	self.statusBar = sb

	local timeText = sb:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	timeText:SetJustifyH('RIGHT')
	self.timeText = timeText

	local labelText = sb:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall')
	labelText:SetJustifyH('LEFT')
	self.labelText = labelText

	self.props = {}

	return self
end

function CastBar:OnLoadSettings()
	if not self.sets.display then
		self.sets.display = {
			icon = true,
			time = true,
			border = false
		}
	end

	self:SetProperty("font", self:GetFontID())
	self:SetProperty("texture", self:GetTextureID())
	self:SetProperty("reaction", "neutral")
end

function CastBar:GetDefaults()
	return {
		point = 'CENTER',
		x = 0,
		y = 30,
		width = 320,
		height = 32,
		padW = 1,
		padH = 1,
		texture = 'blizzard',
		font = 'Friz Quadrata TT',
		display = {
			icon = true,
			time = true,
			border = false
		}
	}
end

--[[ frame events ]]--

function CastBar:OnEvent(event, ...)
	local func = self[event]
	if func then
		func(self, event, ...)
	end
end

function CastBar:OnUpdateCasting(elapsed)
	local sb = self.statusBar
	local lb = self.latencyBar
	local vmin, vmax = sb:GetMinMaxValues()
	local v = sb:GetValue() + elapsed

	if v < vmax then
		sb:SetValue(v)
		lb:SetValue(min(v + self:GetProperty("latency"), vmax))
	else
		sb:SetValue(vmax)
		lb:SetValue(vmax)
		self:SetProperty("state", nil)
	end
end

function CastBar:OnUpdateChanneling(elapsed)
	local sb = self.statusBar
	local lb = self.latencyBar
	local vmin, vmax = sb:GetMinMaxValues()
	local v = sb:GetValue() - elapsed

	if v > vmin then
		sb:SetValue(v)
	else
		sb:SetValue(vmin)
		self:SetProperty("state", nil)
	end
end

function CastBar:OnValueChanged(value)
	self.timeText:SetFormattedText('%.1f', value)
end

function CastBar:OnFinished()
	self:Reset()
end

--[[ game events ]]--

function CastBar:RegisterEvents()
	local unit = self.unit

	self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_START', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_UPDATE', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_CHANNEL_STOP', unit)

	self:RegisterUnitEvent('UNIT_SPELLCAST_START', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_STOP', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_FAILED', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_FAILED_QUIET', unit)

	self:RegisterUnitEvent('UNIT_SPELLCAST_INTERRUPTED', unit)
	self:RegisterUnitEvent('UNIT_SPELLCAST_DELAYED', unit)
end

-- channeling events
function CastBar:UNIT_SPELLCAST_CHANNEL_START(event, unit, name, rank, castID, spellID)
	if unit ~= self.unit then return end

	self:UpdateChannelling(true)
	self:SetProperty("castID", castID)
	self:SetProperty("state", "start")
end

function CastBar:UNIT_SPELLCAST_CHANNEL_UPDATE(event, unit, name, rank, castID, spellID)
	if castID ~= self:GetProperty('castID') then return end

	self:UpdateChannelling()
end

function CastBar:UNIT_SPELLCAST_CHANNEL_STOP(event, unit, name, rank, castID, spellID)
	if castID ~= self:GetProperty('castID') then return end

	self:SetProperty("state", nil)
end

function CastBar:UNIT_SPELLCAST_START(event, unit, name, rank, castID, spellID)
	if unit ~= self.unit then return end

	self:UpdateCasting(true)
	self:SetProperty("castID", castID)
	self:SetProperty("state", "start")
end

function CastBar:UNIT_SPELLCAST_STOP(event, unit, name, rank, castID, spellID)
	if castID ~= self:GetProperty('castID') then return end

	self:SetProperty("state", nil)
end

function CastBar:UNIT_SPELLCAST_FAILED(event, unit, name, rank, castID, spellID)
	if castID ~= self:GetProperty('castID') then return end

	self:SetProperty("reaction", "failed")
	self:SetProperty("label", _G.FAILED)
	self:SetProperty("state", nil)
end

CastBar.UNIT_SPELLCAST_FAILED_QUIET = CastBar.UNIT_SPELLCAST_FAILED

function CastBar:UNIT_SPELLCAST_INTERRUPTED(event, unit, name, rank, castID, spellID)
	if castID ~= self:GetProperty('castID') then return end

	self:SetProperty("reaction", "interrupted")
	self:SetProperty("label", _G.INTERRUPTED)
	self:SetProperty("state", nil)
end

function CastBar:UNIT_SPELLCAST_DELAYED(event, unit, name, rank, castID, spellID)
	if castID ~= self:GetProperty('castID') then return end

	self:UpdateCasting()
end

--[[ attribute events ]]--

function CastBar:mode_update(mode)
	if mode == 'cast' then
		self:SetScript('OnUpdate', self.OnUpdateCasting)
	elseif mode == 'channel' then
		self:SetScript('OnUpdate', self.OnUpdateChanneling)
	elseif mode == 'demo' then
		self:SetupDemo()
	end
end

function CastBar:state_update(state)
	if state == 'start' then
		self.fout:Stop()
		self.fin:Play()
	else
		self:SetScript('OnUpdate', nil)
		self.fin:Stop()
		self.fout:Play()
	end
end

function CastBar:label_update(text)
	self.labelText:SetText(text or '')
end

function CastBar:time_update(text)
	self.timeText:SetText(text or '')
end

function CastBar:icon_update(texture)
	self.icon:SetTexture(texture)
end

function CastBar:spell_update(spellID)
	if spellID and IsHelpfulSpell(spellID) then
		self:SetProperty("reaction", "help")
	elseif spellID and IsHarmfulSpell(spellID) then
		self:SetProperty("reaction", "harm")
	else
		self:SetProperty("reaction", "neutral")
	end
end

function CastBar:reaction_update(reaction)
	if reaction == "failed" or reaction == "interrupted" then
		self.statusBar:SetStatusBarColor(1, 0, 0)
		self.latencyBar:SetStatusBarColor(1, 0, 0)
	elseif reaction == "help" then
		self.statusBar:SetStatusBarColor(0.31, 0.78, 0.47)
	elseif reaction == "harm" then
		self.statusBar:SetStatusBarColor(0.63, 0.36, 0.94)
	else
		self.statusBar:SetStatusBarColor(1, 0.7, 0)
	end

	local r, g, b = self.statusBar:GetStatusBarColor()

	self.latencyBar:SetStatusBarColor(r + 0.25, g + 0.25, b + 0.25)
end

function CastBar:font_update(fontID)
	self.sets.font = fontID

	local newFont = LibStub('LibSharedMedia-3.0'):Fetch('font', fontID)
	local oldFont, fontSize, fontFlags = self.labelText:GetFont()

	if newFont and newFont ~= oldFont then
		self.labelText:SetFont(newFont, fontSize, fontFlags)
		self.timeText:SetFont(newFont, fontSize, fontFlags)
	end
end

function CastBar:texture_update(textureID)
	local texture = LibStub('LibSharedMedia-3.0'):Fetch('statusbar', textureID)

	self.bg:SetTexture(texture)
	self.bg:SetVertexColor(0, 0, 0, 0.5)
	self.statusBar:SetStatusBarTexture(texture)
	self.latencyBar:SetStatusBarTexture(texture)
end

--[[ updates ]]--

function CastBar:SetProperty(key, value)
	local prev = self.props[key]

	if prev ~= value then
		self.props[key] = value

		local func = self[key .. '_update']
		if func then
			func(self, value, prev)
		end
	end
end

function CastBar:GetProperty(key)
	return self.props[key]
end

function CastBar:Layout()
	local padding = self:GetPadding()
	local width, height = self:GetDesiredWidth(), self:GetDesiredHeight()
	local displayIcon = self:Displaying('icon')
	local displayTime = self:Displaying('time')

	self:TrySetSize(width, height)

	local iconSize = self.container:GetHeight() - padding*2

	local icon = self.icon
	icon:SetPoint('LEFT', padding, 0)
	icon:SetSize(iconSize, iconSize)
	icon:SetAlpha(displayIcon and 1 or 0)

	local sb = self.latencyBar
	sb:SetHeight(iconSize)
	sb:SetPoint('RIGHT', -padding or 0, 0)
	if displayIcon then
		sb:SetPoint('LEFT', icon, 'RIGHT', 1, 0)
	else
		sb:SetPoint('LEFT', padding, 0)
	end

	self.statusBar:SetAllPoints(self.latencyBar)

	local time = self.timeText
	time:SetPoint('RIGHT', -2, 0)
	time:SetAlpha(displayTime and 1 or 0)

	local label = self.labelText
	label:SetJustifyH((displayIcon or displayTime) and 'LEFT' or 'CENTER')
	label:SetPoint('LEFT', 2, 0)
	if displayTime then
		label:SetPoint('RIGHT', time, -2, 0)
	else
		label:SetPoint('RIGHT', -2, 0)
	end

	return self
end

function CastBar:UpdateChannelling(reset)
	if reset then
		self:Reset()
	end

	local name, nameSubtext, text, texture, startTime, endTime = UnitChannelInfo(self.unit)

	if name then
		self:SetProperty('mode', 'channel')
		self:SetProperty('label', name or text)
		self:SetProperty('icon', texture)
		self:SetProperty('spell', GetSpellInfo(name))

		local sb = self.statusBar
		sb:SetMinMaxValues(0, (endTime - startTime) / 1000)
		sb:SetValue(endTime / 1000 - GetTime())

		self.latencyBar:SetValue(0)

		return true
	end

	return false
end

function CastBar:UpdateCasting(reset)
	if reset then
		self:Reset()
	end

	local name, nameSubtext, text, texture, startTime, endTime = UnitCastingInfo(self.unit)

	if name then
		self:SetProperty('mode', 'cast')
		self:SetProperty('label', text)
		self:SetProperty('icon', texture)
		self:SetProperty('spell', GetSpellInfo(name))
		self:SetProperty('latency', self:GetLatency())

		local sb = self.statusBar
		sb:SetMinMaxValues(0, (endTime - startTime) / 1000)
		sb:SetValue(GetTime() - startTime / 1000)

		local lb = self.latencyBar
		lb:SetMinMaxValues(sb:GetMinMaxValues())
		lb:SetValue(sb:GetValue() + self:GetProperty("latency"))

		return true
	end

	return false
end

function CastBar:Reset()
	self:SetProperty('state', nil)
	self:SetProperty('mode', nil)
	self:SetProperty('label', nil)
	self:SetProperty('icon', nil)
	self:SetProperty('spell', nil)
	self:SetProperty('reaction', nil)
end

function CastBar:SetupDemo()
	local spellID = self:GetRandomspellID()
	local name, rank, icon = GetSpellInfo(spellID)

	self:SetProperty('mode', 'demo')
	self:SetProperty("label", name)
	self:SetProperty("icon", icon)
	self:SetProperty("spell", spellID)

	self.statusBar:SetMinMaxValues(0, 1)
	self.statusBar:SetValue(1)
end

function CastBar:GetRandomspellID()
	local spells = {}
	local offset = 0

	for i = 1, GetNumSpellTabs() do
		local offset, numSpells = select(3, GetSpellTabInfo(i))
		local tabEnd = offset + numSpells

		for j = offset, tabEnd - 1 do
			local _, spellID = GetSpellBookItemInfo(j, 'player')
			if spellID then
				table.insert(spells, spellID)
			end
		end
	end

	return spells[math.random(1, #spells)]
end

-- the latency indicator in the castbar is meant to tell you when you can
-- safely cast a spell, so we
function CastBar:GetLatency()
	local down, up, lagHome, lagWorld = GetNetStats()

	return (max(lagHome, lagWorld) + self:GetLatencyPadding()) / 1000
end


--[[ settings ]]--

function CastBar:SetDesiredWidth(width)
	self.sets.width = width
	self:Layout()
end

function CastBar:GetDesiredWidth()
	return self.sets.width or 320
end

function CastBar:SetDesiredHeight(height)
	self.sets.height = height
	self:Layout()
end

function CastBar:GetDesiredHeight()
	return self.sets.height or 32
end

--font
function CastBar:SetFontID(fontID)
	self.sets.font = fontID
	self:SetProperty('font', self:GetFontID())

	return self
end

function CastBar:GetFontID()
	return self.sets.font or 'Friz Quadrata TT'
end

--texture
function CastBar:SetTextureID(textureID)
	self.sets.texture = textureID
	self:SetProperty('texture', self:GetTextureID())

	return self
end

function CastBar:GetTextureID()
	return self.sets.texture or 'blizzard'
end

--display
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

--[[ menu ]]--

do
	function CastBar:CreateMenu()
		local menu = Dominos:NewMenu(self.id)

		self:AddLayoutPanel(menu)
		self:AddTexturePanel(menu)
		self:AddFontPanel(menu)

		self.menu = menu

		self.menu:HookScript('OnShow', function()
			self:SetupDemo()
			self:SetProperty("state", "start")
		end)

		self.menu:HookScript('OnHide', function()
			if self:GetProperty("mode") == "demo" then
				self:SetProperty("state", nil)
			end
		end)

		return menu
	end

	function CastBar:AddLayoutPanel(menu)
		local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')

		for _, part in ipairs{'icon', 'time'} do
			panel:NewCheckButton{
				name = l['Display_' .. part],

				get = function() return panel.owner:Displaying(part) end,

				set = function(_, enable) panel.owner:SetDisplay(part, enable) end
			}
		end

		panel.widthSlider = panel:NewSlider{
			name = l.Width,

			min = 1,

			max = function()
				return math.ceil(_G.UIParent:GetWidth() / panel.owner:GetScale())
			end,

			get = function()
				return panel.owner:GetDesiredWidth()
			end,

			set = function(_, value)
				panel.owner:SetDesiredWidth(value)
			end,
		}

		panel.heightSlider = panel:NewSlider{
			name = l.Height,

			min = 1,

			max = function()
				return math.ceil(_G.UIParent:GetHeight() / panel.owner:GetScale())
			end,

			get = function()
				return panel.owner:GetDesiredHeight()
			end,

			set = function(_, value)
				panel.owner:SetDesiredHeight(value)
			end,
		}

		panel.paddingSlider = panel:NewPaddingSlider()
		panel.scaleSlider = panel:NewScaleSlider()
		panel.opacitySlider = panel:NewOpacitySlider()
		panel.fadeSlider = panel:NewFadeSlider()

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
			end,
		}
	end

	function CastBar:AddFontPanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')
		local panel = menu:NewPanel(l.Font)

		panel.fontSelector = Dominos.Options.FontSelector:New{
			parent = panel,

			get = function()
				return panel.owner:GetFontID()
			end,

			set = function(_, value)
				panel.owner:SetFontID(value)
			end,
		}
	end

	function CastBar:AddTexturePanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-CastBar')
		local panel = menu:NewPanel(l.Texture)

		panel.textureSelector = Dominos.Options.TextureSelector:New{
			parent = panel,

			get = function()
				return panel.owner:GetTextureID()
			end,

			set = function(_, value)
				panel.owner:SetTextureID(value)
			end,
		}
	end
end

--[[ exports ]]--

Addon.CastBar = CastBar