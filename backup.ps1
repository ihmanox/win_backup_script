# ========================================
# SCRIPT DE BACKUP UNIVERSAL PARA WINDOWS
# Versión 2.0 - Profesional y Robusto
# ========================================

#Requires -RunAsAdministrator

# CONFIGURACION
$CARPETAS_EXCLUIDAS = @(
    "node_modules",          # Módulos de Node.js (se reinstalan con npm)
    ".git",                  # Repositorios Git (usar git clone)
    ".vscode",               # Configuración de VSCode (opcional)
    ".idea",                 # Configuración de IntelliJ (opcional)
    "bower_components",      # Dependencias Bower
    "vendor",                # Dependencias PHP Composer
    "__pycache__",           # Cache de Python
    ".next",                 # Build de Next.js
    ".nuxt",                 # Build de Nuxt.js
    "dist",                  # Carpetas de distribución (opcional)
    "build",                 # Carpetas de build (opcional)
    "target",                # Build de Java/Maven
    "bin",                   # Binarios compilados
    "obj"                    # Objetos compilados
)

$EXTENSIONES_EXCLUIDAS = @(
    "*.tmp",                 # Archivos temporales
    "*.temp",                # Archivos temporales
    "*.cache",               # Archivos de caché
    "Thumbs.db",             # Miniaturas de Windows
    ".DS_Store"              # Archivos de macOS
)

# ========================================
# FUNCIONES AUXILIARES
# ========================================

function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Get-FormattedSize {
    param([long]$Bytes)
    
    if ($Bytes -ge 1TB) { return "{0:N2} TB" -f ($Bytes / 1TB) }
    elseif ($Bytes -ge 1GB) { return "{0:N2} GB" -f ($Bytes / 1GB) }
    elseif ($Bytes -ge 1MB) { return "{0:N2} MB" -f ($Bytes / 1MB) }
    elseif ($Bytes -ge 1KB) { return "{0:N2} KB" -f ($Bytes / 1KB) }
    else { return "{0} Bytes" -f $Bytes }
}

function Show-Header {
    Clear-Host
    Write-ColorOutput "========================================" "Cyan"
    Write-ColorOutput "  BACKUP UNIVERSAL PARA WINDOWS" "Cyan"
    Write-ColorOutput "  Versión 2.0 - Profesional" "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""
}

# ========================================
# DETECCION DE DISCOS EXTERNOS
# ========================================

function Get-ExternalDisks {
    Show-Header
    Write-ColorOutput "Detectando discos externos..." "Yellow"
    Write-Host ""
    
    $AllDisks = Get-PSDrive -PSProvider FileSystem | Where-Object { 
        $_.Free -gt 0 -and 
        $_.Name -match "^[D-Z]$" 
    }
    
    if ($AllDisks.Count -eq 0) {
        Write-ColorOutput "ERROR: No se encontraron discos disponibles." "Red"
        Write-ColorOutput "Conecta un disco externo y vuelve a ejecutar el script." "Yellow"
        Read-Host "`nPresiona Enter para salir"
        exit
    }
    
    $DiskOptions = @()
    $Counter = 1
    
    foreach ($Disk in $AllDisks) {
        $SizeGB = [math]::Round(($Disk.Used + $Disk.Free) / 1GB, 2)
        $FreeGB = [math]::Round($Disk.Free / 1GB, 2)
        $UsedGB = [math]::Round($Disk.Used / 1GB, 2)
        
        # Obtener información del disco físico
        try {
            $PhysicalDisk = Get-Partition | Where-Object { $_.DriveLetter -eq $Disk.Name } | Get-Disk
            $DiskName = $PhysicalDisk.FriendlyName
            $BusType = $PhysicalDisk.BusType
        } catch {
            $DiskName = "Desconocido"
            $BusType = "Desconocido"
        }
        
        Write-ColorOutput "[$Counter] Disco $($Disk.Name):" "Cyan"
        Write-ColorOutput "    Nombre: $DiskName" "White"
        Write-ColorOutput "    Tamaño Total: $SizeGB GB" "White"
        Write-ColorOutput "    Espacio Libre: $FreeGB GB ($([math]::Round(($FreeGB/$SizeGB)*100, 1))%)" "White"
        Write-ColorOutput "    Conexión: $BusType" "White"
        
        # Sugerencia
        $IsExternal = ($BusType -eq "USB" -or $SizeGB -gt 500)
        if ($IsExternal) {
            Write-ColorOutput "    ✓ RECOMENDADO (Disco externo detectado)" "Green"
        }
        
        Write-Host ""
        
        $DiskOptions += @{
            Number = $Counter
            Letter = $Disk.Name
            Name = $DiskName
            Size = $SizeGB
            Free = $FreeGB
            Type = $BusType
            Recommended = $IsExternal
        }
        $Counter++
    }
    
    return $DiskOptions
}

