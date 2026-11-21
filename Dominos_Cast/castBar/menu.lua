local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local CastBar = Addon.CastBar
local TimerBarMenu = Addon.TimerBarMenu

-- for demo spells without a cast time
local DEMO_CAST_TIME = 3

local function getSpellInfo(spellID)
    local info = C_Spell.GetSpellInfo(spellID)
    if info then
        return info.name, info.iconID, info.castTime
    end
end

-- in case the spellbook is mostly flyouts and future spells
local RANDOM_SPELL_TRIES = 100

-- some classic clients still have the old spellbook api
local getRandomSpellID

if C_SpellBook and C_SpellBook.GetSpellBookSkillLineInfo then
    getRandomSpellID = function()
        local line = C_SpellBook.GetSpellBookSkillLineInfo(C_SpellBook.GetNumSpellBookSkillLines())
        local numSlots = line.itemIndexOffset + line.numSpellBookItems

        for _ = 1, RANDOM_SPELL_TRIES do
            local spell = C_SpellBook.GetSpellBookItemInfo(math.random(1, numSlots), Enum.SpellBookSpellBank.Player)

            if spell and spell.spellID then
                return spell.spellID
            end
        end
    end
else
    getRandomSpellID = function()
        local _, _, offset, numSlots = GetSpellTabInfo(GetNumSpellTabs())

        for _ = 1, RANDOM_SPELL_TRIES do
            local _, spellID = GetSpellBookItemInfo(math.random(1, offset + numSlots), BOOKTYPE_SPELL)

            if spellID then
                return spellID
            end
        end
    end
end

-- a random spell, cast on repeat while the menu is open
function CastBar:StartDemo()
    local spellID = getRandomSpellID()
    if not spellID then
        return
    end

    local name, iconID, castTime = getSpellInfo(spellID)

    if castTime and castTime > 0 then
        castTime = castTime / 1000
    else
        castTime = DEMO_CAST_TIME
    end

    self:SetCast('demo', spellID, nil, nil, castTime)

    local duration = self.duration
    duration:SetTimeFromStart(GetTime(), castTime)

    self.timer:StartCast(name, iconID, duration, Enum.StatusBarTimerDirection.ElapsedTime)
    self:UpdateColors()
    self:UpdateLatency()

    self:CancelDemo()
    self.demoTimer = C_Timer.NewTimer(castTime, function()
        if self.menuShown and self.state == 'demo' then
            self:StartDemo()
        end
    end)
end

function CastBar:CancelDemo()
    if self.demoTimer then
        self.demoTimer:Cancel()
        self.demoTimer = nil
    end
end

function CastBar:OnMenuShown()
    self.menuShown = true

    if not self:IsCasting() then
        self:StartDemo()
    end
end

function CastBar:OnMenuHidden()
    self.menuShown = nil
    self:CancelDemo()

    if self.state == 'demo' then
        self:Finish()
    end
end

CastBar.contextMenu = Dominos.Frame.contextMenu:Extend {
    TimerBarMenu.SizeControls,
    TimerBarMenu:AppearancePanel {
        {
            type = 'check',
            name = 'Display_icon',
            get = 'ShowingIcon',
            set = 'SetShowIcon'
        },
        {
            type = 'check',
            name = 'Display_spark',
            get = 'ShowingSpark',
            set = 'SetShowSpark'
        },
        {
            type = 'sliderWithCheck',
            name = 'Display_latency',
            min = 0,
            max = 500,
            get = 'GetLatencyPadding',
            set = 'SetLatencyPadding',
            check = {
                get = 'ShowingLatency',
                set = 'SetShowLatency'
            }
        }
    },
    TimerBarMenu:ColorsPanel {
        {
            type = 'check',
            name = 'UseSpellReactionColors',
            tooltip = 'UseSpellReactionColorsTip',
            get = 'UseSpellReactionColors',
            set = 'SetUseSpellReactionColors'
        },
        TimerBarMenu:ColorControl('help', 'UseSpellReactionColors'),
        TimerBarMenu:ColorControl('harm', 'UseSpellReactionColors'),
        TimerBarMenu:ColorControl('cast'),
        TimerBarMenu:ColorControl('channel'),
        TimerBarMenu:ColorControl('tradeskill'),
        TimerBarMenu:ColorControl('uninterruptible'),
        TimerBarMenu:ColorControl('failed')
    }
}
