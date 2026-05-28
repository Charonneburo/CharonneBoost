# ============================================================
# V7 OPTION C -- RELOOK ATELIER / CONSOLE TECHNICIEN
# Habillage visuel + navigation sidebar sans casser les modules existants.
# ============================================================

# Palette sombre Charonne Buro
$Global:V7Dark       = [System.Drawing.Color]::FromArgb(18,24,34)
$Global:V7Sidebar    = [System.Drawing.Color]::FromArgb(13,18,27)
$Global:V7Card       = [System.Drawing.Color]::FromArgb(29,38,52)
$Global:V7Card2      = [System.Drawing.Color]::FromArgb(34,45,61)
$Global:V7Accent     = [System.Drawing.Color]::FromArgb(48,124,210)
$Global:V7Good       = [System.Drawing.Color]::FromArgb(54,190,125)
$Global:V7Warn       = [System.Drawing.Color]::FromArgb(230,155,62)
$Global:V7Danger     = [System.Drawing.Color]::FromArgb(210,78,78)
$Global:V7Text       = [System.Drawing.Color]::FromArgb(235,240,248)
$Global:V7Muted      = [System.Drawing.Color]::FromArgb(160,170,185)

# Fenetre responsive : optimisee pour 1366x768 jusqu'a 1920x1080.
# On garde une marge pour la barre des taches et les bordures Windows.
$script:form.Text = "Charonne Boost 0.77 - Atelier Charonne Buro"
$screen = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
$formW = [Math]::Min(1600, [Math]::Max(1100, $screen.Width - 30))
$formH = [Math]::Min(900,  [Math]::Max(650,  $screen.Height - 40))
$script:form.Size = New-Object System.Drawing.Size($formW,$formH)
$script:form.MinimumSize = New-Object System.Drawing.Size(1100,650)
$script:form.StartPosition = "CenterScreen"
$script:form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::Sizable
$script:form.BackColor = $Global:V7Dark
$Global:V7Compact = ($script:form.Width -lt 1450 -or $script:form.Height -lt 780)
$Global:V7SidebarWidth = $(if($Global:V7Compact){160}else{178})
$Global:V7HeaderH = $(if($Global:V7Compact){44}else{50})
$Global:V7ConsoleH = $(if($Global:V7Compact){68}else{84})
$Global:V7ContentX = $Global:V7SidebarWidth + 8
$Global:V7ContentW = $script:form.ClientSize.Width - $Global:V7ContentX - 14
$Global:V7StatusY = $script:form.ClientSize.Height - 28
$Global:V7ProgressY = $Global:V7StatusY - 18
$Global:V7ConsoleY = $Global:V7ProgressY - $Global:V7ConsoleH - 10
$Global:V7TabH = $Global:V7ConsoleY - $Global:V7HeaderH - 8

# Masquer l'ancien header clair sans supprimer les objets utilises par le moteur
foreach($ctrl in @($lblTitle,$lblVer)) { if($ctrl){ $ctrl.Visible = $false } }
if($btnLaunch){
    $btnLaunch.Text = "EXECUTER"
    $btnLaunch.Size = New-Object System.Drawing.Size(118,30)
    $btnLaunch.Location = New-Object System.Drawing.Point(($script:form.ClientSize.Width - 134),10)
    $btnLaunch.BackColor = $Global:V7Good
    $btnLaunch.ForeColor = [System.Drawing.Color]::White
    $btnLaunch.FlatStyle = 'Flat'
    $btnLaunch.FlatAppearance.BorderSize = 0
}

# Header V7
$hdr = New-Object System.Windows.Forms.Panel
$hdr.Location = New-Object System.Drawing.Point($Global:V7SidebarWidth,0)
$hdr.Size = New-Object System.Drawing.Size(($script:form.ClientSize.Width - $Global:V7SidebarWidth),$Global:V7HeaderH)
$hdr.BackColor = $Global:V7Dark
$script:form.Controls.Add($hdr)

