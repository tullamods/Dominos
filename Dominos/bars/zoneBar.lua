local ZoneAbilityFrame = _G.ZoneAbilityFrame
if not ZoneAbilityFrame then return end

local _, Addon = ...

--[[ bar ]]--

local ZoneBar = Addon:CreateClass('Frame', Addon.Frame)

do
	function ZoneBar:New()
		return ZoneBar.proto.New(self, 'zone')
	end

	function ZoneBar:GetDefaults()
		return {
			point = 'RIGHT',
			x = 0,
			y = 0,
			showInPetBattleUI = true,
			showInOverrideUI = true
		}
	end

	function ZoneBar:Layout()
		ZoneAbilityFrame:ClearAllPoints()
		ZoneAbilityFrame:SetPoint('CENTER', self.header)
		ZoneAbilityFrame:SetParent(self.header)

		local w, h = ZoneAbilityFrame:GetSize()
		local pW, pH = self:GetPadding()

		self:SetSize(w + pW, h + pH)
	end

	function ZoneBar:CreateMenu()
		local menu = Addon:NewMenu()

		self:AddLayoutPanel(menu)

		menu:AddAdvancedPanel()

		self.menu = menu
	end

	function ZoneBar:AddLayoutPanel(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

		local panel = menu:NewPanel(l.Layout)

		panel.opacitySlider = panel:NewOpacitySlider()
		panel.fadeSlider = panel:NewFadeSlider()
		panel.scaleSlider = panel:NewScaleSlider()
		panel.paddingSlider = panel:NewPaddingSlider()
	end
end

--[[ module ]]--

local ZoneBarController = Addon:NewModule('ZoneBar')

function ZoneBarController:OnInitialize()
	-- luacheck: push ignore 122
	ZoneAbilityFrame.ignoreFramePositionManager = true
	-- luacheck: pop
end

function ZoneBarController:Load()
	self.frame = ZoneBar:New()
end

function ZoneBarController:Unload()
	self.frame:Free()
end
