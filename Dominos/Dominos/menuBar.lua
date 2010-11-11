--[[
	menuBar.lua
		A Dominos frame for micro menu buttons
--]]

local menuButtons
do
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
	loadButtons(_G['MainMenuBarArtFrame']:GetChildren())
end

--[[ Menu Bar ]]--

local MenuBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.MenuBar  = MenuBar

function MenuBar:New()
	local f = self.super.New(self, 'menu')
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
	return #menuButtons
end

function MenuBar:AddButton(i)
	local b = menuButtons[i]
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

--override, because the menu bar has weird button sizes
local WIDTH_OFFSET = 2
local HEIGHT_OFFSET = 20

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
		self:SetWidth(30); self:SetHeight(30)
	end
end