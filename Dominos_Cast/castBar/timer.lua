-- duration objects drive the fill and time text, so nothing here runs every
-- frame
local _, Addon = ...
local LSM = LibStub('LibSharedMedia-3.0')

local CastTimer = {}

local SPARK_ATLAS = 'ui-castingbar-pip'
local SPARK_WIDTH = 6
local SPARK_ALPHA = 0.6
-- the pip has empty space above and below it
local SPARK_HEIGHT_RATIO = 1.6

-- empowers show a band per stage plus the hold. faint ahead of the cast, lit
-- behind it, so the next stage is always in sight
local BAND_UNLIT_ALPHA = 0.5
-- so neighbors with close colors read apart
local BAND_GAP = 2

-- by how far along to max, so any stage count covers the same range
local STAGE_COLORS = C_CurveUtil.CreateColorCurve()
STAGE_COLORS:SetType(Enum.LuaCurveType.Linear)
STAGE_COLORS:AddPoint(0, CreateColorFromRGBAHexString('FFD200FF'))
STAGE_COLORS:AddPoint(0.5, CreateColorFromRGBAHexString('FF8000FF'))
STAGE_COLORS:AddPoint(1, CreateColorFromRGBAHexString('FF2020FF'))

-- every stage is reached by the hold
local HOLD_COLOR = CreateColorFromRGBAHexString('A1A1A1FF')

-- the bar's color inverted, under the fill so it's covered on the way
local LATENCY_ALPHA = 0.5

local TIME_FORMATTER = C_StringUtil.CreateNumericRuleFormatter()

TIME_FORMATTER:AddBreakpoint({ threshold = 0, format = '%.1f' })

---@param container table the cast bar it belongs to
function CastTimer:Create(container)
    local timer = Mixin(CreateFrame('Frame', nil, container), Addon.TimerMixin, CastTimer)

    timer:CreateParts()

    -- under the border so it frames the icon like the fill, over the background
    local icon = timer:CreatePartTexture(timer.fill, 'ARTWORK')
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    timer.icon = icon

    local spark = timer:CreatePartTexture(timer.overlay, 'ARTWORK')
    spark:SetAtlas(SPARK_ATLAS)
    spark:SetBlendMode('ADD')
    spark:SetAlpha(SPARK_ALPHA)
    spark:SetWidth(SPARK_WIDTH)
    timer.spark = spark

    local latency = timer:CreatePartTexture(timer.fill, 'BACKGROUND', 1)
    latency:SetBlendMode('ADD')
    latency:SetPoint('TOPRIGHT')
    latency:SetPoint('BOTTOMRIGHT')
    timer.latency = latency

    -- ends where the fill does, so bands light up as the cast reaches them
    local litBands = timer:CreatePartFrame(timer.fill)
    litBands:SetClipsChildren(true)
    litBands:Hide()
    timer.litBands = litBands

    timer.bands = {}

    -- already finished, so a failed cast shows a full bar
    timer.failedDuration = C_DurationUtil.CreateDuration()

    timer.timeBinding = C_DurationUtil.CreateDurationTextBinding()
    timer.timeBinding:SetFontString(timer.time)
    timer.timeBinding:SetFormatter(TIME_FORMATTER)

    return timer
end

--------------------------------------------------------------------------------
-- Layout
--------------------------------------------------------------------------------

function CastTimer:SetTimerSize(width, height)
    self.timerWidth = width
    self.timerHeight = height
    self:UpdateFillInset()
end

function CastTimer:SetIconShown(show)
    self.icon:SetShown(show)
    self:UpdateFillInset()
end

-- a square icon at the left, the fill after it
function CastTimer:UpdateFillInset()
    local width = self.timerWidth or 0
    local height = self.timerHeight or 0
    local iconSize = self.icon:IsShown() and height or 0

    self.fillWidth = width - iconSize

    local icon = self.icon
    icon:ClearAllPoints()
    icon:SetPoint('TOPLEFT', self.content)
    icon:SetSize(iconSize, height)

    self:SetFillInset(iconSize)
    self.spark:SetHeight(height * SPARK_HEIGHT_RATIO)
    self:LayoutEmpower()
end

function CastTimer:SetSparkShown(show)
    self.sparkShown = show
    self:UpdateSpark()
end

-- rides the fill's edge, so it moves on its own
function CastTimer:UpdateSpark()
    local spark = self.spark

    spark:ClearAllPoints()
    spark:SetPoint('CENTER', self.fill:GetStatusBarTexture(), 'RIGHT')
    spark:SetShown(self.sparkShown and self.casting)
end

--------------------------------------------------------------------------------
-- Casts
--------------------------------------------------------------------------------

---@param duration LuaDurationObject
---@param direction Enum.StatusBarTimerDirection
function CastTimer:StartCast(label, iconID, duration, direction)
    self.casting = true

    self:ClearEmpower()
    self.label:SetText(label)
    self.icon:SetTexture(iconID)

    self.fill:SetTimerDuration(duration, Enum.StatusBarInterpolation.Immediate, direction)

    self.timeBinding:SetDuration(duration)
    self.timeBinding:SetEnabled(true)

    self:UpdateSpark()
    self:FadeIn()
end

