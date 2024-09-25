powershell
Function Message($pathToFile, $comp, $msg) {
    $logEntry = "$(Get-Date) - $comp - $msg"
    Add-Content -Path "$pathToFile$comp.txt" -Value $logEntry
    Write-Output $logEntry
}

$folderPath = 'e:\Скрипты\Computers\'
$fileNotInstalled = 'e:\Скрипты\NotInstalled.TXT'
$fileInstalled = 'e:\Скрипты\Installed.TXT'
$computerList = Get-Content -Path $fileNotInstalled

# Вывод списка компьютеров
foreach ($comp in $computerList) {
    if (-not (Test-Connection -ComputerName $comp -Quiet)) {
        Message $folderPath $comp "Компьютер не доступен по сети"
        Continue
    }

    Message $folderPath $comp "Компьютер доступен по сети"

    # Проверка установленной программы
    $exePath = "\\$comp\c$\Program Files\1cv8\8.3.25.1374\bin\1cv8s.exe"
    if (Test-Path -Path $exePath) {
        $computerList = $computerList | Where-Object { $_ -ne $comp }
        Set-Content -Path $fileNotInstalled -Value $computerList
        Message $folderPath $comp "1C Установлена"
        Continue
    }

    Message $folderPath $comp "Начинается установка 1С. Создаем папку c:\dst на удаленном компьютере"
    Invoke-Command -ComputerName $comp { New-Item -ItemType Directory -Path "c:\dst" -ErrorAction Stop }

    # Проверка созданной папки
    if (-not (Test-Path -Path "\\$comp\c$\dst")) {
        Message $folderPath $comp "Не удалось создать папку c:\dst"
        Continue
    }

    Message $folderPath $comp "Папка c:\dst создана, копируем в нее дистрибутив 1С"
    Copy-Item -Path "\\corp\root\Distrib\1C\1Cv8\8.3.25.1374-64" -Destination "\\$comp\c$\dst\" -Recurse -ErrorAction Stop

    # Проверка на наличие дистрибутива
    if (-not (Test-Path -Path "\\$comp\c$\dst\8.3.25.1374-64\setup.exe")) {
        Message $folderPath $comp "Не удалось скопировать дистрибутив в папку c:\dst"
        Continue
    }

    Message $folderPath $comp "Дистрибутив 1С скопирован, приступаю к установке"
    Invoke-Command -ComputerName $comp -ScriptBlock {
        Start-Process -FilePath "c:\dst\8.3.25.1374-64\setup.exe" -ArgumentList "/S" -Wait -ErrorAction Stop
    }

    # Повторная проверка установленной программы
    if (Test-Path -Path $exePath) {
        $computerList = $computerList | Where-Object { $_ -ne $comp }
        Set-Content -Path $fileNotInstalled -Value $computerList
        Message $folderPath $comp "1C Установлена"
        Continue
    }
}