$hdrTitle = New-Object System.Windows.Forms.Label
$hdrTitle.Text = "Charonne Boost 0.77"
$hdrTitle.Location = New-Object System.Drawing.Point(14,6)
$hdrTitle.Size = New-Object System.Drawing.Size(320,22)
$hdrTitle.Font = New-Object System.Drawing.Font("Segoe UI",13,[System.Drawing.FontStyle]::Bold)
$hdrTitle.ForeColor = $Global:V7Text
$hdr.Controls.Add($hdrTitle)

$hdrSub = New-Object System.Windows.Forms.Label
$hdrSub.Text = "Console atelier - maintenance Windows, diagnostic, rollback et raccourcis"
$hdrSub.Location = New-Object System.Drawing.Point(16,28)
$hdrSub.Size = New-Object System.Drawing.Size(580,16)
$hdrSub.Font = New-Object System.Drawing.Font("Segoe UI",8)
$hdrSub.ForeColor = $Global:V7Muted
$hdr.Controls.Add($hdrSub)

# Sidebar
$side = New-Object System.Windows.Forms.Panel
$side.Location = New-Object System.Drawing.Point(0,0)
$side.Size = New-Object System.Drawing.Size($Global:V7SidebarWidth,$script:form.ClientSize.Height)
$side.BackColor = $Global:V7Sidebar
$script:form.Controls.Add($side)
$side.BringToFront()

# Logo/texte Charonne Buro supprime de la sidebar : navigation directe, plus propre.

# Ajouter un dashboard en premier onglet
$dashboard = New-Object System.Windows.Forms.TabPage
$dashboard.Text = " Accueil "
$dashboard.BackColor = [System.Drawing.Color]::FromArgb(24,31,43)
$tabControl.TabPages.Insert(0,$dashboard)

# Repositionner le TabControl dans la zone centrale
$tabControl.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7HeaderH)
$tabControl.Size = New-Object System.Drawing.Size($Global:V7ContentW,$Global:V7TabH)
$tabControl.Appearance = [System.Windows.Forms.TabAppearance]::FlatButtons
$tabControl.SizeMode = [System.Windows.Forms.TabSizeMode]::Fixed
$tabControl.ItemSize = New-Object System.Drawing.Size(0,1)
$tabControl.BackColor = $Global:V7Dark
$tabControl.ForeColor = $Global:V7Text
$tabControl.SelectedIndex = 0
foreach($tp in $tabControl.TabPages){ $tp.AutoScroll = $true }

# Console live en bas
$Global:LiveConsole = New-Object System.Windows.Forms.RichTextBox
$Global:LiveConsole.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7ConsoleY)
$Global:LiveConsole.Size = New-Object System.Drawing.Size($Global:V7ContentW,$Global:V7ConsoleH)
$Global:LiveConsole.Multiline = $true
$Global:LiveConsole.ReadOnly = $true
$Global:LiveConsole.ScrollBars = 'Vertical'
$Global:LiveConsole.BackColor = [System.Drawing.Color]::FromArgb(11,15,22)
$Global:LiveConsole.ForeColor = [System.Drawing.Color]::FromArgb(190,230,210)
$Global:LiveConsole.Font = New-Object System.Drawing.Font("Consolas",9)
$Global:LiveConsole.BorderStyle = 'FixedSingle'
$Global:LiveConsole.DetectUrls = $false
$script:form.Controls.Add($Global:LiveConsole)

# Repositionner ancienne barre statut/progression
if($progressBar){
    $progressBar.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7ProgressY)
    $progressBar.Size = New-Object System.Drawing.Size($Global:V7ContentW,14)
    $progressBar.ForeColor = $Global:V7Good
}
if($script:lblStatus){
    $script:lblStatus.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7StatusY)
    $script:lblStatus.Size = New-Object System.Drawing.Size($Global:V7ContentW,18)
    $script:lblStatus.ForeColor = $Global:V7Muted
    $script:lblStatus.BackColor = $Global:V7Dark
}

