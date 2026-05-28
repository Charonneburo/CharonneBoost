# ONGLET 9 : HISTORIQUE DES SESSIONS
# ============================================================
$tab9Hist = New-Object System.Windows.Forms.TabPage
$tab9Hist.Text = " Historique "; $tab9Hist.BackColor = $Global:BgColor
$tabControl.TabPages.Add($tab9Hist)

$cmbHistSessions = New-Object System.Windows.Forms.ComboBox
$cmbHistSessions.Location = New-Object System.Drawing.Point(10,10); $cmbHistSessions.Size = New-Object System.Drawing.Size(320,24)
$cmbHistSessions.Font = New-Object System.Drawing.Font("Segoe UI",9); $cmbHistSessions.DropDownStyle = "DropDownList"
$tab9Hist.Controls.Add($cmbHistSessions)

$btnHistRefresh = New-Object System.Windows.Forms.Button
$btnHistRefresh.Text = "Actualiser"; $btnHistRefresh.Location = New-Object System.Drawing.Point(340,9); $btnHistRefresh.Size = New-Object System.Drawing.Size(90,26)
$btnHistRefresh.FlatStyle = "Flat"; $btnHistRefresh.BackColor = [System.Drawing.Color]::FromArgb(26,42,74); $btnHistRefresh.ForeColor = [System.Drawing.Color]::White; $tab9Hist.Controls.Add($btnHistRefresh)

$btnHistDelete = New-Object System.Windows.Forms.Button
$btnHistDelete.Text = "Supprimer ce log"; $btnHistDelete.Location = New-Object System.Drawing.Point(440,9); $btnHistDelete.Size = New-Object System.Drawing.Size(130,26)
$btnHistDelete.FlatStyle = "Flat"; $btnHistDelete.BackColor = [System.Drawing.Color]::FromArgb(255,245,245); $btnHistDelete.ForeColor = [System.Drawing.Color]::FromArgb(160,30,30)
$tab9Hist.Controls.Add($btnHistDelete)

$btnHistClean = New-Object System.Windows.Forms.Button
$btnHistClean.Text = "Supprimer > 30 jours"; $btnHistClean.Location = New-Object System.Drawing.Point(580,9); $btnHistClean.Size = New-Object System.Drawing.Size(160,26)
$btnHistClean.FlatStyle = "Flat"; $btnHistClean.BackColor = [System.Drawing.Color]::FromArgb(255,245,245); $btnHistClean.ForeColor = [System.Drawing.Color]::FromArgb(160,30,30)
$tab9Hist.Controls.Add($btnHistClean)

# ---- Bouton ROLLBACK SYSTEME ----
$btnRollbackSys = New-Object System.Windows.Forms.Button
$btnRollbackSys.Text      = "Rollback Systeme"
$btnRollbackSys.Location  = New-Object System.Drawing.Point(750, 9)
$btnRollbackSys.Size      = New-Object System.Drawing.Size(150, 26)
$btnRollbackSys.FlatStyle = "Flat"
$btnRollbackSys.BackColor = [System.Drawing.Color]::FromArgb(180, 60, 0)
$btnRollbackSys.ForeColor = [System.Drawing.Color]::White
$btnRollbackSys.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$tab9Hist.Controls.Add($btnRollbackSys)

