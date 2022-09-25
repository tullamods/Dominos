local _, Addon = ...

if not Addon:IsBuild('retail') then
    return
end

-- move a frame to the hidden shadow UI parent, and tell Blizzard to ignore
-- it for frame positon manager purposes
local function banish(...)
    for i = 1, select('#', ...) do
        local name = select(i, ...)
        local frame =_G[name]

        if frame then
            frame:Hide()
            frame:SetParent(Addon.ShadowUIParent)

            -- tells UIParent to ignore this frame
            frame.ignoreFramePositionManager = true

            -- With 8.2 and later there's more restrictions on frame anchoring
            -- if something happens to be attached to a restricted frame. This
            -- causes issues with moving the action bars around, so we perform a
            -- clear all points to avoid some frame dependency issues. We then
            -- follow it up with a SetPoint to handle the cases of bits of the
            -- UI code assuming that this element has a position.
            frame:ClearAllPoints()
            frame:SetPoint('CENTER')
        else
            Addon:Printf('Could not find frame %q', name)
        end
    end
end

local function unregisterEvents(...)
    for i = 1, select('#', ...) do
        local name = select(i, ...)
        local frame =_G[name]

        if frame then
            frame:UnregisterAllEvents()
        else
            Addon:Printf('Could not find frame %q', name)
        end
    end
end

local function disableActionButton(buttonName)
    local button = _G[buttonName]
    if button then
        button:SetAttribute('statehidden', true)
        button:Hide()

        if button.RightDivider then
            button.RightDivider:SetAlpha(0)
        end

        if button.BottomDivider then
            button.BottomDivider:SetAlpha(0)
        end

        if button.SlotArt then
            button.SlotArt:SetAlpha(0)
        end

        if button.SlotBackground then
            button.SlotBackground:SetAlpha(0)
        end
    else
        Addon:Printf('Action Button %q could not be found', buttonName)
    end
end

-- disables override bar transition animations
local function disableSlideOutAnimations(frameName)
    local frame = _G[frameName]

    if not frame then
        Addon:Printf('Could not find frame %q', frameName)
        return
    end

    if not frame.slideOut then
        Addon:Printf('%q has no sldie out animdations to hide', frameName)
        return
    end

    local animation = (frame.slideOut:GetAnimations())
    if animation then
        animation:SetOffset(0, 0)
    end
end

banish(
    "MainMenuBar",
    "MicroButtonAndBagsBar",
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight"
)

unregisterEvents(
    "MultiBarBottomLeft",
    "MultiBarBottomRight",
    "MultiBarLeft",
    "MultiBarRight"
)

disableSlideOutAnimations("OverrideActionBar")

-- we don't completely disable the main menu bar, as there's some logic
-- dependent on it being visible
if MainMenuBar then
    -- the main menu bar is responsible for updating the micro buttons
    -- so we don't disable all events for it
	MainMenuBar:UnregisterEvent("ACTIONBAR_PAGE_CHANGED")
	MainMenuBar:UnregisterEvent("NEUTRAL_FACTION_SELECT_RESULT")
end

-- unregister and hide, but don't reparent the StatusTrackingBarManager to
-- prevent some tainting issues
if StatusTrackingBarManager then
    StatusTrackingBarManager:UnregisterAllEvents()
    StatusTrackingBarManager:Hide()
end

-- set the stock action buttons to hidden by default
for id = 1, NUM_ACTIONBAR_BUTTONS do
    disableActionButton(('ActionButton%d'):format(id))
    disableActionButton(('MultiBarRightButton%d'):format(id))
    disableActionButton(('MultiBarLeftButton%d'):format(id))
    disableActionButton(('MultiBarBottomRightButton%d'):format(id))
    disableActionButton(('MultiBarBottomLeftButton%d'):format(id))
end
