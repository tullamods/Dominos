local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local CastBarModule = Dominos:NewModule('CastBar')

local bar

function CastBarModule:Load()
    bar = Addon.CastBar:New('cast', { 'player', 'vehicle' })
end

function CastBarModule:Unload()
    if bar then
        bar:Free()
        bar = nil
    end
end

function CastBarModule:OnFirstLoad()
    Addon:UpgradeSettings()

    for _, frame in pairs { CastingBarFrame, PlayerCastingBarFrame, PetCastingBarFrame } do
        if frame then
            frame:UnregisterAllEvents()
            frame.ignoreFramePositionManager = true
            frame:SetParent(Dominos.ShadowUIParent)
        end
    end

    LibStub('LibSharedMedia-3.0').RegisterCallback(self, 'LibSharedMedia_Registered')
end

function CastBarModule:LibSharedMedia_Registered(event, mediaType, key)
    if bar then
        bar:OnMediaRegistered(mediaType, key)
    end
end