-- empowers keep their bands while fading, to show the stage they went off at
function CastTimer:FinishCast()
    self:EndCast()
    self:FadeOut(self.FINISH_FADE_DELAY)
end

function CastTimer:FailCast(reason)
    self:EndCast()
    self:ClearEmpower()

    local full = self.failedDuration
    full:SetTimeFromEnd(GetTime(), 1)
    self.fill:SetTimerDuration(full, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.ElapsedTime)

    self.label:SetText(reason)
    self.time:SetText('')

    self:FadeOut(self.FAILED_FADE_DELAY)
end

function CastTimer:EndCast()
    self.casting = nil

    self.timeBinding:SetEnabled(false)
    self:SetLatency(nil)
    self:UpdateSpark()
end

function CastTimer:OnFadedOut()
    self:ClearEmpower()
end

--------------------------------------------------------------------------------
-- Latency
--------------------------------------------------------------------------------

-- in seconds. nil hides it
function CastTimer:SetLatency(latency, total)
    local strip = self.latency

    if not (latency and total and total > 0) then
        strip:Hide()
        return
    end

    strip:SetWidth(self.fillWidth * Clamp(latency / total, 0, 1))
    strip:Show()
end

---@param color ColorMixin
function CastTimer:SetLatencyColor(color)
    local r, g, b = color:GetRGB()

    self.latency:SetColorTexture(1 - r, 1 - g, 1 - b, LATENCY_ALPHA)
end

--------------------------------------------------------------------------------
-- Empowering
--------------------------------------------------------------------------------

-- stageEnds are seconds from the cast's start. total includes the hold. the
-- fill still runs, hidden, and the lit bands show where it is
function CastTimer:StartEmpower(stageEnds, total)
    self:ClearEmpower()

    if not (stageEnds and total and total > 0) then
        return
    end

    self.stageEnds = stageEnds
    self.empowerTotal = total

    -- plus one for the hold
    for i = 1, #stageEnds + 1 do
        local band = self.bands[i]

        if not band then
            band = {
                unlit = self:CreatePartTexture(self.fill, 'BACKGROUND', 2),
                lit = self:CreatePartTexture(self.litBands, 'ARTWORK')
            }

            self.bands[i] = band
        end
    end

    -- in case a new texture swapped the fill's out
    local litBands = self.litBands
    litBands:ClearAllPoints()
    litBands:SetPoint('TOPLEFT', self.fill)
    litBands:SetPoint('BOTTOMRIGHT', self.fill:GetStatusBarTexture())
    litBands:Show()

    self.fill:GetStatusBarTexture():SetAlpha(0)

    self:UpdateBandTextures()
    self:UpdateBandColors()
    self:LayoutEmpower()
end

function CastTimer:ClearEmpower()
    if not self.stageEnds then
        return
    end

    self.stageEnds = nil
    self.empowerTotal = nil

    for _, band in ipairs(self.bands) do
        band.unlit:Hide()
        band.lit:Hide()
    end

    self.litBands:Hide()
    self.fill:GetStatusBarTexture():SetAlpha(1)
end

-- no hold, no hold band
function CastTimer:LayoutEmpower()
    local stageEnds = self.stageEnds
    if not stageEnds then
        return
    end

    local total = self.empowerTotal
    local width = self.fillWidth
    local numBands = #stageEnds + 1
    local bandStart = 0

    for i, band in ipairs(self.bands) do
        local bandEnd = stageEnds[i] or total
        local left = width * bandStart / total
        local bandWidth = width * (bandEnd - bandStart) / total

        if i < numBands then
            bandWidth = bandWidth - BAND_GAP
        end

        local shown = i <= numBands and bandWidth > 0

        for _, texture in pairs(band) do
            texture:ClearAllPoints()

            if shown then
                texture:SetPoint('TOPLEFT', self.fill, 'TOPLEFT', left, 0)
                texture:SetPoint('BOTTOMLEFT', self.fill, 'BOTTOMLEFT', left, 0)
                texture:SetWidth(bandWidth)
            end

            texture:SetShown(shown)
        end

        bandStart = bandEnd
    end
end

function CastTimer:UpdateBandTextures()
    local texture = LSM:Fetch(LSM.MediaType.STATUSBAR, self.textureID)

    for _, band in ipairs(self.bands) do
        band.unlit:SetTexture(texture)
        band.lit:SetTexture(texture)
    end
end

function CastTimer:UpdateBandColors()
    local stageEnds = self.stageEnds
    if not stageEnds then
        return
    end

    local numStages = #stageEnds

    for i, band in ipairs(self.bands) do
        local color = HOLD_COLOR
        if i <= numStages then
            color = STAGE_COLORS:Evaluate(i / numStages)
        end

        local r, g, b = color:GetRGB()

        band.lit:SetVertexColor(r, g, b, 1)
        band.unlit:SetVertexColor(r, g, b, BAND_UNLIT_ALPHA)
    end
end

-- the fill stays hidden while empowering
function CastTimer:SetTexture(textureID)
    self.textureID = textureID
    Addon.TimerMixin.SetTexture(self, textureID)

    if self.stageEnds then
        self.fill:GetStatusBarTexture():SetAlpha(0)
    end

    self:UpdateBandTextures()
end

-- exports
Addon.CastTimer = CastTimer
