local AddonName, Addon = ...
local ButtonThemer = Addon:NewModule('ButtonThemer')

local theme
-- modern theming
if Addon:IsGameType('standard', "forever") then
    -- reserved for if I want to retheme buttons in Dragonflight
    theme = function(button)
        if button.SlotArt and button.SlotArt:IsShown() then
            button.SlotArt:Hide()
            button.SlotBackground:Show()
        end
    end
-- classic, post edit mode
else
    local NORMAL_TEXTURE_RATIO = Round(ActionButton1.NormalTexture:GetWidth()) / Round(ActionButton1:GetWidth())

    local function getIcon(button)
        local icon = button.icon
        if icon and icon.SetTexCoord then
            return icon
        end

        icon = button.Icon
        if icon and icon.SetTexCoord then
            return icon
        end
    end

    -- reserved for if I want to retheme buttons in Dragonflight
    theme = function(button)
        -- crop icon edges to remove borders drawn into the icon
        local icon = getIcon(button)
        if icon then
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        end

        -- resize the normal texture to fit (mostly for stance buttons)
        local nt = button.NormalTexture
        if nt then
            nt:SetSize(button:GetWidth() * NORMAL_TEXTURE_RATIO, button:GetHeight() * NORMAL_TEXTURE_RATIO)
        end
    end
end

function ButtonThemer:Unload()
    self.shouldReskin = true
end

-- masque installed, use for theming
local Masque, MasqueVersion = LibStub('Masque', true)

if Masque then
    -- masque not installed
    function ButtonThemer:Register(button, groupName, ...)
        local group = Masque:Group(AddonName, groupName)

        group:AddButton(button, ...)

        if group.db.Disabled then
            theme(button)
        end
    end

    function ButtonThemer:Unregister(button, groupName)
        local group = Masque:Group(AddonName, groupName)

        group:RemoveButton(button)

        theme(button)
    end

    -- handle differences in the masque API
    if MasqueVersion < 80100 then
        -- in older verisons, fallback to the dominos theme when disabled
        Masque:Register(
            AddonName,
            function(...)
                local _, group, _, _, _, _, disabled = ...

                if disabled then
                    for button in pairs(Masque:Group(AddonName, group).Buttons) do
                        theme(button)
                    end
                end
            end
        )

        function ButtonThemer:Reskin()
            if not self.shouldReskin then
                return
            end

            self.shouldReskin = nil

            for _, groupName in pairs(Masque:Group(AddonName).SubList) do
                Masque:Group(AddonName, groupName):ReSkin()
            end
        end
    else
        function ButtonThemer:Reskin()
            if not self.shouldReskin then
                return
            end

            self.shouldReskin = nil

            for _, group in pairs(Masque:Group(AddonName).SubList) do
                group:ReSkin()
            end
        end
    end
else
    function ButtonThemer:Register(button)
        theme(button)
    end

    function ButtonThemer:Unregister(button)
    end

    function ButtonThemer:Reskin()
    end
end