# Navigation sidebar
$Global:V7NavButtons = @()
function New-V7NavButton {
    param([string]$Text, [int]$Index, [int]$Y)
    $b = New-Object System.Windows.Forms.Button
    $b.Text = "  $Text"
    $b.Tag = $Index
    $b.Location = New-Object System.Drawing.Point(8,$Y)
    $b.Size = New-Object System.Drawing.Size(($Global:V7SidebarWidth-16),30)
    $b.FlatStyle = 'Flat'
    $b.FlatAppearance.BorderSize = 0
    $b.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $b.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $b.BackColor = $Global:V7Sidebar
    $b.ForeColor = $Global:V7Muted
    $b.Add_Click({
        $tabControl.SelectedIndex = [int]$this.Tag
        foreach($nb in $Global:V7NavButtons){
            $nb.BackColor = $Global:V7Sidebar
            $nb.ForeColor = $Global:V7Muted
        }
        $this.BackColor = $Global:V7Accent
        $this.ForeColor = [System.Drawing.Color]::White
    })
    $side.Controls.Add($b)
    $Global:V7NavButtons += $b
    return $b
}

# Navigation dynamique : on reprend STRICTEMENT le texte reel des onglets existants.
# Pas de tableau dur code qui decale tout. Sinon on clique "Diagnostic" et on finit
# dans "Desinstaller", ce qui est une metaphore assez cruelle de Windows.
function Get-V7NavLabel {
    param([string]$TabText)
    $clean = ($TabText -replace "\s+"," ").Trim()
    switch -Regex ($clean) {
        "^Accueil$"                  { return "Accueil" }
        "Configuration Systeme"      { return "Optimisation" }
        "Purge Bloatwares"           { return "Bloatwares" }
        "Logiciels"                  { return "Logiciels" }
        "Reseau / Securite"          { return "Reseau / Securite" }
        "Navigateurs"                { return "Navigateurs" }
        "Demarrage"                  { return "Demarrage" }
        "Diagnostic"                 { return "Diagnostic" }
        "Desinstaller"               { return "Desinstaller" }
        "Historique"                 { return "Historique" }
        "Raccourcis Windows"         { return "Raccourcis Windows" }
        default                       { return $clean }
    }
}

$yNav = 12
for($i=0; $i -lt $tabControl.TabPages.Count; $i++){
    $t = Get-V7NavLabel -TabText $tabControl.TabPages[$i].Text
    New-V7NavButton -Text $t -Index $i -Y $yNav | Out-Null
    $yNav += $(if($Global:V7Compact){31}else{34})
}
if($Global:V7NavButtons.Count -gt 0){
    $Global:V7NavButtons[0].BackColor = $Global:V7Accent
    $Global:V7NavButtons[0].ForeColor = [System.Drawing.Color]::White
}

# Dashboard helpers
function New-V7Card {
    param($Parent,[string]$Title,[string]$Value,[int]$X,[int]$Y,[int]$W=230,[int]$H=82,[System.Drawing.Color]$Accent)
    $p = New-Object System.Windows.Forms.Panel
    $p.Location = New-Object System.Drawing.Point($X,$Y)
    $p.Size = New-Object System.Drawing.Size($W,$H)
    $p.BackColor = $Global:V7Card
    $p.BorderStyle = 'FixedSingle'
    $bar = New-Object System.Windows.Forms.Panel
    $bar.Location = New-Object System.Drawing.Point(0,0)
    $bar.Size = New-Object System.Drawing.Size(5,$H)
    $bar.BackColor = $Accent
    $lt = New-Object System.Windows.Forms.Label
    $lt.Text = $Title
    $lt.Location = New-Object System.Drawing.Point(14,10)
    $lt.Size = New-Object System.Drawing.Size(($W-24),20)
    $lt.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lt.ForeColor = $Global:V7Muted
    $lv = New-Object System.Windows.Forms.Label
    $lv.Text = $Value
    $lv.Location = New-Object System.Drawing.Point(14,34)
    $lv.Size = New-Object System.Drawing.Size(($W-24),34)
    $lv.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lv.ForeColor = $Global:V7Text
    $p.Controls.AddRange(@($bar,$lt,$lv))
    $Parent.Controls.Add($p)
    return $lv
}

