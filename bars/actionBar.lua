--[[
	actionBar.lua
		the code for Dominos action bars and buttons
--]]

--[[ globals ]]--

local Dominos = _G['Dominos']
local ActionButton = Dominos.ActionButton
local HiddenFrame = CreateFrame('Frame'); HiddenFrame:Hide()

local MAX_BUTTONS = 120

local ceil = math.ceil
local min = math.min
local format = string.format

--[[ Action Bar ]]--

local ActionBar = Dominos:CreateClass('Frame', Dominos.ButtonBar)
Dominos.ActionBar = ActionBar

-- Metatable magic.  Basically this says, 'create a new table for this index'
-- I do this so that I only create page tables for classes the user is actually
-- playing
ActionBar.defaultOffsets = {
	__index = function(t, i)
		t[i] = {}
		return t[i]
	end
}

-- Metatable magic.  Basically this says, 'create a new table for this index,
-- with these defaults. I do this so that I only create page tables for classes
-- the user is actually playing
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
			pages.bear = 8
			pages.moonkin = 9
			pages.tree = 7
		elseif i == 'WARRIOR' then
			pages.battle = 6
			pages.defensive = 7
			-- pages.berserker = 8
		elseif i == 'PRIEST' then
			pages.shadow = 6
		elseif i == 'ROGUE' then
			pages.stealth = 6
			pages.shadowdance = 6
		elseif i == 'MONK' then
			pages.tiger = 6
			pages.ox = 7
			pages.serpent = 8
		end

		t[i] = pages
		return pages
	end
}

ActionBar.class = select(2, UnitClass('player'))
local active = {}

function ActionBar:New(id)
	local bar = ActionBar.proto.New(self, id)

	bar.sets.pages = setmetatable(bar.sets.pages, bar.id == 1 and self.mainbarOffsets or self.defaultOffsets)
	bar.pages = bar.sets.pages[bar.class]

	bar:LoadStateController()
	bar:UpdateStateDriver()
	bar:UpdateRightClickUnit()
	bar:UpdateGrid()
	bar:UpdateTransparent(true)

	active[id] = bar

	return bar
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

	ActionBar.proto.Free(self)
end

--returns the maximum possible size for a given bar
function ActionBar:MaxLength()
	return floor(MAX_BUTTONS / Dominos:NumBars())
end


--[[ button stuff]]--

function ActionBar:BaseActionID()
	return self:MaxLength() * (self.id - 1)
end

function ActionBar:GetButton(index)
	return ActionButton:New(self:BaseActionID() + index)
end

function ActionBar:AttachButton(index)
	local button = ActionBar.proto.AttachButton(self, index)

	if button then
		button:SetFlyoutDirection(self:GetFlyoutDirection())
		button:LoadAction()

		self:UpdateAction(index)
	end

	return button
end


--[[ Paging Code ]]--

function ActionBar:SetOffset(stateId, page)
	self.pages[stateId] = page
	self:UpdateStateDriver()
end

function ActionBar:GetOffset(stateId)
	return self.pages[stateId]
end

-- note to self:
-- if you leave a ; on the end of a statebutton string, it causes evaluation
-- issues, especially if you're doing right click selfcast on the base state
function ActionBar:UpdateStateDriver()
	UnregisterStateDriver(self.header, 'page', 0)

	local header = ''
	for i, state in Dominos.BarStates:getAll() do
		local stateId = state.id
		local condition
		if type(state.value) == 'function' then
			condition = state.value()
		else
			condition = state.value
		end

		if self:GetOffset(stateId) then
			header = header .. condition .. 'S' .. i .. ';'
		end
	end

	if header ~= '' then
		RegisterStateDriver(self.header, 'page', header .. 0)
	end

	self:UpdateActions()
	self:RefreshActions()
end

do
	local function ToValidID(id)
		return (id - 1) % MAX_BUTTONS + 1
	end

	--updates the actionID of a given button for all states
	function ActionBar:UpdateAction(index)
		local button = self.buttons[index]
		local maxSize = self:MaxLength()

		button:SetAttribute('button--index', index)

		for i, state in Dominos.BarStates:getAll() do
			local offset = self:GetOffset(state.id)
			local actionId = nil

			if offset then
				actionId = ToValidID(button:GetAttribute('action--base') + offset * maxSize)
			end

			button:SetAttribute('action--S' .. i, actionId)
		end
	end
end

--updates the actionID of all buttons for all states
function ActionBar:UpdateActions()
	for i = 1, #self.buttons do
		self:UpdateAction(i)
	end
end

function ActionBar:LoadStateController()
	self.header:SetAttribute('_onstate-overridebar', [[
		self:RunAttribute('updateState')
	]])

	self.header:SetAttribute('_onstate-overridepage', [[
		self:RunAttribute('updateState')
	]])

	self.header:SetAttribute('_onstate-page', [[
		self:RunAttribute('updateState')
	]])

	self.header:SetAttribute('updateState', [[
		local state
		if self:GetAttribute('state-overridepage') > 10 and self:GetAttribute('state-overridebar') then
			state = 'override'
		else
			state = self:GetAttribute('state-page')
		end

		control:ChildUpdate('action', state)
	]])

	self:UpdateOverrideBar()
