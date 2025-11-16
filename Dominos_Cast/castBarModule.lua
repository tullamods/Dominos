local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")
local CastBarModule = Dominos:NewModule("CastBar")

function CastBarModule:Load()
    self.frame = Addon.CastBar:New("cast", {"player", "vehicle"})
end

function CastBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function CastBarModule:OnFirstLoad()
    for _, frame in pairs { CastingBarFrame, PlayerCastingBarFrame, PetCastingBarFrame } do
        if frame then
            frame:UnregisterAllEvents()
            frame.ignoreFramePositionManager = true
            frame:SetParent(Dominos.ShadowUIParent)
        end
    end
end