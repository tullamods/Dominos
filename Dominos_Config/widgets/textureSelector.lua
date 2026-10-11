--[[
	textureSelector.lua
		Displays a list of textures registered with LibSharedMedia for the user to pick from
--]]

local _, Addon = ...

-- wrapper around LSM in case i want to replace it with something else
-- in the future
local Textures = {}
do
	local libSharedMedia = LibStub('LibSharedMedia-3.0')
	local key = libSharedMedia.MediaType.STATUSBAR

	function Textures:Get(id)
		if id and libSharedMedia:IsValid(key, id) then
			return libSharedMedia:Fetch(key, id)
		end

		return libSharedMedia:GetDefault(key)
	end

	function Textures:GetAll()
		return ipairs(libSharedMedia:List(key))
	end
end

--[[
	The Texture Button
--]]

local TextureButtonMixin = {}

function TextureButtonMixin:OnClick()
	self.owner:OnSelectValue(self.value)
	self:SetChecked(true)
end

function TextureButtonMixin:OnEnter()
	self.bg:SetDesaturated(false)
end

function TextureButtonMixin:OnLeave()
	self.bg:SetDesaturated(true)
end

function TextureButtonMixin:SetValue(value, selectedValue)
	self.value = value
	self:SetChecked(value == selectedValue)

	self.bg:SetTexture(Textures:Get(value))
	self:SetText(value)
end

function TextureButtonMixin:Free()
	self:ClearAllPoints()
	self:SetParent(nil)
	self:Hide()

	table.insert(self.unused, self)
end

do
	local unused = {}

	local function createButton(parent)
		local button = CreateFrame('CheckButton', nil, parent)

		local ct = button:CreateTexture(nil, 'OVERLAY')
		ct:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
		ct:SetPoint('LEFT')
		ct:SetSize(16, 16)
		button:SetCheckedTexture(ct)

		button:SetNormalFontObject('GameFontNormal')
		button:SetHighlightFontObject('GameFontHighlight')
		button:SetText('Loading...')
		button:GetFontString():ClearAllPoints()
		button:GetFontString():SetPoint('LEFT', ct, 'RIGHT', 2, 0)

		local bg = button:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(button)
		bg:SetVertexColor(random(), random(), random(), 1)
		bg:SetDesaturated(true)
		button.bg = bg

		return button
	end

	local function createTextureButton(parent, owner)
		local button = table.remove(unused)

		if button then
			button:SetParent(parent)
			button:Show()
		else
			button = createButton(parent)
			Mixin(button, TextureButtonMixin)
			button:SetScript('OnClick', button.OnClick)
			button:SetScript('OnEnter', button.OnEnter)
			button:SetScript('OnLeave', button.OnLeave)
			button.unused = unused
		end

		button.owner = owner or parent
		return button
	end

	Addon.CreateTextureButton = createTextureButton
end

--[[
	The Texture Selector
--]]

local TextureSelectorMixin = {}

TextureSelectorMixin.buttonWidth = 266
TextureSelectorMixin.buttonHeight = 24
TextureSelectorMixin.buttonPadding = 4

function TextureSelectorMixin:OnShow()
	self:Refresh()
end

function TextureSelectorMixin:OnHide()
	local button = table.remove(self.buttons)
	while button do
		button:Free()
		button = table.remove(self.buttons)
	end
end

function TextureSelectorMixin:OnSelectValue(value)
	self:SetSavedValue(value)
	self:UpdateSelected()
end

function TextureSelectorMixin:Refresh()
	local width = 0
	local selectedValue = self:GetSavedValue()

	for i, id in Textures:GetAll() do
		local button = self:GetOrCreateButton(i)

		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('TOPLEFT')
		else
			button:SetPoint('TOPLEFT', self.buttons[i - 1], 'BOTTOMLEFT', 0, -self.buttonPadding)
		end

		button:SetPoint('RIGHT')
		button:SetSize(self.buttonWidth, self.buttonHeight)
		button:SetValue(id, selectedValue)
		button:Show()

		width = max(width, button:GetWidth())
	end

	local height = (#self.buttons * self.buttons[1]:GetHeight()) + (#self.buttons-1) * self.buttonPadding

	self:GetParent():SetSize(width, height)
end

function TextureSelectorMixin:GetOrCreateButton(i)
	local button = self.buttons[i]

	if not button then
		button = Addon.CreateTextureButton(self, self)
		self.buttons[i] = button
	end

	return button
end

function TextureSelectorMixin:SetSavedValue(value)
	assert(false, 'Hey, you forgot to set SetSavedValue for ' .. self:GetName())
end

function TextureSelectorMixin:GetSavedValue()
	assert(false, 'Hey, you forgot to set GetSavedValue for ' .. self:GetName())
end

function TextureSelectorMixin:UpdateSelected()
	local selectedValue = self:GetSavedValue()
	for _, button in pairs(self.buttons) do
		button:SetChecked(button:GetAttribute('texture') == selectedValue)
	end
end

function Addon:CreateTextureSelector(options)
	local f = CreateFrame('Frame', nil, options.parent)

	Mixin(f, TextureSelectorMixin)

	f.SetSavedValue = options.set
	f.GetSavedValue = options.get
	f:SetScript('OnShow', f.OnShow)
	f:SetScript('OnHide', f.OnHide)
	f.buttons = {}
	f:SetAllPoints(options.parent)

	return f
end

Addon.TextureSelector = TextureSelectorMixin
