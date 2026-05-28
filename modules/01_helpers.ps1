function New-RestorePointSafe {
    param([string]$Description = "Avant Charonne Boost")
    # $rSR defini avant le try pour etre accessible dans le catch
    $rSR = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore"
    try {
        Set-ItemProperty -Path $rSR -Name "SystemRestorePointCreationFrequency" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
        # Verifier si SystemRestore est disponible (GPO entreprise peut le bloquer)
        $srEnabled = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" -Name "RPSessionInterval" -ErrorAction SilentlyContinue)
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description $Description -RestorePointType "MODIFY_SETTINGS" -ErrorAction Stop
        Remove-ItemProperty -Path $rSR -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
        Write-Log "Point de restauration cree : $Description" "Green"
        return $true
    } catch {
        Remove-ItemProperty -Path $rSR -Name "SystemRestorePointCreationFrequency" -ErrorAction SilentlyContinue
        Write-Log "[!] Echec point de restauration : $_" "Red"
        return $false
    }
}

# Get-DiskType v3 : detection NVMe correcte via MSFT_PhysicalDisk
# Win32_DiskDrive.MediaType = "Unspecified" sur la plupart des NVMe
# MSFT_PhysicalDisk.BusType : 17=NVMe, 11=SATA, 8=USB, 3=ATA
function Get-DiskType {
    try {
        $pd = Get-CimInstance -Namespace "root/Microsoft/Windows/Storage" `
                  -ClassName MSFT_PhysicalDisk `
                  -Property BusType,MediaType,Model `
                  -OperationTimeoutSec 4 `
                  -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($pd) {
            if ($pd.BusType -eq 17)  { return "SSD NVMe" }   # BusType 17 = NVMe
            if ($pd.MediaType -eq 4) { return "SSD" }         # MediaType 4 = SSD
            if ($pd.MediaType -eq 3) { return "HDD" }         # MediaType 3 = HDD
        }
        # Fallback Win32_DiskDrive
        $d = Get-CimInstance -ClassName Win32_DiskDrive -Property Model,MediaType `
                 -OperationTimeoutSec 3 -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($d -and ($d.Model -match "NVMe|M\.2|PCIe")) { return "SSD NVMe" }
        if ($d -and ($d.Model -match "SSD|Solid State"))  { return "SSD" }
        return "HDD"
    } catch { return "HDD" }
}
$Global:DiskType = Get-DiskType

# --- RAPPORT ---
$Global:RapportEntries = [System.Collections.Generic.List[hashtable]]::new()
$Global:RapportDate    = Get-Date -Format 'dd/MM/yyyy HH:mm'
$Global:DisqueBefore   = 0

function HtmlRows($list) {
    if (!$list) { return "" }
    ($list | ForEach-Object {
        $st = if ($_.Status) { $_.Status.ToLower() } else { "info" }
        "<tr class='$st'><td>$($_.Time)</td><td>$($_.Msg)</td><td>$($_.Status)</td></tr>"
    }) -join "`n"
}

function Write-Log {
    param([string]$Msg, [string]$Col = "Cyan")
    $ts = Get-Date -Format 'HH:mm:ss'
    $st = switch ($Col) {
        "Green"   { "OK" }
        "Red"     { "ERROR" }
        "Yellow"  { "WARNING" }
        "Magenta" { "PURGE" }
        "Gray"    { "INFO" }
        default    { "INFO" }
    }
    Write-Host "[$ts][$st] $Msg" -ForegroundColor $Col
    if ($script:lblStatus) { $script:lblStatus.Text = "[$st] $Msg"; $script:form.Refresh() }
    if ($Global:LiveConsole) {
        try {
            $line = "[$ts][$st] $Msg`r`n"
            if ($Global:LiveConsole -is [System.Windows.Forms.RichTextBox]) {
                $Global:LiveConsole.SelectionStart = $Global:LiveConsole.TextLength
                $Global:LiveConsole.SelectionColor = switch ($st) {
                    "OK"      { [System.Drawing.Color]::FromArgb(95,220,150) }
                    "WARNING" { [System.Drawing.Color]::FromArgb(245,180,80) }
                    "ERROR"   { [System.Drawing.Color]::FromArgb(240,95,95) }
                    "PURGE"   { [System.Drawing.Color]::FromArgb(190,130,240) }
                    default    { [System.Drawing.Color]::FromArgb(180,210,230) }
                }
                $Global:LiveConsole.AppendText($line)
                $Global:LiveConsole.SelectionColor = $Global:LiveConsole.ForeColor
            } else {
                $Global:LiveConsole.AppendText($line)
                $Global:LiveConsole.SelectionStart = $Global:LiveConsole.TextLength
            }
            $Global:LiveConsole.ScrollToCaret()
        } catch {}
    }
    $rapportStatus = switch ($st) { "ERROR" { "ERREUR" } "WARNING" { "INFO" } default { $st } }
    $Global:RapportEntries.Add(@{ Time=$ts; Msg=$Msg; Status=$rapportStatus })
}



# ============================================================
# SECURITE : confirmations fortes + telechargements verifies
# ============================================================
function Confirm-CBAction {
    param(
        [string]$Title = "Confirmation",
        [string]$Message = "Confirmer cette action ?",
        [ValidateSet("Low","Medium","High","Danger")][string]$Risk = "Medium"
    )
    $prefix = switch ($Risk) {
        "Low"    { "Action simple." }
        "Medium" { "Action systeme moderee." }
        "High"   { "Action sensible : modification durable de Windows." }
        "Danger" { "ACTION A RISQUE : peut necessiter un rollback ou une reparation Windows." }
    }
    $full = "$prefix`n`n$Message`n`nContinuer ?"
    return ([System.Windows.Forms.MessageBox]::Show(
        $full,$Title,[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning
    ) -eq [System.Windows.Forms.DialogResult]::Yes)
}

function Get-CBFileSha256 {
    param([Parameter(Mandatory=$true)][string]$Path)
    try { return (Get-FileHash -Algorithm SHA256 -Path $Path -ErrorAction Stop).Hash.ToUpperInvariant() }
    catch { return "" }
}

function Test-CBInstallerSignature {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [switch]$AllowUnsignedAfterConfirm
    )
    if (-not (Test-Path $Path)) { return $false }
    $sig = Get-AuthenticodeSignature -FilePath $Path -ErrorAction SilentlyContinue
    if ($sig -and $sig.Status -eq 'Valid') {
        Write-Log "Signature valide : $(Split-Path $Path -Leaf)" "Green"
        return $true
    }
    $status = if ($sig) { $sig.Status } else { "Aucune signature" }
    Write-Log "[!] Signature non valide pour $(Split-Path $Path -Leaf) : $status" "Yellow"
    if ($AllowUnsignedAfterConfirm) {
        return (Confirm-CBAction -Title "Signature non valide" -Risk "High" -Message "Le fichier telecharge n a pas une signature Authenticode valide.`n`n$Path`n`nSHA256 : $(Get-CBFileSha256 $Path)`n`nNe le lancez que si vous etes certain de la source.")
    }
    return $false
}

function Invoke-CBSafeDownload {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [Parameter(Mandatory=$true)][string]$Destination,
        [string]$ExpectedSha256 = "",
        [switch]$AllowUnsignedAfterConfirm
    )
    $destDir = Split-Path $Destination -Parent
    if ($destDir -and -not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
    if (Test-Path $Destination) { Remove-Item $Destination -Force -ErrorAction SilentlyContinue }
    Write-Log "Telechargement : $Url" "Cyan"
    try {
        Start-BitsTransfer -Source $Url -Destination $Destination -ErrorAction Stop
    } catch {
        Write-Log "BITS indisponible, tentative WebClient..." "Yellow"
        $wc = New-Object System.Net.WebClient
        $wc.Headers.Add("User-Agent","CharonneBoost/12.2")
        $wc.DownloadFile($Url,$Destination)
    }
    if (-not (Test-Path $Destination)) { throw "Telechargement echoue : fichier introuvable." }
    $hash = Get-CBFileSha256 $Destination
    Write-Log "SHA256 : $hash" "Gray"
    if ($ExpectedSha256 -and ($hash -ne $ExpectedSha256.ToUpperInvariant())) {
        Remove-Item $Destination -Force -ErrorAction SilentlyContinue
        throw "Hash SHA256 incorrect pour $Destination"
    }
    if (-not (Test-CBInstallerSignature -Path $Destination -AllowUnsignedAfterConfirm:$AllowUnsignedAfterConfirm)) {
        Remove-Item $Destination -Force -ErrorAction SilentlyContinue
        throw "Signature refusee ou invalide : $Destination"
    }
    return $Destination
}

# ============================================================
# FENETRE
# ============================================================
# ============================================================
# THEME CLAIR -- Charonne Buro
# ============================================================
$Global:BgColor     = [System.Drawing.Color]::FromArgb(245, 247, 250)
$Global:PanelColor  = [System.Drawing.Color]::White
$Global:FgColor     = [System.Drawing.Color]::FromArgb(30,  30,  30)
$Global:AccentColor = [System.Drawing.Color]::FromArgb(26,  42,  74)
$Global:SubFgColor  = [System.Drawing.Color]::FromArgb(100, 100, 100)

# MODE TECH -- fenetre principale complete
# ============================================================
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text            = "Charonne Boost 0.77"
$script:form.Size            = New-Object System.Drawing.Size($L["FormW"], $L["FormH"])
$script:form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
$script:form.StartPosition   = "CenterScreen"
$script:form.BackColor       = $Global:BgColor
$script:form.MaximizeBox     = $false
$Global:PanelColor           = [System.Drawing.Color]::White

# Icone depuis logo2.png
$iconPath = "$scriptDir\png\logo2.png"
if (Test-Path $iconPath) {
    try {
        $bmp = New-Object System.Drawing.Bitmap($iconPath)
        $script:form.Icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
    } catch {}
}

$Global:CustomFont = $null
# Police externe supprimee du pack : Segoe UI devient la police unique.

# -------------------------------------------------------
# HEADER : nom du programme + bouton LANCER
# -------------------------------------------------------
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text = "Charonne Boost 0.77"
if ($Global:CustomFont) {
    $lblTitle.Font = New-Object System.Drawing.Font($Global:FontCollection.Families[0], $L["TitleSize"], [System.Drawing.FontStyle]::Bold)
} else {
    $lblTitle.Font = New-Object System.Drawing.Font("Segoe UI", $L["TitleSize"], [System.Drawing.FontStyle]::Bold)
}
$lblTitle.ForeColor = $Global:AccentColor
$lblTitle.AutoSize  = $true
$lblTitle.Location  = New-Object System.Drawing.Point(10, 14)
$script:form.Controls.Add($lblTitle)

$lblVer = New-Object System.Windows.Forms.Label
$lblVer.Text      = "v12.1"
$lblVer.Font      = New-Object System.Drawing.Font("Segoe UI", $L["VerSize"], [System.Drawing.FontStyle]::Bold)
$lblVer.ForeColor = [System.Drawing.Color]::FromArgb(39, 174, 96)
$lblVer.AutoSize  = $true
$lblVer.Location  = New-Object System.Drawing.Point(10, 50)
$script:form.Controls.Add($lblVer)

$btnLaunch = New-Object System.Windows.Forms.Button
$btnLaunch.Text      = "LANCER L'OPTIMISATION"
$btnLaunch.Size      = New-Object System.Drawing.Size(210, 44)
$btnLaunch.Location  = New-Object System.Drawing.Point(($L["FormW"] - 220), 16)
$btnLaunch.BackColor = $Global:AccentColor
$btnLaunch.ForeColor = "White"
$btnLaunch.FlatStyle = "Flat"
$btnLaunch.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$script:form.Controls.Add($btnLaunch)

$script:form.Add_Shown({
    $midY   = [int]($L["HeaderH"] / 2)
    $titleW = $lblTitle.PreferredWidth
    $verW   = $lblVer.PreferredWidth
    $gapTV  = 10; $gapVB = 40
    $totalW = $titleW + $gapTV + $verW + $gapVB + $btnLaunch.Width
    $startX = [math]::Max(10, [int](($L["FormW"] - $totalW) / 2))
    $lblTitle.Left  = $startX
    $lblVer.Left    = $startX + $titleW + $gapTV
    $btnLaunch.Left = $startX + $titleW + $gapTV + $verW + $gapVB
    $lblTitle.Top   = $midY - [int]($lblTitle.PreferredHeight / 2) - 2
    $lblVer.Top     = $lblTitle.Top + $lblTitle.PreferredHeight - $lblVer.PreferredHeight - 2
    $btnLaunch.Top  = $midY - [int]($btnLaunch.Height / 2)
})

$tabControl = New-Object System.Windows.Forms.TabControl
$tabControl.Location  = New-Object System.Drawing.Point($L["TabX"], $L["TabY"])
$tabControl.Size      = New-Object System.Drawing.Size($L["TabW"], $L["TabH"])
$tabControl.BackColor = $Global:PanelColor
$tabControl.ForeColor = $Global:FgColor
$script:form.Controls.Add($tabControl)

# --- HELPER : creer une grille 2 colonnes ---
function New-Grid {
    param($Parent, $Items, $CheckboxDict, [scriptblock]$BadgeTest = $null,
          [int]$CardH = 73, [int]$RowH = 75)
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(0, 40)
    $panel.Size = New-Object System.Drawing.Size($L["InnerW"], ($L["InnerH"] - 44))
    $panel.AutoScroll = $false
    $Parent.Controls.Add($panel)
    $gridKeys = @($Items.Keys)
    for ([int]$gi = 0; $gi -lt $gridKeys.Count; $gi++) {
        $label = $gridKeys[$gi]
        $entry = $Items[$label]
        [int]$col = $gi % 3
        [int]$gx  = $L["ColMargin"] + $col * $L["ColStep"]
        [int]$gy  = [math]::Floor($gi / 3) * $RowH
        $box = New-Object System.Windows.Forms.Panel
        $box.Size = New-Object System.Drawing.Size($L["CardW"], $CardH)
        $box.Location = New-Object System.Drawing.Point($gx, $gy)
        $box.BorderStyle = "FixedSingle"
        $box.BackColor   = $Global:PanelColor
        $chk = New-Object System.Windows.Forms.CheckBox
        $chk.Text      = $label
        $chk.Location  = New-Object System.Drawing.Point(10, 5)
        $chk.Size      = New-Object System.Drawing.Size(($L["CardW"] - 20), 16)
        $chk.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
        $chk.ForeColor = $Global:FgColor
        $chk.BackColor = $Global:PanelColor
        $CheckboxDict[$label] = $chk
        $desc = if ($entry -is [hashtable] -and $entry.Desc) { $entry.Desc } else { "" }
        $lbl = New-Object System.Windows.Forms.Label
        $lbl.Text      = $desc
        $lbl.Location  = New-Object System.Drawing.Point(10, 22)
        $lbl.Size      = New-Object System.Drawing.Size(($L["CardW"] - 20), ($CardH - 24))
        $lbl.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
        $lbl.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
        $lbl.BackColor = $Global:PanelColor
        $box.Controls.AddRange(@($chk, $lbl))
        if ($BadgeTest) {
            $present = & $BadgeTest $entry
            if ($present) {
                $box.BackColor = [System.Drawing.Color]::FromArgb(255, 245, 230)
                $badge = New-Object System.Windows.Forms.Label
                $badge.Text = "[Present]"; $badge.AutoSize = $true
                $badge.Location = New-Object System.Drawing.Point(($L["CardW"] - 78), 4)
                $badge.Font = New-Object System.Drawing.Font("Segoe UI", 7.5, [System.Drawing.FontStyle]::Bold)
                $badge.ForeColor = [System.Drawing.Color]::FromArgb(200, 80, 0)
                $box.Controls.Add($badge)
            }
        }
        $panel.Controls.Add($box)
    }
    return $panel
}

# ============================================================
# Cache registre desinstallation -- partage entre logiciels et moteur
# ============================================================
$Global:UninstallCache = $null
function Get-UninstallCache {
    if ($Global:UninstallCache) { return $Global:UninstallCache }
    $all = @()
    foreach ($rp in @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
        $all += @(Get-ItemProperty $rp -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName } | Select-Object DisplayName)
    }
    $Global:UninstallCache = $all; return $all
}
function Test-AppInstalled($App) {
    $pattern = [regex]::Escape($App.Name)
    return [bool](Get-UninstallCache | Where-Object { $_.DisplayName -match $pattern } | Select-Object -First 1)
}


