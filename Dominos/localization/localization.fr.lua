--[[
	Localization_frFR.lua
		Translations for Dominos

	French
--]]
-- French version (by Kubik of Vol'Jin) 2000-10-23
-- à = \195\160
-- â = \195\162
-- ç = \195\167
-- è = \195\168
-- é = \195\169
-- ê = \195\170
-- î = \195\174
-- ï = \195\175
-- ô = \195\180
-- û = \195\187

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'frFR')
if not L then return end

--system messages
L.NewPlayer = 'Nouveau profil cr\195\169\195\169 pour %s'
L.Updated = 'Mise \195\160 jour de v%s'

--profiles
L.ProfileCreated = 'Cr\195\169ation nouveau profil "%s"'
L.ProfileLoaded = 'Charger profil "%s"'
L.ProfileDeleted = 'Effacer profil "%s"'
L.ProfileCopied = 'R\195\169glages copi\195\169s de "%s"'
L.ProfileReset = 'R\195\169initialisation profil "%s"'
L.CantDeleteCurrentProfile = 'Le profil courant ne peut \195\170tre effac\195\169'
L.InvalidProfile = 'Profile invalide "%s"'

--slash command help
L.ShowOptionsDesc = 'Afficher le menu options'
L.ConfigDesc = 'Basculer en mode configuration'

L.SetScaleDesc = 'Fixe l\'\195\169chelle de <frameList>'
L.SetAlphaDesc = 'Fixe l\'opacit\195\169 de <frameList>'
L.SetFadeDesc = 'Fixe l\'opacit\195\169 att\195\169nu\195\169e de <frameList>'

L.SetColsDesc = 'Fixe le nombre de colonnes pour <frameList>'
L.SetPadDesc = 'Fixe le niveau de remplissage de <frameList>'
L.SetSpacingDesc = 'Fixe l\'espacement de <frameList>'

L.ShowFramesDesc = 'Montre la <frameList>'
L.HideFramesDesc = 'Cache la <frameList>'
L.ToggleFramesDesc = 'Bascule entre <frameList>'

--slash commands for profiles
L.SetDesc = 'R\195\169glages activ\195\169s : <profile>'
L.SaveDesc = 'R\195\169glages enregistr\195\169s et bascule sur <profile>'
L.CopyDesc = 'Copie des r\195\169glages de <profile>'
L.DeleteDesc = 'Effacer <profile>'
L.ResetDesc = 'Retourn aux r\195\169glages par d\195\169faut'
L.ListDesc = 'Liste des profils'
L.AvailableProfiles = 'Profils disponibles'
L.PrintVersionDesc = 'Afficher la version'

--dragFrame tooltips
L.ShowConfig = '<Clic droit> pour configurer'
L.HideBar = '<Clic milieu ou Shift-Clic droit> pour cacher'
L.ShowBar = '<Clic milieu ou Shift-Clic droit> pour montrer'
L.SetAlpha = "<Roue de souris> pour r\195\169gler l'opacit\195\169 (|cffffffff%d|r)"

--minimap button stuff
L.ConfigEnterTip = '<Clic gauche> mode configuration'
L.ConfigExitTip = '<Clic gauche> sortir du mode configuration'
L.BindingEnterTip = '<Shift clic gauche> configurer les raccourcis'
L.BindingExitTip = '<Shift clic gauche> arr\195\170ter la config. des raccourcis'
L.ShowOptionsTip = '<Clic droit> afficher le menu d\'options'

--helper dialog stuff
L.ConfigMode = 'Mode Configuration'
L.ConfigModeExit = 'Sortir du Mode Config.'
L.ConfigModeHelp = '<Clic-drag> d\195\169place la barre.  <Clic droit> configurer.  <Clic milieu> ou <Shift-Clic droit> visible/invisible'

--bar tooltips
L.TipRollBar = 'Affiche le cadre des objets tir\195\169s au sort, lorsqu\'on est en groupe.'
L.TipVehicleBar = [[
Affiche les contr\195\180les de vis\195\169e et de sortie du v\195\169hicule.
Toutes les autres actions sont sur la barre de contr\195\180le du v\195\169hicule.]]