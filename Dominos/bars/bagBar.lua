--------------------------------------------------------------------------------
--	Bag Bar - A bar for holding bag buttons
--------------------------------------------------------------------------------

local AddonName, Addon = ...
local L = LibStub("AceLocale-3.0"):GetLocale(AddonName)

-- register buttons for use later
local BagButtons = {}

local BagBar = Addon:CreateClass('Frame', Addon.ButtonBar)

function BagBar:New()
    return BagBar.proto.New(self, 'bags')
end

function BagBar:GetDisplayName()
    return L.BagBarDisplayName
end

function BagBar:GetDefaults()
    if Addon:IsBuild("retail") then
        return {
            displayLayer = 'LOW',
            point = 'BOTTOMRIGHT',
            oneBag = false,
            keyRing = false,
            spacing = 2
        }
    else
        return {
            displayLayer = 'LOW',
            point = 'BOTTOMRIGHT',
            x = 0,
            y = 40,
            oneBag = false,
            keyRing = GetCVarBool('showKeyring') or false,
            spacing = 2
        }
    end
end

function BagBar:SetShowBags(enable)
    self.sets.oneBag = not enable
    self:UpdateBagSlots()
    self:ReloadButtons()
end

function BagBar:ShowBags()
    return not self.sets.oneBag
end

function BagBar:SetShowKeyRing(enable)
    self.sets.keyRing = enable and true
    self:UpdateBagSlots()
    self:ReloadButtons()
end

function BagBar:ShowKeyRing()
    return self.sets.keyRing and not Addon:IsBuild('retail', 'mists', 'cata')
end