# Dashboard contenu
$dashPanel = New-Object System.Windows.Forms.Panel
$dashPanel.Location = New-Object System.Drawing.Point(0,0)
$dashPanel.Size = New-Object System.Drawing.Size(($Global:V7ContentW-22),[Math]::Max(506,($Global:V7TabH-24)))
$dashPanel.BackColor = [System.Drawing.Color]::FromArgb(24,31,43)
$dashboard.AutoScroll = $true
$dashboard.Controls.Add($dashPanel)

$pc = $env:COMPUTERNAME
$win = "Windows"
try { $win = (Get-CimInstance Win32_OperatingSystem -EA SilentlyContinue).Caption } catch {}
$cpu = "CPU"
try { $cpu = (Get-CimInstance Win32_Processor -EA SilentlyContinue | Select-Object -First 1).Name } catch {}
$ram = "RAM"
try { $ram = "{0:N1} Go" -f ((Get-CimInstance Win32_ComputerSystem -EA SilentlyContinue).TotalPhysicalMemory/1GB) } catch {}
$disk = "Disque"
try { $c = Get-PSDrive C -EA SilentlyContinue; $disk = "Libre : {0:N1} Go" -f ($c.Free/1GB) } catch {}
$av = "Non detecte"
try { $av = (Get-CimInstance -Namespace root/SecurityCenter2 -ClassName AntiVirusProduct -EA SilentlyContinue | Select-Object -First 1).displayName } catch {}
if([string]::IsNullOrWhiteSpace($av)){ $av="Defender ou AV non visible" }

New-V7Card $dashPanel "POSTE" $pc 18 18 225 82 $Global:V7Accent | Out-Null
New-V7Card $dashPanel "WINDOWS" $win 258 18 330 82 $Global:V7Good | Out-Null
New-V7Card $dashPanel "RAM" $ram 603 18 170 82 $Global:V7Warn | Out-Null
New-V7Card $dashPanel "DISQUE C:" $disk 788 18 170 82 $Global:V7Good | Out-Null
New-V7Card $dashPanel "CPU" $cpu 18 114 455 82 $Global:V7Accent | Out-Null
New-V7Card $dashPanel "ANTIVIRUS" $av 488 114 470 82 $Global:V7Good | Out-Null

# Rollback dashboard
$roll = New-Object System.Windows.Forms.Panel
$roll.Location = New-Object System.Drawing.Point(18,214)
$roll.Size = New-Object System.Drawing.Size(([Math]::Min(940,$dashPanel.Width-36)),132)
$roll.BackColor = $Global:V7Card
$roll.BorderStyle = 'FixedSingle'
$dashPanel.Controls.Add($roll)

$rTitle = New-Object System.Windows.Forms.Label
$rTitle.Text = "Rollback / derniers cliches avant execution"
$rTitle.Location = New-Object System.Drawing.Point(16,12)
$rTitle.Size = New-Object System.Drawing.Size(420,24)
$rTitle.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$rTitle.ForeColor = $Global:V7Text
$roll.Controls.Add($rTitle)

$Global:V7SnapshotCombo = New-Object System.Windows.Forms.ComboBox
$Global:V7SnapshotCombo.Location = New-Object System.Drawing.Point(18,48)
$Global:V7SnapshotCombo.Size = New-Object System.Drawing.Size(([Math]::Max(360,$roll.Width-350)),28)
$Global:V7SnapshotCombo.DropDownStyle = 'DropDownList'
$roll.Controls.Add($Global:V7SnapshotCombo)

