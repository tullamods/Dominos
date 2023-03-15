--------------------------------------------------------------------------------
-- Flyout
-- Reimplements flyout actions for action buttons
--------------------------------------------------------------------------------

local AddonName, Addon = ...

-- A precalculated list of all known valid flyout ids. Not robust, but also sparse.
-- TODO: regeneate this list once every build
local VALID_FLYOUT_IDS = {
	1, 8, 9, 10, 11, 12, 66, 67, 84, 92, 93, 96, 103, 106, 217, 219, 220, 222, 223, 224, 225, 226, 227, 229
}

-- layout constants from SpellFlyout.lua
local SPELLFLYOUT_DEFAULT_SPACING = 4
local SPELLFLYOUT_INITIAL_SPACING = 7

--------------------------------------------------------------------------------
-- Spell Flyout Button
-- One of the options presented on a flyout menu
--------------------------------------------------------------------------------

local SpellFlyoutButtonMixin = {}

--------------------------------------------------------------------------------
-- Initialization
--------------------------------------------------------------------------------

function SpellFlyoutButtonMixin:Initialize()
	self:SetAttribute("type", "spell")
	self:RegisterForClicks("AnyUp")

	self:SetScript("OnEnter", self.OnEnter)
	self:SetScript("OnLeave", self.OnLeave)
	self:SetScript("PostClick", self.OnPostClick)
end

--------------------------------------------------------------------------------
-- SpellFlyoutButton Event Handlers
--------------------------------------------------------------------------------

function SpellFlyoutButtonMixin:OnEnter()
	if GetCVarBool("UberTooltips") then
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT", 4, 4)

		if GameTooltip:SetSpellByID(self.spellID) then
			self.UpdateTooltip = self.OnEnter
		else
			self.UpdateTooltip = nil
		end
	else
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(self.spellName, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)

		self.UpdateTooltip = nil
	end
end

function SpellFlyoutButtonMixin:OnLeave()
	GameTooltip:Hide()
end

function SpellFlyoutButtonMixin:OnFlyoutUpdated()
	local id = self:GetAttribute("flyoutID")
	local index = self:GetAttribute("flyoutIndex")
	local spellID, overrideSpellID, isKnown, spellName = GetFlyoutSlotInfo(id, index)

	self.icon:SetTexture(GetSpellTexture(overrideSpellID))
	self.icon:SetDesaturated(not isKnown)

	self.spellID = spellID
	self.spellName = spellName

	self:Update()
end

function SpellFlyoutButtonMixin:OnPostClick()
	self:UpdateState()
end

--------------------------------------------------------------------------------
-- SpellFlyoutButton Methods
--------------------------------------------------------------------------------

function SpellFlyoutButtonMixin:Update()
	self:UpdateCooldown()
	self:UpdateState()
	self:UpdateUsable()
	self:UpdateCount()
end

function SpellFlyoutButtonMixin:UpdateCooldown()
	if self.spellID then
		ActionButton_UpdateCooldown(self)
	end
end

function SpellFlyoutButtonMixin:UpdateState()
	self:SetChecked(IsCurrentSpell(self.spellID) and true)
end

function SpellFlyoutButtonMixin:UpdateUsable()
	local isUsable, notEnoughMana = IsUsableSpell(self.spellID)

	if isUsable then
		self.icon:SetVertexColor(1, 1, 1)
	elseif notEnoughMana then
		self.icon:SetVertexColor(0.5, 0.5, 1)
	else
		self.icon:SetVertexColor(0.4, 0.4, 0.4)
	end
end

function SpellFlyoutButtonMixin:UpdateCount()
	if IsConsumableSpell(self.spellID) then
		local count = GetSpellCount(self.spellID)
		if count > (self.maxDisplayCount or 9999) then
			self.Count:SetText("*")
		else
			self.Count:SetText(count)
		end
	else
		self.Count:SetText("")
	end
end

--------------------------------------------------------------------------------
-- Spell Flyout
-- A menu of actions that are shown when you activate a spell flyout button
--------------------------------------------------------------------------------

