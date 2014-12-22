--[[
	Action Button.lua
		A dominos action button
--]]

local KeyBound = LibStub('LibKeyBound-1.0')
local Bindings = Dominos.BindingsController
local Tooltips = Dominos:GetModule('Tooltips')

local ActionButton = Dominos:CreateClass('CheckButton', Dominos.BindableButton)
Dominos.ActionButton = ActionButton
ActionButton.unused = {}
ActionButton.active = {}

local function GetOrCreateActionButton(id)
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

--constructor
function ActionButton:New(id)
	local b = self:Restore(id) or self:Create(id)

	if b then
		b:SetAttribute('showgrid', 0)
		b:SetAttribute('action--base', id)
		b:SetAttribute('_childupdate-action', [[
			local state = message
			local overridePage = self:GetParent():GetAttribute('state-overridepage')
			local newActionID

			if state == 'override' then
				newActionID = self:GetAttribute('button--index') + (overridePage - 1) * 12
			else
				newActionID = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')
			end

			if newActionID ~= self:GetAttribute('action') then
				self:SetAttribute('action', newActionID)
				self:CallMethod('UpdateState')
			end
		]])

		Bindings:Register(b, b:GetName():match('DominosActionButton%d'))
		Tooltips:Register(b)

		--get rid of range indicator text
		local hotkey = b.HotKey
		if hotkey:GetText() == _G['RANGE_INDICATOR'] then
			hotkey:SetText('')
		end

		b:UpdateGrid()
		b:UpdateMacro()

		self.active[id] = b
	end

	return b
end

function ActionButton:Create(id)
	local b = GetOrCreateActionButton(id)

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
		b:HookScript('OnEnter', self.OnEnter)
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
do
	local HiddenActionButtonFrame = CreateFrame('Frame')
	HiddenActionButtonFrame:Hide()

	function ActionButton:Free()
		local id = self:GetAttribute('action--base')

		self.active[id] = nil

		Tooltips:Unregister(self)
		Bindings:Unregister(self)

		self:SetParent(HiddenActionButtonFrame)
		self:Hide()

		self.unused[id] = self
	end
end

--these are all events that are registered OnLoad for action buttons
function ActionButton:LoadEvents()
	ActionBarActionEventsFrame_RegisterFrame(self)
end

--keybound support
function ActionButton:OnEnter()
	KeyBound:Set(self)
end

--override the old update hotkeys function
hooksecurefunc('ActionButton_UpdateHotkeys', ActionButton.UpdateHotkey)

--button visibility
function ActionButton:UpdateGrid()
	if InCombatLockdown() then return end

	if self:GetAttribute('showgrid') > 0 then
		ActionButton_ShowGrid(self)
	else
		ActionButton_HideGrid(self)
	end
end

--macro text
function ActionButton:UpdateMacro()
	if Dominos:ShowMacroText() then
		self.Name:Show()
	else
		self.Name:Hide()
	end
end

function ActionButton:SetFlyoutDirection(direction)
	if InCombatLockdown() then return end

	self:SetAttribute('flyoutDirection', direction)
	ActionButton_UpdateFlyout(self)
end

function ActionButton:UpdateState()
	ActionButton_UpdateState(self)
end

--utility function, resyncs the button's current action, modified by state
function ActionButton:LoadAction()
	local state = self:GetParent():GetAttribute('state-page')
	local id = state and self:GetAttribute('action--' .. state) or self:GetAttribute('action--base')

	self:SetAttribute('action', id)
end

function ActionButton:Skin()
	if not Dominos:Masque('Action Bar', self) then
		self.icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
		self:GetNormalTexture():SetVertexColor(1, 1, 1, 0.5)

		local floatingBG = _G[self:GetName() .. 'FloatingBG']
		if floatingBG then
			floatingBG:Hide()
		end
	end
end
