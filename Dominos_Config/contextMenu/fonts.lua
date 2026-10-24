local AddonName, Addon = ...

-- wrapper around LSM in case i want to replace it with something else
-- in the future
local Fonts = {}
do
	local LSM = LibStub('LibSharedMedia-3.0')

	local fontObjects = setmetatable({}, {
		__index = function(t, k)
			local fontPath = LSM:Fetch("font", k, false)

			if fontPath then
				local fontName = ("%sFonts%s"):format(AddonName, k)
				local font = CreateFont(fontName)

				font:SetFont(fontPath, 12, "OUTLINE")

				t[k] = font

				return font
			end
		end
	})

	function Fonts:GetAll()
		return LSM:List("font")
	end

	function Fonts:GetFontObject(key)
		return fontObjects[key]
	end
end

Addon.Fonts = Fonts