$btnRollbackSys.Add_Click({
    # Lister les snapshots disponibles
    $snapDir = Join-Path $scriptDir "logs"
    $snaps = @(Get-ChildItem $snapDir -Filter "snapshot_*.json" -EA SilentlyContinue | Sort-Object Name -Descending)
    if (-not $snaps) {
        [System.Windows.Forms.MessageBox]::Show(
            "Aucun snapshot systeme trouve.`nLancez d abord une optimisation pour creer un snapshot.",
            "Rollback Systeme", [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    # Choisir le snapshot
    $frmSnap = New-Object System.Windows.Forms.Form
    $frmSnap.Text = "Choisir un snapshot"; $frmSnap.Size = New-Object System.Drawing.Size(480,200)
    $frmSnap.StartPosition = "CenterParent"; $frmSnap.FormBorderStyle = "FixedDialog"
    $frmSnap.BackColor = $Global:BgColor; $frmSnap.MaximizeBox = $false

    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = "Snapshot a restaurer :"; $lbl.Location = New-Object System.Drawing.Point(12,12)
    $lbl.AutoSize = $true; $frmSnap.Controls.Add($lbl)

    $cmb = New-Object System.Windows.Forms.ComboBox
    $cmb.Location = New-Object System.Drawing.Point(12,34); $cmb.Size = New-Object System.Drawing.Size(440,24)
    $cmb.DropDownStyle = "DropDownList"
    $snaps | ForEach-Object { $cmb.Items.Add($_.Name) | Out-Null }
    $cmb.SelectedIndex = 0; $frmSnap.Controls.Add($cmb)

    $lblWarn = New-Object System.Windows.Forms.Label
    $lblWarn.Text = "Attention : cette operation modifie le registre systeme et redemarrera l explorateur."
    $lblWarn.Location = New-Object System.Drawing.Point(12,66); $lblWarn.Size = New-Object System.Drawing.Size(440,32)
    $lblWarn.ForeColor = [System.Drawing.Color]::FromArgb(150,50,0)
    $lblWarn.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
    $frmSnap.Controls.Add($lblWarn)

    $btnOk = New-Object System.Windows.Forms.Button
    $btnOk.Text = "Restaurer"; $btnOk.Location = New-Object System.Drawing.Point(120,110)
    $btnOk.Size = New-Object System.Drawing.Size(100,30); $btnOk.BackColor = [System.Drawing.Color]::FromArgb(180,60,0)
    $btnOk.ForeColor = "White"; $btnOk.FlatStyle = "Flat"; $btnOk.DialogResult = "OK"
    $frmSnap.Controls.Add($btnOk)

    $btnCancel = New-Object System.Windows.Forms.Button
    $btnCancel.Text = "Annuler"; $btnCancel.Location = New-Object System.Drawing.Point(240,110)
    $btnCancel.Size = New-Object System.Drawing.Size(100,30); $btnCancel.FlatStyle = "Flat"; $btnCancel.DialogResult = "Cancel"
    $frmSnap.Controls.Add($btnCancel)
    $frmSnap.AcceptButton = $btnOk; $frmSnap.CancelButton = $btnCancel

    if ($frmSnap.ShowDialog() -eq "OK") {
        $chosen = Join-Path $snapDir $cmb.SelectedItem
        $ok = Restore-SystemSnapshot -SnapFile $chosen
        if ($ok) {
            [System.Windows.Forms.MessageBox]::Show("Rollback effectue avec succes.`nL explorateur a ete redarre.","Rollback Systeme",
                [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        }
    }
})
$btnRollback = New-Object System.Windows.Forms.Button
$btnRollback.Text      = "Restaurer services"
$btnRollback.Location  = New-Object System.Drawing.Point(10, ($L["HistBoxH"] + 50))
$btnRollback.Size      = New-Object System.Drawing.Size(170, 26)
$btnRollback.FlatStyle = "Flat"
$btnRollback.BackColor = [System.Drawing.Color]::FromArgb(26, 42, 74)
$btnRollback.ForeColor = [System.Drawing.Color]::White
$btnRollback.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$btnRollback.FlatAppearance.BorderSize = 0
$tab9Hist.Controls.Add($btnRollback)

$btnRollback.Add_Click({
    # Lister les fichiers rollback disponibles dans logs\
    $rollbackDir = Join-Path $scriptDir "logs"
    $rollbackFiles = @(Get-ChildItem $rollbackDir -Filter "services_rollback_*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)

    if ($rollbackFiles.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Aucun fichier de rollback de services trouve dans :`n$rollbackDir`n`nLancez d abord l action 'Services inutiles' pour creer un rollback.",
            "Rollback services",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }

    # Proposer la selection du fichier via InputBox simulee
    $frmRB = New-Object System.Windows.Forms.Form
    $frmRB.Text = "Choisir un rollback a restaurer"
    $frmRB.Size = New-Object System.Drawing.Size(520, 200)
    $frmRB.StartPosition = "CenterParent"
    $frmRB.BackColor = $Global:BgColor
    $frmRB.FormBorderStyle = "FixedDialog"
    $frmRB.MaximizeBox = $false

    $lblRB = New-Object System.Windows.Forms.Label
    $lblRB.Text = "Fichier de rollback a restaurer :"
    $lblRB.Location = New-Object System.Drawing.Point(10, 12)
    $lblRB.Size = New-Object System.Drawing.Size(480, 18)
    $lblRB.ForeColor = $Global:FgColor
    $frmRB.Controls.Add($lblRB)

    $cmbRB = New-Object System.Windows.Forms.ComboBox
    $cmbRB.Location = New-Object System.Drawing.Point(10, 34)
    $cmbRB.Size = New-Object System.Drawing.Size(480, 24)
    $cmbRB.DropDownStyle = "DropDownList"
    $cmbRB.BackColor = $Global:PanelColor
    $cmbRB.ForeColor = $Global:FgColor
    foreach ($f in $rollbackFiles) { $cmbRB.Items.Add($f.Name) | Out-Null }
    $cmbRB.SelectedIndex = 0
    $frmRB.Controls.Add($cmbRB)

    $btnRBOK = New-Object System.Windows.Forms.Button
    $btnRBOK.Text = "Restaurer"
    $btnRBOK.Location = New-Object System.Drawing.Point(10, 70)
    $btnRBOK.Size = New-Object System.Drawing.Size(100, 28)
    $btnRBOK.BackColor = [System.Drawing.Color]::FromArgb(26, 42, 74)
    $btnRBOK.ForeColor = [System.Drawing.Color]::White
    $btnRBOK.FlatStyle = "Flat"
    $btnRBOK.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $frmRB.Controls.Add($btnRBOK)

    $btnRBCancel = New-Object System.Windows.Forms.Button
    $btnRBCancel.Text = "Annuler"
    $btnRBCancel.Location = New-Object System.Drawing.Point(120, 70)
    $btnRBCancel.Size = New-Object System.Drawing.Size(80, 28)
    $btnRBCancel.FlatStyle = "Flat"
    $btnRBCancel.ForeColor = $Global:FgColor
    $btnRBCancel.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $frmRB.Controls.Add($btnRBCancel)

    $lblRBNote = New-Object System.Windows.Forms.Label
    $lblRBNote.Text = "Restaure le type de demarrage original de chaque service desactive."
    $lblRBNote.Location = New-Object System.Drawing.Point(10, 110)
    $lblRBNote.Size = New-Object System.Drawing.Size(480, 16)
    $lblRBNote.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Italic)
    $lblRBNote.ForeColor = [System.Drawing.Color]::FromArgb(142, 142, 147)
    $frmRB.Controls.Add($lblRBNote)

    if ($frmRB.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) { return }

    $chosenFile = Join-Path $rollbackDir $cmbRB.SelectedItem
    if (-not (Test-Path $chosenFile)) {
        [System.Windows.Forms.MessageBox]::Show("Fichier introuvable.","Erreur",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }

    try {
        $data = Get-Content $chosenFile -Raw | ConvertFrom-Json
        $restored = 0
        $errors   = 0
        foreach ($prop in $data.PSObject.Properties) {
            $svcName   = $prop.Name
            $startType = $prop.Value.StartType
            try {
                Set-Service -Name $svcName -StartupType $startType -ErrorAction Stop
                # Redemarrer si le service etait Running avant
                if ($prop.Value.Status -eq "Running") {
                    Start-Service -Name $svcName -ErrorAction SilentlyContinue
                }
                $restored++
                Write-Log "Rollback service : $svcName -> $startType" "Green"
            } catch {
                $errors++
                Write-Log "[!] Rollback echec pour $svcName : $_" "Yellow"
            }
        }
        [System.Windows.Forms.MessageBox]::Show(
            "Rollback termine.`n`n$restored service(s) restaure(s).`n$errors erreur(s).`n`nFichier utilise :`n$chosenFile",
            "Rollback services",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show(
            "Erreur lecture fichier rollback :`n$_",
            "Erreur",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$lblHistInfo = New-Object System.Windows.Forms.Label
$lblHistInfo.Location = New-Object System.Drawing.Point(10,($L["HistBoxH"] + 48)); $lblHistInfo.Size = New-Object System.Drawing.Size(($L["TabW"] - 30),18)
$lblHistInfo.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
$lblHistInfo.ForeColor = [System.Drawing.Color]::FromArgb(100,100,100)
$tab9Hist.Controls.Add($lblHistInfo)

$rtHist = New-Object System.Windows.Forms.RichTextBox
$rtHist.Location = New-Object System.Drawing.Point(10,42); $rtHist.Size = New-Object System.Drawing.Size(($L["TabW"] - 30),$L["HistBoxH"])
$rtHist.Font = New-Object System.Drawing.Font("Consolas",8.5)
$rtHist.BackColor = [System.Drawing.Color]::White; $rtHist.ForeColor = [System.Drawing.Color]::FromArgb(20,20,20)
$rtHist.ReadOnly = $true; $rtHist.BorderStyle = "None"
$tab9Hist.Controls.Add($rtHist)

function Load-SessionLogs {
    $cmbHistSessions.Items.Clear()
    $logDir = Join-Path $scriptDir "logs"
    if (!(Test-Path $logDir)) { $lblHistInfo.Text = "Aucun dossier logs trouve."; return }
    $logs = Get-ChildItem $logDir -Filter "session_*.log" -ErrorAction SilentlyContinue | Sort-Object Name -Descending
    if ($logs.Count -eq 0) { $lblHistInfo.Text = "Aucune session enregistree."; return }
    foreach ($l in $logs) {
        $date = $l.Name -replace "session_","" -replace "\.log",""
        $cmbHistSessions.Items.Add($date) | Out-Null
    }
    if ($cmbHistSessions.Items.Count -gt 0) { $cmbHistSessions.SelectedIndex = 0 }
    $lblHistInfo.Text = "$($logs.Count) session(s) enregistree(s)."
}

function Show-SessionLog($sessionName) {
    $rtHist.Clear()
    $logPath = Join-Path $scriptDir "logs\session_$sessionName.log"
    if (!(Test-Path $logPath)) { $rtHist.AppendText("Fichier introuvable : $logPath"); return }
    $lines = [System.IO.File]::ReadAllLines($logPath)
    foreach ($line in $lines) {
        $rtHist.SelectionStart = $rtHist.TextLength; $rtHist.SelectionLength = 0
        if     ($line -match "\[OK\]")     { $rtHist.SelectionColor = [System.Drawing.Color]::FromArgb(0,120,40) }
        elseif ($line -match "\[PURGE\]")  { $rtHist.SelectionColor = [System.Drawing.Color]::FromArgb(26,42,74) }
        elseif ($line -match "\[ERREUR\]") { $rtHist.SelectionColor = [System.Drawing.Color]::FromArgb(180,20,20) }
        elseif ($line -match "^===")       { $rtHist.SelectionColor = [System.Drawing.Color]::FromArgb(180,210,255) }
        elseif ($line -match "^---")       { $rtHist.SelectionColor = [System.Drawing.Color]::FromArgb(100,100,100) }
        else                               { $rtHist.SelectionColor = [System.Drawing.Color]::FromArgb(200,220,200) }
        $rtHist.AppendText("$line`n")
    }
}

$cmbHistSessions.Add_SelectedIndexChanged({
    if ($cmbHistSessions.SelectedItem) { Show-SessionLog $cmbHistSessions.SelectedItem }
})
$btnHistRefresh.Add_Click({ Load-SessionLogs })
$btnHistDelete.Add_Click({
    if (!$cmbHistSessions.SelectedItem) { return }
    $logPath = Join-Path $scriptDir "logs\session_$($cmbHistSessions.SelectedItem).log"
    $conf = [System.Windows.Forms.MessageBox]::Show("Supprimer ce log ?","Confirmer",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($conf -eq "Yes") { Remove-Item $logPath -Force -ErrorAction SilentlyContinue; Load-SessionLogs }
})
$btnHistClean.Add_Click({
    $logDir = Join-Path $scriptDir "logs"
    $old = Get-ChildItem $logDir -Filter "*.log" -ErrorAction SilentlyContinue | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) }
    if ($old.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Aucun log de plus de 30 jours.","Nettoyage",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information); return }
    $conf = [System.Windows.Forms.MessageBox]::Show("Supprimer $($old.Count) log(s) anciens ?","Confirmer",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($conf -eq "Yes") { $old | Remove-Item -Force -ErrorAction SilentlyContinue; Load-SessionLogs }
})
$tab9Hist.Add_VisibleChanged({ if ($tab9Hist.Visible -and $cmbHistSessions.Items.Count -eq 0) { Load-SessionLogs } })

$tab5 = New-Object System.Windows.Forms.TabPage
$tab5.Text = " Qui sommes nous ? "; $tab5.BackColor = $Global:BgColor
$tabControl.TabPages.Add($tab5)

$navyColor = $Global:AccentColor
$whiteColor = [System.Drawing.Color]::White

# ================================================================
# BANDEAU HAUT : logo a gauche (45%) | textes a droite (55%)
# ================================================================
$hdrH = [math]::Min(220, [int]($L["InnerH"] * 0.42))
$pnlHeader = New-Object System.Windows.Forms.Panel
$pnlHeader.Location  = New-Object System.Drawing.Point(0, 0)
$pnlHeader.Size      = New-Object System.Drawing.Size($L["InnerW"], $hdrH)
$pnlHeader.BackColor = $Global:BgColor
$tab5.Controls.Add($pnlHeader)

# Logo : 46% de InnerW -- proportion qui donnait le meilleur rendu visuellement
$logoW = [int]($L["InnerW"] * 0.44)
$logoH = $hdrH - 16
$LocalLogo6 = "$scriptDir\png\logo2.png"
if (Test-Path $LocalLogo6) {
    $pbL = New-Object System.Windows.Forms.PictureBox
    $pbL.Image    = [System.Drawing.Image]::FromFile($LocalLogo6)
    $pbL.Size     = New-Object System.Drawing.Size($logoW, $logoH)
    $pbL.Location = New-Object System.Drawing.Point(8, 8)
    $pbL.SizeMode = "Zoom"
    $pbL.BackColor = $Global:BgColor
    $pnlHeader.Controls.Add($pbL)
}

# Separateur vertical
$sepX = $logoW + 18
$sepV = New-Object System.Windows.Forms.Label
$sepV.Size      = New-Object System.Drawing.Size(1, ($hdrH - 24))
$sepV.Location  = New-Object System.Drawing.Point($sepX, 12)
$sepV.BackColor = [System.Drawing.Color]::FromArgb(200, 210, 225)
$pnlHeader.Controls.Add($sepV)

# Bloc texte a droite du separateur
$textX = $sepX + 18
$textW = $L["InnerW"] - $textX - 16

# Slogan principal
$lblSlogan = New-Object System.Windows.Forms.Label
$lblSlogan.Text      = "Votre expert informatique a Paris 11e depuis 1986"
$lblSlogan.Font      = New-Object System.Drawing.Font("Segoe UI", 11, [System.Drawing.FontStyle]::Italic)
$lblSlogan.ForeColor = $Global:AccentColor
$lblSlogan.Location  = New-Object System.Drawing.Point($textX, [int]($hdrH * 0.20))
$lblSlogan.Size      = New-Object System.Drawing.Size($textW, 24)
$pnlHeader.Controls.Add($lblSlogan)

# Ligne de separation horizontale fine
$sepH = New-Object System.Windows.Forms.Label
$sepH.Size      = New-Object System.Drawing.Size($textW, 1)
$sepH.Location  = New-Object System.Drawing.Point($textX, [int]($hdrH * 0.45))
$sepH.BackColor = [System.Drawing.Color]::FromArgb(210, 220, 235)
$pnlHeader.Controls.Add($sepH)

# Services en 2 lignes
$lblSvc1 = New-Object System.Windows.Forms.Label
$lblSvc1.Text      = "Maintenance informatique  |  Reparation carte mere  |  Vente portable PC & Mac"
$lblSvc1.Font      = New-Object System.Drawing.Font("Segoe UI", 8.5)
$lblSvc1.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 80)
$lblSvc1.Location  = New-Object System.Drawing.Point($textX, [int]($hdrH * 0.52))
$lblSvc1.Size      = New-Object System.Drawing.Size($textW, 18)
$pnlHeader.Controls.Add($lblSvc1)

$lblSvc2 = New-Object System.Windows.Forms.Label
$lblSvc2.Text      = "Reseau & Systeme  |  Microsoudure  |  Reconditionnement  |  Occasion"
$lblSvc2.Font      = New-Object System.Drawing.Font("Segoe UI", 8)
$lblSvc2.ForeColor = [System.Drawing.Color]::FromArgb(100, 110, 130)
$lblSvc2.Location  = New-Object System.Drawing.Point($textX, [int]($hdrH * 0.67))
$lblSvc2.Size      = New-Object System.Drawing.Size($textW, 16)
$pnlHeader.Controls.Add($lblSvc2)

# Credit bas
$lblDev = New-Object System.Windows.Forms.Label
$lblDev.Text      = "Developpe par M. Condamine  |  Propulse par Claude IA  |  Charonne Boost v12.1"
$lblDev.Font      = New-Object System.Drawing.Font("Segoe UI", 7, [System.Drawing.FontStyle]::Italic)
$lblDev.ForeColor = [System.Drawing.Color]::FromArgb(150, 150, 150)
$lblDev.Location  = New-Object System.Drawing.Point($textX, [int]($hdrH * 0.84))
$lblDev.Size      = New-Object System.Drawing.Size($textW, 14)
$pnlHeader.Controls.Add($lblDev)

# ================================================================
# CORPS : fond clair, deux colonnes
# ================================================================
$bodyH = $L["InnerH"] - $hdrH - 2
$pnlBody = New-Object System.Windows.Forms.Panel
$pnlBody.Location  = New-Object System.Drawing.Point(0, $hdrH)
$pnlBody.Size      = New-Object System.Drawing.Size($L["InnerW"], $bodyH)
$pnlBody.BackColor = $Global:BgColor
$tab5.Controls.Add($pnlBody)

# Pre-calculer qrTopY ici pour aligner les deux colonnes sur la meme ligne
$qrSize = [math]::Min(160, $bodyH - 20)
$qrTopY = [int](($bodyH - $qrSize) / 2)

# Colonne gauche : coordonnees (45% de la largeur)
$leftW = [int]($L["InnerW"] * 0.45)
$pnlLeft = New-Object System.Windows.Forms.Panel
$pnlLeft.Location  = New-Object System.Drawing.Point(0, 0)
$pnlLeft.Size      = New-Object System.Drawing.Size($leftW, $bodyH)
$pnlLeft.BackColor = $Global:BgColor
$pnlBody.Controls.Add($pnlLeft)

# Titre coordonnees aligne sur le haut du QR code
$lblCoordTitle = New-Object System.Windows.Forms.Label
$lblCoordTitle.Text      = "Coordonnees"
$lblCoordTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$lblCoordTitle.ForeColor = [System.Drawing.Color]::FromArgb(100, 100, 100)
$lblCoordTitle.Location  = New-Object System.Drawing.Point(14, $qrTopY)
$lblCoordTitle.AutoSize  = $true
$pnlLeft.Controls.Add($lblCoordTitle)

# Coordonnees avec icones unicode (Segoe UI Symbol les supporte sous Windows)
# Icones BMP (U+0000-U+FFFF) -- [char] PS 5.1 ne supporte pas > U+FFFF
# Remplacees par des symboles Segoe UI / Wingdings dans la plage BMP
$icoPin   = [char]0x25CF   # cercle plein  (adresse)
$icoMetro = [char]0x24C2   # M encercle    (metro)
$icoWeb   = [char]0x2315   # telephone/web (globe approx)
$icoTel   = [char]0x260F   # combine       (tel)
$icoMail  = [char]0x2709   # enveloppe     (email -- BMP OK)
$icoPC    = [char]0x25A0   # carre plein   (PC)
$icoRec   = [char]0x267B   # recycle       (BMP OK)
$icoGear  = [char]0x2699   # engrenage     (BMP OK)
$icoHome  = [char]0x2302   # maison        (BMP OK)

$infoLines = @(
    @{ Icon=$icoPin;   Text="129 boulevard de Charonne, 75011 Paris"; Action=$null }
    @{ Icon=$icoMetro; Text="Ligne 2 - Station Alexandre Dumas";      Action=$null }
    @{ Icon=$icoWeb;   Text="www.charonneburo.com";                   Action={ Start-Process "https://www.charonneburo.com" } }
    @{ Icon=$icoTel;   Text="01 43 79 35 40";                         Action={ [System.Windows.Forms.Clipboard]::SetText("0143793540"); [System.Windows.Forms.MessageBox]::Show("Numero copie : 01 43 79 35 40") } }
    @{ Icon=$icoMail;  Text="contact@charonneburo.com";               Action={ Start-Process "mailto:contact@charonneburo.com" } }
)
$yI = $qrTopY + 22   # debut des lignes = haut QR + titre "Coordonnees"
foreach ($line in $infoLines) {
    $lIcon = New-Object System.Windows.Forms.Label
    $lIcon.Text      = $line.Icon
    $lIcon.Location  = New-Object System.Drawing.Point(14, $yI)
    $lIcon.Size      = New-Object System.Drawing.Size(24, 24)
    $lIcon.Font      = New-Object System.Drawing.Font("Segoe UI Symbol", 12)
    $lIcon.ForeColor = $navyColor
    $click = ($line.Action -ne $null)
    $lv = New-Object System.Windows.Forms.Label
    $lv.Text     = $line.Text
    $lv.Location = New-Object System.Drawing.Point(42, ($yI + 3))
    $lv.Size     = New-Object System.Drawing.Size(($leftW - 52), 22)
    $lv.Font     = if ($click) { New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Underline) } else { New-Object System.Drawing.Font("Segoe UI", 10) }
    $lv.ForeColor = if ($click) { [System.Drawing.Color]::FromArgb(0, 102, 204) } else { [System.Drawing.Color]::FromArgb(30, 30, 30) }
    if ($click) { $lv.Cursor = [System.Windows.Forms.Cursors]::Hand; $a = $line.Action; $lv.Add_Click($a) }
    $pnlLeft.Controls.AddRange(@($lIcon, $lv))
    $yI += 30
}

# Separateur vertical corps
$sepVBody = New-Object System.Windows.Forms.Label
$sepVBody.Size      = New-Object System.Drawing.Size(1, ($bodyH - 10))
$sepVBody.Location  = New-Object System.Drawing.Point($leftW, 5)
$sepVBody.BackColor = [System.Drawing.Color]::FromArgb(210, 215, 225)
$pnlBody.Controls.Add($sepVBody)

# Colonne droite : QR code + "Nos services" a sa droite
$rightX = $leftW + 2
$rightW = $L["InnerW"] - $rightX
$pnlRight = New-Object System.Windows.Forms.Panel
$pnlRight.Location  = New-Object System.Drawing.Point($rightX, 0)
$pnlRight.Size      = New-Object System.Drawing.Size($rightW, $bodyH)
$pnlRight.BackColor = $Global:BgColor
$pnlBody.Controls.Add($pnlRight)

# QR code : centre verticalement
$qrLocalPath = "$scriptDir\png\qrcode_avis.png"
# qrSize et qrTopY deja calcules en debut de section corps
$pbQR = New-Object System.Windows.Forms.PictureBox
$pbQR.Size        = New-Object System.Drawing.Size($qrSize, $qrSize)
$pbQR.Location    = New-Object System.Drawing.Point(10, $qrTopY)
$pbQR.SizeMode    = "Zoom"
$pbQR.BorderStyle = "FixedSingle"
$pbQR.BackColor   = "White"
$pnlRight.Controls.Add($pbQR)
if (Test-Path $qrLocalPath) {
    $pbQR.Image = [System.Drawing.Image]::FromFile($qrLocalPath)
} else {
    $tab5.Add_VisibleChanged({
        if ($tab5.Visible -and $pbQR.Image -eq $null) {
            try {
                $u = "https://api.qrserver.com/v1/create-qr-code/?size=160x160&ecc=M&data=" + [System.Uri]::EscapeDataString("https://www.google.com/search?q=Charonne+Buro+Avis&rflfq=1&num=20&rldimm=10221874607242452126&tbm=lcl#lkt=LocalPoiReviews")
                $wc2 = New-Object System.Net.WebClient; $b2 = $wc2.DownloadData($u)
                $ms2 = New-Object System.IO.MemoryStream($b2, 0, $b2.Length)
                $pbQR.Image = [System.Drawing.Image]::FromStream($ms2)
            } catch { $pbQR.BackColor = [System.Drawing.Color]::LightGray }
        }
    })
}

# "Nos services" a droite du QR code
$svcX = $qrSize + 18
$svcW = $rightW - $svcX - 8
$lblSvc = New-Object System.Windows.Forms.Label
$lblSvc.Text      = "Nos services"
$lblSvc.Font      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$lblSvc.ForeColor = [System.Drawing.Color]::FromArgb(60, 60, 60)
$lblSvc.Location  = New-Object System.Drawing.Point($svcX, $qrTopY)
$lblSvc.AutoSize  = $true
$pnlRight.Controls.Add($lblSvc)

$svcTexts = @(
    "$icoPC   Depannage PC, Mac, Linux"
    "$icoRec  Reconditionnement materiel"
    "$icoGear Installation et optimisation"
    "$icoHome Domicile ou en boutique"
)
$ySvc = $qrTopY + 28
foreach ($svcLine in $svcTexts) {
    $ls = New-Object System.Windows.Forms.Label
    $ls.Text      = $svcLine
    $ls.Location  = New-Object System.Drawing.Point($svcX, $ySvc)
    $ls.Size      = New-Object System.Drawing.Size($svcW, 24)
    $ls.Font      = New-Object System.Drawing.Font("Segoe UI Symbol", 10)
    $ls.ForeColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $pnlRight.Controls.Add($ls)
    $ySvc += 30
}

# ============================================================
# BARRE DU BAS : progressbar + status uniquement
# (bouton Lancer est maintenant dans le header)
# ============================================================
$progressBar = New-Object System.Windows.Forms.ProgressBar
