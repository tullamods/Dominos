local _, Addon = ...

local DualSpec = _G.LibStub("LibDualSpec-1.0")
local db = Addon:GetParent().db
local options = _G.LibStub("AceDBOptions-3.0"):GetOptionsTable(db, true)
DualSpec:EnhanceOptions(options, db)

Addon:AddOptionsPanelOptions("profiles", options)
