--------------------------------------------------------------------------------
-- frame.lua
-- a custom window like object
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local Frame = Addon:CreateClass('Frame')
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local FlyPaper = LibStub('LibFlyPaper-2.0')

local active = {}
local unused = {}

local function frame_OnSetAlpha(frame, alpha)
    frame:OnSetAlpha(alpha)
end

local function frame_OnSetScale(frame, scale)
    frame:OnSetScale(scale)
end

local frame_UpdateShown =
[[
    if self:GetAttribute("state-hidden") then
        self:Hide()
        return
    end

    local isOverrideUIShown = self:GetAttribute('state-overrideui') and true or false
    local isPetBattleUIShown = self:GetAttribute('state-petbattleui') and true or false

    if isPetBattleUIShown and not self:GetAttribute('state-showinpetbattleui') then
        self:Hide()
        return
    end

    if isOverrideUIShown and not self:GetAttribute('state-showinoverrideui') then
        self:Hide()
        return
    end

    local displayState = self:GetAttribute('state-display')
    if displayState == 'hide' then
        if self:GetAttribute('state-alpha') then
            self:SetAttribute('state-alpha', nil)
        end

        self:Hide()
        return
    end

    local stateAlpha = tonumber(displayState)
    if self:GetAttribute('state-alpha') ~= stateAlpha then
        self:SetAttribute('state-alpha', stateAlpha)
    end

    self:Show()
]]

local frame_CallUpdateShown = "self:RunAttribute('UpdateShown')"

-- constructor
function Frame:New(id, tooltipText)
    id = tonumber(id) or id

    local frame = self:Restore(id) or self:Create(id)

    frame:LoadSettings()
    frame:SetTooltipText(tooltipText)

    Addon.OverrideController:Add(frame)

    frame:OnAcquire(id)
    FlyPaper.AddFrame(AddonName, id, frame)
    active[id] = frame

    return frame
end

function Frame:Create(id)
    local frameName = ('%sFrame%s'):format(AddonName, id)

    local frame = self:Bind(CreateFrame('Frame', frameName, UIParent, 'SecureHandlerStateTemplate'))
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)

    -- compatibility:
    -- in old versions of dominos, frames had an extra header frame to control
    -- visibility, which pushed things up by one frame level
    -- so increase the frame level of frames to account for that
    frame:SetFrameLevel(frame:GetFrameLevel() + 1)

    frame.id = id

    frame:SetAttribute('id', id)

    frame:SetAttribute('_onstate-alpha', "self:CallMethod('FadeOut')")
    frame:SetAttribute('_onstate-display', frame_CallUpdateShown)
    frame:SetAttribute('_onstate-hidden', frame_CallUpdateShown)
    frame:SetAttribute('_onstate-overrideui', frame_CallUpdateShown)
    frame:SetAttribute('_onstate-petbattleui', frame_CallUpdateShown)
    frame:SetAttribute('_onstate-showinoverrideui', frame_CallUpdateShown)
    frame:SetAttribute('_onstate-showinpetbattleui', frame_CallUpdateShown)

    frame:SetAttribute('UpdateShown', frame_UpdateShown)
    hooksecurefunc(frame, 'SetAlpha', frame_OnSetAlpha)
    hooksecurefunc(frame, 'SetScale', frame_OnSetScale)

    frame:OnCreate(id)

    return frame
end

function Frame:Restore(id)
    local frame = unused[id]

    if frame then
        unused[id] = nil

        frame:OnRestore(id)

        return frame
    end
end

-- destructor
function Frame:Free(deleteSettings)
    active[self.id] = nil

    UnregisterStateDriver(self, 'display', 'show')
    Addon.FadeManager:Remove(self)
    Addon.OverrideController:Remove(self)
    FlyPaper.RemoveFrame(AddonName, self.id, self)

    self.docked = nil

    self:ClearAllPoints()
    self:SetUserPlaced(nil)
    self:Hide()

    self:OnRelease(self.id, deleteSettings)


    unused[self.id] = self
end

--------------------------------------------------------------------------------
-- Lifecycle Hooks
--------------------------------------------------------------------------------

