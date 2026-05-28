# ONGLET 4 : RESEAU / PRO + SECURITE (fusionne)
# ============================================================
$tab4 = New-Object System.Windows.Forms.TabPage
$tab4.Text = " Reseau / Securite "; $tab4.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab4)

$netActions = [ordered]@{
    "Tester connectivite Internet"   = @{ Key="PingTest";   Desc="Ping 8.8.8.8, verifie la connexion" }
    "Afficher IP / Passerelle / DNS" = @{ Key="ShowIP";     Desc="Resume les infos reseau de la machine" }
    "Vider cache DNS"                = @{ Key="FlushDNS";   Desc="ipconfig /flushdns, resout les pb DNS" }
    "Mapper un lecteur reseau"       = @{ Key="MapDrive";   Desc="Connecte une lettre de lecteur a un UNC" }
    "Ajouter une imprimante (IP)"    = @{ Key="AddPrinter"; Desc="Ajoute une imprimante par adresse IP" }
    "Reinitialiser pile TCP/IP"      = @{ Key="ResetTCP";   Desc="netsh reset, repare les pb reseau profonds" }
}

$secActions = [ordered]@{
    "Verifier etat Windows Defender"    = @{ Key="CheckDefender";   Desc="Affiche statut antivirus et date MAJ" }
    "Lancer scan rapide Defender"       = @{ Key="QuickScan";       Desc="Analyse rapide des zones critiques" }
    "Verifier / Activer le Pare-feu"    = @{ Key="CheckFirewall";   Desc="Active le firewall sur tous les profils" }
    "Securiser les scripts PowerShell"  = @{ Key="SecurePS";        Desc="RemoteSigned : bloque scripts non signes" }
    "Verifier les MAJ de securite"      = @{ Key="CheckSecUpdates"; Desc="Ouvre Windows Update pour verification" }
    "Desactiver SMBv1"                  = @{ Key="DisableSMBv1";    Desc="Supprime le protocole reseau vulnerable" }
}

# ================================================================
# ONGLET 4 : ACCORDEON Reseau + Securite
# ================================================================
$Global:NetChk = [ordered]@{}
$Global:SecChk = [ordered]@{}

