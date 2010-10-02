--[[
	totemBar
		A dominos totem bar
--]]

--no reason to load if we're not playing a shaman...
local class, enClass = UnitClass('player')
if enClass ~= 'SHAMAN' then
	return
end

local DTB = Dominos:NewModule('totems', 'AceEvent-3.0')
local TotemBar

--hurray for constants
local MAX_TOTEMS = MAX_TOTEMS --fire, earth, water, air
local RECALL_SPELL = TOTEM_MULTI_CAST_RECALL_SPELLS[1]
local START_ACTION_ID = 132 --actionID start of the totembar
local SUMMON_SPELLS = TOTEM_MULTI_CAST_SUMMON_SPELLS

--[[ Module ]]--

function DTB:Load()
	self:LoadTotemBars()

	self:RegisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
end

function DTB:Unload()
	self:FreeTotemBars()

	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	self:UnregisterEvent('UPDATE_MULTI_CAST_ACTIONBAR')
end

function DTB:UPDATE_MULTI_CAST_ACTIONBAR()
	if not InCombatLockdown() then
		self:LoadTotemBars()
	else
		self:RegisterEvent('PLAYER_REGEN_ENABLED')
	end
end

function DTB:PLAYER_REGEN_ENABLED()
	self:LoadTotemBars()
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
end

function DTB:LoadTotemBars()
	for i, spell in pairs(SUMMON_SPELLS) do
		local f = Dominos.Frame:Get('totem' .. i)
		if f then
			f:LoadButtons()
		else
			TotemBar:New(i, spell)
		end
	end
end

function DTB:FreeTotemBars()
	for i, _ in pairs(SUMMON_SPELLS) do
		local f = Dominos.Frame:Get('totem' .. i)
		if f then
			f:Free()
		end
	end
end


--[[ Totem Bar ]]--

TotemBar = Dominos:CreateClass('Frame', Dominos.Frame)

function TotemBar:New(id, spell)
	local f = self.super.New(self, 'totem' .. id)
	f.totemBarID = id
	f.callSpell = spell
	f:LoadButtons()
	f:Layout()

	return f
end

function TotemBar:GetDefaults()
	return {
		point = 'CENTER',
		spacing = 2,
		showRecall = true,
		showTotems = true
	}
end

function TotemBar:NumButtons()
	local numButtons = 0

	if self:IsCallKnown() then
		numButtons = numButtons + 1
	end

	if self:ShowingTotems() then
		numButtons = numButtons + MAX_TOTEMS
	end

	if self:ShowingRecall() and self:IsRecallKnown() then
		numButtons = numButtons + 1
	end

	return numButtons
end

function TotemBar:GetBaseID()
	return START_ACTION_ID + (MAX_TOTEMS * (self.totemBarID - 1))
end

--handle displaying the totemic recall button
function TotemBar:SetShowRecall(show)
	self.sets.showRecall = show and true or false
	self:LoadButtons()
	self:Layout()
end

function TotemBar:ShowingRecall()
	return self.sets.showRecall
end

--handle displaying all of the totem buttons
function TotemBar:SetShowTotems(show)
	self.sets.showTotems = show and true or false
	self:LoadButtons()
	self:Layout()
end

function TotemBar:ShowingTotems()
	return self.sets.showTotems
end


--[[ button stuff]]--

local tinsert = table.insert

function TotemBar:LoadButtons()
	local buttons = self.buttons

	--remove old buttons
	for i, b in pairs(buttons) do
		b:Free()
		buttons[i] = nil
	end

	--add call of X button
	if self:IsCallKnown() then
		tinsert(buttons, self:GetCallButton())
	end

	--add totem actions
	if self:ShowingTotems() then
		for _, totemID in ipairs(SHAMAN_TOTEM_PRIORITIES) do
			tinsert(buttons, self:GetTotemButton(totemID))
		end
	end

	--add recall button
	if self:ShowingRecall() and self:IsRecallKnown() then
		tinsert(buttons, self:GetRecallButton())
	end

	self.header:Execute([[ control:ChildUpdate('action', nil) ]])
end

function TotemBar:IsCallKnown()
	return IsSpellKnown(self.callSpell, false)
end

function TotemBar:GetCallButton()
	return self:CreateSpellButton(self.callSpell)
end


function TotemBar:IsRecallKnown()
	return IsSpellKnown(RECALL_SPELL, false)
end

function TotemBar:GetRecallButton()
	return self:CreateSpellButton(RECALL_SPELL)
end


function TotemBar:GetTotemButton(id)
	return self:CreateActionButton(self:GetBaseID() + id)
end

function TotemBar:CreateSpellButton(spellID)
	local b = Dominos.SpellButton:New(spellID)
	b:SetParent(self.header)
	return b
end

function TotemBar:CreateActionButton(actionID)
	local b = Dominos.ActionButton:New(actionID)
	b:SetParent(self.header)
	b:LoadAction()
	return b
end


--[[ right click menu ]]--

function TotemBar:AddLayoutPanel(menu)
	local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config', 'enUS')
	local panel = menu:AddLayoutPanel()

	--add show totemic recall toggle
	local showRecall = panel:NewCheckButton(L.ShowTotemRecall)

	showRecall:SetScript('OnClick', function(b)
		self:SetShowRecall(b:GetChecked());
		panel.colsSlider:OnShow() --force update the columns slider
	end)

	showRecall:SetScript('OnShow', function(b)
		b:SetChecked(self:ShowingRecall())
	end)

	--add show totems toggle
	local showTotems = panel:NewCheckButton(L.ShowTotems)

	showTotems:SetScript('OnClick', function(b)
		self:SetShowTotems(b:GetChecked());
		panel.colsSlider:OnShow()
	end)

	showTotems:SetScript('OnShow', function(b)
		b:SetChecked(self:ShowingTotems())
	end)
end

function TotemBar:CreateMenu()
	self.menu = Dominos:NewMenu(self.id)
	self:AddLayoutPanel(self.menu)
	self.menu:AddAdvancedPanel()
end