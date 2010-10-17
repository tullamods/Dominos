--[[
	fadeManager.lua
		Handles fading out frames when not moused over
		Necessary since using the blizzard fading functions can cause issues in combat
--]]


--[[ Animation Timer ]]--

local function timer_Create()
	local timer = CreateFrame('Frame')

	local updater = timer:CreateAnimationGroup()
	updater:SetLooping('NONE')
	updater:SetScript('OnFinished', function(self)
		if timer.OnFinished then
			timer:OnFinished()
		end
	end)

	local a = updater:CreateAnimation('Animation'); a:SetOrder(1)
	timer.updater = updater

	timer.Start = function(self)
		self:Stop()
		a:SetDuration(self.duration)
		updater:Play()
	end

	timer.Stop = function(self)
		if updater:IsPlaying() then
			updater:Stop()
		end
	end

	timer.IsPlaying = function(self)
		return updater:IsPlaying()
	end

	return timer
end

--[[ Code to watch frames as they're moused over ]]--

local MouseOverWatcher = timer_Create()
local watched = {}

MouseOverWatcher.duration = 0.15

function MouseOverWatcher:OnFinished()
	for f in pairs(watched) do
		local isFocus = f:IsFocus()
		if f.header:GetAttribute('state-mouseover') then
			if not isFocus then
				f.header:SetAttribute('state-mouseover', isFocus)
			end
		else
			if isFocus then
				f.header:SetAttribute('state-mouseover', isFocus)
			end
		end
	end

	if next(watched) then
		self:Start()
	end
end

function MouseOverWatcher:Add(f)
	watched[f] = true
	f.header:SetAttribute('state-mouseover', f:IsFocus() and true or nil)

	if not self:IsPlaying() then
		self:Start()
	end
end

function MouseOverWatcher:Remove(f)
	watched[f] = nil
	f.header:SetAttribute('state-mouseover', nil)
end

Dominos.MouseOverWatcher = MouseOverWatcher