function Select-BackupDisk {
    param($DiskOptions)
    
    do {
        Write-ColorOutput "Selecciona el disco para el backup (1-$($DiskOptions.Count)) o 'Q' para salir: " "Yellow" -NoNewline
        $Selection = Read-Host
        
        if ($Selection -eq 'Q' -or $Selection -eq 'q') {
            Write-ColorOutput "`nBackup cancelado." "Red"
            exit
        }
        
        $SelectionNum = 0
        $IsValid = [int]::TryParse($Selection, [ref]$SelectionNum) -and 
                   $SelectionNum -ge 1 -and 
                   $SelectionNum -le $DiskOptions.Count
        
        if (-not $IsValid) {
            Write-ColorOutput "Selección inválida. Intenta de nuevo." "Red"
        }
    } while (-not $IsValid)
    
    return $DiskOptions[$SelectionNum - 1]
}

# ========================================
# PROCESO DE BACKUP
# ========================================

function Get-NextBackupFolder {
    param(
        [string]$DestinationDisk,
        [string]$ComputerName
    )
    
    # Normalizar el nombre de la computadora (sin espacios ni caracteres especiales)
    $SafeComputerName = $ComputerName -replace '[^\w-]', '_'
    
    # Buscar TODOS los backups en el disco con el patrón *_BackupXXX
    $AllBackups = Get-ChildItem -Path $DestinationDisk -Directory -ErrorAction SilentlyContinue | 
                  Where-Object { $_.Name -match "_Backup(\d{3})$" }
    
    if ($AllBackups.Count -eq 0) {
        # No hay ningún backup en el disco, crear el primero
        return "${SafeComputerName}_Backup001"
    }
    
    # Encontrar el número más alto de TODOS los backups (sin importar el nombre de la PC)
    $HighestNumber = 0
    foreach ($Backup in $AllBackups) {
        if ($Backup.Name -match "_Backup(\d{3})$") {
            $Number = [int]$matches[1]
            if ($Number -gt $HighestNumber) {
                $HighestNumber = $Number
            }
        }
    }
    
    # Incrementar y formatear con ceros
    $NextNumber = $HighestNumber + 1
    
    if ($NextNumber -gt 999) {
        Write-ColorOutput "ERROR: Se alcanzó el límite de backups en este disco (999)." "Red"
        Write-ColorOutput "Considera usar otro disco o eliminar backups antiguos." "Yellow"
        Read-Host "`nPresiona Enter para salir"
        exit
    }
    
    $NextBackupName = "${SafeComputerName}_Backup{0:D3}" -f $NextNumber
    
    return $NextBackupName
}

