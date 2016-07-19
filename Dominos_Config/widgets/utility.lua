local AddonName, Addon = ...
local Dominos = _G.Dominos

function Addon:CreateClass(...)
	return Dominos:CreateClass(...)
end

-- returns a function that generates unique names for frames
-- in the format <AddonName>_<Prefix>[1, 2, ...]
function Addon:CreateNameGenerator(prefix)
	local id = 0
	return function()
		id = id + 1
		return ('%s_%s_%d'):format('DominosOptions', prefix, id)
	end
end

-- a thing to manage rendering stuff on the next frame
-- will probably push into Dominos since its generally useful
do
	local subscribers = {}	
	local renderer = CreateFrame('Frame'); renderer:Hide()
	
	renderer:SetScript('OnUpdate', function(self)
		while next(subscribers) do
			table.remove(subscribers):OnRender()
		end
		
		self:Hide()
	end)
	
	function Addon:Render(frame)
		for i, f in pairs(subscribers) do
			if f == frame then
				return false
			end
		end
		
		table.insert(subscribers, 1, frame)				
		renderer:Show()
		return true
	end
end

Dominos.Options = Addon