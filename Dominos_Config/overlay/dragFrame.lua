--[[Drag Frame
    Allows users to move around bars in configuration mode and access bar
    specific settings

    Bar Settings: Right Mouse Click or place mouse over frame and press "SPACE"

    Mouse Move:
         Click and hold, move the mouse to move bar. Release mouse to stop dragging.

    Keyboard Move(nudge):
         Place mouse over bar, then press a movement key.
         One press for a single nudge, press and hold for repeated nudge
         nudge amount may be adjusted by pressing and holding a modifier key (shift, ctrl, alt)
         pressing "TAB" will switch focus to other dragFrames that are under the cursor and blocked by current dragFrame.
         pressing "TAB" while current dragFrame's menu is open, will also close the current dragframe's menu and open the next dragFrame's menu
--]]

local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(Addon:GetParent():GetName())

local DragFrame = {}

DragFrame.__index = DragFrame

-- yay bitflags
local function HasFlag(state, flag)
    return bit.band(state, flag) == flag
end

local DRAG_FRAME_STATE = {
    DEFAULT = 0,           -- default state
    HIDDEN = 1,            -- a bar that's hidden
    FOCUSED = 2,           -- a bar that's currently in focus
    ANCHORED = 4,          -- a bar docked to another bar
    PREVIEW = 8,           -- a bar in preview mode, so we want to see what the bar will look like
    KEYBOARD_MOVEMENT = 16 -- a bar we've started moving via the keyboard
}

DragFrame.state = DRAG_FRAME_STATE.DEFAULT

-- drag frame levels
local FRAME_STRATA_LEVELS = {
    BACKGROUND = 1000,
    LOW = 2000,
    MEDIUM = 3000,
    HIGH = 4000,
    FOCUSED = 5000
}

-- drag frame background settings
local BACKGROUND_OPACITY = 0.5

local BACKGROUND_COLORS = {
    -- #114079
    [DRAG_FRAME_STATE.DEFAULT] = CreateColor(0.067, 0.251, 0.475, BACKGROUND_OPACITY),

    -- #071c34
    [DRAG_FRAME_STATE.ANCHORED] = CreateColor(0.027, 0.11, 0.204, BACKGROUND_OPACITY),

    -- #292f31
    [DRAG_FRAME_STATE.HIDDEN] = CreateColor(0.161, 0.184, 0.192, BACKGROUND_OPACITY),

    -- #121415
    [DRAG_FRAME_STATE.HIDDEN + DRAG_FRAME_STATE.ANCHORED] = CreateColor(0.071, 0.078, 0.082, BACKGROUND_OPACITY),

    -- transparent
    [DRAG_FRAME_STATE.PREVIEW] = CreateColor(0, 0, 0, 0),
}

-- apply fallback background colors
setmetatable(BACKGROUND_COLORS, {
    __index = function(t, k)
        -- previewing
        if HasFlag(k, DRAG_FRAME_STATE.PREVIEW) then
            return t[DRAG_FRAME_STATE.PREVIEW]
        end

        -- hidden + anchored
        if HasFlag(k, DRAG_FRAME_STATE.HIDDEN + DRAG_FRAME_STATE.ANCHORED) then
            return t[DRAG_FRAME_STATE.HIDDEN + DRAG_FRAME_STATE.ANCHORED]
        end

        -- hidden
        if HasFlag(k, DRAG_FRAME_STATE.HIDDEN) then
            return t[DRAG_FRAME_STATE.HIDDEN]
        end

        -- anchored
        if HasFlag(k, DRAG_FRAME_STATE.ANCHORED) then
            return t[DRAG_FRAME_STATE.ANCHORED]
        end

        -- otherwise use the default color
        return t[DRAG_FRAME_STATE.DEFAULT]
    end
})

-- drag frame border settings
local BORDER_THICKNESS = 2

local BORDER_OPACITY = 0.8

