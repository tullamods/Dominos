-- the border around each timer: a flat color, or any lsm border
local _, Addon = ...
local LSM = LibStub('LibSharedMedia-3.0')

local TimerBorder = {}

-- drawn black, so it works without a media pack
local FLAT_BORDER_FILE = [[Interface\Buttons\WHITE8X8]]

-- each border's own color, unless the bar has one. the flat one is drawn from
-- a white texture, so it needs a color to be black
local FLAT_BORDER_COLOR = CreateColor(0, 0, 0, 1)
local ART_BORDER_COLOR = CreateColor(1, 1, 1, 1)

-- lsm border art sits this far in from its edge, so the fill meets the inside
-- of it
local BORDER_OUTSET_RATIO = 5 / 16

-- nil for no key or lsm's None, which mean the flat border. some versions
-- give None a path instead of leaving it empty
local function getEdgeFile(borderID)
    if borderID == nil or borderID == 'None' then
        return
    end

    local edgeFile = LSM:Fetch(LSM.MediaType.BORDER, borderID)

    if edgeFile and edgeFile ~= '' then
        return edgeFile
    end
end

-- how far it reaches past the timer
function TimerBorder:GetOutset(borderID, size)
    -- all of the flat one is edge, so it sits wholly outside the fill
    if not getEdgeFile(borderID) then
        return size
    end

    return size * BORDER_OUTSET_RATIO
end

---@return ColorMixin
function TimerBorder:GetStockColor(borderID)
    if getEdgeFile(borderID) then
        return ART_BORDER_COLOR
    end

    return FLAT_BORDER_COLOR
end

-- draws it with a backdrop frame, around region. no color is the stock one
---@param color ColorMixin?
function TimerBorder:Apply(edgeFrame, region, shown, borderID, size, color)
    if not shown then
        edgeFrame:Hide()
        return
    end

    local edgeFile = getEdgeFile(borderID)
    local outset = self:GetOutset(borderID, size)

    edgeFrame:ClearAllPoints()
    edgeFrame:SetPoint('TOPLEFT', region, -outset, outset)
    edgeFrame:SetPoint('BOTTOMRIGHT', region, outset, -outset)
    edgeFrame:SetBackdrop({ edgeFile = edgeFile or FLAT_BORDER_FILE, edgeSize = size })

    edgeFrame:SetBackdropBorderColor((color or self:GetStockColor(borderID)):GetRGBA())

    edgeFrame:Show()
end

-- exports
Addon.TimerBorder = TimerBorder
