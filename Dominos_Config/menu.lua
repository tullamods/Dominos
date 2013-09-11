--[[
	Menu.lua
--]]

--[[
	Copyright (c) 2008-2009 Jason Greer
	All rights reserved.

	Redistribution and use in source and binary forms, with or without 
	modification, are permitted provided that the following conditions are met:

		* Redistributions of source code must retain the above copyright notice, 
		  this list of conditions and the following disclaimer.
		* Redistributions in binary form must reproduce the above copyright
		  notice, this list of conditions and the following disclaimer in the 
		  documentation and/or other materials provided with the distribution.
		* Neither the name of the author nor the names of its contributors may 
		  be used to endorse or promote products derived from this software 
		  without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" 
	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE 
	IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE 
	ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE 
	LIABLE FORANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
	SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
	INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN 
	CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
	POSSIBILITY OF SUCH DAMAGE.
--]]

local Menu = Dominos:CreateClass('Frame')
Dominos.Menu = Menu

local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
local _G = getfenv()
local max = math.max
local min = math.min


Menu.bg = {
	bgFile = 'Interface\\DialogFrame\\UI-DialogBox-Background',
	edgeFile = 'Interface\\DialogFrame\\UI-DialogBox-Border',
	insets = {left = 11, right = 11, top = 12, bottom = 11},
	tile = true,
	tileSize = 32,
	edgeSize = 32,
}

Menu.extraWidth = 20
Menu.extraHeight = 40

function Menu:New(name)
	local f = self:Bind(CreateFrame('Frame', 'DominosFrameMenu' .. name, UIParent))
	f.panels = {}

	f:SetBackdrop(self.bg)
	f:EnableMouse(true)
	f:SetToplevel(true)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	f:SetFrameStrata('DIALOG')
	f:SetScript('OnMouseDown', self.StartMoving)
	f:SetScript('OnMouseUp', self.StopMovingOrSizing)

	--title text
	f.text = f:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
	f.text:SetPoint('TOP', 0, -15)

	--close button
	f.close = CreateFrame('Button', nil, f, 'UIPanelCloseButton')
	f.close:SetPoint('TOPRIGHT', -5, -5)

	return f
end

--tells the panel what frame we're pointed to
function Menu:SetOwner(owner)
	for _,f in pairs(self.panels) do
		f.owner = owner
	end

	if tonumber(owner.id) then
		self.text:SetFormattedText(L.ActionBarSettings, owner.id)
	else
		self.text:SetFormattedText(L.BarSettings, tostring(owner.id):gsub('^%l', string.upper))
	end

	self:Anchor(owner)
end

function Menu:Anchor(f)
	local ratio = UIParent:GetScale() / f:GetEffectiveScale()
	local x = f:GetLeft() / ratio
	local y = f:GetTop() / ratio

	self:ClearAllPoints()
	self:SetPoint('TOPRIGHT', UIParent, 'BOTTOMLEFT', x, y)
end

--shows a given panel
function Menu:ShowPanel(name)
	for i, panel in pairs(self.panels) do
		if panel.name == name then
			if self.dropdown then
				UIDropDownMenu_SetSelectedValue(self.dropdown, i)
			end
			panel:Show()
			self:SetWidth(max(200, panel.width + self.extraWidth))
			self:SetHeight(max(40, panel.height + self.extraHeight))
		else
			panel:Hide()
		end
	end
end

function Menu:GetSelectedPanel()
	for i, panel in pairs(self.panels) do
		if panel:IsShown() then
			return i
		end
	end
	return 1
end

function Menu:NewPanel(name)
	local panel = self.Panel:New(name, self)
	panel.name = name
	table.insert(self.panels, panel)

	if not self.dropdown and #self.panels > 1 then
		self.dropdown = self:NewPanelSelector()
	end

	return panel
end

function Menu:AddLayoutPanel()
	local panel = self:NewPanel(L.Layout)

	panel.opacitySlider = panel:NewOpacitySlider()
	panel.fadeSlider = panel:NewFadeSlider()
	panel.scaleSlider = panel:NewScaleSlider()
	panel.paddingSlider = panel:NewPaddingSlider()
	panel.spacingSlider = panel:NewSpacingSlider()
	panel.colsSlider = panel:NewColumnsSlider()

	return panel
end

function Menu:AddAdvancedPanel()
	local panel = self:NewPanel(L.Advanced)

	panel:NewLeftToRightCheckbox()
	panel:NewTopToBottomCheckbox()
	panel:NewClickThroughCheckbox()
	panel:NewShowInOverrideUICheckbox()
	panel:NewShowInPetBattleUICheckbox()
	
	panel.width = 256
	return panel
end