-- called when a frame is acquired from the pool
function Frame:OnAcquire(id)
    if self.OnEnable then
        Addon:Printf('Bar %q called deprecated method OnEnable', id)
        self:OnEnable()
    end
end

-- called when a frame is first created
function Frame:OnCreate(id)
end

-- called when a frame is pulled in from the inactive pool
function Frame:OnRestore(id)
end

-- called when a frame is sent to the inactive pool
function Frame:OnRelease(id, deleteSettings)
    if self.OnFree then
        Addon:Printf('Bar %q called deprecated method OnFree', id)
        self:OnFree()
    end
end

function Frame:OnLoadSettings()
end

function Frame:OnSetAlpha(alpha)
end

function Frame:OnSetScale(scale)
end

--------------------------------------------------------------------------------
-- Persistence
--------------------------------------------------------------------------------

function Frame:LoadSettings()
    -- get defaults must be provided by anything implementing the Frame type
    self.sets = Addon:GetFrameSets(self.id) or Addon:SetFrameSets(self.id, self:GetDefaults())

    self:Reposition()

    if self.sets.hidden then
        self:HideFrame()
    else
        self:ShowFrame()
    end

    -- convert from flypaper 1.x anchor IDs into points
    -- todo: move this into an upgrade path instead of every time we load sets
    local anchor = self.sets.anchor
    if type(anchor) == "string" then
        local pointStart = #anchor - 1
        local anchorId = anchor:sub(1, pointStart - 1)
        local anchorFrame = anchorId:sub(pointStart)
        local point, relPoint = FlyPaper.ConvertAnchorId(anchorId)

        self.sets.anchor = {
            point = point,
            relPoint = relPoint,
            relTo = anchorFrame
        }
    end

    self:UpdateShowStates()

    self:ShowInOverrideUI(self:ShowingInOverrideUI())
    self:ShowInPetBattleUI(self:ShowingInPetBattleUI())

    self:OnLoadSettings()
end

--------------------------------------------------------------------------------
-- Layout and Sizing
--------------------------------------------------------------------------------

function Frame:SetPadding(width, height)
    width = tonumber(width) or 0
    height = tonumber(height) or width

    self.sets.padW = width ~= 0 and width or nil
    self.sets.padH = height ~= 0 and height or nil

    self:Layout()
end

function Frame:GetPadding()
    local width = self.sets.padW or 0
    local height = self.sets.padH or width

    return width, height
end

function Frame:Layout()
    local width, height = 32, 32
    local paddingW, paddingH = self:GetPadding()

    self:TrySetSize(width + paddingW * 2, height + paddingH * 2)
end

function Frame:TrySetSize(width, height)
    if InCombatLockdown() then
        return
    end

    self:SetSize(width, height)
end

--------------------------------------------------------------------------------
-- Scaling
--------------------------------------------------------------------------------

function Frame:SetFrameScale(newScale, scaleAnchored)
    newScale = tonumber(newScale) or 1

    self.sets.scale = newScale

    FlyPaper.SetScale(self, newScale)
    self:SaveRelativeFramePosition()

    if scaleAnchored then
        for _, f in self:GetAll() do
            if f:GetAnchor() == self then
                f:SetFrameScale(newScale, true)
            end
        end
    else
        for _, f in self:GetAll() do
            if f:GetAnchor() == self then
                f:SaveRelativeFramePosition()
            end
        end
    end
end

function Frame:Rescale()
    self:SetScale(self:GetFrameScale())
end

function Frame:GetFrameScale()
    return self.sets.scale or 1
end

--------------------------------------------------------------------------------
-- Frame Opacity/Fading
--------------------------------------------------------------------------------

function Frame:SetFrameAlpha(alpha)
    if alpha == 1 then
        self.sets.alpha = nil
    else
        self.sets.alpha = alpha
    end

    self:UpdateAlpha()
end

function Frame:GetFrameAlpha()
    return self.sets.alpha or 1
end

