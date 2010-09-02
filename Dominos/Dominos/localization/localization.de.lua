--[[
	Localization.lua
		Translations for Dominos

	German language
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'deDE')
if not L then return end

--system messages
L.NewPlayer = 'Neues Profil f\195\188r %s erstellt'
L.Updated = 'Aktualisiert auf v%s'

--profiles
L.ProfileCreated = 'Neues Profil "%s" erstellt'
L.ProfileLoaded = 'Profil auf "%s" festgelegt'
L.ProfileDeleted = 'Profil "%s" gel\195\182scht'
L.ProfileCopied = 'Einstellungen von "%s" kopiert'
L.ProfileReset = 'Profil "%s" zur\195\188ckgesetzt'
L.CantDeleteCurrentProfile = 'Das aktuelle Profil kann nicht gel\195\182scht werden'
L.InvalidProfile = 'Ung\195\188ltiges Profil "%s"'

--slash command help
L.ShowOptionsDesc = 'Zeige das Einstellungsmen\195\188'
L.ConfigDesc = 'Konfigurations-Modus an- oder ausschalten'

L.SetScaleDesc = 'Die Skalierung von <frameList> festlegen'
L.SetAlphaDesc = 'Die Transparenz von <frameList> festlegen'
L.SetFadeDesc = 'Die verblassende Transparenz von <frameList> festlegen'

L.SetColsDesc = 'Die Anzahl der Spalten f\195\188r <frameList> festlegen'
L.SetPadDesc = 'Die Auff\195\188llung f\195\188r <frameList> festlegen'
L.SetSpacingDesc = 'Den Abstand f\195\188r <frameList> festlegen'

L.ShowFramesDesc = 'Zeigt <frameList>'
L.HideFramesDesc = 'Versteckt <frameList>'
L.ToggleFramesDesc = '<frameList> an- oder ausschalten'

--slash commands for profiles
L.SetDesc = 'Einstellungen zu <profile> verschieben'
L.SaveDesc = 'Speichert die aktuellen Einstellungen und verschiebt sie zu <profile>'
L.CopyDesc = 'Kopiert die Einstellungen von <profile>'
L.DeleteDesc = 'L\195\182scht <profile>'
L.ResetDesc = 'Standardeinstellungen wiederherstellen'
L.ListDesc = 'Alle Profile auflisten'
L.AvailableProfiles = 'Verf\195\188gbare Profile'
L.PrintVersionDesc = 'Zeigt die aktuelle Version an'

--dragFrame tooltips
L.ShowConfig = '<Rechtsklick> zum Konfigurieren'
L.HideBar = '<Mausradklick oder Umschalt-Rechtsklick> zum Anzeigen'
L.ShowBar = '<Mausradklick oder Umschalt-Rechtsklick> zum Verstecken'
L.SetAlpha = '<Mausrad> um die Transparenz festzulegen (|cffffffff%d|r)'

--minimap button stuff
L.ConfigEnterTip = '<Linksklick> um den Konfigurations-Modus zu betreten'
L.ConfigExitTip = '<Linksklick> um den Konfigurations-Modus zu verlassen'
L.BindingEnterTip = '<Umschalt-Linksklick> um den Tastenbelegungs-Modus zu betreten'
L.BindingExitTip = '<Umschalt-Linksklick> um den Tastenbelegungs-Modus zu verlassen'
L.ShowOptionsTip = '<Rechtsklick> um das Einstellungsmen\195\188 anzuzeigen'

--helper dialog stuff
L.ConfigMode = 'Konfigurations-Modus'
L.ConfigModeExit = 'Konfig-Modus verlassen'
L.ConfigModeHelp = '<Ziehe> irgendeine Leiste um sie zu verschieben.  <Rechtsklick> zum Konfigurieren.  <Mausrad-Klick> oder <Umschalt-Rechtsklick> zum Anzeigen/Verstecken.'

--bar tooltips
L.TipRollBar = 'Zeigt innerhalb einer Gruppe die Fenster zum W\195\188rfeln auf Gegenst\195\164nde.'
L.TipVehicleBar = [[
Zeigt Tasten um mit einem Fahrzeuge zu zielen und es zu verlassen.
Alle weiteren Fahrzeug Aktionen werden in der Spielerleiste angezeigt.]]