# ============================================================
# OUTILS PRO V7.4 : pre-check, simulation, reparation Windows
# ============================================================
function Get-CBCheckState {
    param($Dict, [string[]]$Keys)
    $out = @()
    foreach($k in @($Keys)){
        try {
            if($Dict -and $Dict.Contains($k) -and $Dict[$k].Checked){ $out += $k }
        } catch {
            try { if($Dict -and $Dict[$k] -and $Dict[$k].Checked){ $out += $k } } catch {}
        }
    }
    return @($out)
}

function Get-CBSelectedActions {
    $rows = New-Object System.Collections.Generic.List[object]
    try { foreach($n in (Get-CBCheckState -Dict $Global:SysChk -Keys @($appsV39.Keys)))  { $rows.Add([pscustomobject]@{Categorie='Systeme';Action=$n;Risque='Moyen/Eleve'}) } } catch {}
    try { foreach($n in (Get-CBCheckState -Dict $Global:BloatChk -Keys @($bloatMap.Keys))) { $rows.Add([pscustomobject]@{Categorie='Bloatwares';Action=$n;Risque='Faible/Moyen'}) } } catch {}
    try { foreach($a in @($AppsList)) { if($Global:AppChk -and $Global:AppChk[$a.Name] -and $Global:AppChk[$a.Name].Checked){ $rows.Add([pscustomobject]@{Categorie='Logiciels';Action=$a.Name;Risque='Faible'}) } } } catch {}
    try { foreach($n in (Get-CBCheckState -Dict $Global:NetChk -Keys @($netActions.Keys))) { $rows.Add([pscustomobject]@{Categorie='Reseau';Action=$n;Risque='Moyen/Eleve'}) } } catch {}
    try { foreach($n in (Get-CBCheckState -Dict $Global:SecChk -Keys @($secActions.Keys))) { $rows.Add([pscustomobject]@{Categorie='Securite';Action=$n;Risque='Eleve'}) } } catch {}
    return @($rows)
}

