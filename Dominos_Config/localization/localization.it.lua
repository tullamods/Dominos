--[[Dominos Config Localization - Italian]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos-Config', 'itIT')
if not L then return end

L.Scale = 'Proporzione'
L.Opacity = 'Opacità'
L.FadedOpacity = 'Dissolvenza'
L.Visibility = 'Visibilità'
L.Spacing = 'Distanza'
L.Padding = 'Imbottitura'
L.Layout = 'Disposizione'
L.Columns = 'Colonne'
L.Size = 'Grandezza'
L.Modifiers = 'Modificatori'
L.QuickPaging = 'Pagine rapide'
L.Targeting = 'Obiettivo'
L.ShowStates = 'Mostra stati'
L.Set = 'Set'
L.Save = 'Salva'
L.Copy = 'Copia'
L.Delete = 'Cancella'
L.Bar = 'Barra %d'
L.RightClickUnit = 'Clic Destro sul Bersaglio'
L.RCUPlayer = 'Se stesso'
L.RCUFocus = 'Focus'
L.RCUToT = 'Bersaglio del Bersaglio'
L.EnterName = 'Inserisci il nome'
L.PossessBar = 'Barra sostituita'
L.Profiles = 'Profili'
L.ProfilesPanelDesc = 'Ti permette di gestire le disposizioni salvate in Dominos'
L.SelfcastKey = 'Tasto per il lancio su se stessi'
L.QuickMoveKey = 'Tasto per lo spostamento rapito'
L.ShowMacroText = 'Mostra il testo delle macro'
L.ShowBindingText = 'Mostra i tasti assegnati'
L.ShowEmptyButtons = 'Mostra riquadri vuoti'
L.LockActionButtons = 'Blocca la posizione dei pulsanti azione'
L.EnterBindingMode = 'Assegna tasto...'
L.EnterConfigMode = 'Configura le barre...'
L.BarSettings = 'Barra %s'
L.ShowTooltips = 'Mostra informazioni nelle barre'
L.ShowTooltipsCombat = 'Mostra informazioni in combattimento'
L.OneBag = 'Solo una borsa'
L.ShowKeyring = 'Mostra portachiavi'
L.StickyBars = 'Barre appiccicose'
L.ShowMinimapButton = 'Mostra sulla minimappa'
L.Advanced = 'Avanzate'
L.LeftToRight = 'Bottoni da sinistra verso destra'
L.TopToBottom = "Bottoni dall'alto verso basso"
L.LinkedOpacity = "Le barre attaccate ereditano l'opacità"
L.ClickThrough = 'Ignora il passaggio del mouse'
L.DisableMenuButtons = 'Disattiva bottoni'
L.ShowOverrideUI = 'Sostituisci con la barra azioni Blizzard'
L.ShowInOverrideUI = "Mostra con la barra azioni sostituita"
L.ShowInPetBattleUI = 'Mostra nei combattimenti tra mascotte'

L.ALT_KEY_TEXT = 'ALT'

L.State_HELP = 'Aiuto'
L.State_HARM = 'Ferito'
L.State_NOTARGET = 'Nessun bersaglio'
L.State_ALTSHIFT = 'ALT-' .. SHIFT_KEY_TEXT
L.State_CTRLSHIFT = CTRL_KEY_TEXT .. '-' .. SHIFT_KEY_TEXT
L.State_CTRLALT = CTRL_KEY_TEXT .. '-ALT'
L.State_CTRLALTSHIFT = CTRL_KEY_TEXT .. '-ALT-' .. SHIFT_KEY_TEXT

--totems
L.ShowTotems = 'Mostra i Totem'
L.ShowTotemRecall = 'Mostra Richiamo'

--extra bar
L.ExtraBarShowBlizzardTexture = 'Mostra Texture di Blizzard'

--general settings panel
L.General = 'Generale'

--profile settings panel
L.CreateProfile = 'Crea il Profilo...'
L.ResetProfile = 'Reset del Profilo...'
L.CopyProfile = 'Copia il Profilo...'
L.ConfirmResetProfile = 'Sei sicuro di voler azzerare il tuo profilo?'
L.ConfirmCopyProfile = 'Copia i contenuti di %s nel profilo corrente?'
L.ConfirmDeleteProfile = 'Cancellare il profilo %s?'