local SpellFlyoutFrameMixin = {}

-- methods we're importing from the stock UI
SpellFlyoutFrameMixin.SetBorderColor = SpellFlyout_SetBorderColor
SpellFlyoutFrameMixin.SetBorderSize = SpellFlyout_SetBorderSize

-- secure methods
local SpellFlyoutFrame_Toggle = [[
	local flyoutID = ...
	local parent = self:GetAttribute("caller")

	if self:IsShown() and parent == self:GetParent() then
		self:Hide()
		return
	end

	local flyout = FLYOUT_INFO[flyoutID]
	local numSlots = flyout and flyout.numSlots or 0
	local isKnown = flyout and flyout.isKnown or false

	self:SetParent(parent)

	if numSlots == 0 or not isKnown then
		self:Hide()
		return
	end

	local direction = parent:GetAttribute("flyoutDirection") or "UP"
	self:SetAttribute("direction", direction)

	local prevButton = nil
	local numButtons = 0

	for i = 1, numSlots do
		if flyout[i].isKnown then
			numButtons = numButtons + 1

			local button = FLYOUT_SLOTS[numButtons]

			button:ClearAllPoints()

			if direction == "UP" then
				if prevButton then
					button:SetPoint("BOTTOM", prevButton, "TOP", 0, SPELLFLYOUT_DEFAULT_SPACING)
				else
					button:SetPoint("BOTTOM", self, "BOTTOM", 0, SPELLFLYOUT_INITIAL_SPACING)
				end
			elseif direction == "DOWN" then
				if prevButton then
					button:SetPoint("TOP", prevButton, "BOTTOM", 0, -SPELLFLYOUT_DEFAULT_SPACING)
				else
					button:SetPoint("TOP", self, "TOP", 0, -SPELLFLYOUT_INITIAL_SPACING)
				end
			elseif direction == "LEFT" then
				if prevButton then
					button:SetPoint("RIGHT", prevButton, "LEFT", -SPELLFLYOUT_DEFAULT_SPACING, 0)
				else
					button:SetPoint("RIGHT", self, "RIGHT", -SPELLFLYOUT_INITIAL_SPACING, 0)
				end
			elseif direction == "RIGHT" then
				if prevButton then
					button:SetPoint("LEFT", prevButton, "RIGHT", SPELLFLYOUT_DEFAULT_SPACING, 0)
				else
					button:SetPoint("LEFT", self, "LEFT", SPELLFLYOUT_INITIAL_SPACING, 0)
				end
			end

			button:SetAttribute("spell", flyout[i].spellID)
			button:SetAttribute("flyoutID", flyoutID)
			button:SetAttribute("flyoutIndex", i)
			button:Enable()
			button:Show()
			button:CallMethod("OnFlyoutUpdated")

			prevButton = button
		end
	end

	for i = numButtons + 1, #FLYOUT_SLOTS do
		FLYOUT_SLOTS[i]:Hide()
	end

	if numButtons == 0 then
		self:Hide()
		return
	end

	local bW = FLYOUT_SLOTS[1]:GetWidth()
	local bH = FLYOUT_SLOTS[1]:GetHeight()
	local vertical = false

	self:ClearAllPoints()

	if direction == "UP" then
		self:SetPoint("BOTTOM", parent, "TOP")
		vertical = true
	elseif direction == "DOWN" then
		self:SetPoint("TOP", parent, "BOTTOM")
		vertical = true
	elseif direction == "LEFT" then
		self:SetPoint("RIGHT", parent, "LEFT")
	elseif direction == "RIGHT" then
		self:SetPoint("LEFT", parent, "RIGHT")
	end

	if vertical then
		self:SetWidth(bW + (SPELLFLYOUT_DEFAULT_SPACING * 2))
		self:SetHeight(SPELLFLYOUT_INITIAL_SPACING + (bH + SPELLFLYOUT_DEFAULT_SPACING) * numButtons)
	else
		self:SetWidth(SPELLFLYOUT_INITIAL_SPACING + (bW + SPELLFLYOUT_DEFAULT_SPACING) * numButtons)
		self:SetHeight(bH + (SPELLFLYOUT_DEFAULT_SPACING * 2))
	end

	self:CallMethod("LayoutTextures", direction, 0)
	self:Show()
]]