function New-Accordion {
    param($Parent,$Title,$HdrColor,$Y,$W,$Actions,$CDict,$ColW,$ColStep,$ColMargin,[int]$RowH=42)
    $hdrH=30; $rowH=$RowH; $nRows=[math]::Ceiling($Actions.Count/4); $bodyH=$nRows*$rowH+6; $totalH=$hdrH+$bodyH
    $acc=New-Object System.Windows.Forms.Panel; $acc.Location=New-Object System.Drawing.Point(0,$Y)
    $acc.Size=New-Object System.Drawing.Size($W,$totalH); $acc.BackColor=$Global:PanelColor; $Parent.Controls.Add($acc)
    $hdr=New-Object System.Windows.Forms.Panel; $hdr.Location=New-Object System.Drawing.Point(0,0)
    $hdr.Size=New-Object System.Drawing.Size($W,$hdrH); $hdr.BackColor=$HdrColor; $hdr.Cursor=[System.Windows.Forms.Cursors]::Hand; $acc.Controls.Add($hdr)
    $lblH=New-Object System.Windows.Forms.Label; $lblH.Text="  v  $Title"; $lblH.Location=New-Object System.Drawing.Point(8,6)
    $lblH.AutoSize=$true; $lblH.Font=New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
    $lblH.ForeColor=[System.Drawing.Color]::White; $lblH.BackColor=$HdrColor; $hdr.Controls.Add($lblH)
    $btnAll=New-Object System.Windows.Forms.Button; $btnAll.Text="Tout cocher"; $btnAll.Size=New-Object System.Drawing.Size(86,20)
    $btnAll.Location=New-Object System.Drawing.Point(($W-94),5); $btnAll.FlatStyle="Flat"
    $btnAll.Font=New-Object System.Drawing.Font("Segoe UI",7.5); $btnAll.ForeColor=[System.Drawing.Color]::White
    $btnAll.BackColor=[System.Drawing.Color]::FromArgb(30,255,255,255); $btnAll.FlatAppearance.BorderColor=[System.Drawing.Color]::FromArgb(80,255,255,255)
    $hdr.Controls.Add($btnAll)
    $body=New-Object System.Windows.Forms.Panel; $body.Location=New-Object System.Drawing.Point(0,$hdrH)
    $body.Size=New-Object System.Drawing.Size($W,$bodyH); $body.BackColor=$Global:PanelColor; $acc.Controls.Add($body)
    $keys2=@($Actions.Keys)
    for([int]$ii=0;$ii -lt $keys2.Count;$ii++){
        $lbl2=$keys2[$ii]; $ent=$Actions[$lbl2]
        [int]$cx=$ColMargin+($ii%4)*$ColStep; [int]$cy=[math]::Floor($ii/4)*$rowH+4
        $card=New-Object System.Windows.Forms.Panel; $card.Size=New-Object System.Drawing.Size($ColW,($rowH-4))
        $card.Location=New-Object System.Drawing.Point($cx,$cy); $card.BackColor=$Global:PanelColor
        $barC=New-Object System.Windows.Forms.Panel; $barC.Size=New-Object System.Drawing.Size(3,($rowH-4))
        $barC.Location=New-Object System.Drawing.Point(0,0); $barC.BackColor=$HdrColor
        $chk2=New-Object System.Windows.Forms.CheckBox; $chk2.Text=$lbl2
        $chk2.Location=New-Object System.Drawing.Point(8,3); $chk2.Size=New-Object System.Drawing.Size(($ColW-12),14)
        $chk2.Font=New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $chk2.BackColor=$Global:PanelColor; $chk2.ForeColor=$Global:FgColor
        ($CDict.Value)[$lbl2]=$chk2
        $ld2=New-Object System.Windows.Forms.Label; $ld2.Text=$ent.Desc
        $ld2.Location=New-Object System.Drawing.Point(8,18); $ld2.Size=New-Object System.Drawing.Size(($ColW-12),12)
        $ld2.Font=New-Object System.Drawing.Font("Segoe UI",7,[System.Drawing.FontStyle]::Italic)
        $ld2.ForeColor=[System.Drawing.Color]::FromArgb(90,90,90); $ld2.BackColor=$Global:PanelColor
        $card.Controls.AddRange(@($barC,$chk2,$ld2)); $body.Controls.Add($card)
    }
    $btnAll.Add_Click({
        $t=($btnAll.Text -eq "Tout cocher")
        foreach($k in ($CDict.Value).Keys){($CDict.Value)[$k].Checked=$t}
        $btnAll.Text=if($t){"Tout decocher"}else{"Tout cocher"}
    }.GetNewClosure())
    $exp=[ref]$true
    $toggle={
        $exp.Value=-not $exp.Value; $body.Visible=$exp.Value
        $lblH.Text="  $(if($exp.Value){'v'}else{'>'})  $Title"
        $acc.Height=if($exp.Value){$hdrH+$bodyH}else{$hdrH}
        $yOff=$acc.Bottom+4
        foreach($sib in @($Parent.Controls|Where-Object{$_ -is [System.Windows.Forms.Panel] -and $_ -ne $acc})){
            if($sib.Top -gt $acc.Top){$sib.Top=$yOff;$yOff=$sib.Bottom+4}
        }
    }.GetNewClosure()
    $hdr.Add_Click($toggle); $lblH.Add_Click($toggle)
    return $acc
}

$accW=$L["InnerW"]; $accColW=[int](($accW-24)/4); $accColGap=4
$accColMargin=[int](($accW-4*$accColW-3*$accColGap)/2); $accColStep=$accColW+$accColGap
# RowH : reseau=2 lignes (6 items/3cols), securite=3 lignes (7 items/3cols) = 5 lignes cartes
# + 2 headers 32px + ping PingH + marges 30px
$accRowH = 34

