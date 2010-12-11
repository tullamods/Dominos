--[[
	a frame to update bindings to prevent craziness from happening in crazy town
--]]

local BindingsUpdater = CreateFrame('Frame')

function BindingsUpdater:OnEvent(event, ...)
	local a = self[event]
	if a then
		a(self, event, ...)
	end
end

function BindingsUpdater:UPDATE_BINDINGS(event)
	self:UpdateFrames()
	self:UnregisterEvent('UPDATE_BINDINGS')
end

function BindingsUpdater:UpdateFrames()
	for _, frame in Dominos.Frame:GetAll() do
		if frame.UPDATE_BINDINGS then
			frame:UPDATE_BINDINGS()
		end
	end
end

hooksecurefunc('SetBinding', BindingsUpdater.UpdateFrames)
hooksecurefunc('SetBindingClick', BindingsUpdater.UpdateFrames)
hooksecurefunc('SetBindingItem', BindingsUpdater.UpdateFrames)
hooksecurefunc('SetBindingMacro', BindingsUpdater.UpdateFrames)
hooksecurefunc('SetBindingSpell', BindingsUpdater.UpdateFrames)
hooksecurefunc('LoadBindings', BindingsUpdater.UpdateFrames)