local _, Addon = ...
local Dominos = LibStub('AceAddon-3.0'):GetAddon('Dominos')
local MirrorTimerBar = Addon.MirrorTimerBar
local TimerBarMenu = Addon.TimerBarMenu

MirrorTimerBar.contextMenu = Dominos.Frame.contextMenu:Extend {
    TimerBarMenu.SizeControls,
    -- drop downs before sliders, like the other panels
    {
        insert = 'General',
        at = 'start',
        controls = {
            {
                type = 'dropdown',
                name = 'Orientation',
                locale = 'Dominos-CastBar',
                items = {
                    { value = 'VERTICAL', text = 'Orientation_VERTICAL' },
                    { value = 'HORIZONTAL', text = 'Orientation_HORIZONTAL' }
                },
                get = 'GetOrientation',
                set = 'SetOrientation'
            }
        }
    },
    {
        insert = 'General',
        after = 'HeightSlider',
        controls = {
            {
                type = 'slider',
                name = 'Spacing',
                min = 0,
                max = 64,
                softLimits = true,
                get = 'GetSpacing',
                set = 'SetSpacing'
            }
        }
    },
    TimerBarMenu:AppearancePanel(),
    TimerBarMenu:ColorsPanel {
        TimerBarMenu:ColorControl('EXHAUSTION'),
        TimerBarMenu:ColorControl('BREATH'),
        TimerBarMenu:ColorControl('DEATH'),
        TimerBarMenu:ColorControl('FEIGNDEATH')
    }
}
