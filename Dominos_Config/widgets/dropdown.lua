local AddonName, Addon = ...

local DropdownButton = Addon:CreateClass('CheckButton')
do
	local unused = {}

	local function createButton(parent)
		local button = CreateFrame('CheckButton', nil, parent)

		local ct = button:CreateTexture(nil, 'OVERLAY')
		ct:SetTexture([[Interface\Buttons\UI-CheckBox-Check]])
		ct:SetPoint('LEFT')
		ct:SetSize(12, 12)
		button:SetCheckedTexture(ct)

		button:SetNormalFontObject('GameFontNormal')
		button:SetHighlightFontObject('GameFontHighlight')
		button:SetText('Loading...')
		button:GetFontString():ClearAllPoints()
		button:GetFontString():SetPoint('LEFT', ct, 'RIGHT', 2, 0)

		return button
	end

	function DropdownButton:New(parent, owner)
		local button = table.remove(unused)

		if button then
			button:SetParent(parent)
			button:Show()
		else
			button = self:Bind(createButton(parent))
			button:SetScript('OnClick', self.OnClick)
		end
		button.owner = owner or parent
		return button
	end

	function DropdownButton:Free()
		self:ClearAllPoints()
		self:SetParent(nil)
		self:Hide()

		table.insert(unused, self)
	end

	function DropdownButton:OnClick()
		self.owner:OnSelectValue(self.value)
	end

	function DropdownButton:SetItem(item, selectedValue)
		if type(item) == 'table' then
			self.value = item.value
			self:SetText(item.text or item.value)
		else
			self.value = item
			self:SetText(item)
		end

		self:SetChecked(self.value == selectedValue)

		local width, height = self:GetFontString():GetSize()
		self:SetSize(width + 14, height)
	end
end

local DropdownDialog = Addon:CreateClass('Frame', Addon.ScrollablePanel)
do
	local DropdownDialogBackdrop = {
		bgFile   = [[Interface\ChatFrame\ChatFrameBackground]],
		edgeFile = [[Interface\ChatFrame\ChatFrameBackground]],
		insets   = {left = -2, right = -2, top = -2, bottom = -2},
		edgeSize = -2,
	}

	DropdownDialog.minWidth = 120
	DropdownDialog.minHeight = 120

	function DropdownDialog:New()
		local frame = Addon.ScrollablePanel.New(self, _G.UIParent)

		frame:SetBackdrop(DropdownDialogBackdrop)
		frame:SetBackdropColor(0, 0, 0, 0.9)
		frame:SetBackdropBorderColor(0.5, 0.5, 0.5, 0.9)
		frame:EnableMouse(true)
		frame:SetToplevel(true)
		frame:SetMovable(true)
		frame:SetClampedToScreen(true)
		frame:SetFrameStrata('FULLSCREEN_DIALOG')
		frame:Hide()
		frame:SetScript('OnShow', self.OnShow)
		frame:SetScript('OnHide', self.OnHide)

		frame.buttons = {}

		return frame
	end

	function DropdownDialog:OnShow()
		self.vScrollBar:SetValue(0)
	end

	function DropdownDialog:OnHide()
		self:Free()
	end

	function DropdownDialog:Open(options)
		self:Hide()

		self.owner = options.owner
		self:Refresh(options.items, options.value)
		self:SetPoint('TOPRIGHT', options.anchor or options.owner, 'BOTTOMRIGHT')
		self:Show()
	end

	function DropdownDialog:OnSelectValue(value)
		self.owner:OnSelectValue(value)
		self:Hide()
	end

	function DropdownDialog:GetOrCreateButton(i)
		local button = self.buttons[i]

		if not button then
			button = DropdownButton:New(self.container, self)
			self.buttons[i] = button
		end

		return button
	end

	function DropdownDialog:Free()
		self.owner = nil

		local button = table.remove(self.buttons)
		local i = 0
		while button do
			i = i + 1
			button:Free()
			button = table.remove(self.buttons)
		end
	end

	function DropdownDialog:Refresh(items, selectedValue)
		local width, height = 0, 0

		for i, item in ipairs(items) do
			local button = self:GetOrCreateButton(i)
			if i == 1 then
				button:SetPoint('TOPLEFT', 2, -2)
			else
				button:SetPoint('TOPLEFT', self.buttons[i - 1], 'BOTTOMLEFT', 0, -2)
			end

			button:SetItem(item, selectedValue)
			width = max(width, button:GetWidth() + 2)
			height = height + button:GetHeight() + 2
		end

		self.container:SetSize(width, height)
		self:SetHeight(math.min(height + 2, self.minHeight))
		self:SetWidth(width + 8)
	end
end

local Dropdown = Addon:CreateClass('Frame')
do
	local dialog = DropdownDialog:New()

	local function valueButton_OnClick(self)
		local parent = self:GetParent()

		if parent == dialog.owner then
			dialog:Hide()
		else
			parent:ShowMenu()
		end
	end

	Dropdown.items = {}

	function Dropdown:New(options)
		local f = self:Bind(CreateFrame('Frame', nil, options.parent))

		f.buttons = {}

		if type(options.items) == 'function' then
			f.GetItems = options.items
		else
			f.items = options.items
		end

		f.SetSavedValue = options.set
		f.GetSavedValue = options.get

		local text = f:CreateFontString(nil, 'ARTWORK', 'GameFontHighlight')
		text:SetPoint('LEFT')
		text:SetText(options.name)
		f.text = text

		local valueButton = CreateFrame('Button', nil, f)
		valueButton:SetNormalFontObject('GameFontNormalRight')
		valueButton:SetHighlightFontObject('GameFontHighlightRight')
		valueButton:SetScript('OnClick', valueButton_OnClick)
		valueButton:SetPoint('RIGHT')
		valueButton:SetText('Nopenopenope')
		valueButton:SetSize(valueButton:GetFontString():GetSize())
		f.valueButton = valueButton

		local bg = f:CreateTexture(nil, 'BACKGROUND')
		bg:SetAllPoints(bg:GetParent())
		bg:SetColorTexture(0.2, 0.2, 0.2, 0.5)
		f.bg = bg

		local width = max(4 + text:GetWidth() + valueButton:GetWidth(), 240)
		local height = 4 + text:GetHeight()
		f:SetSize(width, height)

		f:SetScript('OnShow', self.OnShow)
		f:SetScript('OnHide', self.OnHide)

		return f
	end

	function Dropdown:OnShow()
		self:UpdateText()
	end

	function Dropdown:OnHide()
		if dialog.owner == self then
			dialog:Hide()
		end
	end

	function Dropdown:OnSelectValue(value)
		self:SetSavedValue(value)
		self:UpdateText()
	end

	function Dropdown:GetEffectiveSize()
		return self:GetSize()
	end

	--[[ Update Methods ]]--

	function Dropdown:SetSavedValue(value) end

	function Dropdown:GetSavedValue() end

	function Dropdown:ShowMenu()
		dialog:Open{
			owner = self,
			items = self:GetItems(),
			value = self:GetSavedValue()
		}

		dialogOwner = self
	end

	function Dropdown:GetItems()
		return self.items
	end

	function Dropdown:UpdateText()
		local selectedValue = self:GetSavedValue()

		for i, item in pairs(self:GetItems()) do
			if item == selectedValue then
				self.valueButton:SetText(item)
				return
			end

			if type(item) == "table" and item.value == selectedValue then
				self.valueButton:SetText(item.text or item.value)
				return
			end
		end
	end
end

Addon.Dropdown = Dropdown