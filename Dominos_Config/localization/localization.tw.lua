--[[
	zhTW (convert from zhCN)
		xuxianhe@gmail.com
        yaroot##gmail#com
]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos-Config', 'zhTW')
if not L then return end

L.Scale = '縮放'
L.Opacity = '透明度'
L.FadedOpacity = '遮罩透明度'
L.Visibility = '可見度'
L.Spacing = '間隔'
L.Padding = '填充'
L.Layout = '布局'
L.Columns = '列'
L.Size = '大小'
L.Modifiers = '修飾鍵'
L.QuickPaging = '快速翻頁'
L.Targeting = '選擇目標時'
L.ShowStates = '顯示狀態'
L.Set = '設置'
L.Save = '保存'
L.Copy = '復制'
L.Delete = '刪除'
L.Bar = '動作條 %d'
L.RightClickUnit = '右鍵點擊'
L.RCUPlayer = '自己'
L.RCUFocus = '焦點'
L.RCUToT = '目標的目標'
L.EnterName = '輸入名稱'
L.PossessBar = '載具'
L.Profiles = '配置管理'
L.ProfilesPanelDesc = '允許你管理Dominos插件的配置'
L.SelfcastKey = '自我施法按鍵'
L.QuickMoveKey = '快速移動按鍵'
L.ShowMacroText = '顯示宏名稱'
L.ShowBindingText = '顯示綁定按鍵'
L.ShowEmptyButtons = '顯示空按鈕'
L.LockActionButtons = '鎖定動作條位置'
L.EnterBindingMode = '綁定按鍵...'
L.EnterConfigMode = '進入設置模式'
L.ActionBarSettings = '動作條 %d 設置'
L.BarSettings = '%s 動作條設置'
L.ShowTooltips = '顯示提示'
L.ShowTooltipsCombat = '戰鬥中顯示鼠標提示'
L.OneBag = '整合背包'
L.ShowKeyring = '顯示鑰匙圈'
L.StickyBars = '粘附動作條'
L.ShowMinimapButton = '顯示小地圖圖標'
L.Advanced = '高級'
L.LeftToRight = '按鈕從左至右排列'
L.TopToBottom = '按鈕從上至下排列'
L.LinkedOpacity = '粘附動作條繼承透明度'
L.ClickThrough = '允許穿透點擊'
L.DisableMenuButtons = '隱藏按鈕'
L.ShowOverrideUI = '使用默認載具介面'
L.ShowInOverrideUI = '載具介面'
L.ShowInPetBattleUI = '寵物戰鬥介面'

L.ALT_KEY_TEXT = 'ALT'

L.State_HELP = '幫助'
L.State_HARM = '損害'
L.State_NOTARGET = '無目標'
L.State_ALTSHIFT = 'ALT-' .. SHIFT_KEY_TEXT
L.State_CTRLSHIFT = CTRL_KEY_TEXT .. '-' .. SHIFT_KEY_TEXT
L.State_CTRLALT = CTRL_KEY_TEXT .. '-ALT'
L.State_CTRLALTSHIFT = CTRL_KEY_TEXT .. '-ALT-' .. SHIFT_KEY_TEXT

--totems
L.ShowTotems = '顯示圖騰'
L.ShowTotemRecall = '顯示回收'
