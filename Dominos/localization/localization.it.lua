--[[Dominos Localization - Italian]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'itIT')
if not L then return end

--system messages
L.NewPlayer = 'Creato un nuovo profilo per %s'
L.Updated = 'Aggiornato alla v%s'

--profiles
L.ProfileCreated = 'Creato il nuovo profilo "%s"'
L.ProfileLoaded = 'Impostato il profilo come "%s"'
L.ProfileDeleted = 'Il profilo "%s" è stato cancellato'
L.ProfileCopied = 'Impostazioni copiate da "%s"'
L.ProfileReset = 'Ripristino del profilo "%s"'
L.CantDeleteCurrentProfile = 'Non è possibile cancellare il profilo corrente'
L.InvalidProfile = '"%s" non è un profilo valido'

--slash command help
L.ShowOptionsDesc = 'Mostra il menù opzioni'
L.ConfigDesc = 'Attiva la modalità configurazione'

L.SetScaleDesc = 'Imposta le proporzioni di <frameList>'
L.SetAlphaDesc = "Imposta l'opacità di <frameList>"
L.SetFadeDesc = "Imposta la dissolvenza di <frameList>"

L.SetColsDesc = 'Imposta il numero di colonne per <frameList>'
L.SetPadDesc = "Imposta l'imbottitura per <frameList>"
L.SetSpacingDesc = 'Imposta la distanza per <frameList>'

L.ShowFramesDesc = 'Mostra la barra <frameList>'
L.HideFramesDesc = 'Nascondi la barra <frameList>'
L.ToggleFramesDesc = 'Visualizzazione della barra <frameList>'

--slash commands for profiles
L.SetDesc = 'Scambia le impostazioni con <profile>'
L.SaveDesc = 'Salva le impostazioni correnti e passa a <profile>'
L.CopyDesc = 'Copia le impostazioni da <profile>'
L.DeleteDesc = 'Cancella <profile>'
L.ResetDesc = 'Ritorna alle impostazioni predefinite'
L.ListDesc = 'Elenca tutti i profili'
L.AvailableProfiles = 'Profili disponibili'
L.PrintVersionDesc = 'Mostra la versione corrente'

--dragFrame tooltips
L.ShowConfig = '<Clic Destro> per configurare.'
L.HideBar = '<Clic Centrale o Shift+Clic Destro> per nascondere.'
L.ShowBar = '<Clic Centrale o Shift+Clic Destro> per mostrare.'
L.SetAlpha = "<Rotella del mouse> per impostare l'opacità (|cffffffff%d|r)"

--minimap button stuff
L.ConfigEnterTip = '<Clic Sinistro> per entrare nella modalità configurazione.'
L.ConfigExitTip = '<Clic Sinistro> per uscire dalla modalità configurazione.'
L.BindingEnterTip = '<Shift+Clic Sinistro> per entrare nella modalità assegnazione.'
L.BindingExitTip = '<Shift+Clic Sinistro> per uscire dalla modalità assegnazione.'
L.ShowOptionsTip = '<Clic Destro> per mostrare il menù opzioni.'

--helper dialog stuff
L.ConfigMode = 'Modalità Configurazione'
L.ConfigModeExit = 'Esci dalla Modalità Configurazione'
L.ConfigModeHelp = '<Trascina> qualsiasi barra per muoverla, <Clic Destro> per configurare e <Clic Centrale> o <Shift+Clic Destro> per cambiare la visibilità.'

--bar tooltips
L.TipRollBar = 'Mostra la finestra dei tiri del bottino quando ci si trova in un gruppo.'
L.TipVehicleBar = [[
Mostra i controlli per entrare e uscire da un veicolo.
Tutte le altre azioni del veicolo sono visualizzate sulla barra principale in uso.]]

L.BarDisplayName = "Barra %s"
L.ActionBarDisplayName = "Barra Azione %s"
