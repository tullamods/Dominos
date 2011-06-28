--[[
	actionBar.lua
		the code for Dominos action bars and buttons
--]]

--libs and omgspeed
local ceil = math.ceil
local min = math.min
local format = string.format
local MAX_BUTTONS = 120
local NUM_POSSESS_BAR_BUTTONS = 12
local KeyBound = LibStub('LibKeyBound-1.0')
local LBF = LibStub('LibButtonFacade', true)


--[[ Action Button ]]--

local ActionButton = Dominos:CreateClass('CheckButton', Dominos.BindableButton)
Dominos.ActionButton = ActionButton
ActionButton.unused = {}
ActionButton.active = {}

--constructor
function ActionButton:New(id)
	local b = self:Restore(id) or self:Create(id)
	if b then
		b:SetAttribute('showgrid', 0)
		b:SetAttribute('action--base', id)
		b:SetAttribute('_childupdate-action', [[
			local id = message and self:GetAttribute('action--' .. message) or self:GetAttribute('action--base')
			self:SetAttribute('action', id)
		]])

		b:UpdateGrid()
		b:UpdateHotkey(b.buttonType)
		b:UpdateMacro()
		b:UnregisterEvent('UPDATE_BINDINGS')

		--hack #1billion, get rid of range indicator text
		local hotkey = _G[b:GetName() .. 'HotKey']
		if hotkey:GetText() == _G['RANGE_INDICATOR'] then
			hotkey:SetText('')
		end

		self.active[id] = b

		return b
	end
end

local function Create(id)
	if id <= 12 then
		local b = _G['ActionButton' .. id]
		b.buttonType = 'ACTIONBUTTON'
		return b
	elseif id <= 24 then
		return CreateFrame('CheckButton', 'DominosActionButton' .. (id-12), nil, 'ActionBarButtonTemplate')
	elseif id <= 36 then
		return _G['MultiBarRightButton' .. (id-24)]
	elseif id <= 48 then
		return _G['MultiBarLeftButton' .. (id-36)]
	elseif id <= 60 then
		return _G['MultiBarBottomRightButton' .. (id-48)]
	elseif id <= 72 then
		return _G['MultiBarBottomLeftButton' .. (id-60)]
	end
	return CreateFrame('CheckButton', 'DominosActionButton' .. (id-60), nil, 'ActionBarButtonTemplate')
end

function ActionButton:Create(id)
	local b = Create(id)
	if b then
		self:Bind(b)

		--this is used to preserve the button's old id
		--we cannot simply keep a button's id at > 0 or blizzard code will take control of paging
		--but we need the button's id for the old bindings system
		b:SetAttribute('bindingid', b:GetID())
		b:SetID(0)

		b:ClearAllPoints()
		b:SetAttribute('useparent-actionpage', nil)
		b:SetAttribute('useparent-unit', true)
		b:EnableMouseWheel(true)
		b:SetScript('OnEnter', self.OnEnter)
		b:Skin()
	end
	return b
end

function ActionButton:Restore(id)
	local b = self.unused[id]
	if b then
		self.unused[id] = nil
		b:LoadEvents()
		ActionButton_UpdateAction(b)
		b:Show()
		self.active[id] = b
		return b
	end
end

--destructor
function ActionButton:Free()
	local id = self:GetAttribute('action--base')

	self.active[id] = nil

	self:UnregisterAllEvents()
	self:SetParent(nil)
	self:Hide()
	self.eventsRegistered = nil
	self.action = nil

	self.unused[id] = self
end

--these are all events that are registered OnLoad for action buttons
function ActionButton:LoadEvents()
	self:RegisterEvent('PLAYER_ENTERING_WORLD')
	self:RegisterEvent('ACTIONBAR_SHOWGRID')
	self:RegisterEvent('ACTIONBAR_HIDEGRID')
	self:RegisterEvent('ACTIONBAR_PAGE_CHANGED')
	self:RegisterEvent('ACTIONBAR_SLOT_CHANGED')
