# ============================================================
# ONGLET 1 : CONFIGURATION SYSTEME
# ============================================================
$tab1 = New-Object System.Windows.Forms.TabPage
$tab1.Text = " Configuration Systeme "; $tab1.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab1)

# ============================================================
# ONGLET 1 : cases ordonnees du plus leger (haut-gauche)
# au plus profond/dangereux (bas-droite)
# Risk = "low"|"medium"|"high"|"disabled"
# ============================================================
$appsV39 = [ordered]@{
    "Creer Point de Restauration"       = @{ Key="RestorePoint";      Risk="low";      Desc="Cree un point de restauration Windows avant toute modification. Recommande en priorite" }
    "Nettoyage Fichiers Temporaires"    = @{ Key="CleanDisk";         Risk="low";      Desc="Nettoie %TEMP%, C:\Windows\Temp et la Corbeille. Recupere de l espace disque" }
    "Afficher Extensions de Fichiers"   = @{ Key="ShowExtensions";    Risk="low";      Desc="Active HideFileExt=0 dans l explorateur. Essentiel pour identifier les fichiers malveillants" }
    "Recherche Locale (sans Bing)"      = @{ Key="LocalSearch";       Risk="low";      Desc="Supprime les suggestions Bing dans la barre de recherche Windows (registre HKCU)" }
    "Desactiver Mise en Veille"         = @{ Key="DisableSleep";      Risk="low";      Desc="powercfg : desactive la mise en veille sur secteur et batterie. Ideal pour les postes fixes" }
    "Telemetrie Microsoft"              = @{ Key="Telemetry";         Risk="medium";   Desc="Passe la telemetrie au niveau minimal, desactive DiagTrack et dmwappushservice" }
    "Copilot (Desactivation totale)"    = @{ Key="Copilot_Deep";      Risk="medium";   Desc="Desactive le bouton Copilot dans la barre des taches et bloque le service via GPO" }
    "Afficher Fichiers Caches"          = @{ Key="ShowHidden";        Risk="medium";   Desc="Active Hidden=1 dans l explorateur. Utile pour la maintenance et le depannage" }
    "Services inutiles (SysMain...)"    = @{ Key="DisableServices";   Risk="medium";   Desc="Adapte automatiquement selon SSD/HDD. WSearch conserve si Outlook est detecte" }
    "Vitesse Systeme (Kernel en RAM)"   = @{ Key="SpeedKernel";       Risk="medium";   Desc="Win32PrioritySeparation=38 : optimise le scheduling pour les applications foreground" }
    "Hibernation (Activer/Desactiver)"  = @{ Key="Hibernation_Toggle";Risk="medium";   Desc="Libere de l espace disque en desactivant hiberfil.sys (peut atteindre plusieurs Go)" }
    "OneDrive (Desinstallation)"        = @{ Key="OneDrive_Deep";     Risk="high";     Desc="Desinstalle OneDrive, supprime les dossiers et empeche la reinstallation automatique" }
    "Activer Bureau a Distance (RDP)"   = @{ Key="EnableRDP";         Risk="high";     Desc="Active fDenyTSConnections=0 et ouvre la regle parefeu RDP (port 3389)" }
    "Desactiver MAJ Automatiques"       = @{ Key="DisableWinUpdate";  Risk="high";     Desc="Pause Windows Update 35 jours via les cles officielles Microsoft. Reversible" }
}

$btnT1 = New-Object System.Windows.Forms.Button
$btnT1.Text = "Tout cocher"; $btnT1.Location = New-Object System.Drawing.Point(10, 8); $btnT1.Size = New-Object System.Drawing.Size(110, 25)
$btnT1.Add_Click({ $t=($btnT1.Text -eq "Tout cocher"); foreach($c in $Global:SysChk.Values){$c.Checked=$t}; $btnT1.Text=if($t){"Tout decocher"}else{"Tout cocher"} })
$tab1.Controls.Add($btnT1)

