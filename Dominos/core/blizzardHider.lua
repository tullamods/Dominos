local _, Addon = ...

local framesToHide = {
    "MainActionBar",
    "MultiBar5",
    "MultiBar6",
    "MultiBar7",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight"
}

if not Addon:IsBuild("retail") then
    framesToHide[#framesToHide + 1] = "MainMenuBar"
    framesToHide[#framesToHide + 1] = "MainMenuBarArtFrame"
end

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
        if not keepEvents[frameName] then
            frame:UnregisterAllEvents()
        end

        (frame.HideBase or frame.Hide)(frame)
        frame:SetParent(Addon.ShadowUIParent)

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
