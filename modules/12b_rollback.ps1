# ============================================================
# 12b_rollback.ps1 -- Moteur de Rollback systeme
# Snapshot avant chaque action systeme -> restauration precise
# Appele par 11_moteur.ps1 : Save-SystemSnapshot / Restore-SystemSnapshot
# ============================================================

$Global:SystemSnapshot = $null

function Save-SystemSnapshot {
    # Prend un snapshot de toutes les valeurs registre touchees par les actions systeme
    $snap = [ordered]@{ Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss"); Entries = [ordered]@{} }
    $e = $snap.Entries

    # Extensions fichiers
    $e["HideFileExt"] = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -EA SilentlyContinue).HideFileExt

    # Fichiers caches
    $e["Hidden"] = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name Hidden -EA SilentlyContinue).Hidden

    # Bing Search
    $e["BingSearchEnabled"] = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" -Name BingSearchEnabled -EA SilentlyContinue).BingSearchEnabled
    $e["DisableSearchBoxSuggestions"] = (Get-ItemProperty "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name DisableSearchBoxSuggestions -EA SilentlyContinue).DisableSearchBoxSuggestions

    # Telemetrie
    $e["AllowTelemetry_Policies"] = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name AllowTelemetry -EA SilentlyContinue).AllowTelemetry
    $e["DiagTrackStart"] = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack" -Name Start -EA SilentlyContinue).Start

    # Copilot
    $e["Copilot_HKLM"] = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" -Name TurnOffWindowsCopilot -EA SilentlyContinue).TurnOffWindowsCopilot
    $e["ShowCopilotButton"] = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name ShowCopilotButton -EA SilentlyContinue).ShowCopilotButton

    # Veille -- GUID schema actif
    $schemeGuid = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" -Name ActivePowerScheme -EA SilentlyContinue).ActivePowerScheme
    $e["ActivePowerScheme"] = $schemeGuid
    if ($schemeGuid) {
        $acPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$schemeGuid\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1a44da"
        $e["SleepACIndex"] = (Get-ItemProperty $acPath -Name ACSettingIndex -EA SilentlyContinue).ACSettingIndex
        $e["SleepDCIndex"] = (Get-ItemProperty $acPath -Name DCSettingIndex -EA SilentlyContinue).DCSettingIndex
    }

    # Hibernation
    $e["HibernateEnabled"] = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name HibernateEnabled -EA SilentlyContinue).HibernateEnabled

    # RDP
    $e["fDenyTSConnections"] = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections -EA SilentlyContinue).fDenyTSConnections

    # Windows Update
    $e["PauseFeatureUpdatesStartTime"] = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name PauseFeatureUpdatesStartTime -EA SilentlyContinue).PauseFeatureUpdatesStartTime
    $e["PauseQualityUpdatesStartTime"] = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name PauseQualityUpdatesStartTime -EA SilentlyContinue).PauseQualityUpdatesStartTime

    # Kernel speed
    $e["Win32PrioritySeparation"] = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name Win32PrioritySeparation -EA SilentlyContinue).Win32PrioritySeparation

    # Services
    $e["SysMainStart"]   = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain"   -Name Start -EA SilentlyContinue).Start
    $e["WSearchStart"]   = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch"   -Name Start -EA SilentlyContinue).Start

    # Xbox Game Bar
    $e["AllowGameDVR"]       = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" -Name AllowGameDVR -EA SilentlyContinue).AllowGameDVR
    $e["GameBarServicesStart"] = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\GameBarServices" -Name Start -EA SilentlyContinue).Start

    $Global:SystemSnapshot = $snap
    Write-Log "Snapshot systeme pris ($($e.Count) entrees)." "Cyan"

    # Sauvegarder sur disque dans logs\
    $snapDir  = Join-Path $scriptDir "logs"
    if (!(Test-Path $snapDir)) { New-Item $snapDir -ItemType Directory | Out-Null }
    $snapFile = Join-Path $snapDir "snapshot_$((Get-Date -Format 'yyyyMMdd_HHmmss')).json"
    $snap | ConvertTo-Json -Depth 4 | Set-Content $snapFile -Encoding UTF8 -EA SilentlyContinue
    Write-Log "Snapshot sauvegarde : $snapFile" "Gray"
    return $snapFile
}

