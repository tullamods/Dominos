-- Translates action slot addresses into Blizzard's action slots.
--
-- Action bars and paging work in addresses: bar N covers the addresses right
-- after bar N - 1, and paging moves a bar to other addresses. The map reorders
-- Blizzard's slots so that those addresses line up with Blizzard's own bars
-- (bar 2 is Blizzard's Action Bar 2), followed by everything else a bar can
-- page to: the main bar's pages, totems, and gamepad storage.
--
-- Addresses whose slots can't hold actions on this client map to slot 0, so
-- they show as empty instead of something unexpected. The map also groups
-- addresses into labeled regions ("Bonus Bar 1"), for anything that shows
-- slots to players.
--
--   Addresses  Slots      Region
--   ---------  ---------  --------------------------------------------------
--   1-12       1-12       Action Bar 1
--   13-24      61-72      Action Bar 2
--   25-36      49-60      Action Bar 3
--   37-48      25-36      Action Bar 4
--   49-60      37-48      Action Bar 5
--   61-72      145-156    Action Bar 6
--   73-84      157-168    Action Bar 7
--   85-96      169-180    Action Bar 8
--   97-108     13-24      Action Page 2
--   109-156    73-120     Bonus Bars 1-4
--   157-168    121-132    Bonus Bar 5 (Skyriding on retail)
--   169-180    133-144    Totems: one set of 4 per summon spell
--                         (Cata, Wrath and Forever only)
--   181-264    181-264    Gamepad Pages 1-3: a D-pad, then LT, RT and LT + RT,
--                         each a D-pad and buttons (gamepad UI only)
--   265-304    265-304    Gamepad Stance Bars 1-5: a D-pad and buttons each
--   305-360    305-360    Unused
--
-- Bars cover addresses 1-168. The rest is only reached by paging.
local AddonName, Addon = ...
local L = LibStub('AceLocale-3.0'):GetLocale(AddonName)
local PAGE_SIZE = 12
local NUM_ADDRESSES = 360

-- all 15 action pages, in address order. totems (12) last, past the bars.
-- anything after maps straight to slots
local PAGE_ORDER = { 1, 6, 5, 3, 4, 13, 14, 15, 2, 7, 8, 9, 10, 11, 12 }
local LAST_ORDERED = #PAGE_ORDER * PAGE_SIZE

local addressPages = {}
for addressPage, page in ipairs(PAGE_ORDER) do
    addressPages[page] = addressPage
end

local function remap(index, pages)
    if index < 1 or index > LAST_ORDERED then
        return index
    end

    local page = math.floor((index - 1) / PAGE_SIZE)
    return (pages[page + 1] - 1) * PAGE_SIZE + (index - 1) % PAGE_SIZE + 1
end

local function getSlot(address)
    return remap(address, PAGE_ORDER)
end

local function getAddress(slot)
    return remap(slot, addressPages)
end

-- address order, parents first
local regions = {}

-- address -> innermost region
local regionAt = {}

-- address -> outermost region starting there
local regionStartingAt = {}

-- region fields:
--   label      shown inside its parent ("Button")
--   name       shown on its own ("Gamepad Page 1 - LT + Button"), default: label
--   address    first address
--   size       number of addresses
--   available  can its slots hold actions? default: true
--   unnamed    names its addresses by slot ("Slot 305"), not by region
--   addressNames  a name for each address, if they have their own (gamepad
--                 buttons)
--   section    only groups other regions, so never names an address
--   parent     containing region, if any
--   children   contained regions, in address order. set here
local function addRegion(region)
    region.name = region.name or region.label
    region.slot = getSlot(region.address)
    region.available = region.available ~= false

    regions[#regions + 1] = region

    local parent = region.parent
    if parent then
        parent.children = parent.children or {}
        parent.children[#parent.children + 1] = region
    end

    -- parents come first
    if not region.section then
        regionStartingAt[region.address] = regionStartingAt[region.address] or region
    end

    for address = region.address, region.address + region.size - 1 do
        regionAt[address] = region
    end

    return region
end

--------------------------------------------------------------------------------
-- Action pages
--------------------------------------------------------------------------------

local TOTEM_PAGE = 12

local function actionBar(n)
    return L.ActionBarDisplayName:format(n)
end

local function bonusBar(n)
    return L.BonusBarRegion:format(n)
end

-- by slot page
local PAGE_LABELS = {
    [1] = actionBar(1),
    [6] = actionBar(2),
    [5] = actionBar(3),
    [3] = actionBar(4),
    [4] = actionBar(5),
    [13] = actionBar(6),
    [14] = actionBar(7),
    [15] = actionBar(8),
    [2] = L.ActionPageRegion:format(2),
    [7] = bonusBar(1),
    [8] = bonusBar(2),
    [9] = bonusBar(3),
    [10] = bonusBar(4),
    [11] = Addon:IsGameType('standard') and L.SkyridingRegion or bonusBar(5),
    [TOTEM_PAGE] = L.TotemsRegion,
}

local function getSpellName(spellId)
    if C_Spell and C_Spell.GetSpellName then
        return C_Spell.GetSpellName(spellId)
    end

    return GetSpellInfo and (GetSpellInfo(spellId))
end

local function addTotemSets(totemPage)
    local numSets = NUM_MULTI_CAST_PAGES or 3
    local setSize = PAGE_SIZE / numSets

    for i = 1, numSets do
        local spellId = TOTEM_MULTI_CAST_SUMMON_SPELLS and TOTEM_MULTI_CAST_SUMMON_SPELLS[i]

        addRegion {
            label = (spellId and getSpellName(spellId)) or L.TotemSetRegion:format(i),
            address = totemPage.address + (i - 1) * setSize,
            size = setSize,
            available = totemPage.available,
            parent = totemPage
        }
    end
end

local function addActionPages()
    -- only where there's a totem bar. by game type, not class, so it's the
    -- same for every character
    local hasTotems = Addon:IsGameType('cata', 'wrath', 'forever')

    local section = addRegion {
        label = L.ActionPagesRegion,
        address = 1,
        size = LAST_ORDERED,
        section = true
    }

    for addressPage, page in ipairs(PAGE_ORDER) do
        local region = addRegion {
            label = PAGE_LABELS[page],
            address = (addressPage - 1) * PAGE_SIZE + 1,
            size = PAGE_SIZE,
            available = page ~= TOTEM_PAGE or hasTotems,
            parent = section
        }

        if page == TOTEM_PAGE and region.available then
            addTotemSets(region)
        end
    end
end

--------------------------------------------------------------------------------
-- Gamepad storage
--------------------------------------------------------------------------------

local function addGamepadRegions()
    local K = Constants and Constants.GamepadActionBarConstants
    if not (C_GamepadUI and C_GamepadUI.GetFirstGamepadActionStorageSlotIndex and K) then
        return
    end

    local GROUP_SIZE = K.NUM_SLOTS_PER_GAMEPAD_ACTION_BAR_GROUP
    local BAR_SIZE = GROUP_SIZE * 2

    -- as action buttons show them, in the player's controller style (A, Cross)
    local function keyName(key)
        return GetBindingText(key, true)
    end

    local lt = keyName('PADLTRIGGER')
    local rt = keyName('PADRTRIGGER')

    -- each group's buttons, in slot order: left, top, right, bottom
    local DPAD_KEYS = { 'PADDLEFT', 'PADDUP', 'PADDRIGHT', 'PADDDOWN' }
    local FACE_KEYS = { 'PAD3', 'PAD4', 'PAD2', 'PAD1' }

    -- past the action pages, address == slot
    local address = C_GamepadUI.GetFirstGamepadActionStorageSlotIndex()

    -- "Gamepad Page 1 - LT + Button", or "Gamepad Page 1 - LT + X"
    local function getName(owner, modifier, label)
        return L.GamepadRegionName:format(owner, modifier and L.GamepadModifiersRegion:format(modifier, label) or label)
    end

    local function addGroup(parent, owner, modifier, label, keys)
        local addressNames

        if #keys == GROUP_SIZE then
            addressNames = {}

            for i, key in ipairs(keys) do
                addressNames[i] = getName(owner, modifier, keyName(key))
            end
        end

        addRegion {
            label = label,
            name = getName(owner, modifier, label),
            address = address,
            size = GROUP_SIZE,
            parent = parent,
            addressNames = addressNames
        }

        address = address + GROUP_SIZE
    end

    local function addBar(parent, owner, modifier)
        addGroup(parent, owner, modifier, L.GamepadDpadRegion, DPAD_KEYS)
        addGroup(parent, owner, modifier, L.GamepadFaceRegion, FACE_KEYS)
    end

    -- a bar per modifier. no modifier is D-pad only: its face buttons are
    -- reserved for UI actions
    for i = 1, K.NUM_STANDARD_PAGES_PER_GAMEPAD_ACTION_BAR_PAGE_UNIT do
        local owner = L.GamepadPageRegion:format(i)
        local page = addRegion { label = owner, address = address, size = GROUP_SIZE + 3 * BAR_SIZE }

        addGroup(page, owner, nil, L.GamepadDpadRegion, DPAD_KEYS)

        for _, modifier in ipairs { lt, rt, L.GamepadModifiersRegion:format(lt, rt) } do
            local layer = addRegion {
                label = modifier,
                name = getName(owner, nil, modifier),
                address = address,
                size = BAR_SIZE,
                parent = page
            }

            addBar(layer, owner, modifier)
        end
    end

    local stanceBars = addRegion {
        label = L.GamepadStanceBarsRegion,
        address = address,
        size = K.NUM_GAMEPAD_STANCE_ACTION_BARS * BAR_SIZE,
        section = true
    }

    for i = 1, K.NUM_GAMEPAD_STANCE_ACTION_BARS do
        local owner = L.GamepadStanceBarRegion:format(i)

        addBar(addRegion { label = owner, address = address, size = BAR_SIZE, parent = stanceBars }, owner)
    end

    if address <= NUM_ADDRESSES then
        addRegion { label = L.UnusedRegion, address = address, size = NUM_ADDRESSES - address + 1, unnamed = true }
    end
end

addActionPages()
addGamepadRegions()

local maxSlot = 0
for _, region in ipairs(regions) do
    if region.available and not region.section then
        maxSlot = math.max(maxSlot, region.slot + region.size - 1)
    end
end

--------------------------------------------------------------------------------
-- API
--------------------------------------------------------------------------------

local AddressMap = {}

-- 0 if unavailable or out of range
function AddressMap:GetSlot(address)
    local region = regionAt[address]

    return region and region.available and getSlot(address) or 0
end

function AddressMap:GetAddress(slot)
    return getAddress(slot)
end

-- address order, parents first. don't modify
function AddressMap:GetRegions()
    return regions
end

-- innermost region, or nil
function AddressMap:GetRegion(address)
    return regionAt[address]
end

-- "Gamepad Page 1 - D-Pad Slot 2", or "Slot 305"
local function getSlotName(address)
    local region = regionAt[address]
    if not region or region.unnamed then
        return L.SlotName:format(address)
    end

    return L.RegionSlotName:format(region.name, address - region.address + 1)
end

-- what starts here, for runs of addresses: "Gamepad Page 1", else
-- "Gamepad Page 1 - D-Pad Slot 2", else "Slot 305"
function AddressMap:GetName(address)
    local region = regionStartingAt[address]
    if region and not region.unnamed then
        return region.name
    end

    return getSlotName(address)
end

-- one address, as its button if it has one: "Gamepad Page 1 - LT + X",
-- else "Action Bar 2 Slot 3"
function AddressMap:GetAddressName(address)
    local region = regionAt[address]
    local names = region and region.addressNames

    return names and names[address - region.address + 1] or getSlotName(address)
end

function AddressMap:GetNumAddresses()
    return NUM_ADDRESSES
end

-- last slot that can hold an action
function AddressMap:GetMaxSlot()
    return maxSlot
end

Addon.AddressMap = AddressMap
