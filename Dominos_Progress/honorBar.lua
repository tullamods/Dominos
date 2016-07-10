local AddonName, Addon = ...
local HonorBar = Dominos:CreateClass('Frame', Dominos.ProgressBar)

do
	HonorBar.type = 'honor'

	function HonorBar:Init()
		self:SetColor(1.0, 0.24, 0, 1)
		self:SetRestColor(1.0, 0.71, 0, 1)
		self:Update()
	end

	function HonorBar:Update()
		local value = UnitHonor('player')
		local max = UnitHonorMax('player')
		local rest = GetHonorExhaustion()

		self:SetValue(value, 0, max)
		self:SetRestValue(rest)

		if rest and rest > 0 then
			self:SetText('%s / %s (+%s)', BreakUpLargeNumbers(value), BreakUpLargeNumbers(max), BreakUpLargeNumbers(rest))
		else
			self:SetText('%s / %s', BreakUpLargeNumbers(value), BreakUpLargeNumbers(max))
		end
	end

	-- the one time i get to use my favorite feature of lua
	function HonorBar:SetToNextType()
		Addon.XPBar:Bind(self)
		self:Init()
	end
end

Addon.HonorBar = HonorBar