local BORDER_COLORS = {
    -- #117479
    [DRAG_FRAME_STATE.DEFAULT] = CreateColor(0.067, 0.455, 0.475, BACKGROUND_OPACITY),

    -- #1ab4bc
    [DRAG_FRAME_STATE.FOCUSED] = CreateColor(0.102, 0.706, 0.737, BORDER_OPACITY)
}

-- apply fallback border colors
setmetatable(BORDER_COLORS, {
    __index = function(t, k)
        -- use the focused color if we have it
        if HasFlag(k, DRAG_FRAME_STATE.FOCUSED) then
            return t[DRAG_FRAME_STATE.FOCUSED]
        end

        -- otherwise use the default color
        return t[DRAG_FRAME_STATE.DEFAULT]
    end
})

-- other settings
local KEYBOARD_MOVEMENT_INCREMENT = 1
local OPACITY_INCREMENT = 0.05

--------------------------------------------------------------------------------
-- Fonts
--------------------------------------------------------------------------------

local DragFrameLabelFont = CreateFont(AddonName .. 'DragFrameFont')

DragFrameLabelFont:CopyFontObject('GameFontNormal')
DragFrameLabelFont:SetJustifyH('CENTER')
DragFrameLabelFont:SetJustifyV('CENTER')

local DragFrameLabelHighlightFont = CreateFont(AddonName .. 'DragFrameHighlightFont')

DragFrameLabelHighlightFont:CopyFontObject(DragFrameLabelFont)
DragFrameLabelHighlightFont:SetTextColor(HIGHLIGHT_FONT_COLOR:GetRGBA())

local DragFrameTextFont = CreateFont(AddonName .. 'DragFrameContentFont')
DragFrameTextFont:CopyFontObject('GameFontNormal')
DragFrameTextFont:SetJustifyH('CENTER')
DragFrameTextFont:SetJustifyV('CENTER')

--------------------------------------------------------------------------------
-- Events
--------------------------------------------------------------------------------
local dragFrames = {}

function DragFrame:Create(parent)
    local frame = setmetatable({ }, DragFrame)
    frame:OnLoad(parent)
    if not tContains(dragFrames, frame) then
        tinsert(dragFrames, frame)
    end
    return frame
end

local highestLevel = 0