function SpellFlyoutFrameMixin:Initialize()
	self.buttons = {}

	self.Background = CreateFrame('Frame', nil, self)
	self.Background:SetAllPoints()

	self.Background.End = self.Background:CreateTexture(nil, 'BACKGROUND')
	self.Background.End:SetAtlas('UI-HUD-ActionBar-IconFrame-FlyoutButton', true)

	self.Background.HorizontalMiddle = self.Background:CreateTexture(nil, 'BACKGROUND')
	self.Background.HorizontalMiddle:SetAtlas('_UI-HUD-ActionBar-IconFrame-FlyoutMidLeft', true)
	self.Background.HorizontalMiddle:SetHorizTile(true)
	self.Background.HorizontalMiddle:Hide()

	self.Background.VerticalMiddle = self.Background:CreateTexture(nil, 'BACKGROUND')
	self.Background.VerticalMiddle:SetAtlas('!UI-HUD-ActionBar-IconFrame-FlyoutMid', true)
	self.Background.VerticalMiddle:SetVertTile(true)
	self.Background.VerticalMiddle:Hide()

	self.Background.Start = self.Background:CreateTexture(nil, 'BACKGROUND')
	self.Background.Start:SetAtlas('UI-HUD-ActionBar-IconFrame-FlyoutBottom', true)

	local command = [[
		FLYOUT_INFO = newtable()
		FLYOUT_SLOTS = newtable()

		SPELLFLYOUT_DEFAULT_SPACING = %d
		SPELLFLYOUT_INITIAL_SPACING = %d
	]]

	self:Execute(command:format(SPELLFLYOUT_DEFAULT_SPACING, SPELLFLYOUT_INITIAL_SPACING))

	self:SetAttribute("Toggle", SpellFlyoutFrame_Toggle)
	self:SetAttribute("_onhide", [[ self:Hide(true) ]])

	self:UpdateKnownFlyouts()
end

function SpellFlyoutFrameMixin:LayoutTextures(direction, distance)
	self.direction = direction
	self.Background.End:ClearAllPoints()
	self.Background.Start:ClearAllPoints()

	if direction == "UP" then
		self.Background.End:SetPoint("TOP", 0, SPELLFLYOUT_INITIAL_SPACING)
		SetClampedTextureRotation(self.Background.End, 0)
		SetClampedTextureRotation(self.Background.VerticalMiddle, 0)
		self.Background.Start:SetPoint("TOP", self.Background.VerticalMiddle, "BOTTOM")
		SetClampedTextureRotation(self.Background.Start, 0)
		self.Background.HorizontalMiddle:Hide()
		self.Background.VerticalMiddle:Show()
		self.Background.VerticalMiddle:ClearAllPoints()
		self.Background.VerticalMiddle:SetPoint("TOP", self.Background.End, "BOTTOM")
		self.Background.VerticalMiddle:SetPoint("BOTTOM", 0, distance)
	elseif direction == "DOWN" then
		self.Background.End:SetPoint("BOTTOM", 0, -SPELLFLYOUT_INITIAL_SPACING)
		SetClampedTextureRotation(self.Background.End, 180)
		SetClampedTextureRotation(self.Background.VerticalMiddle, 180)
		self.Background.Start:SetPoint("BOTTOM", self.Background.VerticalMiddle, "TOP")
		SetClampedTextureRotation(self.Background.Start, 180)
		self.Background.HorizontalMiddle:Hide()
		self.Background.VerticalMiddle:Show()
		self.Background.VerticalMiddle:ClearAllPoints()
		self.Background.VerticalMiddle:SetPoint("BOTTOM", self.Background.End, "TOP")
		self.Background.VerticalMiddle:SetPoint("TOP", 0, -distance)
	elseif direction == "LEFT" then
		self.Background.End:SetPoint("LEFT", -SPELLFLYOUT_INITIAL_SPACING, 0)
		SetClampedTextureRotation(self.Background.End, 270)
		SetClampedTextureRotation(self.Background.HorizontalMiddle, 180)
		self.Background.Start:SetPoint("LEFT", self.Background.HorizontalMiddle, "RIGHT")
		SetClampedTextureRotation(self.Background.Start, 270)
		self.Background.VerticalMiddle:Hide()
		self.Background.HorizontalMiddle:Show()
		self.Background.HorizontalMiddle:ClearAllPoints()
		self.Background.HorizontalMiddle:SetPoint("LEFT", self.Background.End, "RIGHT")
		self.Background.HorizontalMiddle:SetPoint("RIGHT", -distance, 0)
	elseif direction == "RIGHT" then
		self.Background.End:SetPoint("RIGHT", SPELLFLYOUT_INITIAL_SPACING, 0)
		SetClampedTextureRotation(self.Background.End, 90)
		SetClampedTextureRotation(self.Background.HorizontalMiddle, 0)
		self.Background.Start:SetPoint("RIGHT", self.Background.HorizontalMiddle, "LEFT")
		SetClampedTextureRotation(self.Background.Start, 90)
		self.Background.VerticalMiddle:Hide()
		self.Background.HorizontalMiddle:Show()
		self.Background.HorizontalMiddle:ClearAllPoints()
		self.Background.HorizontalMiddle:SetPoint("RIGHT", self.Background.End, "LEFT")
		self.Background.HorizontalMiddle:SetPoint("LEFT", distance, 0)
	end

	self:SetBorderColor(0.7, 0.7, 0.7)
	self:SetBorderSize(47)