--faded opacity (mouse not over the frame)
function Frame:SetFadeMultiplier(alpha)
    alpha = tonumber(alpha) or 1

    if alpha == 1 then
        self.sets.fadeAlpha = nil
    else
        self.sets.fadeAlpha = alpha
    end

    self:UpdateWatched()
    self:UpdateAlpha()
end

function Frame:GetFadeMultiplier()
    return self.sets.fadeAlpha or 1
end

function Frame:SetFadeInDelay(delay)
    delay = tonumber(delay) or 0
    self.sets.fadeInDelay = delay ~= 0 and delay
    self:UpdateWatched()
end

function Frame:GetFadeInDelay()
    return self.sets.fadeInDelay or 0
end

function Frame:SetFadeOutDelay(delay)
    delay = tonumber(delay) or 0
    self.sets.fadeOutDelay = delay ~= 0 and delay
    self:UpdateWatched()
end

function Frame:GetFadeOutDelay()
    return self.sets.fadeOutDelay or 0
end

function Frame:SetFadeInDuration(duration)
    duration = tonumber(duration) or 0.1
    self.sets.fadeInDuration = duration ~= 0.1 and duration
    self:UpdateWatched()
end

function Frame:GetFadeInDuration()
    return self.sets.fadeInDuration or 0.1
end

function Frame:SetFadeOutDuration(duration)
    duration = tonumber(duration) or 0.1
    self.sets.fadeOutDuration = duration ~= 0.1 and duration
    self:UpdateWatched()
end

function Frame:GetFadeOutDuration()
    return self.sets.fadeOutDuration or 0.1
end

function Frame:UpdateAlpha()
    self:SetAlpha(self:GetExpectedAlpha())

    if Addon:IsLinkedOpacityEnabled() then
        self:ForDocked('UpdateAlpha')
    end
end

-- returns the opacity value we expect the frame to be at in its current state
function Frame:GetExpectedAlpha()
    -- if this is a docked frame and linked opacity is enabled
    -- then return the expected opacity of the parent frame
    if Addon:IsLinkedOpacityEnabled() then
        local anchor = (self:GetAnchor())
        if anchor and anchor:FrameIsShown() then
            return anchor:GetExpectedAlpha()
        end
    end

    -- if there's a statealpha value for the frame, then use it
    local stateAlpha = self:GetAttribute('state-alpha')
    if stateAlpha then
        return stateAlpha / 100
    end

    -- if the frame is moused over, then return the frame's normal opacity
    if self.focused then
        return self:GetFrameAlpha()
    end

    return self:GetFrameAlpha() * self:GetFadeMultiplier()
end

--------------------------------------------------------------------------------
-- Focus Checking
--------------------------------------------------------------------------------

local function isChildFocus(...)
    local focus = GetMouseFocus()
    for i = 1, select('#', ...) do
        if focus == select(i, ...) then
            return true
        end
    end

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if f:IsShown() and isChildFocus(f:GetChildren()) then
            return true
        end
    end

    return false
end

local function isDescendant(frame, ...)
    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if frame == f then
            return true
        end
    end

    for i = 1, select('#', ...) do
        local f = select(i, ...)
        if isDescendant(frame, f:GetChildren()) then
            return true
        end
    end

    return false
end

-- returns all frames docked to the given frame
function Frame:IsFocus()
    if self:IsMouseOver(1, -1, -1, 1) then
        return (GetMouseFocus() == WorldFrame) or isChildFocus(self:GetChildren())
    end

    if SpellFlyout and SpellFlyout:IsMouseOver(1, -1, -1, 1) and isDescendant(SpellFlyout:GetParent(), self) then
        return true
    end

    return Addon:IsLinkedOpacityEnabled() and self:IsDockedFocus()
end

function Frame:IsDockedFocus()
    local docked = self.docked

    if docked then
        for _, frame in pairs(docked) do
            if frame:IsFocus() then
                return true
            end
        end
    end

    return false
end

--------------------------------------------------------------------------------
-- Fading
--------------------------------------------------------------------------------

function Frame:FadeIn()
    self:Fade(self:GetExpectedAlpha(), self:GetFadeInDelay(), self:GetFadeInDuration())
end