# Panel scrollable pour contenir les deux accordeons + ping
$pnlTab4 = New-Object System.Windows.Forms.Panel
$pnlTab4.Location = New-Object System.Drawing.Point(0,0)
$pnlTab4.Size = New-Object System.Drawing.Size($L["InnerW"], ($L["InnerH"]))
$pnlTab4.AutoScroll = $true; $pnlTab4.BackColor = $Global:PanelColor
$tab4.Controls.Add($pnlTab4)

$accNet=New-Accordion -Parent $pnlTab4 -Title "Reseau / Pro" `
    -HdrColor ([System.Drawing.Color]::FromArgb(41,128,185)) `
    -Y 5 -W $accW -Actions $netActions -CDict ([ref]$Global:NetChk) `
    -ColW $accColW -ColStep $accColStep -ColMargin $accColMargin -RowH $accRowH

# ============================================================
# PANEL PING interactif -- entre les deux accordeons
# ============================================================
$pnlPing = New-Object System.Windows.Forms.Panel
$pnlPing.Location  = New-Object System.Drawing.Point(0, ($accNet.Bottom + 4))
$pnlPing.Size      = New-Object System.Drawing.Size($accW, 58)
$pnlPing.BackColor = [System.Drawing.Color]::FromArgb(26,42,74)
$pnlTab4.Controls.Add($pnlPing)

$lblPingTitle = New-Object System.Windows.Forms.Label
$lblPingTitle.Text      = "TEST DE CONNEXION"
$lblPingTitle.Location  = New-Object System.Drawing.Point(10, 6)
$lblPingTitle.AutoSize  = $true
$lblPingTitle.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$lblPingTitle.ForeColor = [System.Drawing.Color]::FromArgb(200,220,255)
$lblPingTitle.BackColor = [System.Drawing.Color]::FromArgb(26,42,74)
$pnlPing.Controls.Add($lblPingTitle)

# Boutons IP rapides
$pingTargets = @("8.8.8.8","1.1.1.1","192.168.0.1","192.168.1.1")
$pxBtn = 10
foreach ($ip in $pingTargets) {
    $bip = New-Object System.Windows.Forms.Button
    $bip.Text = $ip; $bip.Size = New-Object System.Drawing.Size(100,26)
    $bip.Location = New-Object System.Drawing.Point($pxBtn, 26)
    $bip.BackColor = [System.Drawing.Color]::FromArgb(44,62,100); $bip.ForeColor = "White"
    $bip.FlatStyle = "Flat"; $bip.Font = New-Object System.Drawing.Font("Segoe UI",8)
    $bip.Add_Click({ $txtPingTarget.Text = $bip.Text }.GetNewClosure())
    $pnlPing.Controls.Add($bip); $pxBtn += 108
}

$lblPingIP = New-Object System.Windows.Forms.Label
$lblPingIP.Text = "IP / Hote :"; $lblPingIP.Location = New-Object System.Drawing.Point(450,30)
$lblPingIP.AutoSize = $true; $lblPingIP.ForeColor = "White"
$lblPingIP.BackColor = [System.Drawing.Color]::FromArgb(26,42,74)
$pnlPing.Controls.Add($lblPingIP)

$txtPingTarget = New-Object System.Windows.Forms.TextBox
$txtPingTarget.Text = "8.8.8.8"; $txtPingTarget.Location = New-Object System.Drawing.Point(520,27)
$txtPingTarget.Size = New-Object System.Drawing.Size(110,22)
$pnlPing.Controls.Add($txtPingTarget)

$btnPing = New-Object System.Windows.Forms.Button
$btnPing.Text = "Ping >"; $btnPing.Location = New-Object System.Drawing.Point(638,26)
$btnPing.Size = New-Object System.Drawing.Size(75,26)
$btnPing.BackColor = [System.Drawing.Color]::FromArgb(39,174,96); $btnPing.ForeColor = "White"
$btnPing.FlatStyle = "Flat"
$pnlPing.Controls.Add($btnPing)

$lblPingResult = New-Object System.Windows.Forms.Label
$lblPingResult.Text = "En attente..."; $lblPingResult.Location = New-Object System.Drawing.Point(720,30)
$lblPingResult.Size = New-Object System.Drawing.Size(250,22)
$lblPingResult.ForeColor = [System.Drawing.Color]::FromArgb(200,220,200)
$lblPingResult.BackColor = [System.Drawing.Color]::FromArgb(26,42,74)
$pnlPing.Controls.Add($lblPingResult)

$btnPing.Add_Click({
    $target = $txtPingTarget.Text.Trim()
    if (-not $target) { return }
    $lblPingResult.Text = "Ping $target..."; $pnlPing.Refresh()
    try {
        $results = 1..4 | ForEach-Object {
            $p = New-Object System.Net.NetworkInformation.Ping
            try { $p.Send($target, 1500) } catch { $null }
        }
        $ok   = @($results | Where-Object { $_ -and $_.Status -eq "Success" })
        $lost = 4 - $ok.Count
        if ($ok.Count -gt 0) {
            $avg = [math]::Round(($ok | Measure-Object RoundtripTime -Average).Average)
            $min = ($ok | Measure-Object RoundtripTime -Minimum).Minimum
            $max = ($ok | Measure-Object RoundtripTime -Maximum).Maximum
            $lblPingResult.Text = "OK : ${avg}ms moy (min ${min} / max ${max}) -- ${lost}/4 perdus"
            $lblPingResult.ForeColor = if ($avg -lt 50) { [System.Drawing.Color]::FromArgb(100,230,100) } else { [System.Drawing.Color]::FromArgb(255,200,80) }
        } else {
            $lblPingResult.Text = "ECHEC -- hote inaccessible"
            $lblPingResult.ForeColor = [System.Drawing.Color]::FromArgb(255,100,100)
        }
    } catch {
        $lblPingResult.Text = "Erreur : $_"
        $lblPingResult.ForeColor = [System.Drawing.Color]::FromArgb(255,150,80)
    }
})

$ySecAcc = $pnlPing.Bottom + 4
$accSec = New-Accordion -Parent $pnlTab4 -Title "Securite" `
    -HdrColor ([System.Drawing.Color]::FromArgb(142,68,173)) `
    -Y $ySecAcc -W $accW -Actions $secActions -CDict ([ref]$Global:SecChk) `
    -ColW $accColW -ColStep $accColStep -ColMargin $accColMargin -RowH $accRowH

