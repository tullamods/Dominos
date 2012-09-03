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

	bar:Layout(true)
	bar:UpdateClickThrough()

	return bar
end

function MenuBar:Create(frameId)
	local bar = MenuBar.super.Create(self, frameId)
	
	local header = bar.header

	
	--[[ init any bar global variables ]]--
	
	header:Execute([[
		SPACING_OFFSET = -2
		PADW_OFFSET = 0
		PADH_OFFSET = 0
		HEIGHT_OFFSET = 22
		WIDTH_OFFSET = 0
		
		myButtons = table.new()
		disabledButtons = table.new()
		activeButtons = table.new()
	]])
	
	--[[ 
		after a layout value is altered, set a dirty bit indicating that we need to adjust the bar's layout 
	--]]
	
	header:SetAttribute('_onstate-petbattleui', [[ 
		self:RunAttribute('updateShown')
		self:RunAttribute('updateLayout') 
	]])
	
	header:SetAttribute('_onstate-overrideui', [[ 
		self:RunAttribute('updateShown')
		self:RunAttribute('updateLayout') 
	]])
	
	header:SetAttribute('_onstate-forcelayout', [[ self:RunAttribute('updateLayout') ]])
	
	header:SetAttribute('_onstate-columns', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-spacing', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-padW', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-padH', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-topToBottom', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-leftToRight', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-disableButton', [[		
		local button = self:GetFrameRef('buttonToDisable')
		local disable = newstate

		if disabledButtons[button] ~= disable then
			disabledButtons[button] = disable		
			needsLayout = true 
		end
	]])
	
	--add button method
	header:SetAttribute('addButton', [[
		local button = self:GetFrameRef('addButton')		
		
		if button then
			table.insert(myButtons, button)
			button:SetParent(self:GetFrameRef('buttonFrame') or self)
		end
	]])
	
	header:SetAttribute('updateActiveButtons', [[
		table.wipe(activeButtons)
		
		for i, button in ipairs(myButtons) do
			if not disabledButtons[button] then
				table.insert(activeButtons, button)
			end
		end
		
		self:SetAttribute('maxLength', #activeButtons)
	]])
	
	header:SetAttribute('updateLayout', [[
		local layoutState
		if self:GetAttribute('state-petbattleui') then
			layoutState = 'petbattleui'
		elseif self:GetAttribute('state-overrideui') then
			layoutState = 'overrideui'
		else
			layoutState = 'standard'
		end
		
		needsLayout = true
		self:RunAttribute('layout-' .. layoutState)
	]])
	
	header:SetAttribute('layout-petbattleui', [[ 
		local numButtons = #myButtons
		local cols = ceil(numButtons / 2)
		
		local b = myButtons[1]
		local w = b:GetWidth() - (WIDTH_OFFSET)
		local h = b:GetHeight() - (HEIGHT_OFFSET + 2)
		
		for i, b in pairs(myButtons) do
			local col = (i-1) % cols
			local row = ceil(i / cols) - 1
		
			local b = myButtons[i]
			b:ClearAllPoints()
			b:SetPoint('TOPLEFT', '$parent', 'TOPLEFT', -16 + w*col + WIDTH_OFFSET, 6 -(h*row) + HEIGHT_OFFSET)
			b:Show()
		end
	]])
	
	header:SetAttribute('layout-overrideui', [[
		for i, button in pairs(myButtons) do
			if not(i == 1 or i == floor(#myButtons / 2) + 1) then
				button:ClearAllPoints()
				button:SetPoint('BOTTOMLEFT', self:GetFrameRef(myButtons[i - 1]:GetName() .. 'Overlay'), 'BOTTOMRIGHT', -3, 0)
				button:Show()
			end
		end
	]])
	
	header:SetAttribute('layout-standard', [[
		if not needsLayout then return end

		self:RunAttribute('updateActiveButtons')
		
		local numButtons = #activeButtons
		if numButtons == 0 then
			self:GetParent():SetWidth(36)
			self:GetParent():SetHeight(36)
			return
		end
		
		local cols = min(self:GetAttribute('state-columns') or numButtons, numButtons)
		local rows = ceil(numButtons / cols)

		local pW, pH = self:GetAttribute('state-padW') or 0, self:GetAttribute('state-padH') or 0
		local spacing = self:GetAttribute('state-spacing') or 0

		local isLeftToRight = self:GetAttribute('state-leftToRight')
		local isTopToBottom = self:GetAttribute('state-topToBottom')

		local firstButton = myButtons[1]
		local w = firstButton:GetWidth() + spacing - WIDTH_OFFSET
		local h = firstButton:GetHeight() + spacing - HEIGHT_OFFSET
		
		for i = 1, #myButtons do
			myButtons[i]:Hide()
		end

		for i, button in pairs(activeButtons) do
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
			
			button:SetParent(self)
			button:ClearAllPoints()
			button:SetPoint('TOPLEFT', '$parent', 'TOPLEFT', w*col + pW, -(h*row + pH) + HEIGHT_OFFSET)
			button:Show()
		end

		self:GetParent():SetWidth(max(w*cols - spacing + pW*2 + WIDTH_OFFSET, 8))
		self:GetParent():SetHeight(max(h*ceil(numButtons / cols) - spacing + pH*2, 8))
		
		needsLayout = nil
	]])
	
	for i, buttonName in ipairs(MICRO_BUTTONS) do
		bar:AddButton(bar:MakeSecure(_G[buttonName]))
	end
	
	hooksecurefunc('UpdateMicroButtons', function()
		if not InCombatLockdown() then
			bar.header:Execute([[ self:RunAttribute('updateLayout') ]])
		end
	end)
	
	return bar
end


--wrap a frame in a secure one for placement/etc
--necesary to reference frames from secure code
function MenuBar:MakeSecure(frame)
	local overlay = CreateFrame('Frame', nil, frame, 'SecureFrameTemplate')
	overlay:SetAllPoints(frame)
	frame.overlay = overlay
	
	return frame;
end

function MenuBar:LoadSettings(...)	
	MenuBar.super.LoadSettings(self, ...)
	
	local header = self.header

	header:SetAttribute('state-columns', self:NumColumns())
	header:SetAttribute('state-spacing', self:GetSpacing())
	header:SetAttribute('state-leftToRight', self:GetLeftToRight())
	header:SetAttribute('state-topToBottom', self:GetTopToBottom())
	
	local pw, ph = self:GetPadding()
	header:SetAttribute('state-padW', pw)
	header:SetAttribute('state-padH', ph)
	
	local disabledButtons = self.sets.disabled
	if disabledButtons then
		for buttonName, disabled in pairs(disabledButtons) do
			local button = _G[buttonName]
			if button then
				self:DisableMenuButton(button, disabled)
			end
		end
	end
end

function MenuBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		x = -244,
		y = 0,
	}
end

function MenuBar:MaxLength()
	return self.header:GetAttribute('maxLength')
end

function MenuBar:AddButton(button)
	self.header:SetFrameRef('addButton', button)
	self.header:SetFrameRef(button:GetName() .. 'Overlay', button.overlay)
	self.header:Execute([[ self:RunAttribute('addButton') ]])
end

function MenuBar:NumButtons()
	return self:MaxLength()
end

function MenuBar:SetColumns(columns)
	self.sets.columns = columns ~= self:NumButtons() and columns or false
	
	self.header:SetAttribute('state-columns', self.sets.columns) --here, false implies (use whatever the maximum value would be)
	self:Layout()
end

function MenuBar:SetSpacing(spacing)
	self.sets.spacing = spacing or 0
	
	self.header:SetAttribute('state-spacing', self.sets.spacing)
	self:Layout()
end

function MenuBar:SetLeftToRight(isLeftToRight)
	local isRightToLeft = not isLeftToRight

	self.sets.isRightToLeft = isRightToLeft
	self.header:SetAttribute('state-leftToRight', isLeftToRight and true or false)
	self:Layout()
end

function MenuBar:SetTopToBottom(isTopToBottom)
	local isBottomToTop = not isTopToBottom

	self.sets.isBottomToTop = isBottomToTop
	self.header:SetAttribute('state-topToBottom', isTopToBottom and true or false)
	self:Layout()
end

function MenuBar:SetPadding(padW, padH)
	local padW = padW or 0
	local padH = padH or padW
	
	self.sets.padW = padW
	self.sets.padH = padH

	self.header:SetAttribute('state-padW', self.sets.padW)
	self.header:SetAttribute('state-padH', self.sets.padH)
	self:Layout()
end

function MenuBar:UpdateClickThrough()
	local clickThrough = self:GetClickThrough()
	if clickThrough then
		self.header:Execute([[ 
			for i, button in ipairs(myButtons) do
				button:EnableMouse(false)
			end
		]])
	else
		self.header:Execute([[
			for i, button in ipairs(myButtons) do
				button:EnableMouse(true)
			end
		]])		
	end
end

function MenuBar:DisableMenuButton(button, disabled)
	local disabledButtons = self.sets.disabled or {}

	disabledButtons[button:GetName()] = disabled or false
	self.header:SetFrameRef('buttonToDisable', button) 
	self.header:SetAttribute('state-disableButton', disabled)
	self:Layout()	
	
	self.sets.disabled = disabledButtons
end

function MenuBar:IsMenuButtonDisabled(button)
	local disabledButtons = self.sets.disabled
	
	if disabledButtons then
		return disabledButtons[button:GetName()]
	end
	
	return false
end

function MenuBar:Layout(force)
	if force then
		self.header:Execute([[ needsLayout = true ]])
	end
	
	self.header:Execute([[ self:RunAttribute('updateLayout') ]])
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