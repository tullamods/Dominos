-- settings a timer bar container shares and pushes down to its timers. the
-- container provides GetTimers(), Layout(), DEFAULT_COLORS and UpdateColors(),
-- and can extend ApplyTimerBarStyle for settings of its own
local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local LSM = LibStub('LibSharedMedia-3.0')
local TimerMixin = Addon.TimerMixin
local TimerBorder = Addon.TimerBorder

local TimerBarSettingsMixin = {}

-- path, size, and flags
local function getStockFont()
    return TimerMixin.stockFontObject:GetFont()
end

-- lsm can list fonts the client lacks (classic), and SetFont errors on those
local function applyFont(bar, fontString)
    local stockPath = getStockFont()
    local fontID = bar:GetFontID()
    local fontPath = fontID and LSM:Fetch(LSM.MediaType.FONT, fontID) or stockPath
    local size = bar:GetFontSize()
    local outline = bar:GetFontOutline()

    local ok, loaded = pcall(fontString.SetFont, fontString, fontPath, size, outline)

    if not ok or loaded == false then
        fontString:SetFont(stockPath, size, outline)
    end

    -- the stock font has a drop shadow, which looks harsh under an outline.
    -- blizzard's outline fonts have none either
    if outline == '' then
        fontString:SetShadowOffset(TimerMixin.stockFontObject:GetShadowOffset())
    else
        fontString:SetShadowOffset(0, 0)
    end
end

-- every setting a timer shows. call it on a timer made after settings load
function TimerBarSettingsMixin:ApplyTimerBarStyle(timer)
    timer:SetTexture(self:GetTextureID())
    timer:SetBorder(self:ShowingBorder(), self:GetBorderID(), self:GetBorderSize(), self:GetCustomBorderColor())
    applyFont(self, timer.label)
    applyFont(self, timer.time)
    timer:SetTextShown(self:ShowingLabel(), self:ShowingTime())
end

-- call from OnLoadSettings. settings only change from the menu, so any change
-- restyles everything. the border counts toward the bar's size, so it lays out
-- again too
function TimerBarSettingsMixin:UpdateTimerBarStyle()
    for _, timer in ipairs(self:GetTimers()) do
        self:ApplyTimerBarStyle(timer)
    end

    self:Layout()
end

-- the module forwards LibSharedMedia_Registered here
function TimerBarSettingsMixin:OnMediaRegistered(mediaType, key)
    local sets = self.sets

    if (mediaType == LSM.MediaType.STATUSBAR and key == sets.texture)
        or (mediaType == LSM.MediaType.BORDER and key == sets.border)
        or (mediaType == LSM.MediaType.FONT and key == sets.font) then
        self:UpdateTimerBarStyle()
    end
end

--------------------------------------------------------------------------------
-- Size, of each timer's fill
--------------------------------------------------------------------------------

function TimerBarSettingsMixin:SetDesiredWidth(width)
    self.sets.width = width
    self:Layout()
end

function TimerBarSettingsMixin:GetDesiredWidth()
    return self.sets.width
end

function TimerBarSettingsMixin:SetDesiredHeight(height)
    self.sets.height = height
    self:Layout()
end

function TimerBarSettingsMixin:GetDesiredHeight()
    return self.sets.height
end

--------------------------------------------------------------------------------
-- Texture
--------------------------------------------------------------------------------

function TimerBarSettingsMixin:SetTextureID(textureID)
    self.sets.texture = textureID
    self:UpdateTimerBarStyle()
end

-- unregistered falls back to lsm's default, like the menu
function TimerBarSettingsMixin:GetTextureID()
    local textureID = self.sets.texture

    if textureID and LSM:IsValid(LSM.MediaType.STATUSBAR, textureID) then
        return textureID
    end

    return LSM:GetDefault(LSM.MediaType.STATUSBAR)
end

--------------------------------------------------------------------------------
-- Border
--------------------------------------------------------------------------------

-- padding goes outside this
function TimerBarSettingsMixin:GetBorderOutset()
    if not self:ShowingBorder() then
        return 0
    end

    return TimerBorder:GetOutset(self:GetBorderID(), self:GetBorderSize())
end

function TimerBarSettingsMixin:SetShowBorder(enable)
    self.sets.showBorder = enable and true or false
    self:UpdateTimerBarStyle()
end

function TimerBarSettingsMixin:ShowingBorder()
    return self.sets.showBorder
end

---@param borderID string|false|nil false or nil for the flat border
function TimerBarSettingsMixin:SetBorderID(borderID)
    self.sets.border = borderID or nil
    self:UpdateTimerBarStyle()
