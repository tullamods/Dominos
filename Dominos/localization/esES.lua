--[[
	Localization.es.lua
		Translations for Dominos

	Español
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'esES')
if not L then return end
--system messages
L.NewPlayer = 'Creado nuevo perfil para %s'
L.Updated = 'Actualizado a v%s'

--profiles
L.ProfileCreated = 'Creado nuevo prefil "%s"'
L.ProfileLoaded = 'Perfil establecido a "%s"'
L.ProfileDeleted = 'Perfil borrado "%s"'
L.ProfileCopied = 'Copiados parámetros de "%s"'
L.ProfileReset = 'Reseteado perfil "%s"'
L.CantDeleteCurrentProfile = 'No se puede borrar el perfil actual'
L.InvalidProfile = 'Perfil inválido "%s"'

--slash command help
L.ShowOptionsDesc = 'Muestra el menu de configuración'
L.ConfigDesc = 'Activa el modo de configuración'

L.SetScaleDesc = 'Establece la escala para <frameList>'
L.SetAlphaDesc = 'Establece la opacidad para <frameList>'
L.SetFadeDesc = 'Establece la opacidad al pasar el ratón para <frameList>'

L.SetColsDesc = 'Establece el numero de columnas para <frameList>'
L.SetPadDesc = 'Establece el nivel de relleno para <frameList>'
L.SetSpacingDesc = 'Establece el nivel de espaciado para <frameList>'

L.ShowFramesDesc = 'Muestra <frameList>'
L.HideFramesDesc = 'Oculta <frameList>'
L.ToggleFramesDesc = 'Activa <frameList>'

--slash commands for profiles
L.SetDesc = 'Cambiar parametros a <profile>'
L.SaveDesc = 'Salvar los parámetros actuales y cambiar a <profile>'
L.CopyDesc = 'Copiar los parámetros de <profile>'
L.DeleteDesc = 'Borra <profile>'
L.ResetDesc = 'Volver a la parámetros por defecto'
L.ListDesc = 'Listar todos los perfiles'
L.AvailableProfiles = 'Perfiles disponibles'
L.PrintVersionDesc = 'Imprimir la versión actual'

--dragFrame tooltips
L.ShowConfig = '<Click Derecho> para configurar'
L.HideBar = '<Click Central o Shift-Click Derecho> para ocultar'
L.ShowBar = '<Click Central o Shift-Click Derecho> para mostrar'
L.SetAlpha = '<Rueda> para establecer la opacidad (|cffffffff%d|r)'

--minimap button stuff
L.ConfigEnterTip = '<Click Izquierdo> para entrar del modo configuración'
L.ConfigExitTip = '<Click Izquierdo> para salir del modo configuración'
L.BindingEnterTip = '<Shift-Click Izquierdo> para entrar al modo de blindeos'
L.BindingExitTip = '<Shift-Click Izquierdo> para salir del modo de blindeos'
L.ShowOptionsTip = '<Click Derecho> para mostrar el menú de opciones'

--helper dialog stuff
L.ConfigMode = 'Modo configuración'
L.ConfigModeExit = 'Salir del modo configuración'
L.ConfigModeHelp = '<Arrastra> cualquier barra para moverla.  <Click Derecho> para configurar.  <Click Central> o <Shift-Click Derecho> para activar o desactivar la visibilidad'

--bar tooltips
L.TipRollBar = 'Muestra los objetos para tirar dados cuando se esta en grupo o raid'
L.TipVehicleBar = [[
Muestra los controlas para entrar y salir de los vehículos.
Las otras acciones del vehículo son visibles en la barra de acciones.]]