end

function SpellFlyoutFrameMixin:UpdateKnownFlyouts()
	local slotsNeeded = 0

	for i = 1, #VALID_FLYOUT_IDS do
		local numSlots = self:UpdateFlyoutInfo(VALID_FLYOUT_IDS[i])

		if numSlots > slotsNeeded then
			slotsNeeded = numSlots
		end
	end

	self:Embiggen(slotsNeeded)
end

function SpellFlyoutFrameMixin:UpdateFlyout(flyoutID)
	local numSlots = self:UpdateFlyoutInfo(flyoutID)

	if numSlots > #self.buttons then
		self:Embiggen(numSlots)
		return true
	end

	return false
end

function SpellFlyoutFrameMixin:UpdateFlyoutInfo(flyoutID)
	local _, _, numSlots, isKnown = GetFlyoutInfo(flyoutID)

	self:Execute(([[
		local flyoutID = %d
		local numSlots = %d
		local isKnown = %q == "true"

		local data = FLYOUT_INFO[flyoutID] or newtable()
		data.numSlots = numSlots
		data.isKnown = isKnown

		FLYOUT_INFO[flyoutID] = data

		-- clear the known state of any newly unused slots
		for i = numSlots + 1, #data do
			data[i].isKnown = false
		end
	]]):format(
		flyoutID,
		numSlots,
		tostring(isKnown)
	))

	for slotID = 1, numSlots do
		local spellID, _, isSlotKnown = GetFlyoutSlotInfo(flyoutID, slotID)

		if isSlotKnown then
			local petIndex, petName = GetCallPetSpellInfo(spellID)
			if petIndex and not (petName and petName ~= "") then
				isSlotKnown = false
			end
		end

		self:Execute(([[
			local flyoutID = %d
			local slotID = %d
			local spellID = %d
			local isKnown = %q == "true"

			local data = FLYOUT_INFO[flyoutID][slotID] or newtable()
			data.spellID = spellID
			data.isKnown = isKnown

			FLYOUT_INFO[flyoutID][slotID] = data
		]]):format(
			flyoutID,
			slotID,
			spellID,
			tostring(isSlotKnown)
		))
	end

	return numSlots
end

-- create any additional flyout buttons that we need
function SpellFlyoutFrameMixin:Embiggen(size)
	local buttons = self.buttons

	for i = #buttons + 1, size do
		local button = self:CreateFlyoutButton(i)

		self:SetFrameRef("flyoutSlotToAdd", button)
		self:Execute([[ tinsert(FLYOUT_SLOTS, self:GetFrameRef("flyoutSlotToAdd")) ]])

		buttons[i] = button
	end