end

--keybound support
function ActionButton:OnEnter()
	if Dominos:ShouldShowTooltips() then
		ActionButton_SetTooltip(self)
	end
	KeyBound:Set(self)
end

--override the old update hotkeys function
hooksecurefunc('ActionButton_UpdateHotkeys', ActionButton.UpdateHotkey)

--button visibility
function ActionButton:UpdateGrid()
	if self:GetAttribute('showgrid') > 0 then
		ActionButton_ShowGrid(self)
	else
		ActionButton_HideGrid(self)
	end
end

--macro text
function ActionButton:UpdateMacro()
	if Dominos:ShowMacroText() then
		_G[self:GetName() .. 'Name']:Show()
	else
		_G[self:GetName() .. 'Name']:Hide()
	end
end

function ActionButton:SetFlyoutDirection(direction)
	self:SetAttribute('flyoutDirection', direction)
	ActionButton_UpdateFlyout(self)
end

--utility function, resyncs the button's current action, modified by state
function ActionButton:LoadAction()
	local state = self:GetParent():GetAttribute('state-page')
	local id = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')
	self:SetAttribute('action', id)
end

function ActionButton:Skin()
	if LBF then
		LBF:Group('Dominos', 'Action Bar'):AddButton(self)
	else
		_G[self:GetName() .. 'Icon']:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)
	end
end


--[[ Action Bar ]]--

local ActionBar = Dominos:CreateClass('Frame', Dominos.Frame)
Dominos.ActionBar = ActionBar

--[[ Constructor Code ]]--

--metatable magic.  Basically this says, 'create a new table for this index'
--I do this so that I only create page tables for classes the user is actually playing
ActionBar.defaultOffsets = {
	__index = function(t, i)
		t[i] = {}
		return t[i]
	end
}

--metatable magic.  Basically this says, 'create a new table for this index, with these defaults'
--I do this so that I only create page tables for classes the user is actually playing
ActionBar.mainbarOffsets = {
	__index = function(t, i)
		local pages = {
			page2 = 1,
			page3 = 2,
			page4 = 3,
			page5 = 4,
			page6 = 5,
		}

		if i == 'DRUID' then
			pages.cat = 6
			pages.bar = 8
			pages.moonkin = 9
			pages.tree = 7
		elseif i == 'WARRIOR' then
			pages.battle = 6
			pages.defensive = 7
			pages.berserker = 8
		elseif i == 'PRIEST' then
			pages.shadow = 6
		elseif i == 'ROGUE' then
			pages.stealth = 6
			pages.shadowdance = 6
		end

		t[i] = pages
		return pages
	end
}

ActionBar.class = select(2, UnitClass('player'))
local active = {}

function ActionBar:New(id)
	local f = self.super.New(self, id)
	f.sets.pages = setmetatable(f.sets.pages, f.id == 1 and self.mainbarOffsets or self.defaultOffsets)

	f.pages = f.sets.pages[f.class]
	f.baseID = f:MaxLength() * (id-1)

	f:LoadStateController()
	f:LoadButtons()
	f:UpdateClickThrough()
	f:UpdateStateDriver()
	f:Layout()
	f:UpdateGrid()
	f:UpdateRightClickUnit()
	f:SetScript('OnSizeChanged', self.OnSizeChanged)

	active[id] = f

	return f
end

function ActionBar:OnSizeChanged()
	if not InCombatLockdown() then
		self:UpdateFlyoutDirection()
	end
end

--TODO: change the position code to be based more on the number of action bars
function ActionBar:GetDefaults()
	local defaults = {}
	defaults.point = 'BOTTOM'
	defaults.x = 0
	defaults.y = 40*(self.id-1)
	defaults.pages = {}
	defaults.spacing = 4
	defaults.padW = 2
	defaults.padH = 2
	defaults.numButtons = self:MaxLength()

	return defaults
end