function Update-V7Snapshots {
    $Global:V7SnapshotCombo.Items.Clear()
    $snapDir = Join-Path $scriptDir "logs"
    if(Test-Path $snapDir){
        $files = Get-ChildItem $snapDir -Filter "snapshot_*.json" -EA SilentlyContinue | Sort-Object LastWriteTime -Descending
        foreach($f in $files){ [void]$Global:V7SnapshotCombo.Items.Add($f.FullName) }
    }
    if($Global:V7SnapshotCombo.Items.Count -gt 0){ $Global:V7SnapshotCombo.SelectedIndex = 0 }
}

$bRefreshSnap = New-Object System.Windows.Forms.Button
$bRefreshSnap.Text = "Actualiser"
$bRefreshSnap.Location = New-Object System.Drawing.Point(($Global:V7SnapshotCombo.Right + 12),46)
$bRefreshSnap.Size = New-Object System.Drawing.Size(100,30)
$bRefreshSnap.BackColor = $Global:V7Accent
$bRefreshSnap.ForeColor = [System.Drawing.Color]::White
$bRefreshSnap.FlatStyle = 'Flat'; $bRefreshSnap.FlatAppearance.BorderSize = 0
$bRefreshSnap.Add_Click({ Update-V7Snapshots })
$roll.Controls.Add($bRefreshSnap)

$bRollback = New-Object System.Windows.Forms.Button
$bRollback.Text = "Restaurer"
$bRollback.Location = New-Object System.Drawing.Point(($bRefreshSnap.Right + 10),46)
$bRollback.Size = New-Object System.Drawing.Size(100,30)
$bRollback.BackColor = $Global:V7Warn
$bRollback.ForeColor = [System.Drawing.Color]::White
$bRollback.FlatStyle = 'Flat'; $bRollback.FlatAppearance.BorderSize = 0
$bRollback.Add_Click({
    if($Global:V7SnapshotCombo.SelectedItem){
        if([System.Windows.Forms.MessageBox]::Show("Restaurer ce snapshot ?`n`n$($Global:V7SnapshotCombo.SelectedItem)","Rollback",'YesNo','Warning') -eq 'Yes'){
            Restore-SystemSnapshot -SnapFile ([string]$Global:V7SnapshotCombo.SelectedItem) | Out-Null
        }
    }
})
$roll.Controls.Add($bRollback)

$bOpenLogs = New-Object System.Windows.Forms.Button
$bOpenLogs.Text = "Logs"
$bOpenLogs.Location = New-Object System.Drawing.Point(($bRollback.Right + 10),46)
$bOpenLogs.Size = New-Object System.Drawing.Size(72,30)
$bOpenLogs.BackColor = $Global:V7Card2
$bOpenLogs.ForeColor = [System.Drawing.Color]::White
$bOpenLogs.FlatStyle = 'Flat'; $bOpenLogs.FlatAppearance.BorderSize = 0
$bOpenLogs.Add_Click({ Start-Process explorer.exe -ArgumentList (Join-Path $scriptDir "logs") })
$roll.Controls.Add($bOpenLogs)

$rHint = New-Object System.Windows.Forms.Label
$rHint.Text = "Les snapshots sont crees automatiquement avant les actions systeme. Le rollback restaure surtout les reglages registre/services, pas les fichiers supprimes ni les Appx. Magie limitee, pas miracle Windows."
$rHint.Location = New-Object System.Drawing.Point(18,88)
$rHint.Size = New-Object System.Drawing.Size(($roll.Width-36),34)
$rHint.Font = New-Object System.Drawing.Font("Segoe UI",8.5)
$rHint.ForeColor = $Global:V7Muted
$roll.Controls.Add($rHint)

