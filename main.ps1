powershell

$folderPath = 'e:\Скрипты\Computers\'
# $fileInstalled = 'e:\Скрипты\Installed.TXT'
$fileNotInstalled = 'e:\Скрипты\NotInstalled.TXT'
$computerList = Get-Content -Path $fileNotInstalled

Function Message($msg) {
    $logEntry = "$(Get-Date) - $comp - $msg"
    Add-Content -Path "$folderPath$comp.txt" -Value $logEntry
    Write-Output $logEntry
}

Function RemoveCompFromList ($comp) {
    $computerList = $computerList | Where-Object { $_ -ne $comp }
    Set-Content -Path $fileNotInstalled -Value $computerList
}

Function СheckIfInstalled () {
    if (Test-Path -Path $exePath) {
        Message "1C Установлена"
        RemoveCompFromList $comp

        return true
    }

    Message "1C не установлена"
    return false
}

# Вывод списка компьютеров
foreach ($comp in $computerList) {
    if (-not (Test-Connection -ComputerName $comp -Quiet)) {
        Message "Компьютер не доступен по сети"
        Continue
    }

    Message "Компьютер доступен по сети"

    # Проверка установленной программы
    $exePath = "\\$comp\c$\Program Files\1cv8\8.3.25.1374\bin\1cv8s.exe"

    if (СheckIfInstalled) {
        Continue
    }
    
    Message "Начинается установка 1С. Создаем папку c:\dst на удаленном компьютере"
    Invoke-Command -ComputerName $comp { New-Item -ItemType Directory -Path "c:\dst" -ErrorAction Stop }
    
    # Проверка созданной папки
    if (-not (Test-Path -Path "\\$comp\c$\dst")) {
        Message "Не удалось создать папку c:\dst"
        Continue
    }
    
    Message "Папка c:\dst создана, копируем в нее дистрибутив 1С"
    Copy-Item -Path "\\corp\root\Distrib\1C\1Cv8\8.3.25.1374-64" -Destination "\\$comp\c$\dst\" -Recurse -ErrorAction Stop
    
    # Проверка на наличие дистрибутива
    if (-not (Test-Path -Path "\\$comp\c$\dst\8.3.25.1374-64\setup.exe")) {
        Message "Не удалось скопировать дистрибутив в папку c:\dst"
        Continue
    }
    
    Message "Дистрибутив 1С скопирован, приступаю к установке"
    Invoke-Command -ComputerName $comp -ScriptBlock {
        Start-Process -FilePath "c:\dst\8.3.25.1374-64\setup.exe" -ArgumentList "/S" -Wait -ErrorAction Stop
    }
    
    # Повторная проверка установленной программы
    if (-not(СheckIfInstalled)) {
        Write-Error "Миша, всё хуйня, давай заново..."
    }
}