# Bouton AdwCleaner direct -- sous l accordeon Securite
$btnAdw = New-Object System.Windows.Forms.Button
$btnAdw.Text      = "AdwCleaner"
$btnAdw.Size      = New-Object System.Drawing.Size(150, 28)
$btnAdw.FlatStyle = "Flat"
$btnAdw.Font      = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$btnAdw.BackColor = [System.Drawing.Color]::FromArgb(142, 68, 173)
$btnAdw.ForeColor = [System.Drawing.Color]::White

$btnAdw.Location = New-Object System.Drawing.Point([int](($accW - $btnAdw.Width)/2), ($accSec.Bottom + 10))
$pnlTab4.Controls.Add($btnAdw)

$btnAdw.Add_Click({
    $btnAdw.Enabled = $false; $btnAdw.Text = "Telechargement en cours..."
    $script:form.Refresh()
    $dest = Join-Path $env:TEMP "adwcleaner.exe"
    try {
        Invoke-CBSafeDownload -Url "https://downloads.malwarebytes.com/file/adwcleaner" -Destination $dest -AllowUnsignedAfterConfirm | Out-Null
        Write-Log "AdwCleaner telecharge : $dest" "Green"
        # Copie sur le bureau
        $bureau = [Environment]::GetFolderPath("Desktop")
        Copy-Item $dest (Join-Path $bureau "AdwCleaner.exe") -Force -ErrorAction SilentlyContinue
        Start-Process $dest
        Write-Log "AdwCleaner lance et copie sur le bureau." "Green"
    } catch {
        Write-Log "[!] Echec telechargement AdwCleaner : $_" "Red"
        [System.Windows.Forms.MessageBox]::Show("Echec du telechargement.`nVerifiez la connexion internet.","AdwCleaner") | Out-Null
    }
    $btnAdw.Text = "AdwCleaner"
    $btnAdw.Enabled = $true
})

# ============================================================