# Actions rapides dashboard
$quick = New-Object System.Windows.Forms.Panel
$quick.Location = New-Object System.Drawing.Point(18,364)
$quick.Size = New-Object System.Drawing.Size(([Math]::Min(940,$dashPanel.Width-36)),96)
$quick.BackColor = $Global:V7Card
$quick.BorderStyle = 'FixedSingle'
$dashPanel.Controls.Add($quick)
$qTitle = New-Object System.Windows.Forms.Label
$qTitle.Text = "Acces rapide"
$qTitle.Location = New-Object System.Drawing.Point(16,12)
$qTitle.Size = New-Object System.Drawing.Size(240,22)
$qTitle.Font = New-Object System.Drawing.Font("Segoe UI",11,[System.Drawing.FontStyle]::Bold)
$qTitle.ForeColor = $Global:V7Text
$quick.Controls.Add($qTitle)

$quickButtons = @(
    @{T="Pre-check"; C={ Invoke-CBPreCheck }},
    @{T="Simulation"; C={ Show-CBSimulation }},
    @{T="Reparer Windows"; C={ Invoke-CBWindowsRepair }},
    @{T="Gestion disque"; C={Start-Process diskmgmt.msc}},
    @{T="Programmes"; C={Start-Process "appwiz.cpl"}},
    @{T="Exporter rapport"; C={
        if(Get-Command Export-CBReport -ErrorAction SilentlyContinue){
            Export-CBReport -DisqueBefore $Global:DisqueBefore -OpenReport | Out-Null
        } else {
            [System.Windows.Forms.MessageBox]::Show("Module rapport non charge.","Rapport") | Out-Null
        }
    }}
)
$xq=16; $yq=46; $iBtn=0
foreach($qb in $quickButtons){
    $b=New-Object System.Windows.Forms.Button
    $b.Text=$qb.T
    $b.Location=New-Object System.Drawing.Point($xq,$yq)
    $b.Size=New-Object System.Drawing.Size(126,28)
    $b.BackColor=$Global:V7Card2; $b.ForeColor=[System.Drawing.Color]::White; $b.FlatStyle='Flat'; $b.FlatAppearance.BorderSize=0
    $click=$qb.C; $b.Add_Click($click)
    $quick.Controls.Add($b)
    $xq += 134; $iBtn++
    if($iBtn -eq 4){ $xq=16; $yq=82 }
}
$quick.Height = 124

Update-V7Snapshots

# Premier log dans console
try { Write-Log "Charonne Boost 0.77 pret." "Gray" } catch { try { $Global:LiveConsole.AppendText("[$(Get-Date -Format 'HH:mm:ss')][INFO] Charonne Boost 0.77 pret.`r`n") } catch {} }

# Repositionnement final apres chargement du moteur (progress/status crees dans 11_moteur)
$script:form.Add_Shown({
    if($btnLaunch){
        $btnLaunch.Location = New-Object System.Drawing.Point(($script:form.ClientSize.Width - 134),10)
        $btnLaunch.Size = New-Object System.Drawing.Size(118,30)
        $btnLaunch.BringToFront()
    }
    if($progressBar){
        $progressBar.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7ProgressY)
        $progressBar.Size = New-Object System.Drawing.Size($Global:V7ContentW,14)
        $progressBar.ForeColor = $Global:V7Good
        $progressBar.BringToFront()
    }
    if($script:lblStatus){
        $script:lblStatus.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7StatusY)
        $script:lblStatus.Size = New-Object System.Drawing.Size($Global:V7ContentW,18)
        $script:lblStatus.ForeColor = $Global:V7Muted
        $script:lblStatus.BackColor = $Global:V7Dark
        $script:lblStatus.BringToFront()
    }
})

