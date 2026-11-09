--[[
	Localization_zhCN.lua
	2008/12/4 Modified by xuxianhe@gmail.com
    Sep 9. 2012 yaroot##gmail#com
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos-Config', 'zhCN')
if not L then return end

L.ActionBarBehavior = "动作条行为"
L.ActionButtonLookAndFeel = "动作按钮外观"
L.BagBarShowBags = "显示背包"
L.BagBarShowKeyRing = "显示钥匙扣"
L.Bar = '动作条 %d'
L.ClickThrough = '允许穿透点击'
L.CopyProfile = '复制配置...'
L.EnterBindingMode = '绑定按键...'
L.EnterConfigMode = '进入设置模式'
L.ExtraBarShowBlizzardTexture = '显示暴雪材质'
L.FadedOpacity = '透明度'
L.FrameStrata = "框体层级"
L.FrameStrata_MEDIUM = "中"
L.FrameLevel = "框体级别"
L.Layout = '布局'
L.LinkedOpacity = '粘附动作条继承透明度'
L.Modifiers = '功能键翻页'
L.Padding = '边距'
L.Paging = "翻页"
L.PossessBar = '载具'
L.PossessBarDesc = "在某些情况下控制敌人时将哪个动作条用来显示特殊动作"
L.Profiles = '配置管理'
L.QuickPaging = '快速翻页'
L.RCUPlayer = '自己'
L.ResetProfile = '重置配置...'
L.RightClickUnit = '右键点击'
L.RowOffset = "列偏移"
L.RowSpacing = "行间距"
L.Scale = '缩放'
L.Set = '选中'
L.ShowBindingText = '显示按键绑定文字'
L.ShowCountText = "显示数量文字"
L.ShowEquippedItemBorders = '显示已装备物品边框'
L.ShowInOverrideUI = '载具界面'
L.ShowInPetBattleUI = '宠物战斗界面'
L.ShowMacroText = '显示宏名称'
L.ShowMinimapButton = '显示小地图按钮'
L.ShowOverrideUI = '使用默认载具界面'
L.ShowOverrideUIDesc = "当驾驶载具等情况下显示暴雪覆盖UI"
L.ShowSpellAnimations = "显示技能动画"
L.ShowSpellGlows = "显示技能高亮"
L.ShowStates = '显示隐藏条件'
L.ShowTooltips = '显示鼠标提示'
L.Spacing = '按钮间隔'
L.State_HARM = '敌对目标'
L.State_HELP = '友方目标'
L.State_NOTARGET = '无目标'
L.State_SHIELD = "持盾"
L.StickyBars = '粘附动作条'
L.ThemeActionButtons = '启用动作条主题 (需要重载界面)'
L.ThemeActionButtonsDesc = "启用时，对动作按钮应用一些自定义样式，未启用时，保持不变"
L.Visibility = '可见性' --NOUSE

-- derived translations
L.State_ALTSHIFT = strjoin('-', ALT_KEY_TEXT, SHIFT_KEY_TEXT)
L.State_CTRLALT = strjoin('-', CTRL_KEY_TEXT, ALT_KEY_TEXT)
L.State_CTRLALTSHIFT = strjoin('-', CTRL_KEY_TEXT, ALT_KEY_TEXT, SHIFT_KEY_TEXT)
L.State_CTRLSHIFT = strjoin('-', CTRL_KEY_TEXT, SHIFT_KEY_TEXT)

L.State_META = IsMacClient() and 'Command 键' or 'Meta 键'

L.Width = '宽'
L.Height = '高'
L.Font = '字体'
L.Texture = '材质'