function DragFrame:OnLoad(parent)
    -- create the frame
    self.frame= CreateFrame('Button', nil, UIParent)
    self.frame:Hide()
    self.frame:SetToplevel(true) -- Sets whether the frame should raise itself when clicked
    self.frame:EnableKeyboard(false) --true or false this to enable or disable keyboard movement.
    self.frame:SetFrameStrata('DIALOG')
    self.frame:SetFixedFrameStrata(true)
    self.frame:RegisterForClicks('AnyUp')
    self.frame:RegisterForDrag('LeftButton')

    self.frame:SetHighlightFontObject(DragFrameLabelHighlightFont)
    self.frame:SetNormalFontObject(DragFrameLabelFont)
    self.frame:SetText("LABEL")

    --keyboard input is now enabled OnEnter and disabled OnLeave.
    --There is also a fall back check at the beginning of OnKeyDown
    --to verify if mouse is still over frame, if not, will disable key input
    self.frame:SetScript("OnMouseWheel", function(_, delta) self:OnMouseWheel(delta) end)
    self.frame:SetScript("OnMouseDown", function(_, button) self:OnMouseDown(button) end)
    self.frame:SetScript("OnClick", function(_, button) self:OnClick(button) end)
    self.frame:SetScript('OnKeyDown', function(_, key) self:OnKeyDown(key) end)
    self.frame:SetScript('OnKeyUp', function(_, key) self:OnKeyUp(key) end)
    self.frame:SetScript("OnMouseUp", function() self:OnMouseUp() end)

    self.frame.UpdateTooltip = function() self:UpdateTooltip() end
    self.frame:SetScript("OnEnter", function() self:OnEnter() end)
    self.frame:SetScript("OnLeave", function() self:OnLeave() end)

    -- add a label
    self.label = self.frame:GetFontString()
    self.label:SetPoint('TOPLEFT', BORDER_THICKNESS * 2, -BORDER_THICKNESS * 2)
    self.label:SetPoint('BOTTOMRIGHT', -BORDER_THICKNESS * 2, BORDER_THICKNESS * 2)

    -- contextual text
    self.text = self.frame:CreateFontString(nil, 'OVERLAY', 2)
    self.text:SetFontObject(DragFrameTextFont)
    self.text:SetPoint('CENTER')
    self.text:Hide()

    -- contextual text background (to make it easier to see)
    self.textBg = self.frame:CreateTexture(nil, 'OVERLAY', 1)
    self.textBg:SetPoint('TOPLEFT', self.text, 'TOPLEFT', -BORDER_THICKNESS * 2, BORDER_THICKNESS * 2)
    self.textBg:SetPoint('BOTTOMRIGHT', self.text, 'BOTTOMRIGHT', BORDER_THICKNESS * 2, -BORDER_THICKNESS * 2)
    self.textBg:SetColorTexture(0, 0, 0, 0.6)
    self.textBg:Hide()

    -- add a background
    self.bg = self.frame:CreateTexture(nil, 'BACKGROUND', 1)
    self.bg:SetPoint('TOPLEFT', BORDER_THICKNESS, -BORDER_THICKNESS)
    self.bg:SetPoint('BOTTOMRIGHT', -BORDER_THICKNESS, BORDER_THICKNESS)
    self.bg:SetColorTexture(BACKGROUND_COLORS[self.state]:GetRGBA())

    -- add a border
    self.borderTop = self.frame:CreateTexture(nil, 'BACKGROUND', 2)
    self.borderTop:SetColorTexture(BORDER_COLORS[self.state]:GetRGBA())
    self.borderTop:SetPoint("TOPLEFT")
    self.borderTop:SetPoint("TOPRIGHT")
    self.borderTop:SetHeight(BORDER_THICKNESS)

    self.borderLeft = self.frame:CreateTexture(nil, 'BACKGROUND', 2)
    self.borderLeft:SetColorTexture(BORDER_COLORS[self.state]:GetRGBA())
    self.borderLeft:SetPoint("TOPLEFT", 0, -BORDER_THICKNESS)
    self.borderLeft:SetPoint("BOTTOMLEFT", 0, BORDER_THICKNESS)
    self.borderLeft:SetWidth(BORDER_THICKNESS)

    self.borderBottom = self.frame:CreateTexture(nil, 'BACKGROUND', 2)
    self.borderBottom:SetColorTexture(BORDER_COLORS[self.state]:GetRGBA())
    self.borderBottom:SetPoint("BOTTOMLEFT")
    self.borderBottom:SetPoint("BOTTOMRIGHT")
    self.borderBottom:SetHeight(BORDER_THICKNESS)

    self.borderRight = self.frame:CreateTexture(nil, 'BACKGROUND', 2)
    self.borderRight:SetColorTexture(BORDER_COLORS[self.state]:GetRGBA())
    self.borderRight:SetPoint("TOPRIGHT", 0, -BORDER_THICKNESS)
    self.borderRight:SetPoint("BOTTOMRIGHT", 0, BORDER_THICKNESS)
    self.borderRight:SetWidth(BORDER_THICKNESS)
end

function DragFrame:OnClick(button)
    if button == 'RightButton' then
        if IsModifierKeyDown() then
            self:SetOwnerShown(not self:IsOwnerShown())
        else
            self:ShowOwnerContextMenu()
        end
    elseif button == 'MiddleButton' then
        self:SetOwnerShown(not self:IsOwnerShown())
    end

    self:UpdateState()
end

function DragFrame:OnEnter()

    self:AddState(DRAG_FRAME_STATE.FOCUSED)

    GameTooltip:SetOwner(self.frame, 'ANCHOR_LEFT')

    self:UpdateTooltip()

    self.frame:EnableKeyboard(true) -- enable keyboard input.
end

