#
# Манифест модуля для модуля "PoshRemoteRegistry".
#
# Создано: kunaludapi, pashalvov
#
# Дата создания: 25.04.2021
#

@{

# Файл модуля сценария или двоичного модуля, связанный с этим манифестом.
# RootModule = ''

# Номер версии данного модуля.
ModuleVersion = '0.1.0'

# Поддерживаемые выпуски PSEditions
# CompatiblePSEditions = @()

# Уникальный идентификатор данного модуля
GUID = '06fd35ac-2dfe-4b30-b7e6-5fc03435b62c'

# Автор данного модуля
Author = 'pashalvov, kunaludapi'

# Компания, создавшая данный модуль, или его поставщик
CompanyName = 'lvovpd.ru'

# Заявление об авторских правах на модуль
Copyright = '(c) 2021 pashalvov, kunaludapi. Все права защищены.'

# Описание функций данного модуля
Description = 'Work whith remote Windows registry'

# Минимальный номер версии обработчика Windows PowerShell, необходимой для работы данного модуля
PowerShellVersion = '5.1'

# Имя узла Windows PowerShell, необходимого для работы данного модуля
# PowerShellHostName = ''

# Минимальный номер версии узла Windows PowerShell, необходимой для работы данного модуля
# PowerShellHostVersion = ''

# Минимальный номер версии Microsoft .NET Framework, необходимой для данного модуля. Это обязательное требование действительно только для выпуска PowerShell, предназначенного для компьютеров.
# DotNetFrameworkVersion = ''

# Минимальный номер версии среды CLR (общеязыковой среды выполнения), необходимой для работы данного модуля. Это обязательное требование действительно только для выпуска PowerShell, предназначенного для компьютеров.
CLRVersion = '4.0'

# Архитектура процессора (нет, X86, AMD64), необходимая для этого модуля
# ProcessorArchitecture = ''

# Модули, которые необходимо импортировать в глобальную среду перед импортированием данного модуля
# RequiredModules = @()

# Сборки, которые должны быть загружены перед импортированием данного модуля
# RequiredAssemblies = @()

# Файлы сценария (PS1), которые запускаются в среде вызывающей стороны перед импортом данного модуля.
# ScriptsToProcess = @()

# Файлы типа (.ps1xml), которые загружаются при импорте данного модуля
# TypesToProcess = @()

# Файлы формата (PS1XML-файлы), которые загружаются при импорте данного модуля
# FormatsToProcess = @()

# Модули для импорта в качестве вложенных модулей модуля, указанного в параметре RootModule/ModuleToProcess
# NestedModules = @()

# В целях обеспечения оптимальной производительности функции для экспорта из этого модуля не используют подстановочные знаки и не удаляют запись. Используйте пустой массив, если нет функций для экспорта.
FunctionsToExport = @('Test-TCPing','Get-RegValueData','Get-RegChildItem','Remove-RegKeyValue','Write-RegValueData')

# В целях обеспечения оптимальной производительности командлеты для экспорта из этого модуля не используют подстановочные знаки и не удаляют запись. Используйте пустой массив, если нет командлетов для экспорта.
CmdletsToExport = @()

# Переменные для экспорта из данного модуля
VariablesToExport = '*'

# В целях обеспечения оптимальной производительности псевдонимы для экспорта из этого модуля не используют подстановочные знаки и не удаляют запись. Используйте пустой массив, если нет псевдонимов для экспорта.
AliasesToExport = @()

# Ресурсы DSC для экспорта из этого модуля
# DscResourcesToExport = @()

# Список всех модулей, входящих в пакет данного модуля
# ModuleList = @()

# Список всех файлов, входящих в пакет данного модуля
FileList = 'tcping.exe', 'PoshRemoteRegistry.psm1'

# Личные данные для передачи в модуль, указанный в параметре RootModule/ModuleToProcess. Он также может содержать хэш-таблицу PSData с дополнительными метаданными модуля, которые используются в PowerShell.
PrivateData = @{

    PSData = @{

        # Теги, применимые к этому модулю. Они помогают с обнаружением модуля в онлайн-коллекциях.
        Tags = 'windows-remoting', 'windows-regestry'

        # URL-адрес лицензии для этого модуля.
        LicenseUri = 'https://github.com/pashalvov/PoshRemoteRegistry/blob/master/LICENSE'

        # URL-адрес главного веб-сайта для этого проекта.
        ProjectUri = 'https://github.com/pashalvov/PoshRemoteRegistry'

        # URL-адрес значка, который представляет этот модуль.
        # IconUri = ''

        # Заметки о выпуске этого модуля
        # ReleaseNotes = ''

        Prerelease = 'alpha'

    } # Конец хэш-таблицы PSData

} # Конец хэш-таблицы PrivateData

# Код URI для HelpInfo данного модуля
HelpInfoURI = 'https://github.com/pashalvov/PoshRemoteRegistry/wiki'

# Префикс по умолчанию для команд, экспортированных из этого модуля. Переопределите префикс по умолчанию с помощью команды Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