function Restore-SystemSnapshot {
    param([string]$SnapFile = "")

    # Charger depuis fichier si fourni, sinon utiliser le snapshot en memoire
    $snap = $null
    if ($SnapFile -and (Test-Path $SnapFile)) {
        $snap = Get-Content $SnapFile -Raw | ConvertFrom-Json
        $e = $snap.Entries
    } elseif ($Global:SystemSnapshot) {
        $e = $Global:SystemSnapshot.Entries
    } else {
        Write-Log "[!] Aucun snapshot disponible pour le rollback." "Red"
        return $false
    }

    Write-Log "Rollback systeme en cours..." "Yellow"
    $restored = 0; $errors = 0

    function Restore-RegVal($path, $name, $val, $type="DWord") {
        if ($null -eq $val) { return }   # valeur non capturee -- ne pas toucher
        try {
            if (!(Test-Path $path)) { New-Item $path -Force | Out-Null }
            Set-ItemProperty -Path $path -Name $name -Value $val -Type $type -Force -EA Stop
            $script:restored++
        } catch { $script:errors++ }
    }

    # Restaurer chaque valeur
    Restore-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "HideFileExt" $e.HideFileExt
    Restore-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "Hidden" $e.Hidden
    Restore-RegVal "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" "ShowCopilotButton" $e.ShowCopilotButton
    Restore-RegVal "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" "BingSearchEnabled" $e.BingSearchEnabled
    Restore-RegVal "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" "DisableSearchBoxSuggestions" $e.DisableSearchBoxSuggestions
    Restore-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" "AllowTelemetry" $e.AllowTelemetry_Policies
    Restore-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot" $e.Copilot_HKLM
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Power" "HibernateEnabled" $e.HibernateEnabled
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" "fDenyTSConnections" $e.fDenyTSConnections
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" "Win32PrioritySeparation" $e.Win32PrioritySeparation
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\DiagTrack" "Start" $e.DiagTrackStart
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" "Start" $e.SysMainStart
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\WSearch" "Start" $e.WSearchStart
    Restore-RegVal "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR" "AllowGameDVR" $e.AllowGameDVR
    Restore-RegVal "HKLM:\SYSTEM\CurrentControlSet\Services\GameBarServices" "Start" $e.GameBarServicesStart

    # Windows Update -- supprimer les cles de pause si elles n existaient pas
    if ($null -eq $e.PauseFeatureUpdatesStartTime) {
        Remove-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -EA SilentlyContinue
    } else {
        Set-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" -Name "PauseFeatureUpdatesStartTime" -Value $e.PauseFeatureUpdatesStartTime -EA SilentlyContinue
    }

    # Veille -- restaurer via powercfg si valeur capturee
    if ($null -ne $e.SleepACIndex -and $e.ActivePowerScheme) {
        try { powercfg /change standby-timeout-ac $e.SleepACIndex 2>$null } catch {}
    }

    # Relancer l explorateur pour appliquer les changements visuels (extensions, fichiers caches)
    try {
        Stop-Process -Name "explorer" -Force -EA SilentlyContinue
        Start-Sleep -Milliseconds 1500
        Start-Process "explorer"
    } catch {}

    Write-Log "Rollback termine : $restored valeurs restaurees, $errors erreurs." "Green"
    return $true
}

# ============================================================
# Bouton rollback dans l onglet Historique (ajoute au chargement)
# Le bouton est cree ici, reference via $Global:BtnRollback
# ============================================================
$Global:BtnRollback = $null   # defini apres creation de l onglet historique