end

function ActionBar:RefreshActions()
	self.header:Execute([[ self:RunAttribute('updateState') ]])
end

function ActionBar:UpdateOverrideBar()
	local isOverrideBar = self:IsOverrideBar()

	self.header:SetAttribute('state-overridebar', isOverrideBar)
end

--returns true if the possess bar, false otherwise
function ActionBar:IsOverrideBar()
	return self == Dominos:GetOverrideBar()
end


--Empty button display
function ActionBar:ShowGrid()
	for _, button in pairs(self.buttons) do
		button:SetAttribute('showgrid', button:GetAttribute('showgrid') + 1)
		button:UpdateGrid()
	end
end

function ActionBar:HideGrid()
	for _, button in pairs(self.buttons) do
		button:SetAttribute('showgrid', max(button:GetAttribute('showgrid') - 1, 0))
		button:UpdateGrid()
	end
end

function ActionBar:UpdateGrid()
	if Dominos:ShowGrid() then
		self:ShowGrid()
	else
		self:HideGrid()
	end
end

---keybound support
function ActionBar:KEYBOUND_ENABLED()
	self:ShowGrid()
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


function ActionBar:OnSetAlpha(alpha)
	self:UpdateTransparent()
end

function ActionBar:UpdateTransparent(force)
	local isTransparent = self:GetAlpha() == 0
	
	if self.__transparent ~= isTransparent or force then
		self.__transparent = isTransparent
		
		if isTransparent then
			self:HideButtonCooldowns()
		else
			self:ShowButtonCooldowns()
		end
	end
end
		
function ActionBar:ShowButtonCooldowns()
	for i, button in pairs(self.buttons) do
		if button.cooldown:GetParent() ~= button then
			button.cooldown:SetParent(button)
			ActionButton_UpdateCooldown(button)
		end
	end	
end

function ActionBar:HideButtonCooldowns()
	-- hide cooldown frames on transparent buttons by sticking them onto a
	-- different parent
	for i, button in pairs(self.buttons) do
		button.cooldown:SetParent(HiddenFrame)
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
	local direction = self:GetFlyoutDirection()

	-- dear blizzard, I'd like to be able to use the useparent-* attribute stuff for this
	for _, button in pairs(self.buttons) do
		button:SetFlyoutDirection(direction)
	end
end

function ActionBar:Layout(...)
	ActionBar.proto.Layout(self, ...)

	self:UpdateFlyoutDirection()
end


function ActionBar:SaveFramePosition(...)
	ActionBar.proto.SaveFramePosition(self, ...)

	self:UpdateFlyoutDirection()
end


-- right click menu code for action bars
-- TODO: Probably enable the showstate stuff for other bars, since every bar
-- basically has showstate functionality for 'free'
do
	local L

	--state slider template
	local function ConditionSlider_OnShow(self)
		self:SetMinMaxValues(-1, Dominos:NumBars() - 1)
		self:SetValue(self:GetParent().owner:GetOffset(self.stateId) or -1)
		self:UpdateText(self:GetValue())

		if self.stateTextFunc then
			_G[self:GetName() .. 'Text']:SetText(self.stateTextFunc())
		end
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

		if type(text) == 'function' then
			s.stateTextFunc = text
		else
			title:SetText(text or L['State_' .. stateId:upper()])
		end

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
		local states = Dominos.BarStates:map(function(s)
			return s.type == type
		end)

		if #states > 0 then
			local p = self:NewPanel(name)

			--HACK: Make the state panel wider for monks
			--		since their stances have long names
			local playerClass = select(2, UnitClass('player'))

			local hasLongStanceNames = playerClass == 'MONK'
									or playerClass == 'ROGUE'
									or playerClass == 'DRUID'

			for i = #states, 1, -1 do
				local state = states[i]
				local slider = ConditionSlider_New(p, state.id, state.text)
				if hasLongStanceNames then
					slider:SetWidth(slider:GetWidth() + 48)
				end
			end

			if hasLongStanceNames then
				p.width = 228
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

		local editBox = CreateFrame('EditBox', p:GetName() .. 'StateText', p, 'InputBoxTemplate')
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


--[[ Action Bar Controller ]]--

local ActionBarController = Dominos:NewModule('ActionBars', 'AceEvent-3.0')

function ActionBarController:Load()
	self:RegisterEvent('UPDATE_BONUS_ACTIONBAR', 'UpdateOverrideBar')
	self:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR', 'UpdateOverrideBar')
	self:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR', 'UpdateOverrideBar')

	for i = 1, Dominos:NumBars() do
		ActionBar:New(i)
	end
end

function ActionBarController:Unload()
	self:UnregisterAllEvents()

	for i = 1, Dominos:NumBars() do
		Dominos.Frame:ForFrame(i, 'Free')
	end
end

function ActionBarController:UpdateOverrideBar()
	if InCombatLockdown() or (not Dominos.OverrideController:OverrideBarActive()) then
		return
	end

	local overrideBar = Dominos:GetOverrideBar()

	for _, button in pairs(overrideBar.buttons) do
		ActionButton_Update(button)
	end
end
