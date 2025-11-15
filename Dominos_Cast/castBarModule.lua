if select(4, GetBuildInfo()) >= 120000 then return end

local _, Addon = ...
local Dominos = LibStub("AceAddon-3.0"):GetAddon("Dominos")

local function disableFrame(name)
    local frame = _G[name]
    if frame then
        frame:UnregisterAllEvents()
        frame.ignoreFramePositionManager = true
        frame:SetParent(Dominos.ShadowUIParent)
    end
end

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
    disableFrame("CastingBarFrame")
    disableFrame("PlayerCastingBarFrame")
    disableFrame("PetCastingBarFrame")
end