end

local SpellFlyoutButton_OnClick = [[
	if not down then
		return nil, "close"
	end

	return false
]]

local SpellFlyoutButton_OnClickPost = [[
    if message == "close" then
        control:Hide()
    end
]]

function SpellFlyoutFrameMixin:CreateFlyoutButton(id)
	local name = ('%sSpellFlyoutButton%d'):format(AddonName, id)
	local button = CreateFrame('CheckButton', name, self, 'SmallActionButtonTemplate, SecureActionButtonTemplate')

	Mixin(button, SpellFlyoutButtonMixin)

	button:Initialize()

	self:WrapScript(button, "OnClick", SpellFlyoutButton_OnClick, SpellFlyoutButton_OnClickPost)

	return button
end

function SpellFlyoutFrameMixin:ForShown(method, ...)
	for _, button in pairs(self.buttons) do
		if button:IsShown() then
			button[method](button, ...)
		end
	end
end

--------------------------------------------------------------------------------
-- Flyout API/event manager
--------------------------------------------------------------------------------

local SpellFlyout = { }

LibStub('AceEvent-3.0'):Embed(SpellFlyout)

local button_OnClick = [[
    local type, id = GetActionInfo(self:GetAttribute('action'))
    if type == 'flyout' then
		if not down then
			control:SetAttribute("caller", self)
			control:RunAttribute("Toggle", id)
		end
        return false
    end
]]

function SpellFlyout:Register(button)
    local frame = self.frame

    if not frame then
		frame = CreateFrame("Frame", nil, nil, "SecureHandlerShowHideTemplate")

		Mixin(frame, SpellFlyoutFrameMixin)

		frame:Initialize()
		frame:HookScript("OnShow", function() self:OnFlyoutShown() end)
		frame:HookScript("OnHide", function() self:OnFlyoutHidden() end)

		self:RegisterEvent("SPELL_FLYOUT_UPDATE")

        self.frame = frame
    end

	frame:WrapScript(button, "OnClick", button_OnClick)
end

function SpellFlyout:CURRENT_SPELL_CAST_CHANGED()
	self.frame:ForShown("UpdateState")
end

function SpellFlyout:PLAYER_REGEN_ENABLED(event)
	if self.updateScheduled then
		self.frame:UpdateKnownFlyouts()
		self:UnregisterEvent(event)
		self.updateScheduled = nil
	end
end

function SpellFlyout:SPELL_FLYOUT_UPDATE(_, flyoutID)
	if flyoutID then
		if InCombatLockdown() then
			self:UpdateFlyoutSpellsWhenOutOfCombat()
		else
			self.frame:UpdateFlyout(flyoutID)
		end
	end

	self.frame:ForShown("Update")
end

function SpellFlyout:SPELL_UPDATE_COOLDOWN()
	self.frame:ForShown("UpdateCooldown")
end

function SpellFlyout:SPELL_UPDATE_USABLE()
	self.frame:ForShown("UpdateUsable")
end

function SpellFlyout:UpdateFlyoutSpellsWhenOutOfCombat()
	if not self.updateScheduled then
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
		self.updateScheduled = true
	end
end

function SpellFlyout:OnFlyoutShown()
	if not self.flyoutShown then
		self.flyoutShown = true

		self:RegisterEvent("CURRENT_SPELL_CAST_CHANGED")
		self:RegisterEvent("SPELL_UPDATE_COOLDOWN")
		self:RegisterEvent("SPELL_UPDATE_USABLE")
	end
end

function SpellFlyout:OnFlyoutHidden()
	if self.flyoutShown then
		self.flyoutShown = nil

		self:UnregisterEvent("CURRENT_SPELL_CAST_CHANGED")
		self:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
		self:UnregisterEvent("SPELL_UPDATE_USABLE")
	end
end

Addon.SpellFlyout = SpellFlyout
