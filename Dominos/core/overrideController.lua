local _, Addon = ...
if not Addon:IsBuild('retail', 'mists', 'cata', 'wrath') then
	return
end

if not OverrideActionBar then
	return
end

local afterMidnight = Addon.IsAfterMidnight and Addon:IsAfterMidnight()

local OverrideController = CreateFrame('Frame', nil, OverrideActionBar, 'SecureHandlerAttributeTemplate, SecureHandlerShowHideTemplate')

local overrideDrivers = {
	form = '[form]1;0',
	overridebar = '[overridebar]1;0',
	possessbar = '[possessbar]1;0',
	sstemp = '[shapeshift]1;0',
	vehicle = '[@vehicle,exists]1;0',
	vehicleui = '[vehicleui]1;0',
	petbattleui = '[petbattle]1;0',
}

function OverrideController:OnLoad()
	self:Execute([[
		myFrames = newtable()
	]])

	self:SetAttributeNoHandler('_onattributechanged', [[
		if not myFrames then
			myFrames = newtable()
		end

		if name == 'overrideui' then
			for _, frame in pairs(myFrames) do
				if frame then
					frame:SetAttribute('state-overrideui', value == 1)
				end
			end
		elseif name == 'petbattleui' then
			for _, frame in pairs(myFrames) do
				if frame then
					frame:SetAttribute('state-petbattleui', value == 1)
				end
			end
		elseif name == 'overridepage' then
			for _, frame in pairs(myFrames) do
				if frame then
					frame:SetAttribute('state-overridepage', value)
				end
			end
		else
			local page
			if HasVehicleActionBar and HasVehicleActionBar() then
				page = GetVehicleBarIndex() or 0
			elseif HasOverrideActionBar and HasOverrideActionBar() then
				page = GetOverrideBarIndex() or 0
			elseif HasTempShapeshiftActionBar and HasTempShapeshiftActionBar() then
				page = GetTempShapeshiftBarIndex() or 0
			else
				page = 0
			end

			if self:GetAttribute('overridepage') ~= page then
				self:SetAttribute('overridepage', page)
			end
		end
	]])

	if afterMidnight then
		self:SetAttributeNoHandler('_onshow', [[ self:SetAttribute('overrideui', 0) ]])
		self:SetAttributeNoHandler('_onhide', [[ self:SetAttribute('overrideui', 0) ]])
		self:SetAttributeNoHandler('overrideui', 0)
	else
		self:SetAttributeNoHandler('_onshow', [[ self:SetAttribute('overrideui', 1) ]])
		self:SetAttributeNoHandler('_onhide', [[ self:SetAttribute('overrideui', 0) ]])
		self:SetAttributeNoHandler('overrideui', OverrideActionBar:IsVisible() and 1 or 0)
	end

	for attribute, driver in pairs(overrideDrivers) do
		RegisterAttributeDriver(self, attribute, driver)
	end

	Addon.RegisterCallback(self, 'LAYOUT_LOADED')
	Addon.RegisterCallback(self, 'USE_OVERRRIDE_UI_CHANGED')
	self.OnLoad = nil
end

function OverrideController:LAYOUT_LOADED()
	self:SetShowOverrideUI(Addon:UsingOverrideUI())
end

function OverrideController:USE_OVERRRIDE_UI_CHANGED(_, show)
	self:SetShowOverrideUI(show)
end

function OverrideController:Add(frame)
	if not frame then
		return
	end

	self:SetFrameRef('add', frame)
	self:Execute([[
		if not myFrames then
			myFrames = newtable()
		end

		local frame = self:GetFrameRef('add')
		if frame then
			local exists = false
			for _, registeredFrame in pairs(myFrames) do
				if registeredFrame == frame then
					exists = true
					break
				end
			end

			if not exists then
				table.insert(myFrames, frame)
			end
		end
	]])

	frame:SetAttribute('state-overrideui', tonumber(self:GetAttribute('overrideui')) == 1)
	frame:SetAttribute('state-petbattleui', tonumber(self:GetAttribute('petbattleui')) == 1)
	frame:SetAttribute('state-overridepage', self:GetAttribute('overridepage') or 0)
end

function OverrideController:Remove(frame)
	if not frame then
		return
	end

	self:SetFrameRef('rem', frame)
	self:Execute([[
		if not myFrames then
			return
		end

		local frameToRemove = self:GetFrameRef('rem')
		for i, frame in pairs(myFrames) do
			if frame == frameToRemove then
				table.remove(myFrames, i)
				break
			end
		end
	]])
end

local originalParent
function OverrideController:SetShowOverrideUI(show)
	if afterMidnight then
		-- Do not reparent or show the native OverrideActionBar on Midnight.
		-- Its action buttons inherit Blizzard's ActionButtonTemplate and can
		-- receive secret cooldown values through protected native dispatchers
		-- after Dominos has touched the frame family. Dominos continues to use
		-- secure override-page state on its own action buttons instead.
		return
	end

	if show then
		if originalParent then
			OverrideActionBar:SetParent(originalParent)
			originalParent = nil
		end
	elseif not originalParent then
		originalParent = OverrideActionBar:GetParent()
		OverrideActionBar:SetParent(Addon.ShadowUIParent)
	end
end

-- Returns true if the player is in a state where they should use actions
-- normally found on the override bar.
function OverrideController:OverrideBarActive()
	return (tonumber(self:GetAttribute('overridepage')) or 0) > 10
end

OverrideController:OnLoad()

Addon.OverrideController = OverrideController
