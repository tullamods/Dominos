--[[
	MenuBar, by Goranaws
--]]

local MenuBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.MenuBar = MenuBar

local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

local MENU_BUTTON_NAMES = {
	[CharacterMicroButton] = CHARACTER_BUTTON,
	[SpellbookMicroButton] = SPELLBOOK_ABILITIES_BUTTON,
	[TalentMicroButton] = TALENTS_BUTTON,
	[AchievementMicroButton] = ACHIEVEMENT_BUTTON,
	[QuestLogMicroButton] = QUESTLOG_BUTTON,
	[GuildMicroButton] = LOOKINGFORGUILD,
	[PVPMicroButton] = PLAYER_V_PLAYER,
	[LFDMicroButton] = DUNGEONS_BUTTON,
	[EJMicroButton] = ENCOUNTER_JOURNAL,
	[CompanionsMicroButton] = MOUNTS_AND_PETS,
	[MainMenuMicroButton] = MAINMENU_BUTTON,
	[HelpMicroButton] = HELP_BUTTON
}

-- local oMoveMicroButtons = _G['MoveMicroButtons']
-- MoveMicroButtons = function(...)
	-- print(
	-- oMoveMicroButtons(...)
-- end

--[[ Menu Bar ]]--

function MenuBar:New()
	local bar = MenuBar.super.New(self, 'menu')

	bar:Layout(true)
	RegisterStateDriver(bar.header, 'perspective', '[vehicleui]override;[overridebar]override;[petbattle]petbattle;normal')

	return bar
end

function MenuBar:Create(frameId)
	local bar = MenuBar.super.Create(self, frameId)
	
	local header = bar.header
	local overrideActionBar = _G['OverrideActionBar']

	
	--[[ init any bar global variables ]]--
	
	header:Execute([[
		SPACING_OFFSET = -2
		PADW_OFFSET = 0
		PADH_OFFSET = 0
		HEIGHT_OFFSET = 22
		WIDTH_OFFSET = 0
	]])
	
	header:SetFrameRef('OverrideActionBar', overrideActionBar)
	
	--[[ 
		after a layout value is altered, set a dirty bit indicating that we need to adjust the bar's layout 
	--]]
	
	header:SetAttribute('_onstate-perspective', [[
		local newstate = newstate or 'normal'
		
		self:RunAttribute('layout-' .. newstate)
	]])
	
	header:SetAttribute('layout-normal', [[ 
		if not myButtons then return end
		
		for i, button in pairs(myButtons) do
			button:SetParent(self)
		end
		
		needsLayout = true
		self:RunAttribute('layout')
	]])
	
	header:SetAttribute('layout-petbattle', [[ 
		if not(myButtons) then return end
		
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
	
	header:SetAttribute('layout-override', [[
		if not(myButtons) then return end
		
		local numButtons = #myButtons
		local cols = ceil(numButtons / 2)
		local spacing = -2

		local b = myButtons[1]
		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET
		local offsetX = 72
		local offsetY = -56
		
		for i, b in pairs(myButtons) do
			local col = (i-1) % cols
			local row = ceil(i / cols) - 1
		
			local b = myButtons[i]
			b:ClearAllPoints()
			b:SetParent(self:GetFrameRef('OverrideActionBar'))
			b:SetPoint('TOPLEFT', '$parent', 'TOP', offsetX + (w*col) + WIDTH_OFFSET, offsetY + (h*row) + HEIGHT_OFFSET)
			b:Show()
		end
	]])
	
	header:SetAttribute('_onstate-numButtons', [[ needsLayout = true ]])

	header:SetAttribute('_onstate-columns', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-spacing', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-padW', [[ needsLayout = true ]])
	
	header:SetAttribute('_onstate-padH', [[ needsLayout = true ]])
	
	--add button method
	header:SetAttribute('addButton', [[
		local button = self:GetFrameRef('addButton')		
		
		if button then
			myButtons = myButtons or table.new()
			table.insert(myButtons, button)
			button:SetParent(self:GetFrameRef('buttonFrame') or self)
		end
		
		self:SetAttribute('maxLength', #myButtons)
	]])
	
	header:SetAttribute('layout', [[
		if not(myButtons and needsLayout) then return end

		local numButtons = self:GetAttribute('state-numButtons') or #myButtons
		local cols = min(self:GetAttribute('state-columns') or numButtons, numButtons)
		
		local rows = ceil(numButtons / cols)
		local spacing = self:GetAttribute('state-spacing') + SPACING_OFFSET
		local pW = self:GetAttribute('state-padW') + PADW_OFFSET
		local pH = self:GetAttribute('state-padH') + PADH_OFFSET

		local b = myButtons[1]
		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET
		
		for i = numButtons + 1, #myButtons do
			myButtons[i]:Hide()
		end
		
		self:GetParent():SetWidth(max(w*cols - spacing + pW*2 + WIDTH_OFFSET, 8))
		self:GetParent():SetHeight(max(h*ceil(numButtons/cols) - spacing + pH*2, 8))

		if numButtons > 0 then
			for i = 1, numButtons do
				local col = (i-1) % cols
				local row = ceil(i / cols) - 1
			
				local b = myButtons[i]
				b:ClearAllPoints()
				b:SetPoint('TOPLEFT', self, 'TOPLEFT', w*col + pW + WIDTH_OFFSET, -(h*row + pH) + HEIGHT_OFFSET)
				b:Show()
			end
		end
		
		needsLayout = nil
	]])
	
	local loadButtons = function(bar, ...)
		for i = 1, select('#', ...) do
			local button = select(i, ...)
			local buttonName = button:GetName()
			if buttonName and buttonName:match('(%w+)MicroButton$') then
				bar:AddButton(button)
			end
		end
	end
	loadButtons(bar, _G['MainMenuBarArtFrame']:GetChildren())
	loadButtons(bar, overrideActionBar:GetChildren())
	
	local wrapper = CreateFrame('Frame', nil, overrideActionBar, 'SecureHandlerShowHideTemplate')
	wrapper:SetAllPoints(wrapper:GetParent())
	header:SetFrameRef('OverrideActionBar', wrapper)
	wrapper:SetFrameRef('header', header)
	
	--pants hack:
	--force the state handler for the header to update on the next frame by setting it to an arbitrary invalid state
	--to ensure that we update micro button positions AFTER MoveMicroButtons is called
	--would be much easier if we could simply secure wrap the OnShow handler of the OverrideActionBar
	--however, we can't since its not a true protected frame
	wrapper:SetAttribute('_onshow', [[ self:GetFrameRef('header'):SetAttribute('state-perspective', 'pants') ]])

	return bar
end

function MenuBar:LoadSettings(...)	
	MenuBar.super.LoadSettings(self, ...)
	
	local header = self.header

	header:SetAttribute('state-numButtons', self:NumButtons())
	header:SetAttribute('state-columns', self:NumColumns())
	header:SetAttribute('state-spacing', self:GetSpacing())
	
	local pw, ph = self:GetPadding()
	header:SetAttribute('state-padW', pw)
	header:SetAttribute('state-padH', ph)
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
	self.header:Execute([[ self:RunAttribute('addButton') ]])
end

function MenuBar:SetNumButtons(numButtons)
	self.sets.numButtons = numButtons or false
	
	self.header:SetAttribute('state-numButtons', numButtons or false) --here, false implies (use whatever the maximum value would be)
	self:Layout()
end

function MenuBar:NumButtons()
	return self.sets.numButtons or self:MaxLength()
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

function MenuBar:SetPadding(padW, padH)
	local padW = padW or 0
	local padH = padH or padW
	
	self.sets.padW = padW
	self.sets.padH = padH

	self.header:SetAttribute('state-padW', self.sets.padW)
	self.header:SetAttribute('state-padH', self.sets.padH)
	self:Layout()
end

function MenuBar:Layout(force)
	if force then
		self.header:Execute([[ needsLayout = true ]])
	end
	
	self.header:Execute([[ 
		self:RunAttribute('layout') 
	]])
end

--[[ Menu Code ]]--

local function SizeSlider_OnShow(self)
	local owner = self:GetParent().owner
	local minValue = 1
	local maxValue = owner:MaxLength()
	local currentValue = owner:NumButtons()
	
	self:SetMinMaxValues(minValue, maxValue)
	self:SetValue(currentValue)
end

local function SizeSlider_UpdateValue(self, value)
	local owner = self:GetParent().owner
	
	owner:SetNumButtons(value)
	
	self:GetParent().Cols:OnShow()
end
	
local function panel_AddSizeSlider(panel)
	local name = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Size
	
	return panel:NewSlider(name, 1, 1, 1, SizeSlider_OnShow, SizeSlider_UpdateValue)
end

local function AddLayoutPanel(menu)
	local p = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
	p:NewOpacitySlider()
	p:NewFadeSlider()
	p:NewScaleSlider()
	p:NewPaddingSlider()
	p:NewSpacingSlider()
	p.Cols = p:NewColumnsSlider()

	panel_AddSizeSlider(p)
end

local function NewCheckButton(name, button, p)
	local tog = p:NewCheckButton(name)

	tog:SetScript('OnClick', function(self)
		self:GetParent().owner.sets.disabled[button:GetName()] = self:GetChecked() or nil
		self:GetParent().owner:Layout()
	end)

	tog:SetScript('OnShow', function(self)
		self:SetChecked(self:GetParent().owner.sets.disabled[button:GetName()])
	end)

	return tog
end

local function AddDisableButtonPanel(menu)
	local p = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').DisableMenuButtons)
	for i = 1, MenuBar:NumMenuButtons() do
		local button = MenuBar:GetMenuButton(i)
		NewCheckButton(MENU_BUTTON_NAMES[button] or  button:GetName(), button, p)
	end
end

function MenuBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)

	AddLayoutPanel(menu)
	-- AddDisableButtonPanel(menu)
	menu:AddAdvancedPanel()
	self.menu = menu
end