$btnRapide = New-Object System.Windows.Forms.Button
$btnRapide.Text = "Nettoyage rapide"; $btnRapide.Location = New-Object System.Drawing.Point(125, 8); $btnRapide.Size = New-Object System.Drawing.Size(130, 25)
$btnRapide.Add_Click({
    foreach($c in $Global:SysChk.Values){$c.Checked=$false}
    $Global:SysChk["Nettoyage Fichiers Temporaires"].Checked = $true
    # WinSxS volontairement exclu (risque d instabilite systeme)
})
$tab1.Controls.Add($btnRapide)

$btnNouveauPoste = New-Object System.Windows.Forms.Button
$btnNouveauPoste.Text = "Nouveau poste CB"
$btnNouveauPoste.Location = New-Object System.Drawing.Point(265, 8); $btnNouveauPoste.Size = New-Object System.Drawing.Size(148, 25)
$btnNouveauPoste.BackColor = [System.Drawing.Color]::FromArgb(58,90,140)
$btnNouveauPoste.ForeColor = "White"; $btnNouveauPoste.FlatStyle = "Flat"
$btnNouveauPoste.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$btnNouveauPoste.Add_Click({
    $profilCB = @(
        "Creer Point de Restauration",
        "Nettoyage Fichiers Temporaires",
        "Afficher Extensions de Fichiers",
        "Recherche Locale (sans Bing)",
        "Copilot (Desactivation totale)",
        "Telemetrie Microsoft",
        "Services inutiles (SysMain...)"
        # "Afficher Fichiers Caches"   -- retire : risque confusion client
        # "Desactiver MAJ Automatiques" -- retire : securite prioritaire
    )
    foreach ($k in $Global:SysChk.Keys) { $Global:SysChk[$k].Checked = ($k -in $profilCB) }
    $bloatCB = @("Cortana","Facebook","Instagram","TikTok","Netflix","Disney+","Spotify","Xbox (Game Bar)","Suggestions / Pubs","Feedback Hub / Aide","Microsoft 365 Copilot")
    foreach ($b in $Global:BloatChk.Keys) { $Global:BloatChk[$b].Checked = ($b -in $bloatCB) }
    [System.Windows.Forms.MessageBox]::Show(
        "Profil Nouveau Poste Charonne Buro applique.`n`nOnglet 1 : 7 actions systeme cochees`n  (MAJ et fichiers caches exclus -- securite client)`nOnglet 2 : Bloatwares sociaux/stream/Cortana coches`n`nVerifiez les selections avant de lancer.",
        "Profil CB", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
})
$tab1.Controls.Add($btnNouveauPoste)

# ---- Snapshot / rollback directement dans l'onglet Systeme ----
$cmbSysSnapshot = New-Object System.Windows.Forms.ComboBox
$cmbSysSnapshot.Location = New-Object System.Drawing.Point(425,8)
$cmbSysSnapshot.Size = New-Object System.Drawing.Size(270,25)
$cmbSysSnapshot.Font = New-Object System.Drawing.Font("Segoe UI",8)
$cmbSysSnapshot.DropDownStyle = "DropDownList"
$tab1.Controls.Add($cmbSysSnapshot)

$btnSysRollback = New-Object System.Windows.Forms.Button
$btnSysRollback.Text = "Rollback"
$btnSysRollback.Location = New-Object System.Drawing.Point(705,8)
$btnSysRollback.Size = New-Object System.Drawing.Size(92,25)
$btnSysRollback.FlatStyle = "Flat"
$btnSysRollback.BackColor = [System.Drawing.Color]::FromArgb(180,60,0)
$btnSysRollback.ForeColor = "White"
$btnSysRollback.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
$tab1.Controls.Add($btnSysRollback)

$btnSysSnapRefresh = New-Object System.Windows.Forms.Button
$btnSysSnapRefresh.Text = "Actualiser"
$btnSysSnapRefresh.Location = New-Object System.Drawing.Point(803,8)
$btnSysSnapRefresh.Size = New-Object System.Drawing.Size(86,25)
$btnSysSnapRefresh.FlatStyle = "Flat"
$btnSysSnapRefresh.BackColor = [System.Drawing.Color]::FromArgb(30,45,65)
$btnSysSnapRefresh.ForeColor = [System.Drawing.Color]::White
$btnSysSnapRefresh.FlatAppearance.BorderSize = 0
$tab1.Controls.Add($btnSysSnapRefresh)

$Global:SysSnapshotMap = @{}
function Refresh-SystemSnapshotsUI {
    $cmbSysSnapshot.Items.Clear(); $Global:SysSnapshotMap.Clear()
    $snapDir = Join-Path $scriptDir "logs"
    $snaps = @(Get-ChildItem $snapDir -Filter "snapshot_*.json" -EA SilentlyContinue | Sort-Object LastWriteTime -Descending)
    if (-not $snaps -or $snaps.Count -eq 0) {
        $cmbSysSnapshot.Items.Add("Aucun cliche avant execution") | Out-Null
        $cmbSysSnapshot.SelectedIndex = 0
        return
    }
    foreach ($sn in $snaps) {
        $label = $sn.Name
        try {
            $j = Get-Content $sn.FullName -Raw -EA Stop | ConvertFrom-Json
            if ($j.Timestamp) { $label = "Avant : $($j.Timestamp)" }
        } catch {}
        $Global:SysSnapshotMap[$label] = $sn.FullName
        $cmbSysSnapshot.Items.Add($label) | Out-Null
    }
    if ($cmbSysSnapshot.Items.Count -gt 0) { $cmbSysSnapshot.SelectedIndex = 0 }
}

$cmbSysSnapshot.Add_SelectedIndexChanged({
    if (-not $cmbSysSnapshot.SelectedItem) { return }
    $sel = [string]$cmbSysSnapshot.SelectedItem
    if (-not $Global:SysSnapshotMap.ContainsKey($sel)) { return }
    try {
        $j = Get-Content $Global:SysSnapshotMap[$sel] -Raw | ConvertFrom-Json
        $count = @($j.Entries.PSObject.Properties).Count
        $btnSysRollback.Text = "Rollback ($count)"
    } catch {}
})
$btnSysSnapRefresh.Add_Click({ Refresh-SystemSnapshotsUI })
$btnSysRollback.Add_Click({
    if (-not $cmbSysSnapshot.SelectedItem) { Refresh-SystemSnapshotsUI }
    $sel = [string]$cmbSysSnapshot.SelectedItem
    if (-not $Global:SysSnapshotMap.ContainsKey($sel)) {
        [System.Windows.Forms.MessageBox]::Show("Aucun cliche disponible.","Rollback",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $chosen = $Global:SysSnapshotMap[$sel]
    $conf = [System.Windows.Forms.MessageBox]::Show(
        "Restaurer l'etat systeme AVANT cette execution ?`n`n$sel`n`nCela restaure les cles registre/services capturees et redemarre l'Explorateur.",
        "Rollback Systeme",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($conf -eq "Yes") {
        $ok = Restore-SystemSnapshot -SnapFile $chosen
        if ($ok) {
            [System.Windows.Forms.MessageBox]::Show("Rollback effectue.","Rollback Systeme",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        }
    }
})
$tab1.Add_VisibleChanged({ if ($tab1.Visible) { Refresh-SystemSnapshotsUI } })
Refresh-SystemSnapshotsUI

# ============================================================
# DETECTION ETAT ACTUEL -- multi-sources, robuste
# Retourne : "actif" | "inactif" | "inconnu"
# ============================================================
function Get-ActionState([string]$Key) {
    try {
        switch ($Key) {

            "ShowExtensions" {
                $v = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                      -Name HideFileExt -EA SilentlyContinue).HideFileExt
                if ($null -eq $v) { return "inconnu" }
                if ($v -eq 0) { return "actif" } else { return "inactif" }
            }

            "ShowHidden" {
                $v = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                      -Name Hidden -EA SilentlyContinue).Hidden
                if ($null -eq $v) { return "inconnu" }
                if ($v -ge 1) { return "actif" } else { return "inactif" }
            }

            "LocalSearch" {
                # Methode 1 : GPO DisableSearchBoxSuggestions
                $v1 = (Get-ItemProperty "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" `
                       -Name DisableSearchBoxSuggestions -EA SilentlyContinue).DisableSearchBoxSuggestions
                if ($v1 -eq 1) { return "actif" }
                # Methode 2 : BingSearchEnabled = 0
                $v2 = (Get-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
                       -Name BingSearchEnabled -EA SilentlyContinue).BingSearchEnabled
                if ($null -ne $v2) { if ($v2 -eq 0) { return "actif" } else { return "inactif" } }
                return "inactif"
            }

            "Telemetry" {
                # Source 1 : cle Policies (GPO/regedit)
                $v1 = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
                       -Name AllowTelemetry -EA SilentlyContinue).AllowTelemetry
                if ($null -ne $v1) { if ($v1 -le 1) { return "actif" } else { return "inactif" } }
                # Source 2 : cle standard
                $v2 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
                       -Name AllowTelemetry -EA SilentlyContinue).AllowTelemetry
                if ($null -ne $v2) { if ($v2 -le 1) { return "actif" } else { return "inactif" } }
                # Source 3 : service DiagTrack desactive
                $svc = Get-Service "DiagTrack" -EA SilentlyContinue
                if ($svc -and $svc.StartType -eq "Disabled") { return "actif" }
                return "inactif"
            }

            "Copilot_Deep" {
                # Source 1 : GPO HKLM
                $v1 = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
                       -Name TurnOffWindowsCopilot -EA SilentlyContinue).TurnOffWindowsCopilot
                if ($v1 -eq 1) { return "actif" }
                # Source 2 : GPO HKCU
                $v2 = (Get-ItemProperty "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" `
                       -Name TurnOffWindowsCopilot -EA SilentlyContinue).TurnOffWindowsCopilot
                if ($v2 -eq 1) { return "actif" }
                # Source 3 : bouton Copilot masque dans la barre des taches
                $v3 = (Get-ItemProperty "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" `
                       -Name ShowCopilotButton -EA SilentlyContinue).ShowCopilotButton
                if ($v3 -eq 0) { return "actif" }
                return "inactif"
            }

            "DisableSleep" {
                # Lire directement le registre du schema actif
                # HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes -> ActivePowerScheme
                $schemeGuid = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes" `
                               -Name ActivePowerScheme -EA SilentlyContinue).ActivePowerScheme
                if ($schemeGuid) {
                    $acPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\User\PowerSchemes\$schemeGuid\238c9fa8-0aad-41ed-83f4-97be242c8f20\29f6c1db-86da-48c5-9fdb-f2b67b1a44da"
                    $acVal = (Get-ItemProperty $acPath -Name ACSettingIndex -EA SilentlyContinue).ACSettingIndex
                    if ($null -ne $acVal) { if ($acVal -eq 0) { return "actif" } else { return "inactif" } }
                }
                # Fallback powercfg : verifier AC et DC
                try {
                    $r = & powercfg /query 2>$null | Out-String
                    if ($r -match "0x00000000") { return "actif" }
                } catch {}
                return "inactif"
            }

            "Hibernation_Toggle" {
                # Methode fiable : powercfg /availablesleepstates
                $r = & powercfg /availablesleepstates 2>$null | Out-String
                if ($r -match "Hibernation has not been enabled") { return "actif" }
                # Fallback : registre HibernateEnabled
                $v = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Power" `
                      -Name HibernateEnabled -EA SilentlyContinue).HibernateEnabled
                if ($null -ne $v) { if ($v -eq 0) { return "actif" } else { return "inactif" } }
                return "inconnu"
            }

            "OneDrive_Deep" {
                $paths = @(
                    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDrive.exe",
                    "$env:ProgramFiles\Microsoft OneDrive\OneDrive.exe",
                    "${env:ProgramFiles(x86)}\Microsoft OneDrive\OneDrive.exe"
                )
                $found = $paths | Where-Object { Test-Path $_ }
                # Aussi verifier registre desinstallation
                $reg = Get-UninstallCache | Where-Object { $_.DisplayName -match "OneDrive" } | Select-Object -First 1
                if (-not $found -and -not $reg) { return "actif" } else { return "inactif" }
            }

            "EnableRDP" {
                $v = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
                      -Name fDenyTSConnections -EA SilentlyContinue).fDenyTSConnections
                if ($null -eq $v) { return "inconnu" }
                if ($v -eq 0) { return "actif" } else { return "inactif" }
            }

            "DisableWinUpdate" {
                # Source 1 : pause officielle
                $v1 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
                       -Name PauseFeatureUpdatesStartTime -EA SilentlyContinue).PauseFeatureUpdatesStartTime
                if ($v1) { return "actif" }
                $v2 = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings" `
                       -Name PauseQualityUpdatesStartTime -EA SilentlyContinue).PauseQualityUpdatesStartTime
                if ($v2) { return "actif" }
                # Source 2 : GPO NoAutoUpdate
                $v3 = (Get-ItemProperty "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" `
                       -Name NoAutoUpdate -EA SilentlyContinue).NoAutoUpdate
                if ($v3 -eq 1) { return "actif" }
                return "inactif"
            }

            "SpeedKernel" {
                $v = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" `
                      -Name Win32PrioritySeparation -EA SilentlyContinue).Win32PrioritySeparation
                if ($null -eq $v) { return "inconnu" }
                if ($v -eq 38) { return "actif" } else { return "inactif" }
            }

            "DisableServices" {
                # Lire directement le registre (plus fiable que Get-Service.StartType)
                $smReg = (Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Services\SysMain" `
                          -Name Start -EA SilentlyContinue).Start
                # Start: 2=Auto, 3=Manual, 4=Disabled
                if ($null -ne $smReg) { if ($smReg -eq 4) { return "actif" } else { return "inactif" } }
                $svc = Get-Service "SysMain" -EA SilentlyContinue
                if ($svc) { if ($svc.StartType -eq "Disabled") { return "actif" } else { return "inactif" } }
                return "inconnu"
            }

            "RestorePoint" { return "inconnu" }
            "CleanDisk"    { return "inconnu" }
            default        { return "inconnu" }
        }
    } catch { return "inconnu" }
}