function Frame:FadeOut()
    self:Fade(self:GetExpectedAlpha(), self:GetFadeOutDelay(), self:GetFadeOutDuration())
end

function Frame:Fade(targetAlpha, delay, duration)
    Addon:Fade(self, targetAlpha, delay, duration)

    if Addon:IsLinkedOpacityEnabled() then
        self:ForDocked('Fade', targetAlpha, delay, duration)
    end
end

--------------------------------------------------------------------------------
-- Frame Visibility
--------------------------------------------------------------------------------

function Frame:ShowFrame()
    self.sets.hidden = nil

    self:SetAttribute('state-hidden', nil)
    self:UpdateWatched()
    self:UpdateAlpha()

    if Addon:IsLinkedOpacityEnabled() then
        self:ForDocked('ShowFrame')
    end
end

function Frame:HideFrame()
    self.sets.hidden = true

    self:SetAttribute('state-hidden', true)
    self:UpdateWatched()
    self:UpdateAlpha()

    if Addon:IsLinkedOpacityEnabled() then
        self:ForDocked('HideFrame')
    end
end

function Frame:ToggleFrame()
    if self:FrameIsShown() then
        self:HideFrame()
    else
        self:ShowFrame()
    end
end

function Frame:FrameIsShown()
    return not self.sets.hidden
end

--------------------------------------------------------------------------------
-- Override UI Visibility
--------------------------------------------------------------------------------

function Frame:ShowInOverrideUI(enable)
    self.sets.showInOverrideUI = enable and true or false

    self:SetAttribute('state-showinoverrideui', enable)
end

function Frame:ShowingInOverrideUI()
    return self.sets.showInOverrideUI
end

--------------------------------------------------------------------------------
-- Pet Battle UI Visibility
--------------------------------------------------------------------------------

function Frame:ShowInPetBattleUI(enable)
    self.sets.showInPetBattleUI = enable and true or false
    self:SetAttribute('state-showinpetbattleui', enable)
end

function Frame:ShowingInPetBattleUI()
    return self.sets.showInPetBattleUI
end

--------------------------------------------------------------------------------
-- Click through bars
--------------------------------------------------------------------------------

function Frame:SetClickThrough(enable)
    self.sets.clickThrough = enable and true or false
    self:UpdateClickThrough()
end

function Frame:GetClickThrough()
    return self.sets.clickThrough
end

function Frame:UpdateClickThrough()
end

--------------------------------------------------------------------------------
-- Showstates
--------------------------------------------------------------------------------

function Frame:SetShowStates(states)
    self.sets.showstates = states
    self:UpdateShowStates()
end

