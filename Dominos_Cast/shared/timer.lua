-- a timer's look. visuals only, its container pushes settings in
local _, Addon = ...
local LSM = LibStub('LibSharedMedia-3.0')
local TimerBorder = Addon.TimerBorder

local TimerMixin = {}

-- what the timer's text starts as. the container applies its font over it
local STOCK_FONT = 'GameFontHighlightSmall'
TimerMixin.stockFontObject = _G[STOCK_FONT]

-- the fill's texture, darkened
local TEXTURE_BACKGROUND_COLOR = { 0, 0, 0, 0.5 }

local TEXT_INSET = 4

-- matches blizzard's cast bar
TimerMixin.FINISH_FADE_DELAY = 0.2
TimerMixin.FAILED_FADE_DELAY = 1.0
local FADE_DURATION = 0.3

--------------------------------------------------------------------------------
-- Pixel snapping
--------------------------------------------------------------------------------

-- snap to whole pixels so edges meet at any ui scale. mists and tbc lack it
local function roundToPixels(region, ...)
    if not (region and region.SetRoundLayoutToNearestPixel) then
        return
    end

    region:SetRoundLayoutToNearestPixel(true)

    if region.GetRegions then
        roundToPixels(region:GetRegions())
        roundToPixels(region:GetChildren())
    end

    roundToPixels(...)
end

--------------------------------------------------------------------------------
-- Parts
--------------------------------------------------------------------------------

-- parts live on a content frame so fading leaves the timer's alpha alone
function TimerMixin:CreateParts()
    -- hover only while showing a timer, for mouseover fading. clicks pass
    -- through. timers aren't protected so this is fine in combat
    self:SetMouseMotionEnabled(false)
    self:SetMouseClickEnabled(false)

    local content = CreateFrame('Frame', nil, self)
    content:SetAllPoints()
    content:SetAlpha(0)
    self.content = content

    -- clips the fill to the timer. border, text and overhangs stay outside
    local clip = CreateFrame('Frame', nil, content)
    clip:SetAllPoints()
    clip:SetClipsChildren(true)
    self.clip = clip

    local fill = CreateFrame('StatusBar', nil, clip)
    fill:SetAllPoints(content)
    fill:SetMinMaxValues(0, 1)
    fill:SetValue(0)
    self.fill = fill

    -- spans the whole timer so the cast bar's icon sits inside it
    local background = fill:CreateTexture(nil, 'BACKGROUND')
    background:SetAllPoints(content)
    self.background = background

    -- lsm borders are backdrops, so need their own frame
    local borderEdge = CreateFrame('Frame', nil, content, 'BackdropTemplate')
    -- over the fill's children, like the empower bands
    borderEdge:SetFrameLevel(fill:GetFrameLevel() + 2)
    self.borderEdge = borderEdge

    local overlay = CreateFrame('Frame', nil, content)
    overlay:SetAllPoints(fill)
    overlay:SetFrameLevel(fill:GetFrameLevel() + 3)
    self.overlay = overlay

    local label = overlay:CreateFontString(nil, 'OVERLAY', STOCK_FONT)
    label:SetWordWrap(false)
    self.label = label

    local time = overlay:CreateFontString(nil, 'OVERLAY', STOCK_FONT)
    time:SetWordWrap(false)
    self.time = time

    local fadeOut = content:CreateAnimationGroup()
    fadeOut:SetToFinalAlpha(true)
    fadeOut:SetScript('OnFinished', function()
        self:FinishFadeOut()
    end)
    self.fadeOut = fadeOut

    local fadeOutAlpha = fadeOut:CreateAnimation('Alpha')
    fadeOutAlpha:SetToAlpha(0)
    fadeOutAlpha:SetDuration(FADE_DURATION)
    self.fadeOutAlpha = fadeOutAlpha

    roundToPixels(self)
end

-- for parts made after CreateParts, so they're snapped like the rest
function TimerMixin:CreatePartTexture(parent, layer, subLevel)
    local texture = parent:CreateTexture(nil, layer, nil, subLevel)
    roundToPixels(texture)

    return texture
end

function TimerMixin:CreatePartFrame(parent)
    local frame = CreateFrame('Frame', nil, parent)
    roundToPixels(frame)

    return frame
end

-- room beside the fill, for the cast bar's icon
function TimerMixin:SetFillInset(left)
    local fill = self.fill

    fill:ClearAllPoints()
    fill:SetPoint('TOPLEFT', self.content, left, 0)
    fill:SetPoint('BOTTOMRIGHT', self.content)
end

--------------------------------------------------------------------------------
-- Texture and color
--------------------------------------------------------------------------------

function TimerMixin:SetTexture(textureID)
    local fill = self.fill
    local background = self.background
    local texture = LSM:Fetch(LSM.MediaType.STATUSBAR, textureID)

    fill:SetStatusBarTexture(texture)

    background:SetTexture(texture)
    background:SetVertexColor(unpack(TEXTURE_BACKGROUND_COLOR))

    -- a new texture drops the color, so put it back
    if self.fillColor then
        fill:SetStatusBarColor(self.fillColor:GetRGBA())
    end
end

---@param color ColorMixin
function TimerMixin:SetFillColor(color)
    self.fillColor = color
    self.fill:SetStatusBarColor(color:GetRGBA())
end

--------------------------------------------------------------------------------
-- Border
--------------------------------------------------------------------------------

---@param color ColorMixin? nil for the border's own
function TimerMixin:SetBorder(shown, borderID, size, color)
    TimerBorder:Apply(self.borderEdge, self.content, shown, borderID, size, color)

    -- a new backdrop has new pieces
    roundToPixels(self.borderEdge)
end

--------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------

-- label left and time right, or centered when alone
function TimerMixin:SetTextShown(showLabel, showTime)
    local label = self.label
    local time = self.time

    label:ClearAllPoints()
    time:ClearAllPoints()

    if showLabel and showTime then
        label:SetPoint('LEFT', TEXT_INSET, 0)
        label:SetPoint('RIGHT', time, 'LEFT', -TEXT_INSET, 0)
        label:SetJustifyH('LEFT')

        time:SetPoint('RIGHT', -TEXT_INSET, 0)
        time:SetJustifyH('RIGHT')
    elseif showLabel then
        label:SetPoint('LEFT', TEXT_INSET, 0)
        label:SetPoint('RIGHT', -TEXT_INSET, 0)
        label:SetJustifyH('CENTER')
    elseif showTime then
        time:SetPoint('CENTER')
        time:SetJustifyH('CENTER')
    end

    label:SetShown(showLabel)
    time:SetShown(showTime)
end

--------------------------------------------------------------------------------
-- Fading
--------------------------------------------------------------------------------

function TimerMixin:FadeIn()
    self.fadeOut:Stop()
    self.content:SetAlpha(1)
    self:SetMouseMotionEnabled(true)
end

-- picks up from the current alpha
function TimerMixin:FadeOut(delay)
    local content = self.content

    self.fadeOut:Stop()

    if content:GetAlpha() <= 0 then
        self:FinishFadeOut()
        return
    end

    self.fadeOutAlpha:SetFromAlpha(content:GetAlpha())
    self.fadeOutAlpha:SetStartDelay(delay or 0)
    self.fadeOut:Play()
end

function TimerMixin:FinishFadeOut()
    self:SetMouseMotionEnabled(false)
    self:OnFadedOut()
end

-- true while fading too
function TimerMixin:IsOnScreen()
    return self.content:GetAlpha() > 0
end

-- for timers to override
function TimerMixin:OnFadedOut()
end

-- exports
Addon.TimerMixin = TimerMixin