-- the bag bar has variable sized buttons, so use a bit of a more complicated
-- layout function to better help with this.
function BagBar:Layout()
    local buttonCount = math.min(self:NumButtons(), #self.buttons)
    if buttonCount == 0 then
        ButtonBar.proto.Layout(self)
        return
    end

    local columnCount = math.max(1, math.min(self:NumColumns(), buttonCount))
    local rowCount = math.ceil(buttonCount / columnCount)

    local leftInset, _, topInset = self:GetButtonInsets()
    local defaultButtonWidth, defaultButtonHeight = self:GetButtonSize()
    local paddingWidth, paddingHeight = self:GetPadding()
    local columnSpacing = self:GetSpacing()
    local rowSpacing = self:GetRowSpacing()
    local rowOffset = self:GetRowOffset()
    local leftToRight = self:GetLeftToRight()
    local topToBottom = self:GetTopToBottom()

    local columnWidths = {}
    local rowHeights = {}
    local columnOffsets = {}
    local rowOffsets = {}
    local buttonRows = {}
    local buttonColumns = {}

    -- Measure the widest button in each column and tallest in each row.
    for column = 1, columnCount do
        columnWidths[column] = 0
    end
    for row = 1, rowCount do
        rowHeights[row] = 0
    end

    for buttonIndex = 1, buttonCount do
        local row = math.floor((buttonIndex - 1) / columnCount) + 1
        local column = (buttonIndex - 1) % columnCount + 1

        if not topToBottom then
            row = rowCount - row + 1
        end
        if not leftToRight then
            column = columnCount - column + 1
        end

        buttonRows[buttonIndex] = row
        buttonColumns[buttonIndex] = column

        local buttonWidth, buttonHeight = self.buttons[buttonIndex]:GetSize()
        buttonWidth = buttonWidth > 0 and buttonWidth or defaultButtonWidth
        buttonHeight = buttonHeight > 0 and buttonHeight or defaultButtonHeight

        columnWidths[column] = math.max(columnWidths[column], buttonWidth)
        rowHeights[row] = math.max(rowHeights[row], buttonHeight)
    end

    -- Calculate each column's and row's starting offset.
    local gridWidth, gridHeight = 0, 0

    for column = 1, columnCount do
        columnOffsets[column] = gridWidth
        gridWidth = gridWidth + columnWidths[column] + columnSpacing
    end
    for row = 1, rowCount do
        rowOffsets[row] = gridHeight
        gridHeight = gridHeight + rowHeights[row] + rowSpacing
    end

    gridWidth = gridWidth - columnSpacing
    gridHeight = gridHeight - rowSpacing

    -- Place each button in its grid cell.
    for buttonIndex = 1, buttonCount do
        local row = buttonRows[buttonIndex]
        local column = buttonColumns[buttonIndex]
        local horizontalRowOffset =
            (rowOffset >= 0 and row - 1 or row - rowCount) * rowOffset

        local x = paddingWidth - leftInset
            + columnOffsets[column]
            + horizontalRowOffset
        local y = paddingHeight - topInset + rowOffsets[row]

        local button = self.buttons[buttonIndex]
        button:ClearAllPoints()
        button:SetParent(self)
        button:SetPoint('TOPLEFT', x, -y)
    end

    self:TrySetSize(
        gridWidth + 2 * paddingWidth + math.abs(rowOffset) * (rowCount - 1),
        gridHeight + 2 * paddingHeight
    )
end

-- Frame Overrides
BagBar:Extend(
    'OnCreate',
    function(self)
        self.bagSlots = {}
    end
)

BagBar:Extend(
    'OnLoadSettings',
    function(self)
        self:UpdateBagSlots()
    end
)

do
    local function maybeAddBagSlot(bagSlots, buttonName)
        local button = _G[buttonName]
        if button then
            bagSlots[#bagSlots+1] = button
        end
    end

    function BagBar:UpdateBagSlots()
        local slots = self.bagSlots

        table.wipe(slots)

        if self:ShowKeyRing() then
            local buttonName = Addon:IsBuild("forever") and 'KeyRingButton' or AddonName .. 'KeyRingButton'
            maybeAddBagSlot(slots, buttonName)
        end

        if self:ShowBags() then
            maybeAddBagSlot(slots, 'CharacterReagentBag0Slot')

            for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
                maybeAddBagSlot(slots, ('CharacterBag%dSlot'):format(slot))
            end
        end

        maybeAddBagSlot(slots, 'MainMenuBarBackpackButton')
    end
end

function BagBar:AcquireButton(index)
    return self.bagSlots[index]
end

function BagBar:OnAttachButton(button)
    button:Show()
end

function BagBar:NumButtons()
    return #self.bagSlots
end

if Addon:IsBuild("retail") then
    function BagBar:GetButtonSize()
        local w, h = MainMenuBarBackpackButton:GetSize()
        local l, r, t, b = self:GetButtonInsets()

        return w - (l + r), h - (t + b)
    end
end

function BagBar:OnCreateMenu(menu)
    local L = LibStub('AceLocale-3.0'):GetLocale('Dominos-Config')

    local layoutPanel = menu:NewPanel(L.Layout)

    layoutPanel:NewCheckButton {
        name = L.BagBarShowBags,
        get = function()
            return layoutPanel.owner:ShowBags()
        end,
        set = function(_, enable)
            layoutPanel.owner:SetShowBags(enable)
            layoutPanel.colsSlider:UpdateRange()
            layoutPanel.colsSlider:UpdateValue()
        end
    }

    if not Addon:IsBuild('retail', 'mists', 'cata') then
        layoutPanel:NewCheckButton {
            name = L.BagBarShowKeyRing,
            get = function()
                return layoutPanel.owner:ShowKeyRing()
            end,
            set = function(_, enable)
                layoutPanel.owner:SetShowKeyRing(enable)
                layoutPanel.colsSlider:UpdateRange()
                layoutPanel.colsSlider:UpdateValue()
            end
        }
    end

    layoutPanel:AddLayoutOptions()

    menu:AddFadingPanel()
    menu:AddAdvancedPanel()
end

--------------------------------------------------------------------------------
--	module
--------------------------------------------------------------------------------

local BagBarModule = Addon:NewModule('BagBar', 'AceEvent-3.0')

function BagBarModule:Load()
    if self.frame == nil then
        self.frame = BagBar:New()
    end
end

function BagBarModule:Unload()
    if self.frame then
        self.frame:Free()
        self.frame = nil
    end
end

function BagBarModule:OnFirstLoad()
    if BagsBar then
        BagsBar:SetParent(Addon.ShadowUIParent)
    end

    -- use our own handling for the blizzard bag bar
    if MainMenuBarManager then
        EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", MainMenuBarManager)
        EventRegistry:UnegisterFrameEventAndCallback("VARIABLES_LOADED", MainMenuBarManager)
    elseif BagsBar then
        EventRegistry:UnregisterCallback("MainMenuBarManager.OnExpandChanged", BagsBar)
        hooksecurefunc(BagsBar, "Layout", function() self:LayoutBagBar() end)
    end

    if BagBarExpandToggle then
        BagBarExpandToggle:Hide()
    end

    self:RegisterButton('CharacterReagentBag0Slot')

    for slot = (NUM_BAG_SLOTS - 1), 0, -1 do
        self:RegisterButton(('CharacterBag%dSlot'):format(slot))
    end

    self:RegisterKeyRingButton()
    self:RegisterButton('MainMenuBarBackpackButton')

    self.RegisterKeyRingButton = nil
    self.RegisterButton = nil

    self:RegisterEvent("PLAYER_REGEN_ENABLED", "LayoutBagBar")

    for _, button in pairs(BagButtons) do
        Addon:GetModule('ButtonThemer'):Register(
            button,
            'Bag Bar',
            {
                Icon = button.icon
            }
        )
    end
end

function BagBarModule:LayoutBagBar()
    if InCombatLockdown() then
        self.needsUpdate = true
        return
    end

    if self.frame then
        self.frame:Layout()
    end

    self.needsUpdate = nil
end

if Addon:IsBuild("retail") then
    function BagBarModule:RegisterButton(name)
        local button = _G[name]
        if not button then
            return
        end

        button:SetSize(MainMenuBarBackpackButton:GetSize())
        button:Hide()

        if button.SetBarExpanded then
            button.SetBarExpanded = function() end
        end

        BagButtons[#BagButtons + 1] = button
    end
elseif Addon:IsBuild("mists", "cata", "wrath") then
    function BagBarModule:RegisterButton(name)
        local button = _G[name]
        if not button then
            return
        end

        button:Hide()
        button:SetSize(36, 36)
        button.IconBorder:SetSize(37, 37)
        button.IconOverlay:SetSize(37, 37)

        _G[button:GetName() .. 'NormalTexture']:SetSize(64, 64)

        BagButtons[#BagButtons + 1] = button
    end
else
    function BagBarModule:RegisterButton(name)
        local button = _G[name]
        if not button then
            return
        end

        button:Hide()
        BagButtons[#BagButtons + 1] = button
    end
end

function BagBarModule:RegisterKeyRingButton()
    if Addon:IsBuild("forever") then
        self:RegisterButton('KeyRingButton')
        return
    end

    if Addon:IsBuild("vanilla", "tbc") then
        -- force hide the old keyring button
        KeyRingButton:Hide()

        -- setup the dominos specific one
        local keyring = CreateFrame('CheckButton', AddonName .. 'KeyRingButton', UIParent, 'ItemButtonTemplate')

        keyring:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        keyring:SetID(KEYRING_CONTAINER)
        keyring.icon:SetTexture([[Interface\Icons\INV_Misc_Bag_16]])

        keyring:SetScript('OnClick', function()
            if CursorHasItem() then
                PutKeyInKeyRing()
            else
                ToggleBag(KEYRING_CONTAINER)
            end
        end)

        keyring:SetScript('OnReceiveDrag', function()
            if CursorHasItem() then
                PutKeyInKeyRing()
            end
        end)

        keyring:SetScript('OnEnter', function(frame)
            GameTooltip:SetOwner(frame, 'ANCHOR_LEFT')

            local color = HIGHLIGHT_FONT_COLOR
            GameTooltip:SetText(KEYRING, color.r, color.g, color.b)
            GameTooltip:AddLine()
        end)

        keyring:SetScript('OnLeave', function()
            GameTooltip:Hide()
        end)

        MainMenuBarBackpackButton:HookScript('OnClick', function()
            if IsControlKeyDown() then
                ToggleBag(KEYRING_CONTAINER)
            end
        end)

        -- prevent the button from coming back
        hooksecurefunc('MainMenuBar_UpdateKeyRing', function()
            KeyRingButton:Hide()
        end)

        self:RegisterButton(keyring:GetName())
    end
end
