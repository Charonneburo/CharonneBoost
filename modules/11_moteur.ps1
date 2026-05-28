$progressBar.Location  = New-Object System.Drawing.Point(6, $L["ProgY"])
$progressBar.Size      = New-Object System.Drawing.Size(($L["FormW"] - 12), 18)
$progressBar.ForeColor = [System.Drawing.Color]::FromArgb(26, 42, 74)
$script:form.Controls.Add($progressBar)

$script:lblStatus = New-Object System.Windows.Forms.Label
$script:lblStatus.Text      = "Pret a optimiser..."
$script:lblStatus.Location  = New-Object System.Drawing.Point(6, $L["StatusY"])
$script:lblStatus.Size      = New-Object System.Drawing.Size(($L["FormW"] - 220), 20)
$script:lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
$script:lblStatus.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
$script:form.Controls.Add($script:lblStatus)

# ============================================================
# LOGIQUE D'EXECUTION
# ============================================================
$btnLaunch.Add_Click({
    $btnLaunch.Enabled = $false

    # Espace disque avant
    $dsk = Get-PSDrive C -ErrorAction SilentlyContinue
    $Global:DisqueBefore = if ($dsk) { [math]::Round($dsk.Used / 1GB, 2) } else { 0 }

    $checkedSys = $appsV39.Keys    | Where-Object { $Global:SysChk[$_].Checked }
    $checkedBlt = $bloatMap.Keys   | Where-Object { $Global:BloatChk[$_].Checked }
    $checkedApp = $AppsList        | Where-Object { $Global:AppChk[$_.Name].Checked }
    $checkedNet = $netActions.Keys | Where-Object { $Global:NetChk[$_].Checked }
    $checkedSec = $secActions.Keys | Where-Object { $Global:SecChk[$_].Checked }

    $total = $checkedSys.Count + $checkedBlt.Count + $checkedApp.Count + $checkedNet.Count + $checkedSec.Count
    if ($total -eq 0) { [System.Windows.Forms.MessageBox]::Show("Rien a faire !"); $btnLaunch.Enabled=$true; return }
    # Confirmation globale si actions sensibles selectionnees
    $riskyNames = @($checkedSys + $checkedNet + $checkedSec | Where-Object { $_ -match 'OneDrive|Hibernation|Services|RDP|TCP|SMB|Telemetry|Copilot|Defender|AdwCleaner|ExecutionPolicy|Pare-feu|Windows Update' })
    if ($riskyNames.Count -gt 0) {
        if (-not (Confirm-CBAction -Title "Confirmation actions sensibles" -Risk "High" -Message "Actions selectionnees :`n- $($riskyNames -join "`n- ")`n`nUn point de restauration est recommande avant de continuer.")) {
            Write-Log "Operation annulee par l utilisateur." "Yellow"
            $btnLaunch.Enabled=$true
            return
        }
    }
    $progressBar.Maximum=$total; $progressBar.Value=0

    # --- SNAPSHOT avant toute action systeme ---
    if ($checkedSys.Count -gt 0) {
        Save-SystemSnapshot | Out-Null
    }

    # --- SYSTEME ---
    foreach ($item in $checkedSys) {
        $task = $appsV39[$item].Key
        Write-Log "Action : $item" "Yellow"
        switch ($task) {
            "OneDrive_Deep" {
                if (Confirm-CBAction -Title "OneDrive" -Risk "High" -Message "Desinstaller completement OneDrive et supprimer le dossier utilisateur OneDrive local ?") {
                    Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
                    $od = if (Test-Path "$env:SystemRoot\SysWOW64\OneDriveSetup.exe") { "$env:SystemRoot\SysWOW64\OneDriveSetup.exe" } else { "$env:SystemRoot\System32\OneDriveSetup.exe" }
                    Start-Process $od -ArgumentList "/uninstall" -Wait -NoNewWindow -ErrorAction SilentlyContinue
                    Remove-Item "$env:UserProfile\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
                    Write-Log "OneDrive desinstalle." "Green"
                }
            }
            "Hibernation_Toggle" {
                if (Confirm-CBAction -Title "Hibernation" -Risk "Medium" -Message "Desactiver l hibernation et supprimer hiberfil.sys ?") {
                    powercfg -h off; Write-Log "Hibernation desactivee." "Green"
                }
            }
            "WinUpdate_DISABLED" {
                # WinSxS desactive volontairement -- DISM /ResetBase peut causer des instabilites
                Write-Log "Nettoyage WinSxS ignore (desactive dans cet outil)." "Yellow"
            }
            "Copilot_Deep" {
                $rp = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
                if (!(Test-Path $rp)) { New-Item -Path $rp -Force | Out-Null }
                Set-ItemProperty -Path $rp -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowCopilotButton" -Value 0 -ErrorAction SilentlyContinue
                Write-Log "Copilot desactive." "Green"
            }
            "Telemetry" {
                # Reduit telemetrie sans bloquer les associations de fichiers
                $telPaths = @(
                    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
                    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
                )
                foreach ($tp in $telPaths) {
                    if (!(Test-Path $tp)) { New-Item -Path $tp -Force | Out-Null }
                    Set-ItemProperty -Path $tp -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
                }
                # Desactiver uniquement les services qui existent sur ce poste
                # DPS (Diagnostic Policy Service) exclu : requis par l assistant de depannage reseau Windows
                $svcs = @("DiagTrack","dmwappushservice","PcaSvc","diagsvc")
                $svcCount = 0
                foreach ($s in $svcs) {
                    if (Get-Service -Name $s -ErrorAction SilentlyContinue) {
                        Stop-Service $s -Force -ErrorAction SilentlyContinue
                        Set-Service  $s -StartupType Disabled -ErrorAction SilentlyContinue
                        $svcCount++
                    }
                }
                Write-Log "Telemetrie reduite ($svcCount service(s) desactive(s))." "Green"
            }
            "SpeedKernel" {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -Type DWord -Force -ErrorAction SilentlyContinue
                Write-Log "Priorite noyau optimisee." "Green"
            }
            "DisableServices" {
                # --------------------------------------------------------
                # LISTE DE SERVICES SURS A DESACTIVER
                # Criteres : non critique systeme, non utilise par Outlook,
                #            non requis par le depannage reseau Windows
                #
                # RETIRES de la liste originale :
                #   RemoteRegistry -- acces registre a distance, risque securite
                #   DPS            -- requis par l assistant depannage reseau
                #
                # CONSERVES selon conditions :
                #   SysMain  -- conserve sur HDD (prefetch utile)
                #   WSearch  -- conserve si Outlook installe
                # --------------------------------------------------------
                $svcsToDisable = [System.Collections.Generic.List[string]]::new()
                $svcsToDisable.Add("MapsBroker")       # Telechargement cartes hors ligne -- inutile
                $svcsToDisable.Add("WMPNetworkSvc")    # Partage media Windows Player -- inutile
                $svcsToDisable.Add("lfsvc")            # Geolocalisation -- inutile sur bureau fixe

                if ($Global:DiskType -eq "SSD") {
                    $svcsToDisable.Add("SysMain")
                    Write-Log "SSD detecte : SysMain sera desactive." "Cyan"
                } else {
                    Write-Log "HDD detecte : SysMain conserve (prefetch utile)." "Yellow"
                }

                $outlookPath1 = $env:ProgramFiles + "\Microsoft Office\root\Office16\OUTLOOK.EXE"
                $outlookPath2 = ${env:ProgramFiles(x86)} + "\Microsoft Office\root\Office16\OUTLOOK.EXE"
                $outlookInstalled = (Test-Path $outlookPath1) -or (Test-Path $outlookPath2)
                if (-not $outlookInstalled) {
                    $svcsToDisable.Add("WSearch")
                    Write-Log "Outlook non detecte : WSearch sera desactive." "Cyan"
                } else {
                    Write-Log "Outlook detecte : WSearch conserve (recherche mail)." "Yellow"
                }

                # --------------------------------------------------------
                # ROLLBACK : sauvegarder l etat AVANT toute modification
                # Fichier : logs\services_rollback_YYYY-MM-DD_HH-mm-ss.json
                # --------------------------------------------------------
                $rollbackDir  = Join-Path $scriptDir "logs"
                if (-not (Test-Path $rollbackDir)) { New-Item $rollbackDir -ItemType Directory | Out-Null }
                $rollbackFile = Join-Path $rollbackDir "services_rollback_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').json"
                $rollbackData = [ordered]@{}
                foreach ($s in $svcsToDisable) {
                    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                    if ($svc) {
                        $rollbackData[$s] = @{
                            StartType = $svc.StartType.ToString()
                            Status    = $svc.Status.ToString()
                        }
                    }
                }
                try {
                    $rollbackData | ConvertTo-Json -Depth 3 | Set-Content $rollbackFile -Encoding UTF8
                    Write-Log "Rollback services sauvegarde : $rollbackFile" "Cyan"
                } catch {
                    Write-Log "[!] Impossible de sauvegarder le rollback services : $_" "Yellow"
                }

                # --------------------------------------------------------
                # DESACTIVATION avec garde d existence
                # --------------------------------------------------------
                $disabledCount = 0
                foreach ($s in $svcsToDisable) {
                    $svc = Get-Service -Name $s -ErrorAction SilentlyContinue
                    if ($svc) {
                        Stop-Service  $s -Force -ErrorAction SilentlyContinue
                        Set-Service   $s -StartupType Disabled -ErrorAction SilentlyContinue
                        $disabledCount++
                        Write-Log "Service desactive : $s" "Cyan"
                    }
                }
                Write-Log "$disabledCount service(s) desactive(s). Rollback disponible dans logs\." "Green"

                # Proposer d afficher le fichier rollback
                $r = [System.Windows.Forms.MessageBox]::Show(
                    "$disabledCount service(s) desactive(s).`n`nRollback sauvegarde :`n$rollbackFile`n`nOuvrir le fichier de rollback ?",
                    "Services desactives",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Information)
                if ($r -eq "Yes" -and (Test-Path $rollbackFile)) {
                    Start-Process "notepad.exe" -ArgumentList $rollbackFile
                }
            }
            "CleanDisk" {
                if ([System.Windows.Forms.MessageBox]::Show(
                    "Nettoyer les fichiers temporaires, le cache Windows Update et la corbeille ?`n`nGain attendu : 500 Mo a plusieurs Go selon l anciennete du poste.",
                    "Nettoyage",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Information) -eq "Yes") {

                    $freed = 0

                    # --- %TEMP% utilisateur -- uniquement si chemin LOCAL (pas reseau) ---
                    $tempPath = $env:TEMP
                    if ($tempPath -and $tempPath -notmatch "^\\\\") {
                        $before = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        Remove-Item "$tempPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                        $after  = (Get-ChildItem $tempPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                        $freed += [math]::Max(0, $before - $after)
                    }

                    # --- Windows\Temp ---
                    Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue

                    # --- Dossiers Temp autres profils (Admin uniquement) ---
                    $profiles = Get-ChildItem "C:\Users" -Directory -ErrorAction SilentlyContinue
                    foreach ($prof in $profiles) {
                        $pt = Join-Path $prof.FullName "AppData\Local\Temp"
                        if ((Test-Path $pt) -and $pt -notmatch "^\\\\") {
                            Remove-Item "$pt\*" -Recurse -Force -ErrorAction SilentlyContinue
                        }
                    }

                    # --- Cache Windows Update (SoftwareDistribution\Download) ---
                    # Sur si Windows est a jour ; le service se relance et re-telecharge si besoin
                    $svcWU = Get-Service -Name wuauserv -ErrorAction SilentlyContinue
                    if ($svcWU) {
                        Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
                        $wuPath = "$env:SystemRoot\SoftwareDistribution\Download"
                        if (Test-Path $wuPath) {
                            $before2 = (Get-ChildItem $wuPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                            Remove-Item "$wuPath\*" -Recurse -Force -ErrorAction SilentlyContinue
                            $after2  = (Get-ChildItem $wuPath -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
                            $freed += [math]::Max(0, $before2 - $after2)
                        }
                        Start-Service wuauserv -ErrorAction SilentlyContinue
                    }

                    # --- Cache de miniatures (thumbnails) -- se regenere automatiquement ---
                    $thumbPath = "$env:LOCALAPPDATA\Microsoft\Windows\Explorer"
                    if (Test-Path $thumbPath) {
                        Get-ChildItem "$thumbPath\thumbcache_*.db" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
                    }

                    # --- Cache de polices Windows ---
                    Stop-Service FontCache -Force -ErrorAction SilentlyContinue
                    Remove-Item "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache*" -Force -ErrorAction SilentlyContinue
                    Start-Service FontCache -ErrorAction SilentlyContinue

                    # --- Prefetch (sur, se reconstitue au prochain demarrage) ---
                    Remove-Item "$env:SystemRoot\Prefetch\*" -Force -ErrorAction SilentlyContinue

                    # --- Corbeille ---
                    Clear-RecycleBin -Force -ErrorAction SilentlyContinue

                    $freedMo = [math]::Round($freed / 1MB, 0)
                    Write-Log "Nettoyage complet termine. Libere mesure : ~$freedMo Mo (hors prefetch/polices/miniatures)." "Green"
                }
            }
            "LocalSearch" {
                # Desactive uniquement la recherche web, ne touche PAS aux associations
                $regS = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer"
                if (!(Test-Path $regS)) { New-Item -Path $regS -Force | Out-Null }
                Set-ItemProperty -Path $regS -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force
                Write-Log "Recherche Bing desactivee dans la barre de recherche." "Green"
            }
            "ShowExtensions" {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
                Write-Log "Extensions de fichiers affichees." "Green"
            }
            "ShowHidden" {
                Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
                Write-Log "Fichiers caches affiches." "Green"
            }
            "DisableSleep" {
                powercfg -change -standby-timeout-ac 0; powercfg -change -standby-timeout-dc 0; powercfg -change -monitor-timeout-ac 0
                Write-Log "Mise en veille desactivee." "Green"
            }
            "EnableRDP" {
                Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value 0
                Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-TCP" -ErrorAction SilentlyContinue
                Enable-NetFirewallRule -Name "RemoteDesktop-UserMode-In-UDP" -ErrorAction SilentlyContinue
                Enable-NetFirewallRule -Name "RemoteDesktop-Shadow-In-TCP" -ErrorAction SilentlyContinue
                Enable-NetFirewallRule -DisplayGroup "Remote Desktop" -ErrorAction SilentlyContinue
                Write-Log "Bureau a distance (RDP) active." "Green"
            }
            "DisableWinUpdate" {
                $choixMAJ = [System.Windows.Forms.MessageBox]::Show(
                    "Mettre les MAJ Windows en pause (35 jours) ?`nLes mises a jour de securite resteront applicables manuellement.`nC est plus sur qu une desactivation permanente.",
                    "MAJ Windows",
                    [System.Windows.Forms.MessageBoxButtons]::YesNo,
                    [System.Windows.Forms.MessageBoxIcon]::Warning)
                if ($choixMAJ -eq "Yes") {
                    # Pause 35 jours (methode Microsoft recommandee)
                    $pauseDate = (Get-Date).AddDays(35).ToString("yyyy-MM-ddTHH:mm:ssZ")
                    $rWUPause = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
                    if (!(Test-Path $rWUPause)) { New-Item -Path $rWUPause -Force | Out-Null }
                    Set-ItemProperty -Path $rWUPause -Name "PauseFeatureUpdatesStartTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $rWUPause -Name "PauseFeatureUpdatesEndTime"   -Value $pauseDate -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $rWUPause -Name "PauseQualityUpdatesStartTime" -Value (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ") -ErrorAction SilentlyContinue
                    Set-ItemProperty -Path $rWUPause -Name "PauseQualityUpdatesEndTime"   -Value $pauseDate -ErrorAction SilentlyContinue
                    Write-Log "MAJ Windows mises en pause 35 jours (jusqu au $(([DateTime]::Now).AddDays(35).ToString('dd/MM/yyyy')))." "Green"
                }
            }
            "RestorePoint" {
                New-RestorePointSafe -Description "Manuel - CB v12 $(Get-Date -Format 'dd/MM/yyyy HH:mm')" | Out-Null
            }
        }
        $progressBar.Value++
    }

    # --- PURGE BLOATWARES ---
    # Point de restauration obligatoire si actions destructives cochees
    if ($checkedBlt.Count -gt 0) {
        Write-Log "Creation point de restauration avant purge..." "Yellow"
        $rpOk = New-RestorePointSafe -Description "Avant purge bloatwares - CB v12"
        if (!$rpOk) {
            $choice = [System.Windows.Forms.MessageBox]::Show(
                "Impossible de creer un point de restauration.`nVoulez-vous continuer quand meme ?`n(Non recommande)",
                "Avertissement",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Warning)
            if ($choice -ne "Yes") { $btnLaunch.Enabled=$true; return }
        }
    }
    foreach ($item in $checkedBlt) {
        Write-Log "Purge : $item" "Magenta"
        $entry = $bloatMap[$item]; $val = $entry.Pkg
        if ($val -eq "Ads") {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -ErrorAction SilentlyContinue
        } elseif ($item -eq "Microsoft 365 Copilot") {
            $val -split ";" | ForEach-Object { Get-AppxPackage -AllUsers $_.Trim() -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null }
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*Copilot*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            $rc="HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
            if(!(Test-Path $rc)){New-Item $rc -Force|Out-Null}
            Set-ItemProperty -Path $rc -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force
        } elseif ($item -eq "Cortana") {
            $val -split ";" | ForEach-Object { Get-AppxPackage -AllUsers $_.Trim() -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Out-Null }
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*Cortana*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            $rco="HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            if(!(Test-Path $rco)){New-Item $rco -Force|Out-Null}
            Set-ItemProperty -Path $rco -Name "AllowCortana" -Value 0 -Type DWord -Force
        } elseif ($item -eq "Xbox (Game Bar)") {
            # Xbox / GamingApp : protege sur Win11, necessite approche multi-methodes
            $val -split ";" | ForEach-Object {
                $pid2 = $_.Trim()
                try { Get-AppxPackage -AllUsers $pid2 -EA SilentlyContinue | Remove-AppxPackage -AllUsers -EA SilentlyContinue | Out-Null } catch {}
                try { Get-AppxProvisionedPackage -Online -EA SilentlyContinue | Where-Object { $_.PackageName -like "*$($pid2.Replace('*',''))*" } | Remove-AppxProvisionedPackage -Online -EA SilentlyContinue | Out-Null } catch {}
            }
            # Desactiver via GPO registre (fonctionne meme si le paquet reste)
            $xbKey = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"
            if (!(Test-Path $xbKey)) { New-Item $xbKey -Force | Out-Null }
            Set-ItemProperty $xbKey -Name "AllowGameDVR" -Value 0 -Type DWord -Force -EA SilentlyContinue
            # Desactiver le service GameBarServices
            try { Stop-Service "GameBarServices" -Force -EA SilentlyContinue } catch {}
            try { Set-Service "GameBarServices" -StartupType Disabled -EA SilentlyContinue } catch {}
            # Desactiver Game Bar pour l utilisateur courant
            Set-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -Type DWord -EA SilentlyContinue
            Set-ItemProperty "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -EA SilentlyContinue
            Write-Log "Xbox Game Bar desactive via GPO + registre + service." "Green"
        } else {
            $val -split ";" | ForEach-Object {
                $pid2=$_.Trim()
                try {
                    $pkgs = Get-AppxPackage -AllUsers $pid2 -ErrorAction SilentlyContinue
                    if ($pkgs) {
                        try {
                            $pkgs | Remove-AppxPackage -AllUsers -ErrorAction Stop | Out-Null
                        } catch {
                            try { $pkgs | Remove-AppxPackage -ErrorAction SilentlyContinue | Out-Null }
                            catch { Write-Log "[Info] $item : composant protege, suppression ignoree." "Yellow" }
                        }
                    }
                } catch {
                    Write-Log "[Info] $item : composant systeme, suppression ignoree." "Yellow"
                }
                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*$($pid2.Replace('*',''))*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Out-Null
            }
        }
        $progressBar.Value++
    }

    # --- LOGICIELS ---
    $RepoPath = "$scriptDir\Logiciels"
    if (!(Test-Path $RepoPath)) { New-Item $RepoPath -ItemType Directory | Out-Null }

    foreach ($App in $checkedApp) {
        Write-Log "Traitement : $($App.Name)" "Cyan"

        # Cas speciaux sans fichier local
        if ($App.Special -eq "AdobeWinget") {
            if (!(Test-AppInstalled $App)) {
                $wProc = Start-Process "winget" -ArgumentList "install --id Adobe.Acrobat.Reader.64-bit --silent --accept-package-agreements --accept-source-agreements" -PassThru
                while ($wProc -and !$wProc.HasExited) { Start-Sleep -Milliseconds 500; $script:form.Refresh() }
                Write-Log "Adobe Acrobat installe." "Green"
            } else { Write-Log "[OK] Adobe Acrobat deja present." "Green" }
            $progressBar.Value++; continue
        }
        if ($App.Special -eq "Office365") {
            Write-Log "Office 365 : ouverture page telechargement Microsoft..." "Yellow"
            Start-Process "https://www.microsoft.com/fr-fr/microsoft-365"
            $progressBar.Value++; continue
        }
        if ($App.Special -eq "AdwCleaner") {
            $dest = Join-Path ([Environment]::GetFolderPath("Desktop")) "AdwCleaner.exe"
            if (Test-Path $dest) { Write-Log "[OK] AdwCleaner deja sur le bureau." "Green" }
            else {
                try { Invoke-CBSafeDownload -Url "https://downloads.malwarebytes.com/file/adwcleaner" -Destination $dest -AllowUnsignedAfterConfirm | Out-Null; Write-Log "AdwCleaner copie sur le bureau." "Green" }
                catch { Write-Log "[!] Echec AdwCleaner : $_" "Red" }
            }
            $progressBar.Value++; continue
        }
        if ($App.Special -eq "NPP") {
            if (Test-AppInstalled $App) { Write-Log "[OK] Notepad++ deja installe." "Green"; $progressBar.Value++; continue }
            $nppDone = $false
            # Methode 1 : GitHub API releases (toujours la derniere version, pas besoin de URL fixe)
            try {
                Write-Log "Notepad++ : recuperation derniere version depuis GitHub..." "White"
                $apiUrl   = "https://api.github.com/repos/notepad-plus-plus/notepad-plus-plus/releases/latest"
                $headers  = @{ "User-Agent" = "CharonneBoost/0.77" }
                $release  = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 10 -ErrorAction Stop
                $asset    = $release.assets | Where-Object { $_.name -match "x64\.exe$" -and $_.name -notmatch "arm" } | Select-Object -First 1
                if ($asset) {
                    $nppFile = Join-Path $env:TEMP "npp-setup.exe"
                    Write-Log "Notepad++ : telechargement $($asset.name)..." "White"
                    Invoke-CBSafeDownload -Url $asset.browser_download_url -Destination $nppFile -AllowUnsignedAfterConfirm | Out-Null
                    if (Test-Path $nppFile) {
                        Write-Log "Notepad++ : installation silencieuse..." "Cyan"
                        $proc = Start-Process -FilePath $nppFile -ArgumentList "/S" -PassThru -Wait
                        Remove-Item $nppFile -Force -ErrorAction SilentlyContinue
                        $nppDone = $true
                        Write-Log "Notepad++ : installe ($($release.tag_name))." "Green"
                    }
                }
            } catch { Write-Log "Notepad++ GitHub : $($_.Exception.Message) -- tentative winget..." "Yellow" }
            # Methode 2 : winget fallback
            if (-not $nppDone) {
                Write-Log "Notepad++ : installation via winget..." "White"
                $wg = Start-Process "winget" -ArgumentList "install --id Notepad++.Notepad++ --silent --accept-package-agreements --accept-source-agreements" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                if ($wg) { while (!$wg.HasExited) { Start-Sleep -Milliseconds 300; $script:form.Refresh() } }
                $nppDone = $true
                Write-Log "Notepad++ : installe via winget." "Green"
            }
            $Global:UninstallCache = $null   # invalider le cache pour re-detection
            $progressBar.Value++; continue
        }
        $Installed  = Test-AppInstalled $App
        if ($Installed) { Write-Log "[OK] $($App.Name) deja present." "Green"; $progressBar.Value++; continue }

        # Chemin du cache installeur local (si App.File defini)
        $LocalFile = if ($App.File) { Join-Path $RepoPath $App.File } else { $null }
        $wingetArgs = "install --id $($App.ID) --silent --accept-package-agreements --accept-source-agreements"

        if (-not $App.Url -and -not $LocalFile) {
            # Pas d URL ni de fichier -> winget uniquement
            Write-Log "Installation via winget : $($App.Name)..." "White"
            $wProc = Start-Process "winget" -ArgumentList $wingetArgs -PassThru -WindowStyle Hidden -EA SilentlyContinue
            if ($wProc) { while (!$wProc.HasExited) { Start-Sleep -Milliseconds 400; $script:form.Refresh() } }
            Write-Log "Termine : $($App.Name)" "Green"
            $progressBar.Value++; continue
        }

        # Telecharger si URL disponible et fichier absent/trop petit
        if ($App.Url -and $LocalFile) {
            if (!(Test-Path $LocalFile) -or (Get-Item $LocalFile -EA SilentlyContinue).Length -lt 500KB) {
                Write-Log "Telechargement : $($App.Name)..." "White"
                try {
                    Invoke-CBSafeDownload -Url $App.Url -Destination $LocalFile -AllowUnsignedAfterConfirm | Out-Null
                    Write-Log "Telecharge : $LocalFile" "Gray"
                } catch {
                    Write-Log "[!] BITS echoue pour $($App.Name), tentative winget..." "Yellow"
                    $wProc = Start-Process "winget" -ArgumentList $wingetArgs -PassThru -WindowStyle Hidden -EA SilentlyContinue
                    if ($wProc) { while (!$wProc.HasExited) { Start-Sleep -Milliseconds 400; $script:form.Refresh() } }
                    Write-Log "Termine via winget : $($App.Name)" "Green"
                    $progressBar.Value++; continue
                }
            }
        }

        # Installer depuis le fichier local
        if ($LocalFile -and (Test-Path $LocalFile)) {
            Write-Log "[+] Installation : $($App.Name)..." "Cyan"
            $proc = Start-Process -FilePath $LocalFile -ArgumentList $App.Args -PassThru -EA SilentlyContinue
            if ($proc) { while (!$proc.HasExited) { $progressBar.Value=[Math]::Min($progressBar.Value,$progressBar.Maximum); Start-Sleep -Milliseconds 250 } }
            Write-Log "Termine : $($App.Name)" "Green"
        } elseif ($App.ID) {
            # Dernier recours : winget
            Write-Log "[!] Fichier absent, installation via winget : $($App.Name)..." "Yellow"
            $wProc = Start-Process "winget" -ArgumentList $wingetArgs -PassThru -WindowStyle Hidden -EA SilentlyContinue
            if ($wProc) { while (!$wProc.HasExited) { Start-Sleep -Milliseconds 400; $script:form.Refresh() } }
            Write-Log "Termine : $($App.Name)" "Green"
        } else {
            Write-Log "[!] Impossible d installer $($App.Name) : ni URL ni ID winget." "Red"
        }

        # Post-install Firefox
        if ($App.Name -eq "Firefox") {
            $pdir="${env:ProgramFiles}\Mozilla Firefox\distribution"
            if(!(Test-Path $pdir)){New-Item $pdir -ItemType Directory -Force|Out-Null}
            $json='{"policies":{"ExtensionSettings":{"uBlock0@raymondhill.net":{"installation_mode":"force_installed","install_url":"https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"}},"Homepage":{"URL":"https://www.google.fr","Locked":false,"StartPage":"homepage"},"OverrideFirstRunPage":"","DisplayBookmarksToolbar":"always"}}'
            [System.IO.File]::WriteAllText("$pdir\policies.json",$json,(New-Object System.Text.UTF8Encoding $false))
        }
        # Post-install Wise : supprimer raccourcis bureau
        if ($App.Name -eq "Wise Disk Cleaner") {
            $desk=[Environment]::GetFolderPath("Desktop")
            @("Wise Disk Cleaner.lnk","Wise Care 365.lnk","Check for updates.lnk") | ForEach-Object { $p=Join-Path $desk $_; if(Test-Path $p){Remove-Item $p -Force} }
        }
        $progressBar.Value++
    }

    # --- RESEAU ---
    foreach ($item in $checkedNet) {
        $task = $netActions[$item].Key; Write-Log "Reseau : $item" "Cyan"
        switch ($task) {
            "PingTest" {
                $r=Test-Connection "8.8.8.8" -Count 2 -Quiet
                $m=if($r){"Connectivite Internet : OK"}else{"Connectivite Internet : ECHEC"}
                Write-Log $m $(if($r){"Green"}else{"Red"})
                [System.Windows.Forms.MessageBox]::Show($m,"Test connectivite")
            }
            "ShowIP" {
                $ip=(Get-NetIPAddress -AddressFamily IPv4|Where-Object{$_.InterfaceAlias -notmatch "Loopback"}|Select-Object -First 1)
                $gw=(Get-NetRoute -DestinationPrefix "0.0.0.0/0"|Select-Object -First 1).NextHop
                $dns=(Get-DnsClientServerAddress -AddressFamily IPv4|Where-Object{$_.InterfaceAlias -notmatch "Loopback"}|Select-Object -First 1).ServerAddresses -join ", "
                $m="IP : $($ip.IPAddress)`nPasserelle : $gw`nDNS : $dns"
                Write-Log $m "Cyan"; [System.Windows.Forms.MessageBox]::Show($m,"Infos reseau")
            }
            "FlushDNS"   { ipconfig /flushdns | Out-Null; Write-Log "Cache DNS vide." "Green" }
            "MapDrive" {
                $f=New-Object System.Windows.Forms.Form; $f.Text="Lecteur reseau"; $f.Size=New-Object System.Drawing.Size(380,160); $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false
                $l1=New-Object System.Windows.Forms.Label; $l1.Text="Lettre (ex: Z):"; $l1.Location=New-Object System.Drawing.Point(10,15); $l1.AutoSize=$true
                $t1=New-Object System.Windows.Forms.TextBox; $t1.Text="Z"; $t1.Location=New-Object System.Drawing.Point(130,12); $t1.Width=40
                $l2=New-Object System.Windows.Forms.Label; $l2.Text="Chemin UNC:"; $l2.Location=New-Object System.Drawing.Point(10,45); $l2.AutoSize=$true
                $t2=New-Object System.Windows.Forms.TextBox; $t2.Text="\\serveur\partage"; $t2.Location=New-Object System.Drawing.Point(130,42); $t2.Width=220
                $bOk=New-Object System.Windows.Forms.Button; $bOk.Text="OK"; $bOk.Location=New-Object System.Drawing.Point(130,75); $bOk.DialogResult="OK"
                $f.Controls.AddRange(@($l1,$t1,$l2,$t2,$bOk)); $f.AcceptButton=$bOk
                if($f.ShowDialog() -eq "OK" -and $t1.Text -and $t2.Text){
                    New-PSDrive -Name $t1.Text.TrimEnd(":") -PSProvider FileSystem -Root $t2.Text -Persist -ErrorAction SilentlyContinue
                    Write-Log "Lecteur $($t1.Text): mappe sur $($t2.Text)" "Green"
                }
            }
            "AddPrinter" {
                $f=New-Object System.Windows.Forms.Form; $f.Text="Imprimante reseau"; $f.Size=New-Object System.Drawing.Size(340,130); $f.StartPosition="CenterScreen"; $f.FormBorderStyle="FixedDialog"; $f.MaximizeBox=$false
                $lIP=New-Object System.Windows.Forms.Label; $lIP.Text="Adresse IP:"; $lIP.Location=New-Object System.Drawing.Point(10,15); $lIP.AutoSize=$true
                $tIP=New-Object System.Windows.Forms.TextBox; $tIP.Text="192.168.1."; $tIP.Location=New-Object System.Drawing.Point(110,12); $tIP.Width=180
                $bOk=New-Object System.Windows.Forms.Button; $bOk.Text="OK"; $bOk.Location=New-Object System.Drawing.Point(110,45); $bOk.DialogResult="OK"
                $f.Controls.AddRange(@($lIP,$tIP,$bOk)); $f.AcceptButton=$bOk
                if($f.ShowDialog() -eq "OK" -and $tIP.Text){
                    $port="IP_$($tIP.Text)"
                    Add-PrinterPort -Name $port -PrinterHostAddress $tIP.Text -ErrorAction SilentlyContinue
                    # Chercher un driver PCL disponible, sinon Generic
                    $driver = Get-PrinterDriver -ErrorAction SilentlyContinue |
                              Where-Object { $_.Name -match "PCL|Universal|Generic" } |
                              Select-Object -First 1
                    $drvName = if ($driver) { $driver.Name } else { "Generic / Text Only" }
                    Add-Printer -Name "Imprimante $($tIP.Text)" -DriverName $drvName -PortName $port -ErrorAction SilentlyContinue
                    Write-Log "Imprimante ajoutee : $($tIP.Text)" "Green"
                }
            }
            "ResetTCP" {
                if(Confirm-CBAction -Title "Reset TCP/IP" -Risk "High" -Message "Reinitialiser la pile TCP/IP et Winsock ? Un redemarrage sera necessaire."){
                    netsh int ip reset | Out-Null; netsh winsock reset | Out-Null
                    Write-Log "TCP/IP reinitialise. Redemarrage necessaire." "Yellow"
                }
            }
        }
        $progressBar.Value++
    }

    # --- SECURITE ---
    foreach ($item in $checkedSec) {
        $task = $secActions[$item].Key; Write-Log "Securite : $item" "Magenta"
        switch ($task) {
            "CheckDefender" {
                $s=Get-MpComputerStatus -ErrorAction SilentlyContinue
                if($s){ $m="Antivirus actif : $($s.AntivirusEnabled)`nProtection temps reel : $($s.RealTimeProtectionEnabled)`nBase mise a jour : $($s.AntivirusSignatureLastUpdated.ToString('dd/MM/yyyy'))"; Write-Log $m "Green"; [System.Windows.Forms.MessageBox]::Show($m,"Windows Defender") }
                else { Write-Log "[!] Impossible de lire l etat Defender." "Red" }
            }
            "QuickScan"       { Start-MpScan -ScanType QuickScan -ErrorAction SilentlyContinue; Write-Log "Scan rapide Defender lance." "Green" }
            "CheckFirewall"   { Get-NetFirewallProfile -ErrorAction SilentlyContinue | Where-Object{!$_.Enabled} | ForEach-Object{ Set-NetFirewallProfile -Name $_.Name -Enabled True -ErrorAction SilentlyContinue; Write-Log "Pare-feu active : $($_.Name)" "Green" } }
            "SecurePS"        { Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine -Force -ErrorAction SilentlyContinue; Write-Log "ExecutionPolicy = RemoteSigned." "Green" }
            "CheckSecUpdates" { Start-Process "ms-settings:windowsupdate"; Write-Log "Windows Update ouvert." "Cyan" }
            "RunAdwCleaner"   {
                # Telecharger AdwCleaner dans %TEMP% et lancer directement
                $adwPath = Join-Path $env:TEMP "adwcleaner.exe"
                $adwUrl  = "https://downloads.malwarebytes.com/file/adwcleaner"
                Write-Log "AdwCleaner : telechargement..." "Cyan"
                try {
                    Invoke-CBSafeDownload -Url $adwUrl -Destination $adwPath -AllowUnsignedAfterConfirm | Out-Null
                    if (Test-Path $adwPath) {
                        Write-Log "AdwCleaner : lancement..." "Cyan"
                        Start-Process $adwPath
                        # Copier sur bureau pour usage futur
                        $desktop = [Environment]::GetFolderPath("Desktop")
                        Copy-Item $adwPath (Join-Path $desktop "AdwCleaner.exe") -Force -ErrorAction SilentlyContinue
                        Write-Log "AdwCleaner lance et copie sur le bureau." "Green"
                    }
                } catch {
                    # Fallback winget
                    $wg = Start-Process "winget" -ArgumentList "install --id Malwarebytes.AdwCleaner --silent --accept-source-agreements" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                    if ($wg) { while (!$wg.HasExited) { Start-Sleep -Milliseconds 300 } }
                    Write-Log "AdwCleaner installe via winget." "Green"
                }
            }
            "DisableSMBv1"    { Disable-WindowsOptionalFeature -Online -FeatureName "SMB1Protocol" -NoRestart -ErrorAction SilentlyContinue | Out-Null; Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force -ErrorAction SilentlyContinue; Write-Log "SMBv1 desactive." "Green" }
        }
        $progressBar.Value++
    }

    Write-Log "Optimisation terminee." "Green"

    # Re-scan badges onglet 2 (leger, seulement les items purges)
    foreach ($b in $checkedBlt) {
        $box = $Global:BloatPanels[$b]
        if ($box) {
            $present = Test-Bloat $bloatMap[$b]
            $script:form.Invoke([Action]{
                $box.BackColor = if($present){[System.Drawing.Color]::FromArgb(60,40,0)}else{"White"}
                foreach ($ctrl in $box.Controls) {
                    if($ctrl -is [System.Windows.Forms.Label] -and $ctrl.Text -eq "[Present]"){ $ctrl.Visible=$present }
                }
            })
        }
    }


    # Sauvegarde uniquement le log de session.
    # Le rapport HTML est maintenant exporte manuellement depuis l accueil.
    Export-CBSessionLog -DisqueBefore $Global:DisqueBefore | Out-Null
    Write-Log "Rapport HTML non genere automatiquement. Utilisez le bouton 'Exporter rapport'." "Gray"

    $restartChoice = [System.Windows.Forms.MessageBox]::Show(
        "Optimisation terminee !`n`nRedemarrer maintenant ?`nATTENTION : sauvegardez vos documents avant de confirmer.",
        "Termine",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question)
    if ($restartChoice -eq "Yes") {
        $confirmRestart = [System.Windows.Forms.MessageBox]::Show(
            "Confirmer le redemarrage immediat ?`n`nLes applications ouvertes seront fermees par Windows.",
            "Redemarrage immediat",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($confirmRestart -eq "Yes") {
            Start-Process "shutdown.exe" -ArgumentList "/r /t 0" -NoNewWindow
        }
    }

    $btnLaunch.Enabled = $true

})

# ============================================================
# LANCEMENT
# ============================================================
# Pre-charger le cache registre AVANT ShowDialog (rapide < 300ms)
$null = Get-UninstallCache

# AppxPackage en job background : non bloquant, disponible apres ~5s
# Le cache sera pret bien avant que l utilisateur clique sur l onglet 2
$script:AppxJob = Start-Job -ScriptBlock {
    Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name
}
$tmrAppx = New-Object System.Windows.Forms.Timer
$tmrAppx.Interval = 400
$tmrAppx.Add_Tick({
    if ($script:AppxJob -and $script:AppxJob.State -ne "Running") {
        $tmrAppx.Stop(); $tmrAppx.Dispose()
        try { $Global:AppxCache = @(Receive-Job $script:AppxJob -ErrorAction SilentlyContinue) } catch {}
        Remove-Job $script:AppxJob -Force -ErrorAction SilentlyContinue
        $script:AppxJob = $null
    }
})
$tmrAppx.Start()

[void]$script:form.ShowDialog()

# Nettoyage propre avant fermeture
Get-Job -ErrorAction SilentlyContinue | Remove-Job -Force -ErrorAction SilentlyContinue
if ($Global:FontCollection) { try { $Global:FontCollection.Dispose() } catch {} }
$script:form.Dispose()

# Fermer le terminal parent a la fermeture de la fenetre
$ppid = (Get-CimInstance Win32_Process -Filter "ProcessId=$PID" -ErrorAction SilentlyContinue).ParentProcessId
if ($ppid) {
    $pname = (Get-Process -Id $ppid -ErrorAction SilentlyContinue).Name
    # Ne fermer QUE un terminal console (cmd/powershell), jamais un IDE
    $safeToClose = @("cmd","powershell","pwsh")
    $neverClose  = @("code","ise","powershell_ise","devenv","idea","notepad++")
    if ($pname -in $safeToClose -and $pname -notin $neverClose) {
        Stop-Process -Id $ppid -Force -ErrorAction SilentlyContinue
    }
}
[System.Environment]::Exit(0)