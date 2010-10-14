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

	timer.Start = function(self, duration)
		self:Stop()
		a:SetDuration(duration)
		updater:Play()
	end

	timer.Stop = function(self)
		if updater:IsPlaying() then
			updater:Stop()
		end
	end

	return timer
end

local function fader_Create(parent)
	local fadeGroup = parent:CreateAnimationGroup()
	fadeGroup:SetLooping('NONE')
	fadeGroup:SetScript('OnFinished', function(self) parent:SetAlpha(self.targetAlpha) end)

	local fade = fadeGroup:CreateAnimation('Alpha')
	fade:SetSmoothing('NONE')
	fade:SetOrder(1)

	return function(targetAlpha, duration)
		if not fadeGroup:IsPlaying() then
			fadeGroup:Stop()
			fadeGroup.targetAlpha = targetAlpha
			fade:SetChange(targetAlpha - parent:GetAlpha())
			fade:SetDuration(duration)
			fadeGroup:Play()
		end
	end
end


--[[ Watch Frames For Fade Changing ]]--

local FadeWatcher = timer_Create()
do
	local watchedFrames = {}
	local DELAY, FADE_TIME = 0.12, 0.1

	local Fade = setmetatable({}, {__index = function(t, k)
		local fade = fader_Create(k)
		t[k] = fade
		return fade
	end})

	function FadeWatcher:OnFinished()
		for f in pairs(watchedFrames) do
			local expectedAlpha, currentAlpha = f:GetExpectedAlpha(), f:GetAlpha()
			if abs(expectedAlpha - currentAlpha) > 0.01 then
				Fade[f](expectedAlpha, 0.1)
			end
		end

		if next(watchedFrames) then
			self:Start(DELAY)
		end
	end

	function FadeWatcher:Add(f)
		watchedFrames[f] = true
		self:Start(DELAY)
	end

	function FadeWatcher:Remove(f)
		watchedFrames[f] = nil
	end
end

--[[ Registers Frames for Fading ]]--

Dominos.FadeManager = {
	Add = function(self, f)
		FadeWatcher:Add(f)
	end,

	Remove = function(self, f)
		FadeWatcher:Remove(f)
	end
}