end

-- unregistered is the flat border, like the menu
function TimerBarSettingsMixin:GetBorderID()
    local borderID = self.sets.border

    if borderID and LSM:IsValid(LSM.MediaType.BORDER, borderID) then
        return borderID
    end
end

function TimerBarSettingsMixin:SetBorderSize(size)
    self.sets.borderSize = size
    self:UpdateTimerBarStyle()
end

function TimerBarSettingsMixin:GetBorderSize()
    return self.sets.borderSize
end

---@param hex string? RRGGBBAA, nil for the border's own color
function TimerBarSettingsMixin:SetBorderColor(hex)
    self.sets.borderColor = hex
    self:UpdateTimerBarStyle()
end

-- for the menu, which shows the border's own color when there's none set
---@return string hex RRGGBBAA
function TimerBarSettingsMixin:GetBorderColor()
    local color = self:GetCustomBorderColor() or TimerBorder:GetStockColor(self:GetBorderID())

    return Dominos:GetHexFromColor(color:GetRGBA())
end

---@return ColorMixin?
function TimerBarSettingsMixin:GetCustomBorderColor()
    local hex = self.sets.borderColor

    return hex and Dominos:GetColorFromHex(hex)
end

--------------------------------------------------------------------------------
-- Colors, by key. the container has DEFAULT_COLORS and UpdateColors()
--------------------------------------------------------------------------------

---@return ColorMixin
function TimerBarSettingsMixin:GetColor(key)
    local colors = self.sets.colors
    local hex = colors and colors[key]

    return hex and Dominos:GetColorFromHex(hex) or self.DEFAULT_COLORS[key]
end

-- for the menu
---@return string hex RRGGBBAA
function TimerBarSettingsMixin:GetColorHex(key)
    return Dominos:GetHexFromColor(self:GetColor(key):GetRGBA())
end

---@param hex string? RRGGBBAA, nil for the default
function TimerBarSettingsMixin:SetColor(key, hex)
    local colors = self.sets.colors

    if hex then
        if not colors then
            colors = {}
            self.sets.colors = colors
        end

        colors[key] = hex
    elseif colors then
        colors[key] = nil

        if next(colors) == nil then
            self.sets.colors = nil
        end
    end

    self:UpdateColors()
end

--------------------------------------------------------------------------------
-- Font
--------------------------------------------------------------------------------

---@param fontID string|false|nil false or nil for the stock font
function TimerBarSettingsMixin:SetFontID(fontID)
    self.sets.font = fontID or nil
    self:UpdateTimerBarStyle()
end

-- unregistered is the stock font, like the menu
function TimerBarSettingsMixin:GetFontID()
    local fontID = self.sets.font

    if fontID and LSM:IsValid(LSM.MediaType.FONT, fontID) then
        return fontID
    end
end

function TimerBarSettingsMixin:SetFontSize(size)
    self.sets.fontSize = size
    self:UpdateTimerBarStyle()
end

-- nil follows the stock font
function TimerBarSettingsMixin:GetFontSize()
    if self.sets.fontSize then
        return self.sets.fontSize
    end

    local _, size = getStockFont()
    return Round(size)
end

---@param outline FontOutline
function TimerBarSettingsMixin:SetFontOutline(outline)
    self.sets.fontOutline = outline
    self:UpdateTimerBarStyle()
end

-- nil follows the stock font, whose flags can hold more than the outline
---@return FontOutline
function TimerBarSettingsMixin:GetFontOutline()
    if self.sets.fontOutline then
        return self.sets.fontOutline
    end

    local _, _, flags = getStockFont()
    flags = flags or ''

    if flags:find('THICKOUTLINE', 1, true) then
        return 'THICKOUTLINE'
    elseif flags:find('OUTLINE', 1, true) then
        return 'OUTLINE'
    end

    return ''
end

--------------------------------------------------------------------------------
-- Text
--------------------------------------------------------------------------------

function TimerBarSettingsMixin:SetShowLabel(enable)
    self.sets.showLabel = enable and true or false
    self:UpdateTimerBarStyle()
end

function TimerBarSettingsMixin:ShowingLabel()
    return self.sets.showLabel
end

function TimerBarSettingsMixin:SetShowTime(enable)
    self.sets.showTime = enable and true or false
    self:UpdateTimerBarStyle()
end

function TimerBarSettingsMixin:ShowingTime()
    return self.sets.showTime
end

-- exports
Addon.TimerBarSettingsMixin = TimerBarSettingsMixin
