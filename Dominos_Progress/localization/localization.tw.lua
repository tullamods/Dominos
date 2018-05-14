--[[
	localization.tw.lua	
	2016/7/18 New translations by 彩虹ui https://www.facebook.com/rainbowui/
	
	Triditional Chinese 繁體中文
]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos-Progress', 'zhTW')
if not L then return end

L.Texture = '材質'
L.Width = '寬度'
L.Height = '高度'
L.AlwaysShowText = '保持顯示文字'
L.Segmented = '區段格子'
L.Font = '文字'
L.LockDisplayMode = ('%s %s %s'):format(_G.LOCK, _G.DISPLAY, _G.MODE)
L.ShowLabels = '顯示標籤文字'
L.CompressValues = '顯示簡短的數值'