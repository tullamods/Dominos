local _, Addon = ...

if not Addon:IsBuild('retail') then
    return
end

-- move a frame to the hidden shadow UI parent, and tell Blizzard to ignore
-- it for frame positon manager purposes
local function banish(...)
    for i = 1, select('#', ...) do
        local name = select(i, ...)
        local frame = _G[name]

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
        local frame = _G[name]

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
        button:UnregisterAllEvents()
        button:SetAttribute('statehidden', true)
        button:Hide()
    else
        Addon:Printf('Action Button %q could not be found', buttonName)
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

-- disable the stock action buttons
for i = 1, NUM_ACTIONBAR_BUTTONS do
    disableActionButton(('ActionButton%d'):format(i))
    disableActionButton(('MultiBarRightButton%d'):format(i))
    disableActionButton(('MultiBarLeftButton%d'):format(i))
    disableActionButton(('MultiBarBottomRightButton%d'):format(i))
    disableActionButton(('MultiBarBottomLeftButton%d'):format(i))
end

-- disable some action bar controller updates that we probably don't need
-- ActionBarController:UnregisterEvent('UPDATE_POSSESS_BAR')