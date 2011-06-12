local MenuBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.MenuBar  = MenuBar

local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

local menuButtons
local loadButtons = function(...)
	menuButtons = {}
	for i = 1, select('#', ...) do
		local b = select(i, ...)
		local name = b:GetName()
		if name and name:match('(%w+)MicroButton$') then
			table.insert(menuButtons, b)
		end
	end
end


--[[ Menu Bar ]]--

function MenuBar:New()
	local f = self.super.New(self, 'menu')
	f:GenerateButtons()
	f:LoadButtons()
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

function MenuBar:NumButtons()
	return self.sets.numButtons or #menuButtons
end

function MenuBar:AddButton(i)
	local b = menuButtons[i]
	b:SetParent(self.header)
	b:Show()
	self.buttons[i] = b
end

function MenuBar:RemoveButton(i)
	local b = self.buttons[i]
	b:SetParent(nil)
	b:Hide()
	self.buttons[i] = nil
end
	
function MenuBar:GenerateButtons()
	loadButtons(_G['MainMenuBarArtFrame']:GetChildren())
end

function MenuBar:Layout()
	if #self.buttons > 0 then
		local cols = min(self:NumColumns(), #self.buttons)
		local rows = ceil(#self.buttons / cols)

		local pW, pH = self:GetPadding()
		local spacing = self:GetSpacing()

		local b = self.buttons[1]
		local w = b:GetWidth() + spacing - WIDTH_OFFSET
		local h = b:GetHeight() + spacing - HEIGHT_OFFSET

		for i,b in pairs(self.buttons) do
			local col = (i-1) % cols
			local row = ceil(i / cols) - 1
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
		self:SetMinMaxValues(1, #menuButtons)
		self:SetValue(self:GetParent().owner:NumButtons())
	end

	size.UpdateValue = function(self, value)
		self:GetParent().owner:SetNumButtons(value)
		_G[self:GetParent():GetName() .. L.Columns]:OnShow()
	end
end

local function AddLayoutPanel(menu)
	local p = menu:NewPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
	p:NewOpacitySlider()
	p:NewFadeSlider()
	p:NewScaleSlider()
	p:NewPaddingSlider()
	p:NewSpacingSlider()
	p:NewColumnsSlider()

	panel_AddSizeSlider(p)
end

local function AddAdvancedLayout(self)
	self:AddAdvancedPanel()
end

function MenuBar:CreateMenu()
	local menu = Dominos:NewMenu(self.id)

	AddLayoutPanel(menu)
	menu:AddAdvancedPanel()

	self.menu = menu
end