# Ajustement simple si la fenetre est redimensionnee manuellement.
function Update-V7ResponsiveLayout {
    try {
        $Global:V7Compact = ($script:form.Width -lt 1450 -or $script:form.Height -lt 780)
        $Global:V7SidebarWidth = $(if($Global:V7Compact){160}else{178})
        $Global:V7HeaderH = $(if($Global:V7Compact){44}else{50})
        $Global:V7ConsoleH = $(if($Global:V7Compact){68}else{84})
        $Global:V7ContentX = $Global:V7SidebarWidth + 8
        $Global:V7ContentW = $script:form.ClientSize.Width - $Global:V7ContentX - 14
        $Global:V7StatusY = $script:form.ClientSize.Height - 28
        $Global:V7ProgressY = $Global:V7StatusY - 18
        $Global:V7ConsoleY = $Global:V7ProgressY - $Global:V7ConsoleH - 10
        $Global:V7TabH = $Global:V7ConsoleY - $Global:V7HeaderH - 8
        if($side){ $side.Size = New-Object System.Drawing.Size($Global:V7SidebarWidth,$script:form.ClientSize.Height) }
        foreach($nb in $Global:V7NavButtons){ if($nb){ $nb.Size = New-Object System.Drawing.Size(($Global:V7SidebarWidth-16),30) } }
        if($hdr){ $hdr.Location = New-Object System.Drawing.Point($Global:V7SidebarWidth,0); $hdr.Size = New-Object System.Drawing.Size(($script:form.ClientSize.Width - $Global:V7SidebarWidth),$Global:V7HeaderH) }
        if($btnLaunch){ $btnLaunch.Location = New-Object System.Drawing.Point(($script:form.ClientSize.Width - 134),10) }
        if($tabControl){ $tabControl.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7HeaderH); $tabControl.Size = New-Object System.Drawing.Size($Global:V7ContentW,$Global:V7TabH) }
        if($Global:LiveConsole){ $Global:LiveConsole.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7ConsoleY); $Global:LiveConsole.Size = New-Object System.Drawing.Size($Global:V7ContentW,$Global:V7ConsoleH) }
        if($progressBar){ $progressBar.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7ProgressY); $progressBar.Size = New-Object System.Drawing.Size($Global:V7ContentW,14) }
        if($script:lblStatus){ $script:lblStatus.Location = New-Object System.Drawing.Point($Global:V7ContentX,$Global:V7StatusY); $script:lblStatus.Size = New-Object System.Drawing.Size($Global:V7ContentW,18) }
    } catch {}
}
$script:form.Add_Resize({ Update-V7ResponsiveLayout })

# Harmonisation finale V7 : evite les boutons blanc sur blanc herites de WinForms.
function Set-CBButtonReadable {
    param([System.Windows.Forms.Control]$Root)
    foreach($ctrl in $Root.Controls){
        if($ctrl -is [System.Windows.Forms.Button]){
            $isSidebar = ($ctrl.Parent -and $ctrl.Parent.BackColor -eq $Global:V7Sidebar)
            if(-not $isSidebar){
                if($ctrl.BackColor.ToArgb() -eq [System.Drawing.Color]::White.ToArgb() -or $ctrl.BackColor.ToArgb() -eq [System.Drawing.SystemColors]::Control.ToArgb()){
                    $ctrl.BackColor = $Global:V7Card2
                }
                if($ctrl.ForeColor.ToArgb() -eq [System.Drawing.Color]::White.ToArgb() -and $ctrl.BackColor.ToArgb() -eq [System.Drawing.Color]::White.ToArgb()){
                    $ctrl.ForeColor = $Global:V7Text
                } elseif($ctrl.ForeColor.ToArgb() -eq [System.Drawing.SystemColors]::ControlText.ToArgb()){
                    $ctrl.ForeColor = $Global:V7Text
                }
                $ctrl.FlatStyle = 'Flat'
                $ctrl.FlatAppearance.BorderSize = 0
            }
        }
        if($ctrl.HasChildren){ Set-CBButtonReadable -Root $ctrl }
    }
}
Set-CBButtonReadable -Root $script:form