function ActionBar:Free()
	active[self.id] = nil
	self.super.Free(self)
end

--returns the maximum possible size for a given bar
function ActionBar:MaxLength()
	return floor(MAX_BUTTONS / Dominos:NumBars())
end


--[[ button stuff]]--

function ActionBar:LoadButtons()
	for i = 1, self:NumButtons() do
		local b = ActionButton:New(self.baseID + i)
		if b then
			b:SetParent(self.header)
			b:SetFlyoutDirection(self:GetFlyoutDirection())
			self.buttons[i] = b
		else
			break
		end
	end
	self:UpdateActions()
end

function ActionBar:AddButton(i)
	local b = ActionButton:New(self.baseID + i)
	if b then
		self.buttons[i] = b
		b:SetParent(self.header)
		b:SetFlyoutDirection(self:GetFlyoutDirection())
		b:LoadAction()
		self:UpdateAction(i)
		self:UpdateGrid()
	end
end

function ActionBar:RemoveButton(i)
	local b = self.buttons[i]
	self.buttons[i] = nil
	b:Free()
end


--[[ Paging Code ]]--

function ActionBar:SetOffset(stateId, page)
	self.pages[stateId] = page
	self:UpdateStateDriver()
end

function ActionBar:GetOffset(stateId)
	return self.pages[stateId]
end

--note to self:
--if you leave a ; on the end of a statebutton string, it causes evaluation issues, especially if you're doing right click selfcast on the base state
function ActionBar:UpdateStateDriver()
--	UnregisterStateDriver(self.header, 'page', 0)

	local header = ''
	for i, state in Dominos.BarStates:getAll() do
		local stateId = state.id
		local condition
		if type(state.value) == 'function' then
			condition = state.value()
		else
			condition = state.value
		end
		
		if condition then
			--possess bar: special case
			if stateId == 'possess' then
				if self:IsPossessBar() then
					header = header .. condition .. 'possess;'
				end
			elseif self:GetOffset(stateId) then
				header = header .. condition .. 'S' .. i .. ';'
			end
		end
	end

	if header ~= '' then
		RegisterStateDriver(self.header, 'page', header .. 0)
	end

	self:UpdateActions()
	self:RefreshActions()
end

local function ToValidID(id)
	return (id - 1) % MAX_BUTTONS + 1
end

--updates the actionID of a given button for all states
function ActionBar:UpdateAction(i)
	local b = self.buttons[i]
	local maxSize = self:MaxLength()
	
	for i, state in Dominos.BarStates:getAll() do	
		local offset = self:GetOffset(state.id)
		local actionId = nil
		if offset then
			actionId = ToValidID(b:GetAttribute('action--base') + offset * maxSize) 
		end
		b:SetAttribute('action--S' .. i, actionId)
	end

	if self:IsPossessBar() and i <= NUM_POSSESS_BAR_BUTTONS then
		b:SetAttribute('action--possess', MAX_BUTTONS + i)
	else
		b:SetAttribute('action--possess', nil)
	end
end

