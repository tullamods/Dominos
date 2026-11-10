if not (MultiCastActionBarFrame and UnitClassBase('player') == 'SHAMAN') then return end

--------------------------------------------------------------------------------
-- Totem art
-- Helper class for managing MultiCastActionBarFrame art
--------------------------------------------------------------------------------

local _, Addon = ...

local TotemArt = {
    TEXTURE_FILE = 'Interface\\Buttons\\UI-TotemBar',

    FLYOUT_THICKNESS = 32,
    FLYOUT_CAP_LENGTH = 20,
    FLYOUT_CAP_INSET = 10,

    -- as drawn pointing up. the close button is the same size
    ARROW_WIDTH = 28,
    ARROW_HEIGHT = 18,
}

local ARROW_HIGHLIGHT_WIDTH = 20
local ARROW_HIGHLIGHT_HEIGHT = 11
local RING_SIZE = 34
local FILE_WIDTH = 128
local FILE_HEIGHT = 256

-- texcoords from the pixel box in the file
local function fromPixels(left, right, top, bottom)
    return { left / 128, right / 128, top / 256, bottom / 256 }
end

--- @class TotemTexCoords
--- @field empty? number[] behind an empty slot
--- @field ring? number[] element colored frame over a button
--- @field arrow? number[] the open button, pointing up
--- @field cap? number[] flyout far end
--- @field body? number[] flyout stretch between the cap and the arrow
--- @field close? number[] flyout close button, pointing back at the totem

--- pixel boxes as left, right, top, bottom, by totem slot. spell is summon and
--- recall (its arrow shows before any slot is hovered), highlight is for the
--- arrow and close buttons
--- @type table<number|'spell'|'highlight', TotemTexCoords>
local TEXCOORDS = {
    [EARTH_TOTEM_SLOT] = {
        empty = fromPixels(66, 96, 3, 33),
        ring = fromPixels(1, 35, 172, 206),
        arrow = fromPixels(99, 127, 160, 178),
        cap = fromPixels(0, 32, 46, 68),
        body = fromPixels(0, 32, 68, 88),
        close = fromPixels(99, 127, 141, 159),
    },
    [FIRE_TOTEM_SLOT] = {
        empty = fromPixels(67, 97, 100, 130),
        ring = fromPixels(36, 70, 172, 206),
        arrow = fromPixels(99, 127, 122, 140),
        cap = fromPixels(33, 65, 46, 68),
        body = fromPixels(33, 65, 68, 88),
        close = fromPixels(99, 127, 103, 121),
    },
    [WATER_TOTEM_SLOT] = {
        empty = fromPixels(39, 69, 209, 239),
        ring = fromPixels(1, 35, 207, 240),
        arrow = fromPixels(99, 127, 199, 217),
        cap = fromPixels(0, 32, 1, 23),
        body = fromPixels(0, 32, 23, 43),
        close = fromPixels(99, 127, 180, 198),
    },
    [AIR_TOTEM_SLOT] = {
        empty = fromPixels(66, 96, 36, 66),
        ring = fromPixels(36, 70, 137, 171),
        arrow = fromPixels(99, 127, 237, 255),
        cap = fromPixels(0, 32, 91, 113),
        body = fromPixels(0, 32, 113, 133),
        close = fromPixels(99, 127, 218, 236),
    },
    spell = {
        ring = fromPixels(1, 35, 137, 171),
        arrow = fromPixels(99, 127, 84, 102),
    },
    highlight = {
        arrow = fromPixels(72, 92, 88, 98),
        close = fromPixels(72, 92, 69, 79),
    },
}

--------------------------------------------------------------------------------
-- Turning
-- art points up, other directions move which corner of the texcoords lands in which
-- texture corner
--------------------------------------------------------------------------------

-- texcoord index (left, right, top, bottom) for each SetTexCoord argument, the x
-- and y of ul, ll, ur, lr
local TEXCOORD_ORDER = {
    UP = { 1, 3, 1, 4, 2, 3, 2, 4 },
    DOWN = { 2, 4, 2, 3, 1, 4, 1, 3 },
    LEFT = { 2, 3, 1, 3, 2, 4, 1, 4 },
    RIGHT = { 1, 4, 2, 4, 1, 3, 2, 3 },
}

local function setArt(texture, direction, texCoords)
    local t = TEXCOORD_ORDER[direction]

    texture:SetTexture(TotemArt.TEXTURE_FILE)
    texture:SetTexCoord(
        texCoords[t[1]], texCoords[t[2]], texCoords[t[3]], texCoords[t[4]],
        texCoords[t[5]], texCoords[t[6]], texCoords[t[7]], texCoords[t[8]]
    )
end

local function setButtonArt(button, direction, texCoords, highlightTexCoords)
    setArt(button:GetNormalTexture(), direction, texCoords)

    local highlight = button:GetHighlightTexture()

    highlight:ClearAllPoints()
    highlight:SetPoint('CENTER')

    if TotemArt:IsSideways(direction) then
        highlight:SetSize(ARROW_HIGHLIGHT_HEIGHT, ARROW_HIGHLIGHT_WIDTH)
    else
        highlight:SetSize(ARROW_HIGHLIGHT_WIDTH, ARROW_HIGHLIGHT_HEIGHT)
    end

    setArt(highlight, direction, highlightTexCoords)
end

function TotemArt:IsSideways(direction)
    return direction == 'LEFT' or direction == 'RIGHT'
end

--------------------------------------------------------------------------------
-- Buttons
--------------------------------------------------------------------------------

function TotemArt:SetEmptySlot(texture, slot)
    setArt(texture, 'UP', TEXCOORDS[slot].empty)
end

-- no slot for summon and recall
function TotemArt:AddRing(button, slot)
    local ring = button:CreateTexture(nil, 'OVERLAY')

    ring:SetSize(RING_SIZE, RING_SIZE)
    ring:SetPoint('CENTER')
    setArt(ring, 'UP', TEXCOORDS[slot or 'spell'].ring)
end

-- close button too
function TotemArt:GetArrowSize(direction)
    if self:IsSideways(direction) then
        return self.ARROW_HEIGHT, self.ARROW_WIDTH
    end

    return self.ARROW_WIDTH, self.ARROW_HEIGHT
end
-- slot is nil before the first hover
function TotemArt:SetArrow(arrow, slot, direction)
    local texCoords = TEXCOORDS[slot or 'spell']

    setButtonArt(arrow, direction, texCoords.arrow, TEXCOORDS.highlight.arrow)
end

function TotemArt:SetClose(close, slot, direction)
    setButtonArt(close, direction, TEXCOORDS[slot].close, TEXCOORDS.highlight.close)
end

function TotemArt:SetFlyout(cap, body, slot, direction)
    setArt(cap, direction, TEXCOORDS[slot].cap)
    setArt(body, direction, TEXCOORDS[slot].body)
end

-- export
Addon.TotemArt = TotemArt
