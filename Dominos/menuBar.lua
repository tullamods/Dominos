--[[
	MenuBar, by Goranaws
--]]

local MenuBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.MenuBar = MenuBar

local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

local MICRO_BUTTONS = _G['MICRO_BUTTONS']
local MICRO_BUTTON_NAMES = {
	['CharacterMicroButton'] = CHARACTER_BUTTON,
	['SpellbookMicroButton'] = SPELLBOOK_ABILITIES_BUTTON,
	['TalentMicroButton'] = TALENTS_BUTTON,
	['AchievementMicroButton'] = ACHIEVEMENT_BUTTON,
	['QuestLogMicroButton'] = QUESTLOG_BUTTON,
	['GuildMicroButton'] = LOOKINGFORGUILD,
	['PVPMicroButton'] = PLAYER_V_PLAYER,
	['LFDMicroButton'] = DUNGEONS_BUTTON,
	['CompanionsMicroButton'] = MOUNTS_AND_PETS,
	['EJMicroButton'] = ENCOUNTER_JOURNAL,
	['MainMenuMicroButton'] = MAINMENU_BUTTON,
	['HelpMicroButton'] = HELP_BUTTON
}

--[[ Menu Bar ]]--

function MenuBar:New()
	local bar = MenuBar.super.New(self, 'menu')

	bar:LoadButtons()
	bar:Layout()

	return bar
end

function MenuBar:Create(frameId)
	local bar = MenuBar.super.Create(self, frameId)
	
	bar.buttons = {}
	bar.activeButtons = {}

	local header = bar.header
	
	header:SetAttribute('_onstate-petbattleui', [[ 
		self:RunAttribute('updateShown')
		self:CallMethod('Layout')
	]])
	
	header:SetAttribute('_onstate-overrideui', [[ 
		self:RunAttribute('updateShown')
		self:CallMethod('Layout')
	]])
	
	_G['MainMenuBar']:HookScript('OnShow', function() bar:Layout() end)
	
	header.Layout = function() bar:Layout() end
	
	return bar
end

function MenuBar:LoadButtons()
	for i, buttonName in ipairs(MICRO_BUTTONS) do
		self:AddButton(i)
	end
	
	self:UpdateClickThrough()
end

function MenuBar:AddButton(i) 
	local buttonName = MICRO_BUTTONS[i]
	local button = _G[buttonName]
	
	button:SetParent(self.header)
	button:Show()

	self.buttons[i] = button
end

function MenuBar:RemoveButton(i)
	local button = self.buttons[i]
	if button then
		button:SetParent(nil)
		button:Hide()
		self.buttons[i] = nil
	end
end

function MenuBar:LoadSettings(...)	
	MenuBar.super.LoadSettings(self, ...)
	
	self.activeButtons = {}
end

function MenuBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		x = -244,
		y = 0,
	}
end

function MenuBar:NumButtons()
	return #self.activeButtons
end

function MenuBar:DisableMenuButton(button, disabled)
	local disabledButtons = self.sets.disabled or {}

	disabledButtons[button:GetName()] = disabled or false	
	self.sets.disabled = disabledButtons

	self:Layout()	
end

function MenuBar:IsMenuButtonDisabled(button)
	local disabledButtons = self.sets.disabled
	
	if disabledButtons then
		return disabledButtons[button:GetName()]
	end
	
	return false
end

function MenuBar:Layout()
	if self.header:GetAttribute('state-petbattleui') then
		self:LayoutPetBattle()
		return
	end
	
	if self.header:GetAttribute('state-overrideui') then
		self:LayoutOverrideUI()
		return
	end

	self:LayoutNormal()
end

