local AddonName, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local EncounterBar = Dominos:CreateClass('Frame', Dominos.Frame); Addon.EncounterBar = EncounterBar

function EncounterBar:New()
	local f = Dominos.Frame.New(self, 'encounter')
	
	f:AttachPlayerPowerBarAlt()
	f:Layout()

	return f
end

function EncounterBar:GetDefaults()
	return { point = 'CENTER' }
end

function EncounterBar:NumButtons()
	return 1
end

function EncounterBar:Layout()
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