function Start-Backup {
    param(
        [string]$DestinationDisk,
        [string]$ComputerName
    )
    
    $User = $env:USERNAME
    
    # Normalizar el nombre de la computadora
    $SafeComputerName = $ComputerName -replace '[^\w-]', '_'
    
    # Obtener el siguiente número de backup disponible para esta computadora
    $FinalBackupName = Get-NextBackupFolder -DestinationDisk $DestinationDisk -ComputerName $ComputerName
    $DestinationPath = Join-Path $DestinationDisk $FinalBackupName
    
    # Mostrar backups existentes de ESTA computadora
    $ExistingBackupsThisPC = Get-ChildItem -Path $DestinationDisk -Directory -ErrorAction SilentlyContinue | 
                              Where-Object { $_.Name -match "^${SafeComputerName}_Backup\d{3}$" } |
                              Sort-Object Name
    
    # Mostrar backups de OTRAS computadoras
    $ExistingBackupsOtherPCs = Get-ChildItem -Path $DestinationDisk -Directory -ErrorAction SilentlyContinue | 
                                Where-Object { $_.Name -match "^.+_Backup\d{3}$" -and $_.Name -notmatch "^${SafeComputerName}_Backup\d{3}$" } |
                                Sort-Object Name
    
    Write-Host ""
    
    if ($ExistingBackupsThisPC.Count -gt 0) {
        Write-ColorOutput "Backups existentes de esta computadora ($ComputerName):" "Green"
        foreach ($Backup in $ExistingBackupsThisPC) {
            $LastModified = $Backup.LastWriteTime.ToString('dd/MM/yyyy HH:mm:ss')
            Write-ColorOutput "  • $($Backup.Name) - $LastModified" "White"
        }
        Write-Host ""
    }
    
    if ($ExistingBackupsOtherPCs.Count -gt 0) {
        Write-ColorOutput "Backups de otras computadoras en este disco:" "Cyan"
        $GroupedByPC = $ExistingBackupsOtherPCs | Group-Object { $_.Name -replace '_Backup\d{3}
    
    # Definir carpetas a respaldar
    $FoldersToBackup = @(
        @{Name="Escritorio"; Path="$env:USERPROFILE\Desktop"},
        @{Name="Documentos"; Path="$env:USERPROFILE\Documents"},
        @{Name="Imagenes"; Path="$env:USERPROFILE\Pictures"},
        @{Name="Videos"; Path="$env:USERPROFILE\Videos"},
        @{Name="Musica"; Path="$env:USERPROFILE\Music"},
        @{Name="Descargas"; Path="$env:USERPROFILE\Downloads"},
        @{Name="Favoritos"; Path="$env:USERPROFILE\Favorites"}
    )
    
    Show-Header
    Write-ColorOutput "INICIANDO BACKUP" "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "Computadora: $env:COMPUTERNAME" "White"
    Write-ColorOutput "Usuario: $User" "White"
    Write-ColorOutput "Destino: $DestinationPath" "White"
    Write-Host ""
    Write-ColorOutput "Carpetas excluidas: $($CARPETAS_EXCLUIDAS -join ', ')" "DarkGray"
    Write-Host ""
    Write-Host ""
    
    $TotalFolders = 0
    $SuccessCount = 0
    $SkippedCount = 0
    $ErrorCount = 0
    $StartTime = Get-Date
    
    foreach ($Folder in $FoldersToBackup) {
        $TotalFolders++
        $Source = $Folder.Path
        $Destination = Join-Path $DestinationPath $Folder.Name
        
        Write-ColorOutput "[$TotalFolders/$($FoldersToBackup.Count)] Procesando: $($Folder.Name)" "Cyan"
        
        if (-not (Test-Path $Source)) {
            Write-ColorOutput "  ⊗ Carpeta no existe" "DarkGray"
            $SkippedCount++
            Write-Host ""
            continue
        }
        
        # Construir comando robocopy con exclusiones
        $ExcludeDirs = $CARPETAS_EXCLUIDAS -join " "
        $ExcludeFiles = $EXTENSIONES_EXCLUIDAS -join " "
        
        try {
            # Parámetros robocopy:
            # /E = Copiar subcarpetas incluyendo vacías
            # /R:1 = 1 reintento
            # /W:1 = 1 segundo entre reintentos
            # /XJ = Excluir junction points
            # /XD = Excluir directorios
            # /XF = Excluir archivos
            # /NFL = No File List (sin lista de archivos)
            # /NDL = No Directory List (sin lista de directorios)
            # /NP = No Progress (sin porcentaje)
            # /BYTES = Mostrar tamaños en bytes
            # /MT:8 = Multi-thread con 8 hilos (más rápido)
            
            $RobocopyArgs = @(
                "`"$Source`"",
                "`"$Destination`"",
                "/E",
                "/R:1",
                "/W:1",
                "/XJ",
                "/NFL",
                "/NDL", 
                "/NP",
                "/MT:8"
            )
            
            # Agregar exclusiones
            foreach ($ExDir in $CARPETAS_EXCLUIDAS) {
                $RobocopyArgs += "/XD"
                $RobocopyArgs += "`"$ExDir`""
            }
            
            foreach ($ExFile in $EXTENSIONES_EXCLUIDAS) {
                $RobocopyArgs += "/XF"
                $RobocopyArgs += "`"$ExFile`""
            }
            
            $Result = & robocopy $RobocopyArgs
            
            # Códigos de salida de robocopy:
            # 0 = Sin cambios
            # 1 = Archivos copiados exitosamente
            # 2 = Archivos extras en destino
            # 3 = Archivos copiados y extras encontrados
            # 4-7 = Archivos no coincidentes o errores menores
            # 8+ = Errores graves
            
            if ($LASTEXITCODE -lt 8) {
                Write-ColorOutput "  ✓ Completado" "Green"
                $SuccessCount++
            } else {
                Write-ColorOutput "  ⚠ Completado con advertencias (código: $LASTEXITCODE)" "Yellow"
                $SuccessCount++
            }
        }
        catch {
            Write-ColorOutput "  ✗ Error: $($_.Exception.Message)" "Red"
            $ErrorCount++
        }
        
        Write-Host ""
    }
    
    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime
    
    # Crear log
    $LogDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $LogFile = Join-Path $DestinationPath "backup_log_$LogDate.txt"
    
    # Asegurar que la carpeta existe
    if (-not (Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }
    
    $LogContent = @"
========================================
REGISTRO DE BACKUP
========================================
Fecha: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Computadora: $env:COMPUTERNAME
Usuario: $User
Destino: $DestinationPath
Duración: $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s

RESUMEN:
Total de carpetas procesadas: $TotalFolders
Copias exitosas: $SuccessCount
Carpetas omitidas: $SkippedCount
Errores: $ErrorCount

CARPETAS RESPALDADAS:
"@
    
    foreach ($Folder in $FoldersToBackup) {
        if (Test-Path $Folder.Path) {
            $LogContent += "`n[✓] $($Folder.Name) - $($Folder.Path)"
        } else {
            $LogContent += "`n[⊗] $($Folder.Name) - NO EXISTE"
        }
    }
    
    $LogContent += "`n`nCARPETAS EXCLUIDAS:`n$($CARPETAS_EXCLUIDAS -join ', ')"
    $LogContent += "`n`nEXTENSIONES EXCLUIDAS:`n$($EXTENSIONES_EXCLUIDAS -join ', ')"
    
    $LogContent | Out-File -FilePath $LogFile -Encoding UTF8
    
    # Resumen final
    Show-Header
    Write-ColorOutput "BACKUP COMPLETADO" "Green"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "✓ Carpetas exitosas: $SuccessCount/$TotalFolders" "Green"
    
    if ($SkippedCount -gt 0) {
        Write-ColorOutput "⊗ Carpetas omitidas: $SkippedCount" "Yellow"
    }
    
    if ($ErrorCount -gt 0) {
        Write-ColorOutput "✗ Errores: $ErrorCount" "Red"
    }
    
    Write-Host ""
    Write-ColorOutput "Duración: $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s" "White"
    Write-Host ""
    Write-ColorOutput "Ubicación del backup:" "White"
    Write-ColorOutput "  $DestinationPath" "Cyan"
    Write-Host ""
    Write-ColorOutput "Log guardado en:" "White"
    Write-ColorOutput "  $LogFile" "Cyan"
    Write-Host ""
    
    # Calcular tamaño total del backup
    try {
        $BackupStats = Get-ChildItem $DestinationPath -Recurse -File -ErrorAction SilentlyContinue | 
                       Measure-Object -Property Length -Sum
        
        Write-ColorOutput "Estadísticas del backup:" "White"
        Write-ColorOutput "  Archivos totales: $($BackupStats.Count)" "Cyan"
        Write-ColorOutput "  Tamaño total: $(Get-FormattedSize $BackupStats.Sum)" "Cyan"
    } catch {
        Write-ColorOutput "No se pudieron calcular las estadísticas del backup." "Yellow"
    }
    
    Write-Host ""
    Write-ColorOutput "Presiona cualquier tecla para salir..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ========================================
# PROGRAMA PRINCIPAL
# ========================================

try {
    # Detectar discos
    $DiskOptions = Get-ExternalDisks
    
    # Seleccionar disco
    $SelectedDisk = Select-BackupDisk -DiskOptions $DiskOptions
    
    # Confirmar selección
    Show-Header
    Write-ColorOutput "Has seleccionado:" "Yellow"
    Write-ColorOutput "  Disco: $($SelectedDisk.Letter): - $($SelectedDisk.Name)" "White"
    Write-ColorOutput "  Espacio libre: $(Get-FormattedSize ($SelectedDisk.Free * 1GB))" "White"
    Write-Host ""
    
    Write-Host ""
    Write-ColorOutput "El backup se guardará con numeración automática (Backup###)" "Cyan"
    Write-ColorOutput "Se detectará automáticamente el siguiente número disponible" "DarkGray"
    Write-Host ""
    Write-ColorOutput "¿Continuar con el backup? (S/N): " "Yellow" -NoNewline
    $Confirm = Read-Host
    
    if ($Confirm -ne 'S' -and $Confirm -ne 's') {
        Write-ColorOutput "`nBackup cancelado." "Red"
        exit
    }
    
    # Iniciar backup
    Start-Backup -DestinationDisk "$($SelectedDisk.Letter):"
    
} catch {
    Write-ColorOutput "`nERROR CRÍTICO: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Ubicación: $($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.OffsetInLine)" "Red"
    Write-Host ""
    Read-Host "Presiona Enter para salir"
}, '' }
        foreach ($Group in $GroupedByPC) {
            Write-ColorOutput "  $($Group.Name): $($Group.Count) backup(s)" "DarkGray"
        }
        Write-Host ""
    }
    
    Write-ColorOutput "Creando nuevo backup: $FinalBackupName" "Green"
    
    # Crear carpeta de destino
    New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    Write-ColorOutput "✓ Carpeta de backup creada: $DestinationPath" "Green"
    
    # Definir carpetas a respaldar
    $FoldersToBackup = @(
        @{Name="Escritorio"; Path="$env:USERPROFILE\Desktop"},
        @{Name="Documentos"; Path="$env:USERPROFILE\Documents"},
        @{Name="Imagenes"; Path="$env:USERPROFILE\Pictures"},
        @{Name="Videos"; Path="$env:USERPROFILE\Videos"},
        @{Name="Musica"; Path="$env:USERPROFILE\Music"},
        @{Name="Descargas"; Path="$env:USERPROFILE\Downloads"},
        @{Name="Favoritos"; Path="$env:USERPROFILE\Favorites"}
    )
    
    Show-Header
    Write-ColorOutput "INICIANDO BACKUP" "Cyan"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "Computadora: $env:COMPUTERNAME" "White"
    Write-ColorOutput "Usuario: $User" "White"
    Write-ColorOutput "Destino: $DestinationPath" "White"
    Write-Host ""
    Write-ColorOutput "Carpetas excluidas: $($CARPETAS_EXCLUIDAS -join ', ')" "DarkGray"
    Write-Host ""
    Write-Host ""
    
    $TotalFolders = 0
    $SuccessCount = 0
    $SkippedCount = 0
    $ErrorCount = 0
    $StartTime = Get-Date
    
    foreach ($Folder in $FoldersToBackup) {
        $TotalFolders++
        $Source = $Folder.Path
        $Destination = Join-Path $DestinationPath $Folder.Name
        
        Write-ColorOutput "[$TotalFolders/$($FoldersToBackup.Count)] Procesando: $($Folder.Name)" "Cyan"
        
        if (-not (Test-Path $Source)) {
            Write-ColorOutput "  ⊗ Carpeta no existe" "DarkGray"
            $SkippedCount++
            Write-Host ""
            continue
        }
        
        # Construir comando robocopy con exclusiones
        $ExcludeDirs = $CARPETAS_EXCLUIDAS -join " "
        $ExcludeFiles = $EXTENSIONES_EXCLUIDAS -join " "
        
        try {
            # Parámetros robocopy:
            # /E = Copiar subcarpetas incluyendo vacías
            # /R:1 = 1 reintento
            # /W:1 = 1 segundo entre reintentos
            # /XJ = Excluir junction points
            # /XD = Excluir directorios
            # /XF = Excluir archivos
            # /NFL = No File List (sin lista de archivos)
            # /NDL = No Directory List (sin lista de directorios)
            # /NP = No Progress (sin porcentaje)
            # /BYTES = Mostrar tamaños en bytes
            # /MT:8 = Multi-thread con 8 hilos (más rápido)
            
            $RobocopyArgs = @(
                "`"$Source`"",
                "`"$Destination`"",
                "/E",
                "/R:1",
                "/W:1",
                "/XJ",
                "/NFL",
                "/NDL", 
                "/NP",
                "/MT:8"
            )
            
            # Agregar exclusiones
            foreach ($ExDir in $CARPETAS_EXCLUIDAS) {
                $RobocopyArgs += "/XD"
                $RobocopyArgs += "`"$ExDir`""
            }
            
            foreach ($ExFile in $EXTENSIONES_EXCLUIDAS) {
                $RobocopyArgs += "/XF"
                $RobocopyArgs += "`"$ExFile`""
            }
            
            $Result = & robocopy $RobocopyArgs
            
            # Códigos de salida de robocopy:
            # 0 = Sin cambios
            # 1 = Archivos copiados exitosamente
            # 2 = Archivos extras en destino
            # 3 = Archivos copiados y extras encontrados
            # 4-7 = Archivos no coincidentes o errores menores
            # 8+ = Errores graves
            
            if ($LASTEXITCODE -lt 8) {
                Write-ColorOutput "  ✓ Completado" "Green"
                $SuccessCount++
            } else {
                Write-ColorOutput "  ⚠ Completado con advertencias (código: $LASTEXITCODE)" "Yellow"
                $SuccessCount++
            }
        }
        catch {
            Write-ColorOutput "  ✗ Error: $($_.Exception.Message)" "Red"
            $ErrorCount++
        }
        
        Write-Host ""
    }
    
    $EndTime = Get-Date
    $Duration = $EndTime - $StartTime
    
    # Crear log
    $LogDate = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $LogFile = Join-Path $DestinationPath "backup_log_$LogDate.txt"
    
    # Asegurar que la carpeta existe
    if (-not (Test-Path $DestinationPath)) {
        New-Item -ItemType Directory -Path $DestinationPath -Force | Out-Null
    }
    
    $LogContent = @"
========================================
REGISTRO DE BACKUP
========================================
Fecha: $(Get-Date -Format "dd/MM/yyyy HH:mm:ss")
Computadora: $env:COMPUTERNAME
Usuario: $User
Destino: $DestinationPath
Duración: $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s

RESUMEN:
Total de carpetas procesadas: $TotalFolders
Copias exitosas: $SuccessCount
Carpetas omitidas: $SkippedCount
Errores: $ErrorCount

CARPETAS RESPALDADAS:
"@
    
    foreach ($Folder in $FoldersToBackup) {
        if (Test-Path $Folder.Path) {
            $LogContent += "`n[✓] $($Folder.Name) - $($Folder.Path)"
        } else {
            $LogContent += "`n[⊗] $($Folder.Name) - NO EXISTE"
        }
    }
    
    $LogContent += "`n`nCARPETAS EXCLUIDAS:`n$($CARPETAS_EXCLUIDAS -join ', ')"
    $LogContent += "`n`nEXTENSIONES EXCLUIDAS:`n$($EXTENSIONES_EXCLUIDAS -join ', ')"
    
    $LogContent | Out-File -FilePath $LogFile -Encoding UTF8
    
    # Resumen final
    Show-Header
    Write-ColorOutput "BACKUP COMPLETADO" "Green"
    Write-ColorOutput "========================================" "Cyan"
    Write-Host ""
    Write-ColorOutput "✓ Carpetas exitosas: $SuccessCount/$TotalFolders" "Green"
    
    if ($SkippedCount -gt 0) {
        Write-ColorOutput "⊗ Carpetas omitidas: $SkippedCount" "Yellow"
    }
    
    if ($ErrorCount -gt 0) {
        Write-ColorOutput "✗ Errores: $ErrorCount" "Red"
    }
    
    Write-Host ""
    Write-ColorOutput "Duración: $($Duration.Hours)h $($Duration.Minutes)m $($Duration.Seconds)s" "White"
    Write-Host ""
    Write-ColorOutput "Ubicación del backup:" "White"
    Write-ColorOutput "  $DestinationPath" "Cyan"
    Write-Host ""
    Write-ColorOutput "Log guardado en:" "White"
    Write-ColorOutput "  $LogFile" "Cyan"
    Write-Host ""
    
    # Calcular tamaño total del backup
    try {
        $BackupStats = Get-ChildItem $DestinationPath -Recurse -File -ErrorAction SilentlyContinue | 
                       Measure-Object -Property Length -Sum
        
        Write-ColorOutput "Estadísticas del backup:" "White"
        Write-ColorOutput "  Archivos totales: $($BackupStats.Count)" "Cyan"
        Write-ColorOutput "  Tamaño total: $(Get-FormattedSize $BackupStats.Sum)" "Cyan"
    } catch {
        Write-ColorOutput "No se pudieron calcular las estadísticas del backup." "Yellow"
    }
    
    Write-Host ""
    Write-ColorOutput "Presiona cualquier tecla para salir..." "Gray"
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

# ========================================
# PROGRAMA PRINCIPAL
# ========================================

try {
    # Detectar discos
    $DiskOptions = Get-ExternalDisks
    
    # Seleccionar disco
    $SelectedDisk = Select-BackupDisk -DiskOptions $DiskOptions
    
    # Confirmar selección
    Show-Header
    Write-ColorOutput "Has seleccionado:" "Yellow"
    Write-ColorOutput "  Disco: $($SelectedDisk.Letter): - $($SelectedDisk.Name)" "White"
    Write-ColorOutput "  Espacio libre: $(Get-FormattedSize ($SelectedDisk.Free * 1GB))" "White"
    Write-Host ""
    
    Write-Host ""
    Write-ColorOutput "El backup se guardará con numeración automática (Backup###)" "Cyan"
    Write-ColorOutput "Se detectará automáticamente el siguiente número disponible" "DarkGray"
    Write-Host ""
    Write-ColorOutput "¿Continuar con el backup? (S/N): " "Yellow" -NoNewline
    $Confirm = Read-Host
    
    if ($Confirm -ne 'S' -and $Confirm -ne 's') {
        Write-ColorOutput "`nBackup cancelado." "Red"
        exit
    }
    
    # Iniciar backup
    Start-Backup -DestinationDisk "$($SelectedDisk.Letter):"
    
} catch {
    Write-ColorOutput "`nERROR CRÍTICO: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Ubicación: $($_.InvocationInfo.ScriptLineNumber):$($_.InvocationInfo.OffsetInLine)" "Red"
    Write-Host ""
    Read-Host "Presiona Enter para salir"
}
