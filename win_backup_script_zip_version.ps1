# ===============================
# Script: backup.ps1
# Autor: Ihmanox
# Descripción:
#   Respaldar carpetas de usuario a un disco externo
#   con nomenclatura <PCNAME>_backup001 secuencial
#   y guardar el backup como archivo .zip
# ===============================

# --- 1. Detectar discos externos (removibles o fijos distintos a C:) ---
$removableDrives = Get-PSDrive -PSProvider FileSystem | Where-Object {
    $driveLetter = $_.Root.Substring(0,2)
    $vol = Get-WmiObject Win32_LogicalDisk -Filter "DeviceID='$driveLetter'"
    $vol.DriveType -eq 2 -or ($vol.DriveType -eq 3 -and $_.Root -ne "C:\")
}

if ($removableDrives.Count -eq 0) {
    Write-Host "No se detectaron discos externos. Conecte un USB/HDD externo y vuelva a ejecutar."
    exit
}
elseif ($removableDrives.Count -eq 1) {
    $BackupDestination = $removableDrives[0].Root
    Write-Host "Usando disco detectado: $BackupDestination"
}
else {
    Write-Host "Se detectaron varios discos externos:"
    $i = 1
    foreach ($d in $removableDrives) {
        Write-Host "$i) $($d.Root)"
        $i++
    }
    $choice = Read-Host "Seleccione el número del disco donde quiere guardar el respaldo"
    $BackupDestination = $removableDrives[[int]$choice - 1].Root
    Write-Host "Seleccionado: $BackupDestination"
}

# --- 2. Crear carpeta temporal de backup ---
$ComputerName = $env:COMPUTERNAME
$BasePath = $BackupDestination

$ExistingBackups = Get-ChildItem -Path $BasePath -Directory -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -like "${ComputerName}_backup*" }

if ($ExistingBackups) {
    $Numbers = $ExistingBackups.Name | ForEach-Object {
        if ($_ -match "${ComputerName}_backup(\d{3})") {
            [int]$matches[1]
        }
    }
    if ($Numbers.Count -gt 0) {
        $NextNumber = ($Numbers | Measure-Object -Maximum).Maximum + 1
    }
    else {
        $NextNumber = 1
    }
}
else {
    $NextNumber = 1
}

$BackupFolderName = "{0}_backup{1:000}" -f $ComputerName, $NextNumber
$TempBackupFolder = Join-Path $env:TEMP $BackupFolderName
New-Item -Path $TempBackupFolder -ItemType Directory -Force | Out-Null
Write-Host "Carpeta temporal creada: $TempBackupFolder"

# --- 3. Carpetas comunes de usuario ---
$FoldersToBackup = @(
    "Desktop",
    "Documents",
    "Downloads",
    "Music",
    "Pictures",
    "Videos",
    "Favorites",
    "Contacts",
    "Links",
    "Saved Games",
    "Searches",
    "3D Objects"
)

# --- 4. Archivo de log ---
$LogFile = Join-Path $TempBackupFolder "backup_log.txt"
$LogContent = "=== Backup ejecutado el $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') en equipo $ComputerName ===`n"

# --- 5. Respaldar todos los usuarios ---
$UsersRoot = "C:\Users"
$UserProfiles = Get-ChildItem -Path $UsersRoot -Directory | Where-Object {
    $_.Name -notin @("All Users", "Default", "Default User", "Public")
}

foreach ($User in $UserProfiles) {
    Write-Host "`n=============================="
    Write-Host "Respaldando usuario: $($User.Name)"
    Write-Host "=============================="

    foreach ($Folder in $FoldersToBackup) {
        $Source = Join-Path $User.FullName $Folder
        $Target = Join-Path $TempBackupFolder "$($User.Name)\$Folder"

        if (Test-Path $Source) {
            Write-Host "Respaldando: $Source ..."
            try {
                Copy-Item -Path $Source -Destination $Target -Recurse -Force -ErrorAction Stop
                Write-Host "Completado: $Folder"
                $LogContent += "`n[OK] Respaldado: $Source"
            }
            catch {
                Write-Host "Error al respaldar: $Folder - $($_.Exception.Message)"
                $LogContent += "`n[ERROR] Falló respaldo: $Source - $($_.Exception.Message)"
            }
        }
        else {
            Write-Host "Carpeta no encontrada: $Source"
            $LogContent += "`n[SKIP] No existe: $Source"
        }
    }
}

# --- 6. Guardar log ---
$LogContent | Out-File -FilePath $LogFile -Encoding UTF8

# --- 7. Comprimir la carpeta completa en un .zip ---
$ZipBackupPath = Join-Path $BackupDestination ($BackupFolderName + ".zip")
if (Test-Path $ZipBackupPath) { Remove-Item $ZipBackupPath -Force }

Write-Host "`nComprimiendo backup en: $ZipBackupPath ..."
Compress-Archive -Path "$TempBackupFolder\*" -DestinationPath $ZipBackupPath -Force

# --- 8. Limpiar carpeta temporal ---
Remove-Item -Path $TempBackupFolder -Recurse -Force

Write-Host "`nRespaldo completado. Backup guardado en: $ZipBackupPath"
Write-Host "Revisa el log dentro del zip para más detalles."
