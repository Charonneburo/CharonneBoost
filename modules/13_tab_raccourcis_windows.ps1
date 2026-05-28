# ============================================================
# ONGLET V7 : RACCOURCIS WINDOWS
# v0.76.1 - correctif lancement raccourcis : isolation des arguments MouseEventArgs.
# ============================================================
$tabWinTools = New-Object System.Windows.Forms.TabPage
$tabWinTools.Text = " Raccourcis Windows "
$tabWinTools.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tabWinTools)

function Invoke-CBShortcut {
    param([string]$Command, [string]$Arguments = "")
    try {
        if ([string]::IsNullOrWhiteSpace($Arguments)) {
            Start-Process -FilePath $Command -ErrorAction Stop | Out-Null
        } else {
            Start-Process -FilePath $Command -ArgumentList $Arguments -ErrorAction Stop | Out-Null
        }
        Write-Log "Raccourci lance : $Command $Arguments" "Green"
    } catch {
        Write-Log "[!] Impossible de lancer : $Command $Arguments -- $_" "Red"
        [System.Windows.Forms.MessageBox]::Show("Impossible de lancer :`n$Command $Arguments`n`n$_","Charonne Boost",'OK','Warning') | Out-Null
    }
}

$shortcutGroups = [ordered]@{
    "Systeme" = @(
        @{Name="Gestion disques"; Cmd="diskmgmt.msc"; Desc="Partitions / volumes"},
        @{Name="Peripheriques"; Cmd="devmgmt.msc"; Desc="Pilotes / materiel"},
        @{Name="Services"; Cmd="services.msc"; Desc="Services Windows"},
        @{Name="Taches"; Cmd="taskmgr"; Desc="Gestionnaire"},
        @{Name="Infos systeme"; Cmd="msinfo32"; Desc="Configuration"},
        @{Name="Registre"; Cmd="regedit"; Desc="Editeur registre"}
    )
    "Reseau" = @(
        @{Name="Connexions"; Cmd="ncpa.cpl"; Desc="Cartes reseau"},
        @{Name="Pare-feu avance"; Cmd="wf.msc"; Desc="Regles Windows"},
        @{Name="IP complete"; Cmd="cmd.exe"; Args="/k ipconfig /all"; Desc="ipconfig /all"},
        @{Name="Bureau distant"; Cmd="SystemPropertiesRemote.exe"; Desc="RDP / assistance"}
    )
    "Affichage / Son" = @(
        @{Name="Affichage"; Cmd="control.exe"; Args="desk.cpl"; Desc="Resolution / ecrans"},
        @{Name="Son"; Cmd="control.exe"; Args="mmsys.cpl"; Desc="Peripheriques audio"},
        @{Name="Mixer volume"; Cmd="sndvol"; Desc="Volume par app"},
        @{Name="Calibrage"; Cmd="dccw"; Desc="Couleurs ecran"}
    )
    "Depannage" = @(
        @{Name="Evenements"; Cmd="eventvwr.msc"; Desc="Journaux Windows"},
        @{Name="Fiabilite"; Cmd="perfmon.exe"; Args="/rel"; Desc="Historique erreurs"},
        @{Name="Ressources"; Cmd="resmon"; Desc="CPU / disque"},
        @{Name="Nettoyage"; Cmd="cleanmgr"; Desc="Cleanmgr"},
        @{Name="Msconfig"; Cmd="msconfig"; Desc="Demarrage"}
    )
    "Utilitaires" = @(
        @{Name="Capture"; Cmd="snippingtool"; Desc="Capture ecran"},
        @{Name="Clavier visuel"; Cmd="osk"; Desc="Accessibilite"},
        @{Name="Loupe"; Cmd="magnify"; Desc="Zoom Windows"},
        @{Name="Programmes"; Cmd="appwiz.cpl"; Desc="Ajout / suppression"}
    )
}

$groupColors = [ordered]@{
    "Systeme"          = [System.Drawing.Color]::FromArgb(37,99,235)
    "Reseau"           = [System.Drawing.Color]::FromArgb(14,165,233)
    "Affichage / Son"  = [System.Drawing.Color]::FromArgb(168,85,247)
    "Depannage"        = [System.Drawing.Color]::FromArgb(245,158,11)
    "Utilitaires"      = [System.Drawing.Color]::FromArgb(34,197,94)
}

