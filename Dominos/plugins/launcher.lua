-- lancher.lua - The Dominos minimap button
local AddonName, Addon = ...
local Launcher = Addon:NewModule('Launcher')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local DBIcon = LibStub('LibDBIcon-1.0')

function Launcher:OnInitialize()
    DBIcon:Register(AddonName, self:CreateDataBrokerObject(), self:GetSettings())

    if AddonCompartmentFrame and AddonCompartmentFrame.RegisterAddon then
        AddonCompartmentFrame:RegisterAddon{
            text = AddonName,
            icon = C_AddOns.GetAddOnMetadata(AddonName, 'IconTexture'),
            -- unfortunately, func doesn't pass in what button was clicked here
            -- so we default to showing the options menu
            func = function()
                Addon:ShowOptionsFrame()
            end
        }
    end
end

function Launcher:Load()
    self:Update()
end

function Launcher:Update()
    DBIcon:Refresh(AddonName, self:GetSettings())
end

function Launcher:GetSettings()
    return Addon.db.profile.minimap
end

function Launcher:CreateDataBrokerObject()
    return LibStub('LibDataBroker-1.1'):NewDataObject(
        AddonName,
        {
            type = 'launcher',
            icon = C_AddOns.GetAddOnMetadata(AddonName, 'IconTexture'),
            OnClick = Addon.OnLaunch,
            OnTooltipShow = function(tooltip)
                if not tooltip or not tooltip.AddLine then
                    return
                end

                GameTooltip_SetTitle(tooltip, AddonName)

                if Addon:Locked() then
                    GameTooltip_AddInstructionLine(tooltip, L.ConfigEnterTip)
                else
                    GameTooltip_AddInstructionLine(tooltip, L.ConfigExitTip)
                end

                if Addon:IsBindingModeEnabled() then
                    GameTooltip_AddInstructionLine(tooltip, L.BindingExitTip)
                else
                    GameTooltip_AddInstructionLine(tooltip, L.BindingEnterTip)
                end

                if Addon:IsConfigAddonEnabled() then
                    GameTooltip_AddInstructionLine(tooltip, L.ShowOptionsTip)
                end

                if Addon:IsBuild('mists', 'cata', 'wrath') then
                    local _, _, latencyHome, latencyWorld = GetNetStats()

                    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
                    GameTooltip_AddNormalLine(tooltip, MAINMENUBAR_LATENCY_LABEL:format(latencyHome, latencyWorld))
                elseif Addon:IsBuild('classic') then
                    local _,_, latencyHome, latencyWorld = GetNetStats()
                    local latency = math.max(latencyHome, latencyWorld)

                    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)
                    GameTooltip_AddNormalLine(tooltip, ("%s %d%s"):format(MAINMENUBAR_LATENCY_LABEL, latency, MILLISECONDS_ABBR))
                end
            end
        }
    )
end