function Show-CBSimulation {
    $actions = @(Get-CBSelectedActions)
    if($actions.Count -eq 0){
        [System.Windows.Forms.MessageBox]::Show("Aucune action cochee.`nCochez des elements puis relancez la simulation.","Simulation",'OK','Information') | Out-Null
        Write-Log "Simulation : aucune action selectionnee." "Yellow"
        return
    }
    $txt = "SIMULATION - rien ne sera modifie`r`n" + ("="*48) + "`r`n`r`n"
    foreach($grp in ($actions | Group-Object Categorie)){
        $txt += "[$($grp.Name)]`r`n"
        foreach($a in $grp.Group){ $txt += " - $($a.Action)  [$($a.Risque)]`r`n" }
        $txt += "`r`n"
    }
    $txt += "Total : $($actions.Count) action(s).`r`n`r`nConseil : creez/verifiez un snapshot avant les actions Systeme/Reseau/Securite."
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Charonne Boost - Simulation"
    $f.Size = New-Object System.Drawing.Size(720,520)
    $f.StartPosition = 'CenterParent'
    $f.BackColor = [System.Drawing.Color]::FromArgb(18,24,34)
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Multiline = $true; $tb.ReadOnly = $true; $tb.ScrollBars = 'Vertical'
    $tb.Dock = 'Fill'; $tb.Text = $txt
    $tb.Font = New-Object System.Drawing.Font('Consolas',10)
    $tb.BackColor = [System.Drawing.Color]::FromArgb(11,15,22)
    $tb.ForeColor = [System.Drawing.Color]::FromArgb(220,235,245)
    $f.Controls.Add($tb)
    Write-Log "Simulation affichee : $($actions.Count) action(s) selectionnee(s)." "Gray"
    $f.ShowDialog($script:form) | Out-Null
}

