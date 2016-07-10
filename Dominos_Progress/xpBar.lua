local AddonName, Addon = ...
local XPBar = Dominos:CreateClass('Frame', Dominos.ProgressBar)

do
	XPBar.type = 'xp'

	function XPBar:Init()
		self:SetColor(0.58, 0.0, 0.55, 1)
		self:SetRestColor(0.25, 0.25, 1, 1)
		self:Update()
	end

	function XPBar:Update()
		local value = UnitXP('player')
		local max = UnitXPMax('player')
		local rest = GetXPExhaustion()

		self:SetValue(value, 0, max)
		self:SetRestValue(rest)
		self:UpdateText(value, max, rest)
	end

	function XPBar:UpdateText(value, max, rest)
		if rest and rest > 0 then
			self:SetText('%s / %s (+%s)', BreakUpLargeNumbers(value), BreakUpLargeNumbers(max), BreakUpLargeNumbers(rest))
		else
			self:SetText('%s / %s', BreakUpLargeNumbers(value), BreakUpLargeNumbers(max))
		end
	end

	-- the one time i get to use my favorite feature of lua
	function XPBar:SetToNextType()
		Addon.ReputationBar:Bind(self)
		self:Init()
	end
end

Addon.XPBar = XPBar