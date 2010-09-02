--[[
	Localization.ru.lua
		Translations for Dominos
	Translate by ZealZany
	Russian
--]]

local L = LibStub('AceLocale-3.0'):NewLocale('Dominos', 'ruRU')
if not L then return end

--system messages
L.NewPlayer = 'Создан новый профиль для %s'
L.Updated = 'Обновлено до v%s'

--profiles
L.ProfileCreated = 'Создан новый профиль "%s"'
L.ProfileLoaded = 'Установить профиль в "%s"'
L.ProfileDeleted = 'Удален профиль "%s"'
L.ProfileCopied = 'Настройки скопированы из "%s"'
L.ProfileReset = 'Сбросить профиль "%s"'
L.CantDeleteCurrentProfile = 'Невозможно удалить текущий профиль'
L.InvalidProfile = 'Некорректный профиль "%s"'

--slash command help
L.ShowOptionsDesc = 'Показывает меню опций'
L.ConfigDesc = 'Устанавливает режим конфигурирования'

L.SetScaleDesc = 'Установливает масштаб <frameList>'
L.SetAlphaDesc = 'Устанавливает прозрачность <frameList>'
L.SetFadeDesc = 'Устанавливает затемнение <frameList>'

L.SetColsDesc = 'Устанавливает количество столбцов <frameList>'
L.SetPadDesc = 'Устанавливает уровень заполнения <frameList>'
L.SetSpacingDesc = 'Устанавливает уровень отступов <frameList>'

L.ShowFramesDesc = 'Показывает данный <frameList>'
L.HideFramesDesc = 'Скрывает данный <frameList>'
L.ToggleFramesDesc = 'Фиксирует данный <frameList>'

--slash commands for profiles
L.SetDesc = 'Переключает на <profile>'
L.SaveDesc = 'Сохраняет текущие настройки в <profile>'
L.CopyDesc = 'Копирует настройки в <profile>'
L.DeleteDesc = 'Удаляет <profile>'
L.ResetDesc = 'Возарщает настройки по умолчанию'
L.ListDesc = 'Отображает все профили'
L.AvailableProfiles = 'Доступные профили'
L.PrintVersionDesc = 'Сообщает текущую версию'

--dragFrame tooltips
L.ShowConfig = '<ПКМ> для конфигурирования'
L.HideBar = '<СКМ или Shift-ПКМ> для скрытия'
L.ShowBar = '<СКП или Shift-ПКМ> для показа'
L.SetAlpha = '<КолесоМыши> для установки прозрачности (|cffffffff%d|r)'

--minimap button stuff
L.ConfigEnterTip = '<ЛКМ> для режима конфигурирования'
L.ConfigExitTip = '<ЛКМ> для выхода из режима конфигурирования'
L.BindingEnterTip = '<Shift ЛКМ> для режима назначения горячих клавиш'
L.BindingExitTip = '<Shift ЛКМ> для выхода из режима назначения горячих клавиш'
L.ShowOptionsTip = '<ПКМ> для открытия опций'

--helper dialog stuff
L.ConfigMode = 'Режим конфигурирования'
L.ConfigModeExit = 'Выход из режима конфигурирования'
L.ConfigModeHelp = '<Схватите> любую панель для перемещения.  <ПКМ> для настройки.  <СКМ> или <Shift-ЛКМ> для изменения видимости'