# Onglet 1 : cartes compactes horizontales 2 colonnes
$Global:SysChk = [ordered]@{}
$panelSys = New-Object System.Windows.Forms.Panel
$panelSys.Location  = New-Object System.Drawing.Point(0, 40)
$panelSys.Size      = New-Object System.Drawing.Size($L["InnerW"], ($L["InnerH"] - 44))
$panelSys.AutoScroll= $true
$tab1.Controls.Add($panelSys)
$cW2 = [int](($L["InnerW"] - 24) / 2); $cGap2 = 8; $cH = 58; $cRowH = $cH + 4
$cMarL = [int](($L["InnerW"] - 2*$cW2 - $cGap2) / 2)
$riskAccent = @{ "low"=[System.Drawing.Color]::FromArgb(39,174,96); "medium"=[System.Drawing.Color]::FromArgb(230,126,34); "high"=[System.Drawing.Color]::FromArgb(192,57,43) }
$riskBg = @{ "low"=[System.Drawing.Color]::White; "medium"=[System.Drawing.Color]::FromArgb(255,252,245); "high"=[System.Drawing.Color]::FromArgb(255,248,248) }

# Couleurs badge etat
$stateColors = @{
    "actif"   = @{ Fg=[System.Drawing.Color]::FromArgb(0,120,50);   Bg=[System.Drawing.Color]::FromArgb(220,245,230); Text="Actif" }
    "inactif" = @{ Fg=[System.Drawing.Color]::FromArgb(150,60,0);   Bg=[System.Drawing.Color]::FromArgb(255,243,225); Text="Inactif" }
    "inconnu" = @{ Fg=[System.Drawing.Color]::FromArgb(160,160,160);Bg=[System.Drawing.Color]::FromArgb(248,248,248); Text="N/A" }
}