function Frame:GetShowStates()
    local states = self.sets.showstates

    -- hack to convert [combat] into [combat]show;hide in case a user is using
    -- the old style of showstates
    if states then
        if states:sub(#states) == ']' then
            states = states .. 'show;hide'
            self.sets.showstates = states
        end
    end

    return states
end

function Frame:UpdateShowStates()
    local showstates = self:GetShowStates()

    if showstates and showstates ~= '' then
        RegisterStateDriver(self, 'display', showstates)
    else
        UnregisterStateDriver(self, 'display')

        if self:GetAttribute('state-display') then
            self:SetAttribute('state-display', nil)
        end
    end
end

--------------------------------------------------------------------------------
-- Positioning
--------------------------------------------------------------------------------

-- how far away a frame can be from another frame/edge to trigger anchoring
Frame.stickyTolerance = 8

function Frame:StickToFrame()
    local point, relFrame, relPoint = FlyPaper.GetBestAnchorForGroup(self, AddonName, self.stickyTolerance)

    if point then
        self:SetAnchor(relFrame, point, relPoint)
        return true
    end
end

-- grid anchoring
function Frame:StickToGrid()
    if not Addon:GetAlignmentGridEnabled() then
        return
    end

    local xScale, yScale = Addon:GetAlignmentGridScale()
    local point, relPoint, x, y = FlyPaper.GetBestAnchorForParentGrid(self, xScale, yScale, self.stickyTolerance)

    if point then
        self:SetFramePosition(point, self:GetParent(), relPoint, x, y)
        return true
    end
end

-- screen edge and center point anchoring
function Frame:StickToEdge()
    local point, relPoint, x, y = FlyPaper.GetBestAnchorForParent(self)
    local scale = self:GetScale()

    if point then
        local stick = false

        if math.abs(x * scale) <= self.stickyTolerance then
            x = 0
            stick = true
        end

        if math.abs(y * scale) <= self.stickyTolerance then
            y = 0
            stick = true
        end

        if stick then
            self:SetFramePosition(point, self:GetParent(), relPoint, x, y)
            return true
        end
    end
end

function Frame:StickToAnything()
    return self:StickToFrame()
        or self:StickToEdge()
        or self:StickToGrid()
end

-- bar anchoring
function Frame:Stick()
    self:ClearAnchor()

    -- only do sticky code if the alt key is not currently down
    if Addon:Sticky() and not IsAltKeyDown() then
        self:StickToAnything()
    end

    self:SaveRelativeFramePosition()
end

function Frame:Reanchor()
    local relFrame, point, relPoint = self:GetAnchor()

    if relFrame then
        self:ClearAllPoints()
        self:SetPoint(point, relFrame, relPoint)
    else
        self:ClearAnchor()
        self:Reposition()
    end
end

function Frame:SetAnchor(relFrame, point, relPoint, x, y)
    self:ClearAnchor()

    if relFrame.docked then
        local found = false

        for i, f in pairs(relFrame.docked) do
            if f == self then
                found = i
                break
            end
        end

        if not found then
            table.insert(relFrame.docked, self)
        end
    else
        relFrame.docked = { self }
    end

    local anchor = self.sets.anchor
    if not anchor then
        anchor = { }

        self.sets.anchor = anchor
    end

    anchor.point = point
    anchor.relFrame = relFrame.id
    anchor.relPoint = relPoint
    anchor.x = x
    anchor.y = y

    self:ClearAllPoints()
    self:SetPoint(point, relFrame, relPoint, x, y)
    self:UpdateWatched()
    self:UpdateAlpha()
end

function Frame:ClearAnchor()
    local relFrame = self:GetAnchor()

    if relFrame and relFrame.docked then
        for i, f in pairs(relFrame.docked) do
            if f == self then
                table.remove(relFrame.docked, i)
                break
            end
        end

        if not next(relFrame.docked) then
            relFrame.docked = nil
        end
    end

    self.sets.anchor = nil
    self:UpdateWatched()
    self:UpdateAlpha()
end

function Frame:GetAnchor()
    local anchor = self.sets.anchor

    if type(anchor) == "table" then
        local point = anchor.point
        local relFrameId = anchor.relFrame
        local relPoint = anchor.relPoint
        local x = anchor.x or 0
        local y = anchor.y or 0

        return Frame:Get(relFrameId), point, relPoint, x, y
    end
end

-- absolute positioning
function Frame:SetFramePosition(point, relFrame, relPoint, x, y)
    self:ClearAllPoints()
    self:SetPoint(point, relFrame, relPoint, x, y)
end

function Frame:SetAndSaveFramePosition(point, relFrame, relPoint, x, y)
    self:SetFramePosition(point, relFrame, relPoint, x, y)
    self:SaveFramePosition(self:GetRelativeFramePosition())
end

-- relative positioning
function Frame:SaveRelativeFramePosition()
    self:SaveFramePosition(self:GetRelativeFramePosition())
end

function Frame:GetRelativeFramePosition()
    local point, relPoint, x, y = FlyPaper.GetBestAnchorForParent(self)

    return point, relPoint, x, y
end

-- loading and positionin
function Frame:Reposition()
    local point, relPoint, x, y = self:GetSavedFramePosition()
    local scale = self:GetFrameScale()

    self:ClearAllPoints()
    self:SetScale(scale)
    self:SetFramePosition(point, self:GetParent(), relPoint, x, y)
end

function Frame:SaveFramePosition(point, relPoint, x, y)
    point = point or 'CENTER'
    relPoint = relPoint or point
    x = tonumber(x) or 0
    y = tonumber(y) or 0

    local sets = self.sets

    if point == 'CENTER' then
        sets.point = nil
    else
        sets.point = point
    end

    if relPoint == point then
        sets.relPoint = nil
    else
        sets.relPoint = relPoint
    end

    if x == 0 then
        sets.x = nil
    else
        sets.x = x
    end

    if y == 0 then
        sets.y = nil
    else
        sets.y = y
    end

    self:SetUserPlaced(true)
end

function Frame:GetSavedFramePosition()
    local sets = self.sets

    if not sets then
        return 'CENTER'
    end

    local point = sets.point or 'CENTER'
    local relPoint = sets.relPoint or point
    local x = sets.x or 0
    local y = sets.y or 0

    return point, relPoint, x, y
end

--------------------------------------------------------------------------------
-- Context Menus
--------------------------------------------------------------------------------

function Frame:CreateMenu()
    local menu = Addon:NewMenu()

    if menu then
        self:OnCreateMenu(menu)
        return menu
    end
end

function Frame:OnCreateMenu(menu)
    menu:AddLayoutPanel()
    menu:AddAdvancedPanel()
    menu:AddFadingPanel()
end

function Frame:ShowMenu()
    local menu = self.menu
    if not menu then
        menu = self:CreateMenu()
        self.menu = menu
    end

    if menu then
        menu:Hide()
        menu:SetOwner(self)
        menu:ShowPanel(LibStub('AceLocale-3.0'):GetLocale('Dominos-Config').Layout)
        menu:Show()
    end
end

--------------------------------------------------------------------------------
-- Tooltip Text
--------------------------------------------------------------------------------

function Frame:GetDisplayName()
    return L.BarDisplayName:format(tostring(self.id):gsub('^%l', string.upper))
end

function Frame:SetTooltipText(text)
    self.tooltipText = text
end

function Frame:GetTooltipText()
    return self.tooltipText
end

--------------------------------------------------------------------------------
-- Mouseover
--------------------------------------------------------------------------------

function Frame:UpdateWatched()
    local shouldWatch =
        self:FrameIsShown() and self:GetFadeMultiplier() < 1 and
        not (Addon:IsLinkedOpacityEnabled() and self:GetAnchor())

    if shouldWatch then
        Addon.FadeManager:Add(self)
    else
        Addon.FadeManager:Remove(self)
    end
end

--------------------------------------------------------------------------------
-- Metamethods
--------------------------------------------------------------------------------

function Frame:Get(id)
    return active[tonumber(id) or id]
end

function Frame:GetAll()
    return pairs(active)
end

function Frame:CallMethod(method, ...)
    local func = self[method]

    if type(func) == 'function' then
        return func(self, ...)
    else
        error(('Frame %s does not have a method named %q'):format(self.id, method), 2)
    end
end

function Frame:MaybeCallMethod(method, ...)
    local func = self[method]

    if type(func) == 'function' then
        return func(self, ...)
    end
end

function Frame:ForAll(method, ...)
    for _, frame in self:GetAll() do
        frame:MaybeCallMethod(method, ...)
    end
end

function Frame:ForDocked(method, ...)
    local docked = self.docked
    if docked then
        for _, frame in pairs(docked) do
            frame:CallMethod(method, ...)
        end
    end
end

-- takes a frameId, and performs the specified action on that frame
-- this adds two special ids: 'all' for all frames and '<number>-<number>' for
-- a range of IDs
function Frame:ForFrame(id, method, ...)
    if id == 'all' then
        self:ForAll(method, ...)
    else
        local startID, endID = tostring(id):match('(%d+)-(%d+)')

        startID = tonumber(startID)
        endID = tonumber(endID)

        if startID and endID then
            if startID > endID then
                local t = startID
                startID = endID
                endID = t
            end

            for i = startID, endID do
                local f = self:Get(i)
                if f then
                    f:MaybeCallMethod(method, ...)
                end
            end
        else
            local f = self:Get(id)
            if f then
                f:MaybeCallMethod(method, ...)
            end
        end
    end
end

-- exports
Addon.Frame = Frame
