--[[
	localization.koKR.lua
	translated & modified by SayClub
]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'koKR')
if not L then return end

--system messages
L.NewPlayer = '%s에 대해 새 프로필이 생성되었습니다.'
L.Updated = 'v%s|1으로;로; 갱신되었습니다.'

--profiles
L.ProfileCreated = '"%s"에 대해 새 프로필이 생성되었습니다.'
L.ProfileLoaded = '프로필을 "%s"|1으로;로; 설정합니다.'
L.ProfileDeleted = '프로필 "%s"|1이;가; 삭제되었습니다.'
L.ProfileCopied = '"%s"에서 설정이 복사되었습니다.'
L.ProfileReset = '프로필 "%s"|1을;를; 초기화합니다.'
L.CantDeleteCurrentProfile = '현재 프로필을 삭제할 수 없습니다.'
L.InvalidProfile = '잘못된 프로필 "%s"'

--slash command help
L.ShowOptionsDesc = '옵션 메뉴를 표시합니다.'
L.ConfigDesc = '설정 모드를 전환합니다.'

L.SetScaleDesc = '<frameList>의 비율을 설정합니다.'
L.SetAlphaDesc = '<frameList>의 투명도를 설정합니다.'
L.SetFadeDesc = '<frameList>의 사라짐 불투명도를 설정합니다.'

L.SetColsDesc = '<frameList>에 대한 행의 갯수를 설정합니다.'
L.SetPadDesc = '<frameList>에 대한 열 간격 레벨을 설정합니다.'
L.SetSpacingDesc = '<frameList>에 대한 행 간격 레벨을 설정합니다.'

L.ShowFramesDesc = '주어진 <frameList>|1을;를; 표시합니다.'
L.HideFramesDesc = '주어진 <frameList>|1을;를; 숨깁니다.'
L.ToggleFramesDesc = '주어진 <frameList>|1을;를; 전환합니다.'

--slash commands for profiles
L.SetDesc = '설정을 <profile>|1으로;로; 교체합니다.'
L.SaveDesc = '현재 설정을 저장하고 <profile>|1으로;로; 교체합니다.'
L.CopyDesc = '<profile>에서 설정을 복사합니다.'
L.DeleteDesc = '<profile>|1을;를; 삭제합니다.'
L.ResetDesc = '기본 설정으로 복귀합니다.'
L.ListDesc = '모든 프로필을 나열합니다.'
L.AvailableProfiles = '가능한 프로필'
L.PrintVersionDesc = '현재 버전을 출력합니다.'

--dragFrame tooltips
L.ShowConfig = '설정: <오른쪽-클릭>'
L.HideBar = '숨기기: <가운데-클릭 혹은 Shift+오른쪽-클릭>'
L.ShowBar = '표시: <가운데-클릭 혹은 Shift+오른쪽-클릭>'
L.SetAlpha = '투명도 설정(|cffffffff%d|r): <마우스휠>'

--minimap button stuff
L.ConfigEnterTip = '<클릭> 설정 모드 들어가기'
L.ConfigExitTip = '<클릭> 설정 모드 종료하기'
L.BindingEnterTip = '<Shift+클릭> 단축키 모드 들어가기'
L.BindingExitTip = '<Shift+클릭> 단축키 모드 종료하기'
L.ShowOptionsTip = '<오른쪽-클릭> 옵션 메뉴 표시'

--helper dialog stuff
L.ConfigMode = '설정 모드'
L.ConfigModeExit = '설정 모드 종료'
L.ConfigModeHelp = '<끌기> 바 이동.  <오른쪽-클릭> 설정.  <가운데-클릭> 또는 <Shift-오른쪽-클릭> 표시 전환'

--bar tooltips
L.TipRollBar = '파티 및 공격대시 아이템 주사위 프레임을 표시합니다.'
L.TipVehicleBar = [[
차량 내리기 버튼을 표시합니다.
모든 다른 탈것의 행동을 추가바에 표시합니다.]]

L.BarDisplayName = "%s 바" 
L.ActionBarDisplayName = "행동 단축바 %s"
