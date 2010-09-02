--[[
	KeyBound localization file
		Traditional Chinese by ?
--]]

if (GetLocale() ~= "zhTW") then
	return
end

local REVISION = 90000 + tonumber(("$Revision: 92 $"):match("%d+"))
if (LibKeyBoundLocale10 and REVISION <= LibKeyBoundLocale10.REVISION) then
	return
end

LibKeyBoundLocale10 = {
	REVISION = REVISION;
	Enabled = "按鍵綁定模式已啟用";
	Disabled = "按鍵綁定模式已停用";
	ClearTip = format("按 %s 清除所有綁定", GetBindingText("ESCAPE", "KEY_"));
	NoKeysBoundTip = "目前沒有綁定按鍵";
	ClearedBindings = "從 %s 移除按鍵綁定";
	BoundKey = "設定 %s 到 %s";
	UnboundKey = "取消綁定 %s 從 %s";
	CannotBindInCombat = "無法在戰鬥狀態綁定按鍵";
	CombatBindingsEnabled = "離開戰鬥狀態, 按鍵綁定模式已啟用";
	CombatBindingsDisabled = "進入戰鬥狀態, 按鍵綁定模式已停用";
	BindingsHelp = "將滑鼠停留在按鈕上, 然後按下欲指定快捷鍵之後就能綁定。  要清除目前綁定的按鈕請按 %s.";

	-- This is the short display version you see on the Button
	["Alt"] = "A",
	["Ctrl"] = "C",
	["Shift"] = "S",
	["NumPad"] = "N",

	["Backspace"] = "BS",
	["Button1"] = "鼠1",
	["Button2"] = "鼠2",
	["Button3"] = "鼠3",
	["Button4"] = "鼠4",
	["Button5"] = "鼠5",
	["Button6"] = "鼠6",
	["Button7"] = "鼠7",
	["Button8"] = "鼠8",
	["Button9"] = "鼠9",
	["Button10"] = "鼠10",
	["Button11"] = "鼠11",
	["Button12"] = "鼠12",
	["Button13"] = "鼠13",
	["Button14"] = "鼠14",
	["Button15"] = "鼠15",
	["Button16"] = "鼠16",
	["Button17"] = "鼠17",
	["Button18"] = "鼠18",
	["Button19"] = "鼠19",
	["Button20"] = "鼠20",
	["Button21"] = "鼠21",
	["Button22"] = "鼠22",
	["Button23"] = "鼠23",
	["Button24"] = "鼠24",
	["Button25"] = "鼠25",
	["Button26"] = "鼠26",
	["Button27"] = "鼠27",
	["Button28"] = "鼠28",
	["Button29"] = "鼠29",
	["Button30"] = "鼠30",
	["Button31"] = "鼠31",
	["Capslock"] = "Cp",
	["Clear"] = "Cl",
	["Delete"] = "Del",
	["End"] = "En",
	["Home"] = "HM",
	["Insert"] = "Ins",
	["Mouse Wheel Down"] = "WD",
	["Mouse Wheel Up"] = "WU",
	["Num Lock"] = "NL",
	["Page Down"] = "PD",
	["Page Up"] = "PU",
	["Scroll Lock"] = "SL",
	["Spacebar"] = "Sp",
	["Tab"] = "Tb",

	["Down Arrow"] = "下",
	["Left Arrow"] = "左",
	["Right Arrow"] = "右",
	["Up Arrow"] = "上",
}
setmetatable(LibKeyBoundLocale10, {__index = LibKeyBoundBaseLocale10})