function Invoke-CBPreCheck {
    $lines = New-Object System.Collections.Generic.List[string]
    $Global:CBPreOK = 0; $Global:CBPreWarn = 0; $Global:CBPreErr = 0
    function Add-PreLine([string]$Level,[string]$Msg){
        if($Level -eq 'OK'){ $Global:CBPreOK++ } elseif($Level -eq 'WARNING'){ $Global:CBPreWarn++ } else { $Global:CBPreErr++ }
        $lines.Add("[$Level] $Msg") | Out-Null
    }
    $principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if($principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){ Add-PreLine OK "Droits administrateur : OK" } else { Add-PreLine ERROR "Droits administrateur absents" }
    try { $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop; Add-PreLine OK "Windows : $($os.Caption) build $($os.BuildNumber)" } catch { Add-PreLine WARNING "Impossible de lire la version Windows" }
    try { $drive = Get-PSDrive C -ErrorAction Stop; $free=[math]::Round($drive.Free/1GB,1); if($free -ge 15){ Add-PreLine OK "Espace libre C: ${free} Go" } else { Add-PreLine WARNING "Espace libre C: ${free} Go seulement" } } catch { Add-PreLine WARNING "Impossible de lire l'espace disque" }
    try { $wu = Get-Service wuauserv -ErrorAction Stop; if($wu.Status -eq 'Running'){ Add-PreLine OK "Windows Update : service actif" } else { Add-PreLine WARNING "Windows Update : $($wu.Status)" } } catch { Add-PreLine WARNING "Service Windows Update introuvable" }
    try { $cs = Get-Service cryptsvc -ErrorAction Stop; if($cs.Status -eq 'Running'){ Add-PreLine OK "Service cryptographique : actif" } else { Add-PreLine WARNING "Service cryptographique : $($cs.Status)" } } catch { Add-PreLine ERROR "Service cryptographique introuvable" }
    try { $av = Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -ErrorAction Stop | Select-Object -First 3; if($av){ Add-PreLine OK "Antivirus detecte : $($av.displayName -join ', ')" } else { Add-PreLine WARNING "Aucun antivirus detecte via SecurityCenter2" } } catch { Add-PreLine WARNING "Impossible de lire l'etat antivirus" }
    try { $bat = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue; if($bat){ if($bat.BatteryStatus -eq 2){ Add-PreLine OK "Portable sur secteur" } else { Add-PreLine WARNING "Portable probablement sur batterie" } } else { Add-PreLine OK "Pas de batterie detectee" } } catch {}
    try { if(Test-Connection 1.1.1.1 -Count 1 -Quiet -ErrorAction SilentlyContinue){ Add-PreLine OK "Connexion Internet : OK" } else { Add-PreLine WARNING "Connexion Internet non confirmee" } } catch { Add-PreLine WARNING "Test Internet impossible" }
    try { $snapDir = Join-Path $scriptDir 'logs'; $last = Get-ChildItem $snapDir -Filter 'snapshot_*.json' -EA SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1; if($last){ Add-PreLine OK "Dernier snapshot : $($last.LastWriteTime.ToString('dd/MM/yyyy HH:mm'))" } else { Add-PreLine WARNING "Aucun snapshot rollback trouve" } } catch {}

    $ok = $Global:CBPreOK; $warn = $Global:CBPreWarn; $err = $Global:CBPreErr
    $txt = "PRE-CHECK CHARONNE BOOST`r`n" + ("="*42) + "`r`n" + ($lines -join "`r`n") + "`r`n`r`nResume : OK=$ok  WARNING=$warn  ERROR=$err"
    Write-Log "Pre-check termine : OK=$ok WARNING=$warn ERROR=$err" $(if($err -gt 0){'Red'}elseif($warn -gt 0){'Yellow'}else{'Green'})
    [System.Windows.Forms.MessageBox]::Show($txt,"Pre-check securite",'OK',$(if($err -gt 0){'Error'}elseif($warn -gt 0){'Warning'}else{'Information'})) | Out-Null
}

function Invoke-CBWindowsRepair {
    if(-not (Confirm-CBAction -Title "Reparer composants Windows" -Risk "High" -Message "Lancer DISM RestoreHealth puis SFC /scannow ?`n`nAucun nettoyage manuel WinSxS ne sera effectue.`nCette operation peut etre longue.")){ return }
    Write-Log "Reparation Windows : lancement DISM /RestoreHealth" "Yellow"
    try {
        Start-Process -FilePath "dism.exe" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
        Write-Log "DISM termine. Lancement SFC /scannow" "Yellow"
        Start-Process -FilePath "sfc.exe" -ArgumentList "/scannow" -Wait -NoNewWindow
        Write-Log "Reparation Windows terminee. Consultez CBS.log si des erreurs persistent." "Green"
    } catch {
        Write-Log "[!] Erreur reparation Windows : $_" "Red"
    }
}