function DragFrame:OnLeave()
    self:RemoveState(DRAG_FRAME_STATE.FOCUSED)

    if GameTooltip:GetOwner() == self.frame then
        GameTooltip:Hide()
    end

    self.frame:EnableKeyboard(false) -- disable keyboard input.
end

local function IsKeyInSet(key, ...)--no longer needed.
    for i = 1, select('#', ...) do
        if key == (select(i, ...)) then
            return true
        end
    end
end

local binds = {
    MOVEFORWARD = "0,1", --not sure if this is cheaper than using 4 tables...
    TURNLEFT = "-1,0",
    MOVEBACKWARD = "0,-1",
    TURNRIGHT = "1,0",
}

local nudgeMachine = CreateFrame("Frame")
--I had thought Dominos had a unified "OnUpdate", for anything that needs run OnUpdate... not finding it now. ~Goranaws
local nudging = {}

function nudgeMachine:Activate(frame)
    local dragFrame = frame
    if not nudgeMachine:GetScript("OnUpdate") then
        local t = GetTime()
        nudgeMachine:SetScript("OnUpdate", function()
            local _t = GetTime()
            local reset = _t - t
            for i, key in pairs(nudging) do
                local action = GetBindingAction(key)
                local direction = action and binds[action]
                local x, y = string.split(",", direction)
                if reset >= .25 then --nudge no more than every quarter second.
                    local increment = IsShiftKeyDown() == true and .1
                                   or IsControlKeyDown() == true and 5
                                   or IsAltKeyDown() == true and 10
                                   or KEYBOARD_MOVEMENT_INCREMENT
                    dragFrame:NudgeFrame(tonumber(x) * increment, tonumber(y) * increment)
                end
            end
            if reset >= .25 then
                --cannot be done above. Otherwise, might skip a nudge direction if reset in middle of parsing.
                t = GetTime()
            end
            dragFrame:StopActiveNudge() --stop nudging if frame moves from under cursor.
        end)
    end
end

function nudgeMachine:Deactivate()
    nudgeMachine:SetScript("OnUpdate", nil)
end

local prevDragFrame
function DragFrame:StartActiveNudge(key)
    if prevDragFrame and prevDragFrame ~= self then
        prevDragFrame:StopActiveNudge(true) --extreme edge case: a second frame calls this function while another is running it.
    end
    local action = GetBindingAction(key)
    if action and binds[action] then
        if not tContains(nudging, key) then
            tinsert(nudging, key)
        end
        nudgeMachine:Activate(self)
    end
    prevDragFrame = self
end

