local AddonName, AddonTable = ...
local Addon = LibStub('AceAddon-3.0'):NewAddon(AddonTable, AddonName, 'AceEvent-3.0', 'AceConsole-3.0')
local ParentAddonName = C_AddOns.GetAddOnDependencies(AddonName)
local ParentAddon = LibStub('AceAddon-3.0'):GetAddon(ParentAddonName)

--------------------------------------------------------------------------------
-- Interface Options Menu
--------------------------------------------------------------------------------

Addon.optionsMenuPanels = { }

function Addon:OnEnable()
    ParentAddon.callbacks:Fire('OPTIONS_MENU_LOADING', self)

    -- register ace config options
    LibStub('AceConfig-3.0'):RegisterOptionsTable(
        ParentAddonName,
        function()
            local options = {
                type = 'group',
                name = ParentAddonName,
                childGroups = "tab",
                args = {}
            }

            for _, panel in self:GetOptionsPanels() do
                if panel.options then
                    options.args[panel.key] = panel.options
                end
            end

            return options
        end
    )


    ParentAddon.callbacks:Fire('OPTIONS_MENU_LOADED', self)
end

-- shows the first options panel frame we have
function Addon:ShowPrimaryOptionsPanel()
    local dialog = LibStub('AceConfigDialog-3.0')

    dialog:Open(ParentAddonName)
    dialog:SelectGroup(ParentAddonName, self.optionsMenuPanels[1].key)
end

function Addon:AddOptionsPanelOptions(key, options)
    return table.insert(self.optionsMenuPanels, {key = key, options = options})
end

function Addon:AddOptionsPanelFrame(key, frame)
    return table.insert(self.optionsMenuPanels, {key = key, frame = frame})
end

function Addon:GetOptionsPanels()
    return ipairs(self.optionsMenuPanels)
end

--------------------------------------------------------------------------------
-- Utility Methods
--------------------------------------------------------------------------------

function Addon:GetParent()
    return ParentAddon
end

function Addon:GetLocale()
    return LibStub("AceLocale-3.0"):GetLocale(ParentAddonName .. '-Config')
end

function Addon:IsGameType(...)
    return ParentAddon:IsGameType(...)
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

ParentAddon.Options = Addon
