local _, Addon = ...
if not Addon:IsBuild('retail', 'cata', 'wrath') then
	return
end

local OverrideController = CreateFrame('Frame', nil, OverrideActionBar, 'SecureHandlerAttributeTemplate, SecureHandlerShowHideTemplate')

function OverrideController:OnLoad()
	self:SetAttributeNoHandler("_onattributechanged", [[
		if name == "overrideui" then
			for _, frame in pairs(myFrames) do
				frame:SetAttribute("state-overrideui", value == 1)
			end
		elseif name == "petbattleui" then
			for _, frame in pairs(myFrames) do
				frame:SetAttribute("state-petbattleui", value == 1)
			end
		elseif name == "overridepage" then
			for _, frame in pairs(myFrames) do
				frame:SetAttribute("state-overridepage", value)
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

			if self:GetAttribute("overridepage") ~= page then
				self:SetAttribute("overridepage", page)
			end
		end
	]])

	self:SetAttributeNoHandler("_onshow", [[ self:SetAttribute("overrideui", 1) ]])
	self:SetAttributeNoHandler("_onhide", [[ self:SetAttribute("overrideui", 0) ]])
	self:SetAttributeNoHandler('overrideui', OverrideActionBar:IsVisible())

	-- init
	self:Execute([[ myFrames = table.new() ]])

	for attribute, driver in pairs {
		form = '[form]1;0',
		overridebar = '[overridebar]1;0',
		possessbar = '[possessbar]1;0',
		sstemp = '[shapeshift]1;0',
		vehicle = '[@vehicle,exists]1;0',
		vehicleui = '[vehicleui]1;0',
		petbattleui = '[petbattle]1;0'
	} do
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
	self:SetFrameRef('add', frame)
	self:Execute([[ table.insert(myFrames, self:GetFrameRef('add')) ]])

	-- initialize state
	frame:SetAttribute('state-overrideui', tonumber(self:GetAttribute('overrideui')) == 1)
	frame:SetAttribute('state-petbattleui', tonumber(self:GetAttribute('petbattleui')) == 1)
	frame:SetAttribute('state-overridepage', self:GetAttribute('overridepage') or 0)
end

function OverrideController:Remove(frame)
	self:SetFrameRef('rem', frame)

	self:Execute([[
		for i, frame in pairs(myFrames) do
			if frame == self:GetFrameRef('rem') then
				table.remove(myFrames, i)
				break
			end
		end
	]])
end

local originalParent = nil
function OverrideController:SetShowOverrideUI(show)
	if show then
		if originalParent ~= nil then
			OverrideActionBar:SetParent(originalParent)
			originalParent = nil
		end
	elseif originalParent == nil then
		originalParent = OverrideActionBar:GetParent()
		OverrideActionBar:SetParent(Addon.ShadowUIParent)
	end
end

-- returns true if the player is in a state where they should be using actions
-- normally found on the override bar
function OverrideController:OverrideBarActive()
	return (self:GetAttribute("overridepage") or 0) > 10
end

OverrideController:OnLoad()

-- exports
Addon.OverrideController = OverrideController