do
	local info = {}
	local function AddItem(text, value, func, checked)
		info.text = text
		info.func = func
		info.value = value
		info.checked = checked
		info.arg1 = text
		UIDropDownMenu_AddButton(info)
	end

	local function Dropdown_OnShow(self)
		UIDropDownMenu_SetWidth(self, 110)
		UIDropDownMenu_Initialize(self, self.Initialize)
		UIDropDownMenu_SetSelectedValue(self, self:GetParent():GetSelectedPanel())
	end

	function Menu:NewPanelSelector()
		local f = CreateFrame('Frame', self:GetName() .. 'PanelSelector', self, 'UIDropDownMenuTemplate')
		_G[f:GetName() .. 'Text']:SetJustifyH('LEFT')

		f:SetScript('OnShow', Dropdown_OnShow)

		local function Item_OnClick(item, name)
			self:ShowPanel(name)
			UIDropDownMenu_SetSelectedValue(f, item.value)
		end

		function f:Initialize()
			local parent = self:GetParent()
			local selected = parent:GetSelectedPanel()
			for i,panel in ipairs(parent.panels) do
				AddItem(panel.name, i, Item_OnClick, i == selected)
			end
		end

		f:SetPoint('TOPLEFT', 0, -36)
		for _,panel in pairs(self.panels) do
			panel:SetPoint('TOPLEFT', 10, -(32 + f:GetHeight() + 6))
		end

		self.extraHeight = (self.extraHeight or 0) + f:GetHeight() + 6

		return f
	end
end

--[[
	Panel Components
--]]

--a panel is a subframe of a menu, basically
local Panel = Dominos:CreateClass('Frame')
Menu.Panel = Panel

Panel.width = 0
Panel.height = 0

function Panel:New(name, parent)
	local f = self:Bind(CreateFrame('Frame', parent:GetName() .. name, parent))
	if parent.dropdown then
		f:SetPoint('TOPLEFT', 10, -(32 + parent.dropdown:GetHeight() + 4))
	else
		f:SetPoint('TOPLEFT', 10, -32)
	end
	f:SetPoint('BOTTOMRIGHT', -10, 10)
	f:Hide()

	return f
end


--[[ Checkbuttons ]]--

--checkbutton
function Panel:NewCheckButton(name, getter, setter)
	local button = CreateFrame('CheckButton', self:GetName() .. name, self, 'InterfaceOptionsCheckButtonTemplate')
	_G[button:GetName() .. 'Text']:SetText(name)

	local prev = self.checkbutton
	if prev then
		button:SetPoint('TOP', prev, 'BOTTOM', 0, -2)
	else
		button:SetPoint('TOPLEFT', 2, 0)
	end
	
	if getter then
		button:SetScript('OnShow', function(self) 
			local owner = self:GetParent().owner
			local f = owner[getter]
			self:SetChecked(f(owner))
		end)
	end
	
	if setter then
		button:SetScript('OnClick', function(self) 
			local owner = self:GetParent().owner
			local f = owner[setter]
			f(owner, self:GetChecked())
		end)
	end
	
	self.height = self.height + 28
	self.checkbutton = button

	return button
end


--[[ Sliders ]]--

--basic slider
do
	local function Slider_GetNearestValueOnScale(self, value)
		local value = self:GetValue() or 0
		local step = self:GetValueStep() or 1
		local minVal, maxVal = self:GetMinMaxValues()

		local closestValue = minVal
		local closestValueDistance = math.huge
		
		for sliderValue = minVal, maxVal, step do
			local distance = math.abs(value - sliderValue)

			if distance < closestValueDistance then
				closestValue = sliderValue
				closestValueDistance = distance
			end

			if distance > closestValueDistance then
				break
			end
		end

		return closestValue
	end

	local function Slider_OnMouseWheel(self, arg1)
		local step = self:GetValueStep() * arg1
		local value = self:GetValue()
		local minVal, maxVal = self:GetMinMaxValues()

		if step > 0 then
			self:SetValue(min(value+step, maxVal))
		else
			self:SetValue(max(value+step, minVal))
		end
	end

	local function Slider_OnShow(self)
		self.showing = true

		if self.OnShow then
			self:OnShow()
		end

		self.showing = nil
	end

	local function Slider_OnValueChanged(self, value)
		local newValue = Slider_GetNearestValueOnScale(self, value)

		if newValue ~= value then
			self:SetValue(newValue)
			return
		end

		if not self.showing then
			self:UpdateValue(newValue)
		end

		if self.UpdateText then
			self:UpdateText(newValue)
		else
			self.valText:SetText(newValue)
		end
	end

	function Panel:NewSlider(text, low, high, step, OnShow, UpdateValue, UpdateText)
		local name = self:GetName() .. text

		local slider = CreateFrame('Slider', name, self, 'OptionsSliderTemplate')
		slider:SetMinMaxValues(low, high)
		slider:SetValueStep(step)
		slider:EnableMouseWheel(true)
		BlizzardOptionsPanel_Slider_Enable(slider) --colors the slider properly

		_G[name .. 'Text']:SetText(text)
		_G[name .. 'Low']:SetText('')
		_G[name .. 'High']:SetText('')

		local text = slider:CreateFontString(nil, 'BACKGROUND')
		text:SetFontObject('GameFontHighlightSmall')
		text:SetPoint('LEFT', slider, 'RIGHT', 7, 0)
		slider.valText = text

		slider.OnShow = OnShow
		slider.UpdateValue = UpdateValue
		slider.UpdateText = UpdateText

		slider:SetScript('OnShow', Slider_OnShow)
		slider:SetScript('OnValueChanged', Slider_OnValueChanged)
		slider:SetScript('OnMouseWheel', Slider_OnMouseWheel)

		local prev = self.slider
		if prev then
			slider:SetPoint('BOTTOM', prev, 'TOP', 0, 16)
			self.height = self.height + 34
		else
			slider:SetPoint('BOTTOMLEFT', 4, 4)
			self.height = self.height + 38
		end
		self.slider = slider

		return slider
	end
