local AddonName, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local EncounterBar = Dominos:CreateClass('Frame', Dominos.Frame); Addon.EncounterBar = EncounterBar

function EncounterBar:New()
	local f = EncounterBar.proto.New(self, 'encounter')

	f:AttachPlayerPowerBarAlt()
	f:ShowInOverrideUI(true)
	f:ShowInPetBattleUI(true)
	f:Layout()

	return f
end

function EncounterBar:OnEvent(self, event, ...)
	local f = self[event]
	if f then
		f(self, event, ...)
	end
end

function EncounterBar:GetDefaults()
	return { point = 'CENTER' }
end

function EncounterBar:Layout()
	if InCombatLockdown() then
		return
	end

	local bar = self.PlayerPowerBarAlt
	local width, height = bar:GetSize()
	local pW, pH = self:GetPadding()

	width = math.max(width, 36 * 6)
	height = math.max(height, 36)

	self:SetSize(width + pW, height + pH)
end

function EncounterBar:AttachPlayerPowerBarAlt()
	if not self.PlayerPowerBarAlt then
		local bar = _G['PlayerPowerBarAlt']

		bar:ClearAllPoints()
		bar:SetParent(self.header)
		bar:SetPoint('CENTER', self.header)

		if bar:GetScript('OnSizeChanged') then
			bar:HookScript('OnSizeChanged', function() self:Layout() end)
		else
			bar:SetScript('OnSizeChanged', function() self:Layout() end)
		end

		self.PlayerPowerBarAlt = bar
	end
end

function EncounterBar:GetPlayerPowerBarAlt()
	return _G['PlayerPowerBarAlt']
end

function EncounterBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)

	self:AddLayoutPanel(menu)
	self:AddAdvancedPanel(menu)

	self.menu = menu

	return menu
end

function EncounterBar:AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)

	panel.opacitySlider = panel:NewOpacitySlider()
	panel.fadeSlider = panel:NewFadeSlider()
	panel.scaleSlider = panel:NewScaleSlider()
	panel.paddingSlider = panel:NewPaddingSlider()
	panel.spacingSlider = panel:NewSpacingSlider()

	return panel
end

function EncounterBar:AddAdvancedPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Advanced)

	panel:NewClickThroughCheckbox()

	return panel
end
