local _, Addon = ...
local OverrideController = Addon:CreateHiddenFrame('Frame', nil, UIParent, 'SecureHandlerStateTemplate')

function OverrideController:OnLoad()
    self:SetAttribute('_onstate-possess', [[
		self:RunAttribute('updateOverridePage')
	]])

    self:SetAttribute('updateOverridePage', [[
		local newPage = GetBonusBarOffset() or 0

		self:SetAttribute('state-overridepage', newPage)
	]])

    self:Execute([[ myFrames = table.new() ]])

    RegisterStateDriver(self, 'possess', '[bonusbar:5]1;0')

	Addon.Frame:Extend("OnAcquire", function(frame) self:Add(frame); end)
	Addon.Frame:Extend("OnRelease", function(frame) self:Remove(frame); end)

    self.OnLoad = nil
end

function OverrideController:Add(frame)
    self:SetFrameRef('FrameToRegister', frame)

    self:Execute([[
		local frame = self:GetFrameRef('FrameToRegister')

		table.insert(myFrames, frame)
	]])

    -- OnLoad states
    frame:SetAttribute('state-overridepage', self:GetAttribute('state-overridepage') or 0)
end

function OverrideController:Remove(frame)
    self:SetFrameRef('FrameToUnregister', frame)

    self:Execute([[
		local frameToUnregister = self:GetFrameRef('FrameToUnregister')

		for i, frame in pairs(myFrames) do
			if frame == frameToUnregister then
				table.remove(myFrames, i)
				break
			end
		end
	]])
end

-- returns true if the player is in a state where they should be using actions
-- normally found on the override bar
function OverrideController:OverrideBarActive()
    return (self:GetAttribute('state-overridepage') or 0) > 10
end

OverrideController:OnLoad()

-- exports
Addon.OverrideController = OverrideController
