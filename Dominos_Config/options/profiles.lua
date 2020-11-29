local _, Addon = ...

Addon:AddOptionsPanelOptions(
    "profiles",
    _G.LibStub("AceDBOptions-3.0"):GetOptionsTable(Addon:GetParent().db, true)
)