function MenuBar:LayoutNormal()
	self:UpdateActiveButtons()
	
	for i, button in pairs(self.buttons) do
		button:Hide()
	end
	
	local numButtons = #self.activeButtons
	if numButtons == 0 then
		self:SetSize(36, 36)
		return
	end
	
	local cols = min(self:NumColumns(), numButtons)
	local rows = ceil(numButtons / cols)

	local pW, pH = self:GetPadding()
	local spacing = self:GetSpacing()

	local isLeftToRight = self:GetLeftToRight()
	local isTopToBottom = self:GetTopToBottom()

	local firstButton = self.buttons[1]
	local w = firstButton:GetWidth() + spacing - WIDTH_OFFSET
	local h = firstButton:GetHeight() + spacing - HEIGHT_OFFSET

	for i, button in pairs(self.activeButtons) do
		local col, row
		
		if isLeftToRight then
			col = (i-1) % cols
		else
			col = (cols-1) - (i-1) % cols
		end

		if isTopToBottom then
			row = ceil(i / cols) - 1
		else
			row = rows - ceil(i / cols)
		end
		
		button:SetParent(self.header)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH) + HEIGHT_OFFSET)
		button:Show()
	end

	-- Update bar size, if we're not in combat
	-- TODO: manage bar size via secure code
	if not InCombatLockdown() then
		local newWidth = max(w*cols - spacing + pW*2 + WIDTH_OFFSET, 8)
		local newHeight = max(h*ceil(numButtons / cols) - spacing + pH*2, 8)
		self:SetSize(newWidth, newHeight)
	end
end

function MenuBar:LayoutPetBattle()
	local parentFrame = _G['PetBattleFrame'].BottomFrame.MicroButtonFrame
	local anchorX, anchorY = -10, 27
	
	UpdateMicroButtonsParent(parentFrame)
	MoveMicroButtons("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", anchorX, anchorY, true)
								
	self:FixButtonPositions()
end

function MenuBar:LayoutOverrideUI()
	local parentFrame = _G['OverrideActionBar']
	local anchorX, anchorY = OverrideActionBar_GetMicroButtonAnchor()
	
	UpdateMicroButtonsParent(parentFrame)
	MoveMicroButtons("BOTTOMLEFT", parentFrame, "BOTTOMLEFT", anchorX, anchorY, true)
	
	self:FixButtonPositions()
end

function MenuBar:FixButtonPositions()
	local myButtons = self.buttons
	
	for i, button in pairs(myButtons) do
		if not(i == 1 or i == floor(#myButtons / 2) + 1) then
			button:ClearAllPoints()
			button:SetPoint('BOTTOMLEFT', myButtons[i - 1], 'BOTTOMRIGHT', -3, 0)
		end
		button:Show()
	end
end

function MenuBar:UpdateActiveButtons()
	for i = 1, #self.activeButtons do self.activeButtons[i] = nil end
	
	for i, button in ipairs(self.buttons) do
		if not self:IsMenuButtonDisabled(button) then
			table.insert(self.activeButtons, button)
		end
	end
end

--[[ Menu Code ]]--

local function Menu_AddLayoutPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
	
	panel:NewOpacitySlider()
	panel:NewFadeSlider()
	panel:NewScaleSlider()
	panel:NewPaddingSlider()
	panel:NewSpacingSlider()
	panel:NewColumnsSlider()
	
	return panel
end

local function Panel_AddDisableMenuButtonCheckbox(panel, button, name)
	local checkbox = panel:NewCheckButton(name or button:GetName())

	checkbox:SetScript('OnClick', function(self)
		local owner = self:GetParent().owner
		
		owner:DisableMenuButton(button, self:GetChecked())
	end)

	checkbox:SetScript('OnShow', function(self)
		local owner = self:GetParent().owner
		
		self:SetChecked(owner:IsMenuButtonDisabled(button))
	end)

	return checkbox
end

local function Menu_AddDisableMenuButtonsPanel(menu)
	local panel = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').DisableMenuButtons)
	panel.width = 200
	
	for i, buttonName in ipairs(MICRO_BUTTONS) do
		Panel_AddDisableMenuButtonCheckbox(panel, _G[buttonName], MICRO_BUTTON_NAMES[buttonName])
	end
	
	return panel
end

function MenuBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)

	Menu_AddLayoutPanel(menu)
	Menu_AddDisableMenuButtonsPanel(menu)
	menu:AddAdvancedPanel()
	
	self.menu = menu
	
	return menu
end