$panelTools = New-Object System.Windows.Forms.Panel
$panelTools.Dock = [System.Windows.Forms.DockStyle]::Fill
$panelTools.AutoScroll = $true
$panelTools.BackColor = $Global:PanelColor
$tabWinTools.Controls.Add($panelTools)

$tileW = if($Global:V7Compact){176}else{192}
$tileH = 38
$gapX  = 7
$gapY  = 6
$nCols = [math]::Max(3,[math]::Min(5,[int](($L["InnerW"]-28)/($tileW+$gapX))))
$x0 = 12
$y = 10

foreach($group in $shortcutGroups.Keys){
    $accent = if($groupColors.Contains($group)){$groupColors[$group]}elseif($Global:V7Accent){$Global:V7Accent}else{$Global:AccentColor}

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $group
    $lbl.Location = New-Object System.Drawing.Point($x0,$y)
    $lbl.Size = New-Object System.Drawing.Size(420,20)
    $lbl.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
    $lbl.ForeColor = $accent
    $panelTools.Controls.Add($lbl)
    $y += 22

    $i=0
    foreach($it in $shortcutGroups[$group]){
        $col = $i % $nCols; $row = [math]::Floor($i/$nCols)
        $x = $x0 + $col * ($tileW + $gapX)
        $yy = $y + $row * ($tileH + $gapY)

        $card = New-Object System.Windows.Forms.Panel
        $card.Location = New-Object System.Drawing.Point($x,$yy)
        $card.Size = New-Object System.Drawing.Size($tileW,$tileH)
        $card.BackColor = if($Global:V7Card2){$Global:V7Card2}else{[System.Drawing.Color]::FromArgb(248,250,252)}
        $card.BorderStyle = 'FixedSingle'
        $card.Cursor = [System.Windows.Forms.Cursors]::Hand

        $bar = New-Object System.Windows.Forms.Panel
        $bar.Location = New-Object System.Drawing.Point(0,0)
        $bar.Size = New-Object System.Drawing.Size(5,$tileH)
        $bar.BackColor = $accent

        $title = New-Object System.Windows.Forms.Label
        $title.Text = $it.Name
        $title.Location = New-Object System.Drawing.Point(12,4)
        $title.Size = New-Object System.Drawing.Size(($tileW-18),16)
        $title.Font = New-Object System.Drawing.Font("Segoe UI",8.2,[System.Drawing.FontStyle]::Bold)
        $title.ForeColor = if($Global:V7Text){$Global:V7Text}else{$Global:FgColor}
        $title.BackColor = $card.BackColor

        $desc = New-Object System.Windows.Forms.Label
        $desc.Text = $it.Desc
        $desc.Location = New-Object System.Drawing.Point(12,20)
        $desc.Size = New-Object System.Drawing.Size(($tileW-18),14)
        $desc.Font = New-Object System.Drawing.Font("Segoe UI",6.9)
        $desc.ForeColor = if($Global:V7Muted){$Global:V7Muted}else{$Global:SubFgColor}
        $desc.BackColor = $card.BackColor

        $shortcutCmd = [string]$it.Cmd
        $shortcutArgs = if($it.ContainsKey('Args')){ [string]$it.Args } else { "" }
        # IMPORTANT : ne pas utiliser une variable nommee $args ici.
        # Dans un evenement WinForms, PowerShell injecte automatiquement les parametres
        # sender / MouseEventArgs dans $args, ce qui les transmettait par erreur a regedit/control.exe.
        $click = {
            param($sender, $eventArgs)
            Invoke-CBShortcut -Command $shortcutCmd -Arguments $shortcutArgs
        }.GetNewClosure()
        foreach($c in @($card,$bar,$title,$desc)){ $c.Add_Click($click) }
        $card.Controls.AddRange(@($bar,$title,$desc))
        $panelTools.Controls.Add($card)
        $i++
    }
    $rows = [math]::Ceiling($shortcutGroups[$group].Count / $nCols)
    $y += ($rows * ($tileH + $gapY)) + 12
}
$panelTools.AutoScrollMinSize = New-Object System.Drawing.Size(1,($y+20))
