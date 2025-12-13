local _, Addon = ...

local framesToHide = {
    "MainMenuBar",
    "MainActionBar",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight",
    "StanceBar",
    "MainMenuBarVehicleLeaveButton",
    "MainMenuBarArtFrame"
}

local keepEvents = {
    MainActionBar = true
}

local wipeActionButtons = {
    MultiBar5 = true,
    MultiBar6 = true,
    MultiBar7 = true,
    MultiBarBottomLeft = true,
    MultiBarBottomRight = true,
    MultiBarLeft = true,
    MultiBarRight = true
}

for _, frameName in ipairs(framesToHide) do
    local frame = _G[frameName]

    if frame then
        (frame.HideBase or frame.Hide)(frame)
        frame:SetParent(Addon.ShadowUIParent)

        if not keepEvents[frameName] then
            frame:UnregisterAllEvents()
        end

        if frame.actionButtons and type(frame.actionButtons) == "table" then
            for _, button in pairs(frame.actionButtons) do
                button:UnregisterAllEvents()
                button:SetAttributeNoHandler("statehidden", true)
                button:Hide()
            end

            if wipeActionButtons[frameName] then
                table.wipe(frame.actionButtons)
            end
        end
    else
        Addon:Printf('Could not find frame %q', frameName)
    end
end