end

--scale
do
	local function Slider_OnShow(self)
		self:SetValue(self:GetParent().owner:GetScale() * 100)
	end

	local function Slider_UpdateValue(self, value)
		self:GetParent().owner:SetFrameScale(value/100)
	end

	function Panel:NewScaleSlider()
		return self:NewSlider(L.Scale, 50, 150, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--opacity
do
	local function Slider_OnShow(self)
		self:SetValue(self:GetParent().owner:GetFrameAlpha() * 100)
	end

	local function Slider_UpdateValue(self, value)
		self:GetParent().owner:SetFrameAlpha(value/100)
	end

	function Panel:NewOpacitySlider()
		return self:NewSlider(L.Opacity, 0, 100, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--faded opacity
do
	local function Slider_OnShow(self)
		self:SetValue(self:GetParent().owner:GetFadeMultiplier() * 100)
	end

	local function Slider_UpdateValue(self, value)
		self:GetParent().owner:SetFadeMultiplier(value/100)
	end

	function Panel:NewFadeSlider()
		return self:NewSlider(L.FadedOpacity, 0, 100, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--padding
do
	local function Slider_OnShow(self)
		self:SetValue(self:GetParent().owner:GetPadding())
	end

	local function Slider_UpdateValue(self, value)
		self:GetParent().owner:SetPadding(value)
	end

	function Panel:NewPaddingSlider()
		return self:NewSlider(L.Padding, -16, 32, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--spacing
do
	local function Slider_OnShow(self)
		self:SetValue(self:GetParent().owner:GetSpacing())
	end

	local function Slider_UpdateValue(self, value)
		self:GetParent().owner:SetSpacing(value)
	end

	function Panel:NewSpacingSlider()
		return self:NewSlider(L.Spacing, -8, 32, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--columns
do
	local function Slider_OnShow(self)
		local min, max = 1, self:GetParent().owner:NumButtons()
		if max > min then
			BlizzardOptionsPanel_Slider_Enable(self)
			self:SetMinMaxValues(min, max)
		else
			BlizzardOptionsPanel_Slider_Disable(self)
			self:SetMinMaxValues(1, 1)
		end
		self:SetValue(self:GetParent().owner:NumColumns())
	end

	local function Slider_UpdateValue(self, value)
		self:GetParent().owner:SetColumns(value)
	end

	function Panel:NewColumnsSlider()
		return self:NewSlider(L.Columns, 1, 1, 1, Slider_OnShow, Slider_UpdateValue)
	end
end

--right to left & left to right checkboxes
do
	function Panel:NewLeftToRightCheckbox()
		return self:NewCheckButton(L.LeftToRight, 'GetLeftToRight', 'SetLeftToRight')
	end
	
	function Panel:NewTopToBottomCheckbox()			
		return self:NewCheckButton(L.TopToBottom, 'GetTopToBottom', 'SetTopToBottom')
	end
	
	function Panel:NewClickThroughCheckbox()			
		return self:NewCheckButton(L.ClickThrough, 'GetClickThrough', 'SetClickThrough')
	end
	
	function Panel:NewShowInOverrideUICheckbox()			
		return self:NewCheckButton(L.ShowInOverrideUI, 'ShowingInOverrideUI', 'ShowInOverrideUI')
	end
	
	function Panel:NewShowInPetBattleUICheckbox()			
		return self:NewCheckButton(L.ShowInPetBattleUI, 'ShowingInPetBattleUI', 'ShowInPetBattleUI')
	end
end