--updates the actionID of all buttons for all states
function ActionBar:UpdateActions()
	local maxSize = self:MaxLength()

	for i, state in Dominos.BarStates:getAll() do
		local offset = self:GetOffset(state.id)
		if offset then
			for _, b in pairs(self.buttons) do
				local actionId = ToValidID(b:GetAttribute('action--base') + offset * maxSize)
				b:SetAttribute('action--S' .. i, actionId)
			end
		else
			for _, b in pairs(self.buttons) do
				b:SetAttribute('action--S' .. i, nil)
			end
		end
	end

	if self:IsPossessBar() then
		for i = 1, min(#self.buttons, NUM_POSSESS_BAR_BUTTONS) do
			self.buttons[i]:SetAttribute('action--possess', MAX_BUTTONS + i)
		end
		for i = NUM_POSSESS_BAR_BUTTONS + 1, #self.buttons do
			self.buttons[i]:SetAttribute('action--possess', nil)
		end
	else
		for _,b in pairs(self.buttons) do
			b:SetAttribute('action--possess', nil)
		end
	end
end

function ActionBar:LoadStateController()
	self.header:SetAttribute('_onstate-page', [[ control:ChildUpdate('action', newstate) ]])
end

function ActionBar:RefreshActions()
	local state = self.header:GetAttribute('state-page')
	if state then
		self.header:Execute(format([[ control:ChildUpdate('action', '%s') ]], state))
	else
		self.header:Execute([[ control:ChildUpdate('action', nil) ]])
	end
end

--returns true if the possess bar, false otherwise
function ActionBar:IsPossessBar()
	return self == Dominos:GetPossessBar()
end


--Empty button display
function ActionBar:ShowGrid()
	for _,b in pairs(self.buttons) do
		b:SetAttribute('showgrid', b:GetAttribute('showgrid') + 1)
		b:UpdateGrid()
	end
end

function ActionBar:HideGrid()
	for _,b in pairs(self.buttons) do
		b:SetAttribute('showgrid', max(b:GetAttribute('showgrid') - 1, 0))
		b:UpdateGrid()
	end
end

function ActionBar:UpdateGrid()
	if Dominos:ShowGrid() then
		self:ShowGrid()
	else
		self:HideGrid()
	end
end

function ActionBar:UPDATE_BINDINGS()
	for _,b in pairs(self.buttons) do
		b:UpdateHotkey(b.buttonType)
	end
end

---keybound support
function ActionBar:KEYBOUND_ENABLED() 	
	self:ShowGrid()
	for _, b in pairs(self.buttons) do
		b:RegisterEvent('UPDATE_BINDINGS')
	end
end

function ActionBar:KEYBOUND_DISABLED()
	self:HideGrid()
end

--right click targeting support
function ActionBar:UpdateRightClickUnit()
	self.header:SetAttribute('*unit2', Dominos:GetRightClickUnit())
end

--utility functions
function ActionBar:ForAll(method, ...)
	for _,f in pairs(active) do
		f[method](f, ...)
	end
end

--[[ flyout direction updating ]]--

function ActionBar:GetFlyoutDirection()
	local w, h = self:GetSize()
	local isVertical = w < h
	local anchor = self:GetPoint()
	
	if isVertical then
		if anchor and anchor:match('LEFT') then
			return 'RIGHT'
		end
		return 'LEFT'
	end
	
	if anchor and anchor:match('TOP') then
		return 'DOWN'
	end
	return 'UP'		
end

function ActionBar:UpdateFlyoutDirection()
	if self.buttons then
		local direction = self:GetFlyoutDirection()

		--dear blizzard, I'd like to be able to use the useparent-* attribute stuff for this
		for _,b in pairs(self.buttons) do
			b:SetFlyoutDirection(direction)
		end
	end
end

function ActionBar:SavePosition()
	Dominos.Frame.SavePosition(self)
	self:UpdateFlyoutDirection()
end


--right click menu code for action bars
--TODO: Probably enable the showstate stuff for other bars, since every bar basically has showstate functionality for 'free'
do
	local L

	--state slider template
	local function ConditionSlider_OnShow(self)
		self:SetMinMaxValues(-1, Dominos:NumBars() - 1)
		self:SetValue(self:GetParent().owner:GetOffset(self.stateId) or -1)
		self:UpdateText(self:GetValue())
	end

	local function ConditionSlider_UpdateValue(self, value)
		self:GetParent().owner:SetOffset(self.stateId, (value > -1 and value) or nil)
	end

	local function ConditionSlider_UpdateText(self, value)
		if value > -1 then
			local page = (self:GetParent().owner.id + value - 1) % Dominos:NumBars() + 1
			self.valText:SetFormattedText(L.Bar, page)
		else
			self.valText:SetText(DISABLE)
		end
	end

	local function ConditionSlider_New(panel, stateId, text)
		local s = panel:NewSlider(stateId, 0, 1, 1)
		s.OnShow = ConditionSlider_OnShow
		s.UpdateValue = ConditionSlider_UpdateValue
		s.UpdateText = ConditionSlider_UpdateText
		s.stateId = stateId
		s:SetWidth(s:GetWidth() + 28)

		local title = _G[s:GetName() .. 'Text']
		title:ClearAllPoints()
		title:SetPoint('BOTTOMLEFT', s, 'TOPLEFT')
		title:SetJustifyH('LEFT')
		title:SetText(text or L['State_' .. stateId:upper()])

		local value = s.valText
		value:ClearAllPoints()
		value:SetPoint('BOTTOMRIGHT', s, 'TOPRIGHT')
		value:SetJustifyH('RIGHT')

		return s
	end

	local function AddLayout(self)
		local p = self:AddLayoutPanel()

		local size = p:NewSlider(L.Size, 1, 1, 1)
		size.OnShow = function(self)
			self:SetMinMaxValues(1, self:GetParent().owner:MaxLength())
			self:SetValue(self:GetParent().owner:NumButtons())
		end

		size.UpdateValue = function(self, value)
			self:GetParent().owner:SetNumButtons(value)
			_G[self:GetParent():GetName() .. L.Columns]:OnShow()
		end
	end

	local function AddAdvancedLayout(self)
		self:AddAdvancedPanel()
	end

	--GetSpellInfo(spellID) is awesome for localization
	local function addStatePanel(self, name, type)
		local states = Dominos.BarStates:map(function(s) return s.type == type end)
		if #states > 0 then
			local p = self:NewPanel(name)
			for i = #states, 1, -1 do
				local state = states[i]
				ConditionSlider_New(p, state.id, state.text)
			end
		end
	end
	
	local function AddClass(self)
		addStatePanel(self, UnitClass('player'), 'class')
	end

	local function AddPaging(self)
		addStatePanel(self, L.QuickPaging, 'page')
	end

	local function AddModifier(self)
		addStatePanel(self, L.Modifiers, 'modifier')
	end

	local function AddTargeting(self)
		addStatePanel(self, L.Targeting, 'target')
	end

	local function AddShowState(self)
		local p = self:NewPanel(L.ShowStates)
		p.height = 56

		local editBox = CreateFrame('EditBox', p:GetName() .. 'StateText', p,  'InputBoxTemplate')
		editBox:SetWidth(148) editBox:SetHeight(20)
		editBox:SetPoint('TOPLEFT', 12, -10)
		editBox:SetAutoFocus(false)
		editBox:SetScript('OnShow', function(self)
			self:SetText(self:GetParent().owner:GetShowStates() or '')
		end)
		editBox:SetScript('OnEnterPressed', function(self)
			local text = self:GetText()
			self:GetParent().owner:SetShowStates(text ~= '' and text or nil)
		end)
		editBox:SetScript('OnEditFocusLost', function(self) self:HighlightText(0, 0) end)
		editBox:SetScript('OnEditFocusGained', function(self) self:HighlightText() end)

		local set = CreateFrame('Button', p:GetName() .. 'Set', p, 'UIPanelButtonTemplate')
		set:SetWidth(30) set:SetHeight(20)
		set:SetText(L.Set)
		set:SetScript('OnClick', function(self)
			local text = editBox:GetText()
			self:GetParent().owner:SetShowStates(text ~= '' and text or nil)
			editBox:SetText(self:GetParent().owner:GetShowStates() or '')
		end)
		set:SetPoint('BOTTOMRIGHT', -8, 2)

		return p
	end

	function ActionBar:CreateMenu()
		local menu = Dominos:NewMenu(self.id)

		L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')
		AddLayout(menu)
		AddClass(menu)
		AddPaging(menu)
		AddModifier(menu)
		AddTargeting(menu)
		AddShowState(menu)
		AddAdvancedLayout(menu)

		ActionBar.menu = menu
	end
end
