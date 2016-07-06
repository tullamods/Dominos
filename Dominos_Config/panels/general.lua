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
end

--
--
-- --[[ Dropdowns ]]--
--
-- do
-- 	local info = {}
-- 	local function AddItem(text, value, func, checked, arg1)
-- 		info.text = text
-- 		info.func = func
-- 		info.value = value
-- 		info.checked = checked
-- 		info.arg1 = arg1
-- 		UIDropDownMenu_AddButton(info)
-- 	end
--
-- 	local function AddRightClickTargetSelector(self)
-- 		local dd = self:NewDropdown(L.RightClickUnit)
--
-- 		dd:SetScript('OnShow', function(self)
-- 			UIDropDownMenu_SetWidth(self, 110)
-- 			UIDropDownMenu_Initialize(self, self.Initialize)
-- 			UIDropDownMenu_SetSelectedValue(self, Dominos:GetRightClickUnit() or 'NONE')
-- 		end)
--
-- 		local function Item_OnClick(self)
-- 			Dominos:SetRightClickUnit(self.value ~= 'NONE' and self.value or nil)
-- 			UIDropDownMenu_SetSelectedValue(dd, self.value)
-- 		end
--
-- 		function dd:Initialize()
-- 			local selected = Dominos:GetRightClickUnit()  or 'NONE'
--
-- 			AddItem(L.RCUPlayer, 'player', Item_OnClick, 'player' == selected)
-- 			AddItem(L.RCUFocus, 'focus', Item_OnClick, 'focus' == selected)
-- 			AddItem(L.RCUToT, 'targettarget', Item_OnClick, 'targettarget' == selected)
-- 			AddItem(NONE_KEY, 'NONE', Item_OnClick, 'NONE' == selected)
-- 		end
-- 		return dd
-- 	end
--
-- 	local function AddPossessBarSelector(self)
-- 		local dd = self:NewDropdown(L.PossessBar)
--
-- 		dd:SetScript('OnShow', function(self)
-- 			UIDropDownMenu_SetWidth(self, 110)
-- 			UIDropDownMenu_Initialize(self, self.Initialize)
-- 			UIDropDownMenu_SetSelectedValue(self, Dominos:GetOverrideBar().id)
-- 		end)
--
-- 		local function Item_OnClick(self)
-- 			Dominos:SetOverrideBar(self.value)
-- 			UIDropDownMenu_SetSelectedValue(dd, self.value)
-- 		end
--
-- 		function dd:Initialize()
-- 			local selected = Dominos:GetOverrideBar().id
--
-- 			for i = 1, Dominos:NumBars() do
-- 				AddItem('Action Bar ' .. i, i, Item_OnClick, i == selected)
-- 			end
-- 		end
-- 		return dd
-- 	end
--
-- 	local rightClickUnit = AddRightClickTargetSelector(Options)
-- 	rightClickUnit:SetPoint('TOPRIGHT', -10, -120)
--
-- 	local possess = AddPossessBarSelector(Options)
-- 	possess:SetPoint('TOP', rightClickUnit, 'BOTTOM', 0, -16)
-- end
