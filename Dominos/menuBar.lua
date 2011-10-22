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
	[RaidMicroButton] = RAID,
	[MainMenuMicroButton] = MAINMENU_BUTTON,
	[HelpMicroButton] = HELP_BUTTON
}

local getButtons = function(...)
	local buttons = {}
	for i = 1, select('#', ...) do
		local b = select(i, ...)
		local name = b:GetName()
		if name and name:match('(%w+)MicroButton$') then
			table.insert(buttons, b)
		end
	end
	return buttons
end

--[[ Menu Bar ]]--

function MenuBar:New()
	local f = self.super.New(self, 'menu')
	f:LoadButtons()
	if not f.sets.disabled then
		f.sets.disabled = {}
	end
	--f:Layout()
	f:Layout()
	return f
end

function MenuBar:GetDefaults()
	return {
		point = 'BOTTOMRIGHT',
		x = -244,
		y = 0,
	}
end

function MenuBar:NumButtons(f)
	local self = self
	if f then
		self  = f
	end
	return self.sets.numButtons or self:NumMenuButtons()
end

function MenuBar:AddButton(i)
	local b = self:GetMenuButton(i)
	if b then
		b:SetParent(self.header)
		b:Show()

		self.buttons[i] = b
	end
end

function MenuBar:RemoveButton(i)
	local b = self.buttons[i]
	if b then
		b:SetParent(nil)
		b:Hide()

		self.buttons[i] = nil
	end
end

do
	local menuButtons
	
	local getMenuButtons = function() 
		if not menuButtons then
			menuButtons = getButtons(_G['MainMenuBarArtFrame']:GetChildren())
		end
		return menuButtons
	end
	
	function MenuBar:GetMenuButton(index)
		return getMenuButtons()[index]
	end
	
	function MenuBar:NumMenuButtons()
		return #getMenuButtons()
	end
end

function MenuBar:Layout()
	self.buttons = {}
	
	for i = 1, self:NumMenuButtons() do
		if not self.sets.disabled[self:GetMenuButton(i):GetName()] and (i <= self:NumButtons(self) ) then
			self:GetMenuButton(i):Show()
			tinsert(self.buttons, self:GetMenuButton(i))
		else
			self:GetMenuButton(i):Hide()
		end
	end

	if #self.buttons > 0 then
		local cols = min(self:NumColumns(), #self.buttons)
		local rows = ceil(#self.buttons / cols)

		local pW, pH = self:GetPadding()
		local spacing = self:GetSpacing()

		local isLeftToRight = self:GetLeftToRight()
		local isTopToBottom = self:GetTopToBottom()

		local b = self.buttons[1]
		
		local L, R, T, B = b:GetHitRectInsets() --By default T = 18. all others are zero
		if T > 0 then
			HEIGHT_OFFSET = T + 2
		else
			HEIGHT_OFFSET = 0
		end

		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET

		for i, b in pairs(self.buttons) do
			local col
			local row
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
			
			b:ClearAllPoints()
			b:SetPoint('TOPLEFT', w*col + pW, -(h*row + pH) + HEIGHT_OFFSET)
		end

		self:SetWidth(max(w*cols - spacing + pW*2 + WIDTH_OFFSET, 8))
		self:SetHeight(max(h*ceil(#self.buttons/cols) - spacing + pH*2, 8))
	else
		self:SetSize(30, 30)
	end
end

--[[ Menu Code ]]--

local function panel_AddSizeSlider(p)
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
	local size = p:NewSlider(L.Size, 1, 1, 1)

	size.OnShow = function(self)
		self:SetMinMaxValues(1, self:GetParent().owner:NumMenuButtons())
		self:SetValue(self:GetParent().owner:NumButtons())
	end

	size.UpdateValue = function(self, value)
		self:GetParent().owner:SetNumButtons(value)
		p.Cols:OnShow()
	end
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
	AddDisableButtonPanel(menu)
	menu:AddAdvancedPanel()
	self.menu = menu
end