$gridKeys1 = @($appsV39.Keys)
$renderIdx = 0
for ([int]$gi = 0; $gi -lt $gridKeys1.Count; $gi++) {
    $label = $gridKeys1[$gi]; $entry = $appsV39[$label]
    $risk  = if ($entry.Risk) { $entry.Risk } else { "low" }
    if ($risk -eq "disabled") { continue }
    [int]$col2 = $renderIdx % 2; [int]$row2 = [math]::Floor($renderIdx / 2)
    [int]$gx   = $cMarL + $col2 * ($cW2 + $cGap2); [int]$gy = $row2 * $cRowH
    $bgCard = $riskBg[$risk]; $accent = $riskAccent[$risk]

    # Detection etat actuel
    $state    = Get-ActionState $entry.Key
    $stColor  = $stateColors[$state]

    $box = New-Object System.Windows.Forms.Panel
    $box.Size = New-Object System.Drawing.Size($cW2, $cH); $box.Location = New-Object System.Drawing.Point($gx, $gy)
    $box.BackColor = $bgCard; $box.Cursor = [System.Windows.Forms.Cursors]::Hand
    $bar = New-Object System.Windows.Forms.Panel
    $bar.Size = New-Object System.Drawing.Size(4, $cH); $bar.Location = New-Object System.Drawing.Point(0,0); $bar.BackColor = $accent
    $chk = New-Object System.Windows.Forms.CheckBox
    $chk.Text = ""; $chk.Location = New-Object System.Drawing.Point(10, [int](($cH - 18) / 2)); $chk.Size = New-Object System.Drawing.Size(18,18); $chk.BackColor = $bgCard
    $Global:SysChk[$label] = $chk

    # Titre action
    $lblT2 = New-Object System.Windows.Forms.Label
    $lblT2.Text = $label; $lblT2.Location = New-Object System.Drawing.Point(34, 6)
    $lblT2.Size = New-Object System.Drawing.Size([int]($cW2*0.55), 14)
    $lblT2.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
    $lblT2.ForeColor = switch($risk){"high"{[System.Drawing.Color]::FromArgb(192,57,43)}"medium"{[System.Drawing.Color]::FromArgb(160,80,0)}default{$Global:FgColor}}
    $lblT2.BackColor = $bgCard

    # Description
    $lblD2 = New-Object System.Windows.Forms.Label
    $lblD2.Text = $entry.Desc; $lblD2.Location = New-Object System.Drawing.Point(34, 24)
    $lblD2.Size = New-Object System.Drawing.Size(([int]($cW2 * 0.60)), 26)
    $lblD2.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Italic)
    $lblD2.ForeColor = [System.Drawing.Color]::FromArgb(80,80,80); $lblD2.BackColor = $bgCard

    # Badge etat : petit rectangle en haut a droite
    $lblState = New-Object System.Windows.Forms.Label
    $lblState.Text      = $stColor.Text
    $lblState.AutoSize  = $false
    $lblState.Size      = New-Object System.Drawing.Size(56, 16)
    $lblState.Location  = New-Object System.Drawing.Point(($cW2 - 62), [int](($cH - 16) / 2))
    $lblState.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Bold)
    $lblState.ForeColor = $stColor.Fg
    $lblState.BackColor = $stColor.Bg
    $lblState.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $lblState.BorderStyle = "FixedSingle"

    foreach ($ctrl in @($box,$lblT2,$lblD2)) {
        $ctrl.Add_Click({ $chk.Checked = -not $chk.Checked }.GetNewClosure())
    }
    $box.Controls.AddRange(@($bar,$chk,$lblT2,$lblD2,$lblState)); $panelSys.Controls.Add($box)
    $renderIdx++
}

# ============================================================
