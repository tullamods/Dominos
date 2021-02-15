local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local L = LibStub('AceLocale-3.0'):GetLocale('Dominos')

local ContainerFrame = Dominos:CreateClass('Frame', Dominos.Frame)

do
	function ContainerFrame:New(id, frame, description)
		local bar = ContainerFrame.proto.New(self, id, description)

		bar.repositionedFrame = frame
		bar.description = description

		bar:Layout()

		return bar
	end

	function ContainerFrame:GetDisplayName()
		return "weapon enchant"
	end

	function ContainerFrame:GetDescription()
		return "Displays Temporary Weapon Enchantments."
	end

	function ContainerFrame:GetDefaults()
		return {
			point = 'CENTER',
			x = 90,
			y = 0,
			columns = 1,
			spacing = 2,
			showInPetBattleUI = true,
			showInOverrideUI = true,
		}
	end

	function ContainerFrame:Layout()
		local frame = self.repositionedFrame

		frame:ClearAllPoints()
		frame:SetPoint('TOPRIGHT', self)

		local pW, pH = self:GetPadding()
		self:SetSize((36 * 3) + pW, 44 + pH)
	end

	function ContainerFrame:OnCreateMenu(menu)
		local l = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

		local panel = menu:NewPanel(l.Layout)

		panel.scaleSlider = panel:NewScaleSlider()
		panel.paddingSlider = panel:NewPaddingSlider()

		menu:AddFadingPanel()
	end
end

local ContainerFrameModule = Dominos:NewModule('TempEnchants')

do
	function ContainerFrameModule:OnInitialize()
		_G.TemporaryEnchantFrame.ignoreFramePositionManager = true
	end

	function ContainerFrameModule:Load()
		self.frames = {
			ContainerFrame:New('roll', _G.TemporaryEnchantFrame)
		}
	end

	function ContainerFrameModule:Unload()
		for _, frame in pairs(self.frames) do
			frame:Free()
		end
	end
end