function DragFrame:StopActiveNudge(key)
    if key == true then
        wipe(nudging)
    else
        local _ = key and tDeleteItem(nudging, key)
    end
    local isOver = (self.frame and MouseIsOver(self.frame)) and true or nil
    if (not isOver) or (#nudging == 0) then
        nudgeMachine:Deactivate()
    end
end

--[[
    previously, this function was to be called by all Dominos' frames
    on every key press. Having this enable "OnEnter" and disable
    "OnLeave",should help reduce memory usage.(even slightly is a good thing)
--]]
function DragFrame:OnKeyDown(key)
    local keyNotUsed = true --key has not been used
    if self:OnKeyUp() == true then
        keyNotUsed = true
    elseif key == "SPACE" then
        --toggle display of options
        if self.owner.menu and self.owner.menu:IsShown() then
            self.owner.menu:Hide()
        else
            self:OnClick("RightButton")
        end

        keyNotUsed = false
    elseif key == "TAB" then
        -- shift focus to other dragFrames under cursor
        self:OnTabPressed()

        keyNotUsed = false
    else
        local action = GetBindingAction(key) --what is this key's binding set to?
        if self:HasState(DRAG_FRAME_STATE.FOCUSED) and binds[action] then --is the mouse over the frame, and is this a movement key?
            local increment = IsShiftKeyDown() == true and .1 --smaller adjustments for moar precisions! ~Goranaws
                         or IsControlKeyDown() == true and  5 --adjustment steps!
                         or IsAltKeyDown()     == true and 10
                         or KEYBOARD_MOVEMENT_INCREMENT --an amount the frame will move.

            local x, y = string.split(",", binds[action]) --split movement up; could use table, and then us unpack(binds[action])

            self:NudgeFrame(tonumber(x) * increment, tonumber(y) * increment) --nudge the frame in the indicated direction by the increment amount.

            keyNotUsed = false --key has been used, don't pass it on.

            self:StartActiveNudge(key)
        end
    end
    self.frame:SetPropagateKeyboardInput(keyNotUsed) --pass or don't pass on key press to next frame with keyboard input enabled
end

function DragFrame:OnKeyUp(key)
    self:StopActiveNudge(key)

    if MouseIsOver(self.frame) ~= true then
        self:OnLeave()
        return true
    end
end

local strata = {--ALL stratas must be included for proper calculations
    "BACKGROUND",        --1
    "LOW",               --2
    "MEDIUM",            --3
    "HIGH",              --4
    "DIALOG",            --5
    "FULLSCREEN",        --6
    "FULLSCREEN_DIALOG", --7
    "TOOLTIP",           --8
}

local function GetFrameZAxis(frame)
    frame = frame.owner or frame
    local layer = tIndexOf(strata, frame:GetFrameStrata())
    local level = frame:GetFrameLevel() / 10000 -- GetFrameLevel can only return between 1 and 10000
    return layer + level
end

local function SetFrameZAxis(frame, value) --tada! ~Goranaws
    frame = frame.owner or frame
    frame:SetFrameStrata(strata[floor(value)])
    frame:GetFrameLevel((value - floor(value)) * 10000)
end

local tabFrames = {}

function DragFrame:OnTabPressed()
    wipe(tabFrames) --clean before you use it.

    for j, otherFrame in pairs(dragFrames) do
        --
        if MouseIsOver(otherFrame.frame) then
            tinsert(tabFrames, otherFrame)
        end
    end

    if #tabFrames > 0 then
        local _min, _max = 1, #tabFrames

        --sort by frame layer and level
        local sort = function(a, b) return (a and b) and GetFrameZAxis(a) >= GetFrameZAxis(b) end
        table.sort(tabFrames, sort)

        local currentIndex = tIndexOf(tabFrames, self) or 1

        local _next = currentIndex + 1
        if _next > _max then
            _next = _min
        end

        local nextFocus = tabFrames[_next]
        local _ = nextFocus and nextFocus:OnEnter()
        if nextFocus then
            self:RemoveState(DRAG_FRAME_STATE.FOCUSED)
            self.frame:EnableKeyboard(false) -- disable keyboard input for current frame.
            if self.owner.menu and self.owner.menu:IsShown() then
                self.owner.menu:Hide()
                nextFocus:OnClick("RightButton")
                nextFocus.owner.menu:Show()
            end

            self.frame:Lower()
            nextFocus.frame:Raise()
        end
    end
end

function DragFrame:OnMouseDown(button)
    if button == 'LeftButton' then
        self:SetMoving(true)
    end
end

function DragFrame:OnMouseUp()
    self:SetMoving(false)
end

function DragFrame:OnMouseWheel(delta)
    self:IncrementOpacity(delta)
end

function DragFrame:OnMovingChanged(isMoving)
    local owner = self.owner
    if not owner then
        return
    end

    if isMoving then
        owner:StartMoving()
    else
        owner:StopMovingOrSizing()
        owner:Stick()
    end
end

function DragFrame:OnOwnerChanged(owner)
    if not owner then
        self.frame:Hide()
        return
    end

    self:UpdateState()

    -- attach to frame
    self.frame:ClearAllPoints()
    self.frame:SetAllPoints(owner)

    -- update label
    self.label:SetText(owner:GetDisplayName())

    -- show
    self.frame:Show()
  
    --not sure this is needed now. as drag frames are focused, they now change levels to be on top of other dragFrames.
    --dragFrame strata is now also locked to "DIALOG"
    self.frame:SetFrameLevel(DRAG_FRAME_LEVELS[owner:GetDisplayLevel() or 'LOW'])
  
    self:UpdateFrameLevel()
end

function DragFrame:OnStateChanged(state)
    self.bg:SetColorTexture(BACKGROUND_COLORS[state]:GetRGBA())
    self.borderBottom:SetColorTexture(BORDER_COLORS[state]:GetRGBA())
    self.borderLeft:SetColorTexture(BORDER_COLORS[state]:GetRGBA())
    self.borderRight:SetColorTexture(BORDER_COLORS[state]:GetRGBA())
    self.borderTop:SetColorTexture(BORDER_COLORS[state]:GetRGBA())
    self:UpdateFrameLevel()
end

function DragFrame:OnContextMenuShown()
    self:ShowPreview()
end

function DragFrame:OnContextMenuHidden()
    self:HidePreview()
end

--------------------------------------------------------------------------------
-- Methods
--------------------------------------------------------------------------------

function DragFrame:SetOwner(owner)
    local oldOwner = self.owner
    if oldOwner ~= owner then
        self.owner = owner
        self:OnOwnerChanged(owner)
    end
end

function DragFrame:SetMoving(isMoving)
    isMoving = isMoving and true or false

    local wasMoving = self.isMoving and true or false

    if wasMoving ~= isMoving then
        self.isMoving = isMoving
        self:OnMovingChanged(isMoving)
    end
end

function DragFrame:AddState(value)
    local oldState = self.state
    local newState = bit.bor(self.state, value)

    if oldState ~= newState then
        self.state = newState
        self:OnStateChanged(newState)
    end
end

function DragFrame:RemoveState(value)
    local oldState = self.state
    local newState = bit.band(self.state, bit.bnot(value))

    if oldState ~= newState then
        self.state = newState
        self:OnStateChanged(newState)
    end
end

function DragFrame:ClearState()
    local oldState = self.state
    local newState = 0

    if oldState ~= newState then
        self.state = newState
        self:OnStateChanged(newState)
    end
end

function DragFrame:HasState(value)
    return HasFlag(self.state, value)
end

function DragFrame:UpdateState()
    if not self.owner then
        self:ClearState()
        return
    end

    if self.owner:IsAnchored() then
        self:AddState(DRAG_FRAME_STATE.ANCHORED)
    else
        self:RemoveState(DRAG_FRAME_STATE.ANCHORED)
    end

    if not self:IsOwnerShown() then
        self:AddState(DRAG_FRAME_STATE.HIDDEN)
    else
        self:RemoveState(DRAG_FRAME_STATE.HIDDEN)
    end
end

function DragFrame:UpdateTooltip()
    local tooltip = _G.GameTooltip

    GameTooltip_SetTitle(tooltip, ('%s %s(%s)%s'):format(self.owner:GetDisplayName(), NORMAL_FONT_COLOR_CODE, self.owner.id, FONT_COLOR_CODE_CLOSE))

    local description = self.owner:GetDescription()
    if description then
        GameTooltip_AddNormalLine(tooltip, description)
    end

    GameTooltip_AddBlankLinesToTooltip(tooltip, 1)

    GameTooltip_AddInstructionLine(tooltip, L.ShowConfig)

    if self:IsOwnerShown() then
        GameTooltip_AddInstructionLine(tooltip, L.HideBar)
    else
        GameTooltip_AddInstructionLine(tooltip, L.ShowBar)
    end

    GameTooltip_AddInstructionLine(tooltip, L.SetAlpha:format(Round(self.owner:GetFrameAlpha() * 100)))

    GameTooltip_AddInstructionLine(tooltip, L.KeyboardMovementTip)

    tooltip:Show()
end

-- visibility
function DragFrame:SetOwnerShown(isShown)
    if not self.owner then
        return
    end

    if isShown then
        self.owner:ShowFrame()
        self:ShowTemporaryText(0.5, L.Shown)
    else
        self.owner:HideFrame()
        self:ShowTemporaryText(0.5, L.Hidden)
    end
end

function DragFrame:IsOwnerShown()
    return self.owner and self.owner:FrameIsShown()
end

-- opacity
function DragFrame:SetOwnerOpacity(opacity)
    if not self.owner then
        return
    end

    self.owner:SetFrameAlpha(opacity)
    self:ShowTemporaryText(0.5, "%s %s", FormatPercentage(opacity, true), OPACITY)
    self:ShowTemporaryPreview(0.5)
end

function DragFrame:GetOwnerOpacity()
    if self.owner then
        return self.owner:GetFrameAlpha()
    end
    return 1
end

function DragFrame:IncrementOpacity(direction)
    if not self.owner then
        return
    end

    local delta = OPACITY_INCREMENT * direction
    local newOpacity = Clamp(self:GetOwnerOpacity() + delta, 0, 1)

    self:SetOwnerOpacity(newOpacity)
end

-- position
function DragFrame:NudgeFrame(dx, dy)
    local ox, oy, ow, oh = self.owner:GetRect()
    local _, _, pw, ph = self.owner:GetParent():GetRect()
    local x = Clamp((ox + dx), 0, pw - ow) --rounding prevents .1 micro adjustements
    local y = Clamp((oy + dy), 0, ph - oh)

    self.owner:ClearSavedAnchor()
    self.owner:ClearAllPoints()
    self.owner:SetPoint("BOTTOMLEFT", x, y)
    self.owner:SaveRelativePostiion()
    self.owner:RestorePosition()

    self:ShowTemporaryText(0.5, "(%d, %d)", self.owner:GetRect())
end

-- preview
function DragFrame:ShowTemporaryText(duration, text, ...)
    if select("#", ...) > 0 then
        self.text:SetFormattedText(text, ...)
    else
        self.text:SetText(text)
    end

    self.label:Hide()
    self.text:Show()
    self.textBg:Show()

    self._tempTextEndTime = GetTime() + duration

    if not self._hideTempText then
        self._hideTempText = function()
            if self._tempTextEndTime and self._tempTextEndTime <= GetTime() then
                self.text:Hide()
                self.textBg:Hide()
                self.label:Show()
            end
        end
    end

    _G.C_Timer.After(duration, self._hideTempText)
end

function DragFrame:ShowTemporaryPreview(duration)
    self:AddState(DRAG_FRAME_STATE.PREVIEW)

    self._previewEndTime = GetTime() + duration

    if not self._hidePreview then
        self._hidePreview = function()
            if self._previewEndTime and self._previewEndTime <= GetTime() then
                self:RemoveState(DRAG_FRAME_STATE.PREVIEW)
            end
        end
    end

    _G.C_Timer.After(duration, self._hidePreview)
end

function DragFrame:ShowPreview()
    self:AddState(DRAG_FRAME_STATE.PREVIEW)
    self._previewEndTime = nil
end

function DragFrame:HidePreview()
    self:RemoveState(DRAG_FRAME_STATE.PREVIEW)
end

function DragFrame:ShowOwnerContextMenu()
    if not self.owner then
        return
    end

    self.owner:ShowMenu()
end

function DragFrame:UpdateFrameLevel()
    local owner = self.owner
    if not owner then
        return
    end

    if self:HasState(DRAG_FRAME_STATE.FOCUSED) then
        self.frame:SetFrameLevel(FRAME_STRATA_LEVELS.FOCUSED)
    else
        local level = (FRAME_STRATA_LEVELS[owner:GetDisplayLayer()] or 0) + owner:GetDisplayLevel()
        self.frame:SetFrameLevel(level)
    end
end

--------------------------------------------------------------------------------
-- Exports
--------------------------------------------------------------------------------

Addon.DragFrameLabelFont = DragFrameLabelFont
Addon.DragFrameLabelHighlightFont = DragFrameLabelHighlightFont
Addon.DragFrame = DragFrame
