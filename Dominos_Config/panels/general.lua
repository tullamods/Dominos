--[[
	general.lua
		The general GeneralPanel of the Dominos options menu
--]]
local AddonName, Addon = ...
local Dominos = _G.Dominos
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

local GeneralPanel = Addon.AddonOptionsPanel:New{ name = 'General' }
do
	local lockButton = GeneralPanel:Add('Button', {
		name = L.EnterConfigMode,
		width = 136,
		height = 22,
		click = function()
			Dominos:ToggleLockedFrames()
			HideUIPanel(InterfaceOptionsFrame)
		end
	})
	lockButton:SetPoint('TOPLEFT', 12, -72)

	local bindButton = GeneralPanel:Add('Button', {
		name = L.EnterBindingMode,
		width = 136,
		height = 22,
		click = function()
			Dominos:ToggleBindingMode()
			HideUIPanel(InterfaceOptionsFrame)
		end
	})
	bindButton:SetPoint('LEFT', lockButton, 'RIGHT', 4, 0)


	--[[ General Settings ]]--

	local stickyBarsToggle = GeneralPanel:Add('CheckButton', {
		name = L.StickyBars,
		get = function() return Dominos:Sticky() end,
		set = function(enable) Dominos:SetSticky(enable) end
	})
	stickyBarsToggle:SetPoint('TOPLEFT', lockButton, 'BOTTOMLEFT', 0, -24)

	local linkedOpacityToggle = GeneralPanel:Add('CheckButton',{
		name = L.LinkedOpacity,
		small = true,
		get = function() return Dominos:IsLinkedOpacityEnabled() end,
		set = function(enable) Dominos:SetLinkedOpacity(enable) end
	})
	linkedOpacityToggle:SetPoint('TOP', stickyBarsToggle, 'BOTTOM', 8, -2)

	local showMinimapButtonToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowMinimapButton,
		get = function() return Dominos:ShowingMinimap() end,
		set = function(enable) Dominos:SetShowMinimap(enable) end
	})
	showMinimapButtonToggle:SetPoint('TOP', linkedOpacityToggle, 'BOTTOM', -8, -10)

	-- --[[ Action Bar Settings ]]--

	--lock action button positions
	--this option causes taint, but only for the session that the option is set in
	local lockButtonsToggle = GeneralPanel:Add('CheckButton', {
		name = L.LockActionButtons,
		get = function() return LOCK_ACTIONBAR == '1' end,
		set = function() _G['InterfaceOptionsActionBarsPanelLockActionBars']:Click() end
	})
	lockButtonsToggle:SetPoint('TOP', showMinimapButtonToggle, 'BOTTOM', 0, -10)

	--show empty buttons
	local showEmptyButtonsToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowEmptyButtons,
		get = function() return Dominos:ShowGrid() end,
		set = function(enable) Dominos:SetShowGrid(enable) end
	})
	showEmptyButtonsToggle:SetPoint('TOP', lockButtonsToggle, 'BOTTOM', 0, -10)

	--show keybinding text
	local showBindingsButtonToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowBindingText,
		get = function() return Dominos:ShowBindingText() end,
		set = function(enable) Dominos:SetShowBindingText(enable) end
	})
	showBindingsButtonToggle:SetPoint('TOP', showEmptyButtonsToggle, 'BOTTOM', 0, -10)

	--show macro text
	local showMacroTextToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowMacroText,
		get = function() return Dominos:ShowMacroText() end,
		set = function(enable) Dominos:SetShowMacroText(enable) end
	})
	showMacroTextToggle:SetPoint('TOP', showBindingsButtonToggle, 'BOTTOM', 0, -10)

	--show tooltips
	local showTooltipsToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowTooltips,
		get = function() return Dominos:ShowTooltips() end,
		set = function(enable) Dominos:SetShowTooltips(enable) end
	})
	showTooltipsToggle:SetPoint('TOP', showMacroTextToggle, 'BOTTOM', 0, -10)

	--show tooltips in combat
	local showTooltipsInCombatToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowTooltipsCombat,
		small = true,
		get = function() return Dominos:ShowCombatTooltips() end,
		set = function(enable) Dominos:SetShowCombatTooltips(enable) end
	})
	showTooltipsInCombatToggle:SetPoint('TOP', showTooltipsToggle, 'BOTTOM', 8, -2)

	--show override ui
	local useBlizzardOverrideUIToggle = GeneralPanel:Add('CheckButton', {
		name = L.ShowOverrideUI,
		get = function() return Dominos:UsingOverrideUI() end,
		set = function(enable) Dominos:SetUseOverrideUI(enable) end
	})
	useBlizzardOverrideUIToggle:SetPoint('TOP', showTooltipsInCombatToggle, 'BOTTOM', -8, -10)


	--right click unit
	local rightClickUnitSelector = GeneralPanel:Add('Dropdown', {
		name = L.RightClickUnit,
		get = function()
			return Dominos:GetRightClickUnit() or 'NONE'
		end,

		set = function(_, value)
			Dominos:SetRightClickUnit(value ~= 'NONE' and value or nil)
		end,

		items = {
			{text = L.RCUPlayer, value = 'player'},
			{text = L.RCUFocus, value = 'focus'},
			{text = L.RCUToT, value = 'targettarget'},
			{text = NONE_KEY, value = 'NONE'},
		}
	})

	rightClickUnitSelector:SetPoint('TOPRIGHT', -10, -120)


	--right click unit
	local possessBarSelector = GeneralPanel:Add('Dropdown', {
		name = L.PossessBar,

		get = function()
			local bar = Dominos:GetOverrideBar()

			return bar and bar.id or 1
		end,

		set = function(_, value)
			Dominos:SetOverrideBar(value)
		end,

		items = function()
			local items = {}

			for i = 1, Dominos:NumBars() do
				table.insert(items, { text = ('Action Bar %d'):format(i), value = i })
			end

			return items
		end
	})

	possessBarSelector:SetPoint('TOP', rightClickUnitSelector, 'BOTTOM', 0, -2)

	-- profile selector
	local profileSelector = GeneralPanel:Add('Dropdown', {
		name = 'Profile',

		get = function()
			return Dominos.db:GetCurrentProfile()
		end,

		set = function(_, value)
			Dominos:SetProfile(value)
			GeneralPanel:Hide()
			GeneralPanel:Show()
		end,

		items = function()
			local profiles = Dominos.db:GetProfiles()

			table.sort(profiles)

			return profiles
		end
	})

	profileSelector:SetPoint('TOP', possessBarSelector, 'BOTTOM', 0, -2)
end