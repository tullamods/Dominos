local _, Addon = ...

local afterMidnight = Addon.IsAfterMidnight and Addon:IsAfterMidnight()
local detachedNativeActionButtons = setmetatable({}, { __mode = "k" })

local function noop()
end

local nativeActionButtonPrefixes = {
    "ActionButton",
    "MultiBarBottomLeftButton",
    "MultiBarBottomRightButton",
    "MultiBarLeftButton",
    "MultiBarRightButton",
    "MultiBar5Button",
    "MultiBar6Button",
    "MultiBar7Button"
}

local function disableNativeActionButtonDispatch(button)
    if not afterMidnight or not button or button.dominosNativeDispatchDisabled then
        return
    end

    -- Hidden native action buttons must not keep executing Blizzard's shared
    -- ActionButton_Update/UpdatePressAndHoldAction path once Dominos owns the
    -- visible bar.  Midnight can mark cooldown and action attributes as secret,
    -- and those protected updates are only safe from Blizzard's untainted path.
    button.dominosNativeOnEvent = button.OnEvent
    button.dominosNativeOnUpdate = button.OnUpdate
    button.dominosNativeUpdate = button.Update
    button.dominosNativeUpdateAction = button.UpdateAction
    button.dominosNativeUpdatePressAndHoldAction = button.UpdatePressAndHoldAction
    button.dominosNativeCheckNeedsUpdate = button.CheckNeedsUpdate
    button.dominosNativeActionButtonOnClick = button.ActionBarActionButtonDerivedMixin_OnClick

    button.OnEvent = noop
    button.OnUpdate = noop
    button.Update = noop
    button.UpdateAction = noop
    button.UpdatePressAndHoldAction = noop
    button.CheckNeedsUpdate = noop
    button.ActionBarActionButtonDerivedMixin_OnClick = noop
    button.eventsRegistered = nil
    button.needsUpdate = nil
    button.dominosNativeDispatchDisabled = true
end

local function removeFrameFromArray(frames, frame)
    if type(frames) ~= "table" then
        return
    end

    for i = #frames, 1, -1 do
        if frames[i] == frame then
            table.remove(frames, i)
        end
    end
end

local function unregisterFrame(owner, frame)
    if not owner or not frame then
        return
    end

    if type(owner.UnregisterFrame) == "function" then
        pcall(owner.UnregisterFrame, owner, frame)
    elseif type(owner.frames) == "table" then
        removeFrameFromArray(owner.frames, frame)
        owner.frames[frame] = nil
    end
end

local function unregisterActionWatcher(owner, action, frame)
    if not owner or not action or not frame or type(owner.UnregisterFrame) ~= "function" then
        return
    end

    pcall(owner.UnregisterFrame, owner, action, frame)
end

local function getButtonAction(button)
    if not button then
        return nil
    end

    if button.action then
        return button.action
    end

    if type(button.GetAttribute) == "function" then
        return button:GetAttribute("action")
    end
end

local function suppressFrameInput(frame)
    if not frame then
        return
    end

    -- Do not call Hide(), HideBase(), SetShown(), SetParent(), or protected
    -- action-button attributes here on Midnight.  Those paths can taint Blizzard's
    -- EditMode action-bar visibility controller, which later causes blocked calls
    -- such as MainActionBar:SetShownBase().  Alpha/mouse suppression keeps the
    -- stock frames visually inert while Dominos owns the visible bars.
    if type(frame.SetAlpha) == "function" then
        frame:SetAlpha(0)
    end

    if type(frame.EnableMouse) == "function" then
        frame:EnableMouse(false)
    end

    if type(frame.SetMouseClickEnabled) == "function" then
        frame:SetMouseClickEnabled(false)
    end

    if type(frame.SetMouseMotionEnabled) == "function" then
        frame:SetMouseMotionEnabled(false)
    end
end

local function detachNativeActionButton(button)
    if not button then
        return
    end

    local action = getButtonAction(button)

    -- Native action buttons are registered with shared Blizzard dispatcher frames.
    -- On Midnight, touching these hidden stock buttons from Dominos can taint them;
    -- if they remain registered, Blizzard's native OnEvent path later calls
    -- protected SetAttribute/SetCooldown with secret values and the stack blames
    -- Dominos.  Detach the hidden stock buttons from the shared dispatchers and
    -- let Dominos-created buttons own the visible/update path instead.
    --
    -- This intentionally runs every time it is requested instead of only once:
    -- Blizzard or another addon may re-register a hidden stock button after Dominos
    -- has detached it, especially when native ActionButton attributes are changed.
    unregisterFrame(ActionBarButtonEventsFrame, button)
    unregisterFrame(ActionBarActionEventsFrame, button)
    unregisterFrame(ActionBarButtonUpdateFrame, button)
    unregisterActionWatcher(ActionBarButtonRangeCheckFrame, action, button)
    unregisterActionWatcher(ActionBarButtonUsableWatcherFrame, action, button)
    disableNativeActionButtonDispatch(button)

    if not detachedNativeActionButtons[button] then
        suppressFrameInput(button)
        detachedNativeActionButtons[button] = true
    end
