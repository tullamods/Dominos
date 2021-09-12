local _, Addon = ...

local DualSpec = _G.LibStub("LibDualSpec-1.0")
local options = _G.LibStub("AceDBOptions-3.0"):GetOptionsTable(Addon:GetParent().db, true)
local db = Addon:GetParent().db
DualSpec:EnhanceOptions(options, db)

Addon:AddOptionsPanelOptions("profiles", options)
