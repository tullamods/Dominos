--[[
    zhTW (convert from zhCN)
    xuxianhe@gmail.com
    yaroot##gmail#com
]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'zhTW')
if not L then return end

--system messages
L.NewPlayer = '建立新配置 %s'
L.Updated = '升級到 v%s'

--profiles
L.ProfileCreated = '建立新配置 "%s"'
L.ProfileLoaded = '配置設置為 "%s"'
L.ProfileDeleted = '刪除配置 "%s"'
L.ProfileCopied = '從 "%s" 復制配置到 "%s"'
L.ProfileReset = '重置配置 "%s"'
L.CantDeleteCurrentProfile = '不能刪除當前配置'
L.InvalidProfile = '無效的配置文件 "%s"'

--slash command help
L.ShowOptionsDesc = '顯示設置菜單'
L.ConfigDesc = '設置模式開關'

L.SetScaleDesc = '縮放 <frameList>'
L.SetAlphaDesc = '透明度 <frameList>'
L.SetFadeDesc = '遮罩透明度 <frameList>'

L.SetColsDesc = '列 <frameList>'
L.SetPadDesc = '填充 <frameList>'
L.SetSpacingDesc = '間隔 <frameList>'

L.ShowFramesDesc = '顯示 <frameList>'
L.HideFramesDesc = '隱藏 <frameList>'
L.ToggleFramesDesc = '開關 <frameList>'

--slash commands for profiles
L.SetDesc = '配置切換為 <profile>'
L.SaveDesc = '保存當前配置為 <profile>'
L.CopyDesc = '從 <profile> 復制配置'
L.DeleteDesc = '刪除 <profile>'
L.ResetDesc = '返回默認配置'
L.ListDesc = '列出所有配置'
L.AvailableProfiles = '可用設置'
L.PrintVersionDesc = '顯示當前版本'

--dragFrame tooltips
L.ShowConfig = '<右鍵> 設置'
L.HideBar = '<中鍵或者Shift+右鍵> 隱藏'
L.ShowBar = '<中鍵或者Shift+右鍵> 顯示'
L.SetAlpha = '<滾輪> 設置透明度 (|cffffffff%d|r)'

--minimap button stuff
L.ConfigEnterTip = '<左鍵> 進入設置模式'
L.ConfigExitTip = '<右鍵> 離開設置模式'
L.BindingEnterTip = '<Shift+左鍵> 進入按鍵綁定模式'
L.BindingExitTip = '<Shift+左鍵> 退出按鍵綁定模式'
L.ShowOptionsTip = '<Right Click> to show the options menu'

--helper dialog stuff
L.ConfigMode = '設置模式'
L.ConfigModeExit = '離開設置模式'
L.ConfigModeHelp = '<拖動> 動作條.  <右鍵> 打開設置.  <中鍵> 或 <Shift-右鍵> 隱藏/顯示動作條'

--bar tooltips
L.TipRollBar = '在团队中显示物品掷点面板'
L.TipVehicleBar = [[
显示瞄准和离开载具的控制按钮.
其他载具按钮将在心灵控制条上显示.]]