end

local function hideNativeActionButton(button)
    if not button then
        return
    end

    if afterMidnight then
        detachNativeActionButton(button)
        return
    end

    button:UnregisterAllEvents()
    button:SetAttributeNoHandler("statehidden", true)
    button:Hide()
end

local function detachNativeActionButtonGlobals()
    if not afterMidnight then
        return
    end

    local maxButtons = NUM_ACTIONBAR_BUTTONS or 12
    for _, prefix in ipairs(nativeActionButtonPrefixes) do
        for i = 1, maxButtons do
            hideNativeActionButton(_G[prefix .. i])
        end
    end
end

local function detachOverrideActionBarButtons()
    if not afterMidnight or not OverrideActionBar then
        return
    end

    -- The native override buttons are not stored in OverrideActionBar.actionButtons.
    -- They are SpellButton1..N parent keys with global names
    -- OverrideActionBarButton1..N, and they inherit ActionButtonTemplate. If they
    -- remain registered with Blizzard's shared action dispatchers, hidden/tainted
    -- native override buttons can still call ActionButton_UpdateCooldown() and
    -- UpdatePressAndHoldAction() with secret values from a Dominos-tainted stack.
    local maxButtons = NUM_OVERRIDE_BUTTONS or 6
    for i = 1, maxButtons do
        local button = OverrideActionBar["SpellButton" .. i] or _G["OverrideActionBarButton" .. i]
        hideNativeActionButton(button)
    end

    if type(OverrideActionBar.UnregisterAllEvents) == "function" then
        OverrideActionBar:UnregisterAllEvents()
    end

    suppressFrameInput(OverrideActionBar)
end

local function disableNativeActionBarController()
    if not ActionBarController or type(ActionBarController.UnregisterAllEvents) ~= "function" then
        return
    end

    -- Dominos provides its own secure paging/override state controller.  On
    -- Midnight, allowing Blizzard's ActionBarController to continue driving the
    -- hidden MainActionBar can re-enter protected EditMode visibility functions
    -- from a tainted stack after Dominos suppresses the stock bars.  Disabling
    -- the controller event pump prevents hidden Blizzard bars from being shown,
    -- hidden, or repaged behind Dominos.
    ActionBarController:UnregisterAllEvents()
end

local function suppressNativeActionBarFrame(frame)
    if not frame then
        return
    end

    if afterMidnight then
        suppressFrameInput(frame)
        return
    end

    (frame.HideBase or frame.Hide)(frame)
    frame:SetParent(Addon.ShadowUIParent)
end

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

local controllerDisabler
if afterMidnight then
    disableNativeActionBarController()

    -- Run once more after login/entering-world in case Blizzard has reloaded or
    -- reinitialized the controller after this file was evaluated.
    controllerDisabler = CreateFrame("Frame")
    controllerDisabler:RegisterEvent("PLAYER_LOGIN")
    controllerDisabler:RegisterEvent("PLAYER_ENTERING_WORLD")
    controllerDisabler:SetScript("OnEvent", function(self)
        disableNativeActionBarController()
        detachNativeActionButtonGlobals()
        detachOverrideActionBarButtons()
    end)
end

for _, frameName in ipairs(framesToHide) do
    local frame = _G[frameName]

    if frame then
        if (not afterMidnight) and (not keepEvents[frameName]) then
            frame:UnregisterAllEvents()
        end

        suppressNativeActionBarFrame(frame)

        if frame.actionButtons and type(frame.actionButtons) == "table" then
            for _, button in pairs(frame.actionButtons) do
                hideNativeActionButton(button)
            end

            if (not afterMidnight) and wipeActionButtons[frameName] then
                table.wipe(frame.actionButtons)
            end
        end
    else
        Addon:Printf('Could not find frame %q', frameName)
    end
end

-- Some stock buttons can be rebuilt or re-registered outside frame.actionButtons.
-- Detach by the Blizzard global button names as well so hidden native buttons do
-- not keep receiving shared ActionButton events.
detachNativeActionButtonGlobals()

-- OverrideActionBar uses SpellButton parent keys instead of actionButtons, so
-- handle it explicitly after Blizzard's regular action bars are suppressed.
detachOverrideActionBarButtons()
