--[[
	MenuBar, by Goranaws
--]]

local MenuBar = Dominos:CreateClass('Frame', Dominos.ButtonBar)
Dominos.MenuBar = MenuBar

local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

local MICRO_BUTTONS = {
	"CharacterMicroButton",
	"SpellbookMicroButton",
	"TalentMicroButton",
	"AchievementMicroButton",
	"QuestLogMicroButton",
	"GuildMicroButton",
	"LFDMicroButton",
	"EJMicroButton",
	"CollectionsMicroButton",
	"StoreMicroButton",
	"HelpMicroButton",
	"MainMenuMicroButton"
}

local MICRO_BUTTON_NAMES = {
	['CharacterMicroButton'] = _G['CHARACTER_BUTTON'],
	['SpellbookMicroButton'] = _G['SPELLBOOK_ABILITIES_BUTTON'],
	['TalentMicroButton'] = _G['TALENTS_BUTTON'],
	['AchievementMicroButton'] = _G['ACHIEVEMENT_BUTTON'],
	['QuestLogMicroButton'] = _G['QUESTLOG_BUTTON'],
	['GuildMicroButton'] = _G['LOOKINGFORGUILD'],
	['LFDMicroButton'] = _G['DUNGEONS_BUTTON'],
	['EJMicroButton'] = _G['ENCOUNTER_JOURNAL'],
	['MainMenuMicroButton'] = _G['MAINMENU_BUTTON'],
	['HelpMicroButton'] = _G['HELP_BUTTON'],
	['StoreMicroButton'] = _G['BLIZZARD_STORE'],
	['CollectionsMicroButton'] = _G['COLLECTIONS']
}


--[[ Menu Bar ]]--

function MenuBar:New()
	local bar = MenuBar.proto.New(self, 'menu')

	bar:LoadButtons()
	bar:Layout()

	return bar
end

function MenuBar:Create(frameId)
	local bar = MenuBar.proto.Create(self, frameId)

	bar.buttons = {}
	bar.activeButtons = {}

	local getOrHook = function(frame, script, action)
		if frame:GetScript(script) then
			frame:HookScript(script, action)
		else
			frame:SetScript(script, action)
		end
	end

	local requestLayoutUpdate
	do
		local f = CreateFrame('Frame'); f:Hide()
		local delay = 0.01

		f:SetScript('OnUpdate', function(self, elapsed)
			self:Hide()
			bar:Layout()
		end)

		requestLayoutUpdate = function() f:Show() end
	end

	hooksecurefunc('UpdateMicroButtons', requestLayoutUpdate)

	local petBattleFrame = _G['PetBattleFrame'].BottomFrame.MicroButtonFrame

	getOrHook(petBattleFrame, 'OnShow', function()
		bar.isPetBattleUIShown = true
		requestLayoutUpdate()
	end)

	getOrHook(petBattleFrame, 'OnHide', function()
		bar.isPetBattleUIShown = nil
		requestLayoutUpdate()
	end)


	local overrideActionBar = _G['OverrideActionBar']

	getOrHook(overrideActionBar, 'OnShow', function()
		bar.isOverrideUIShown = Dominos:UsingOverrideUI()
		requestLayoutUpdate()
	end)

	getOrHook(overrideActionBar, 'OnHide', function()
		bar.isOverrideUIShown = nil
		requestLayoutUpdate()
	end)

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

	if button then
		button:SetParent(self.header)
		button:Show()

		self.buttons[i] = button
	end
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
	MenuBar.proto.LoadSettings(self, ...)

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
	if self.isPetBattleUIShown then
		self:LayoutPetBattle()
	elseif self.isOverrideUIShown then
		self:LayoutOverrideUI()
	else
		self:LayoutNormal()
	end
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
	self:FixButtonPositions()
end

function MenuBar:LayoutOverrideUI()
	self:FixButtonPositions()
end

function MenuBar:FixButtonPositions()
	local isStoreEnabled = C_StorePublic.IsEnabled()
	local overrideButtons = {}

	for i, buttonName in ipairs(MICRO_BUTTONS) do
		local button = _G[buttonName]
		button:Hide()

		local shouldAddButton

		if buttonName == 'HelpMicroButton' then
			shouldAddButton = not isStoreEnabled
		elseif buttonName == 'StoreMicroButton' then
			shouldAddButton = isStoreEnabled
		else
			shouldAddButton = true
		end

		if shouldAddButton then
			table.insert(overrideButtons, button)
		end
	end

	for i, button in ipairs(overrideButtons) do
		if i > 1 then
			button:ClearAllPoints()
			if i == 7 then
				button:SetPoint('TOPLEFT', overrideButtons[1], 'BOTTOMLEFT', 0, HEIGHT_OFFSET + 4)
			else
				button:SetPoint('BOTTOMLEFT', overrideButtons[i - 1], 'BOTTOMRIGHT', -WIDTH_OFFSET, 0)
			end
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

	if menu then
		Menu_AddLayoutPanel(menu)
		Menu_AddDisableMenuButtonsPanel(menu)
		menu:AddAdvancedPanel()

		self.menu = menu
	end

	return menu
end


--[[ module ]]--

local MenuBarController = Dominos:NewModule('MenuBar')

function MenuBarController:OnInitialize()

	-- fixed blizzard nil bug
	if not _G['AchievementMicroButton_Update'] then
		_G['AchievementMicroButton_Update'] = function() end
	end
end

function MenuBarController:Load()
	self.frame = MenuBar:New()
end

function MenuBarController:Unload()
	if self.frame then
		self.frame:Free()
		self.frame = nil
	end
end
