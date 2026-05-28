# ============================================================
# ONGLET 3 : LOGICIELS
# 7 colonnes, cartes 80px, icone 48px
# Bandeaux categories 22px, tout sur 1 ecran si possible
# ============================================================
$tab3 = New-Object System.Windows.Forms.TabPage
$tab3.Text = " Logiciels "; $tab3.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab3)

$AppsList = @(
    @{ Cat="NAVIGATEUR";  Name="Firefox";           ID="Mozilla.Firefox";                   File="FirefoxInstaller.exe";    Args="/S";                            Url="https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=fr"; Img="firefox.png";     Special=$null }
    @{ Cat="NAVIGATEUR";  Name="Google Chrome";     ID="Google.Chrome";                     File="ChromeSetup.exe";         Args="/silent /install";              Url="https://dl.google.com/chrome/install/ChromeSetup.exe";                      Img="chrome.png";      Special=$null }
    @{ Cat="NAVIGATEUR";  Name="Opera";             ID="Opera.Opera";                       File="OperaSetup.exe";          Args="/silent /allusers=1";           Url=$null;                                                                       Img="opera.png";       Special=$null }
    @{ Cat="MULTIMEDIA";  Name="VLC";               ID="VideoLAN.VLC";                      File="VLC-Setup.exe";           Args="/L=1036 /S";                    Url=$null;                                                                       Img="vlc.png";         Special=$null }
    @{ Cat="MULTIMEDIA";  Name="XnView";            ID="XnSoft.XnViewMP";                   File="XnViewMP-win-x64.exe";    Args="/verysilent";                   Url="https://download.xnview.com/XnViewMP-win-x64.exe";                          Img="xnview.png";      Special=$null }
    @{ Cat="MULTIMEDIA";  Name="GIMP";              ID="GIMP.GIMP";                         File="gimp-setup.exe";          Args="/VERYSILENT /NORESTART";        Url=$null;                                                                       Img="gimp.png";        Special=$null }
    @{ Cat="COMPRESSION"; Name="7-Zip";             ID="7zip.7zip";                         File="7z-setup.exe";            Args="/S";                            Url="https://www.7-zip.org/a/7z2408-x64.exe";                                   Img="7zip.png";        Special=$null }
    @{ Cat="COMPRESSION"; Name="WinRAR";            ID="RARLab.WinRAR";                     File="winrar-x64-720fr.exe";    Args="/S";                            Url="https://www.win-rar.com/fileadmin/winrar-versions/winrar-x64-720fr.exe";    Img="winrar.png";      Special=$null }
    @{ Cat="BUREAUTIQUE"; Name="PDF24";             ID="geeksoftware.PDF24Creator";          File="pdf24-creator-setup.exe"; Args="/VERYSILENT /NORESTART";        Url="https://download.pdf24.org/pdf24-creator-11.30.1-x64.exe";                 Img="pdf24.png";       Special=$null }
    @{ Cat="BUREAUTIQUE"; Name="Adobe Acrobat";     ID="Adobe.Acrobat.Reader.64-bit";       File="";                        Args="";                              Url=$null;                                                                       Img="acrobat.png";     Special="AdobeWinget" }
    @{ Cat="BUREAUTIQUE"; Name="LibreOffice";       ID="TheDocumentFoundation.LibreOffice"; File="LibreOffice-Setup.exe";   Args="/VERYSILENT /NORESTART";        Url=$null;                                                                       Img="libreoffice.png"; Special=$null }
    @{ Cat="BUREAUTIQUE"; Name="Office 365";        ID="Microsoft.Office";                  File="";                        Args="";                              Url=$null;                                                                       Img="office.png";      Special="Office365" }
    @{ Cat="UTILITAIRE";  Name="Notepad++";         ID="Notepad++.Notepad++";               File="npp-setup.exe";           Args="/S";                            Url=$null;                                                                       Img="notepad.png";     Special="NPP" }
    @{ Cat="UTILITAIRE";  Name="Everything";        ID="voidtools.Everything";              File="Everything-Setup.exe";    Args="/S";                            Url="https://www.voidtools.com/Everything-1.4.1.1026.x64-Setup.exe";             Img="everything.png";  Special=$null }
    @{ Cat="UTILITAIRE";  Name="Wise Disk Cleaner"; ID="WiseCleaner.WiseDiskCleaner";       File="WiseDiskCleaner.exe";     Args="/VERYSILENT";                   Url=$null;                                                                       Img="wise.png";        Special=$null }
    @{ Cat="SECURITE";    Name="Malwarebytes";      ID="Malwarebytes.Malwarebytes";         File="MBSetup.exe";             Args="/verysilent";                   Url="https://downloads.malwarebytes.com/file/mb5_offline";                       Img="malwarebytes.png";Special=$null }
    @{ Cat="SECURITE";    Name="Bitdefender";       ID="Bitdefender.Bitdefender";           File="bitdefender_setup.exe";   Args="/quiet";                        Url="https://download.bitdefender.com/windows/installer/en-US/bitdefender_isecurity.exe"; Img="bitdefender.png"; Special=$null }
    @{ Cat="ACCES DIST";  Name="AnyDesk";           ID="AnyDeskSoftwareGmbH.AnyDesk";       File="AnyDesk.exe";             Args="--install `"$env:ProgramFiles\AnyDesk`" --start-with-win --silent"; Url="https://download.anydesk.com/AnyDesk.exe"; Img="anydesk.png"; Special=$null }
    @{ Cat="ACCES DIST";  Name="TeamViewer";        ID="TeamViewer.TeamViewer";             File="TeamViewer_Setup.exe";    Args="/S";                            Url="https://download.teamviewer.com/download/TeamViewer_Setup_x64.exe";         Img="teamviewer.png";  Special=$null }
)

$Global:UninstallCache = $null

# Boutons
$btnT3 = New-Object System.Windows.Forms.Button
$btnT3.Text = "Tout cocher"; $btnT3.Location = New-Object System.Drawing.Point(10,8)
$btnT3.Size = New-Object System.Drawing.Size(110,25); $btnT3.FlatStyle = "Flat"
$btnT3.Add_Click({ $t=($btnT3.Text -eq "Tout cocher"); foreach($c in $Global:AppChk.Values){$c.Checked=$t}; $btnT3.Text=if($t){"Tout decocher"}else{"Tout cocher"} })
$tab3.Controls.Add($btnT3)

$btnAppRefresh = New-Object System.Windows.Forms.Button
$btnAppRefresh.Text = "Actualiser detection"; $btnAppRefresh.Size = New-Object System.Drawing.Size(140,25)
$btnAppRefresh.Location = New-Object System.Drawing.Point(128,8)
$btnAppRefresh.FlatStyle = "Flat"; $btnAppRefresh.Font = New-Object System.Drawing.Font("Segoe UI",8)
$tab3.Controls.Add($btnAppRefresh)

$btnInstBasique = New-Object System.Windows.Forms.Button
$btnInstBasique.Text = "Installation basique CB"
$btnInstBasique.Location = New-Object System.Drawing.Point(278,8); $btnInstBasique.Size = New-Object System.Drawing.Size(170,25)
$btnInstBasique.BackColor = [System.Drawing.Color]::FromArgb(26,42,74); $btnInstBasique.ForeColor = "White"
$btnInstBasique.FlatStyle = "Flat"; $btnInstBasique.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
$tab3.Controls.Add($btnInstBasique)
$btnInstBasique.Add_Click({
    $basique = @("VLC","7-Zip","Firefox","Wise Disk Cleaner")
    foreach ($k in $Global:AppChk.Keys) { $Global:AppChk[$k].Checked = ($k -in $basique) }
    [System.Windows.Forms.MessageBox]::Show("Pack CB : VLC, 7-Zip, Firefox, Wise Disk Cleaner selectionnes.`n`nCliquez LANCER L OPTIMISATION.","Installation basique CB") | Out-Null
})

$panelApps = New-Object System.Windows.Forms.Panel
$panelApps.Location = New-Object System.Drawing.Point(0,40)
$panelApps.Size = New-Object System.Drawing.Size($L["InnerW"],($L["InnerH"]-44))
$panelApps.AutoScroll = $true; $panelApps.BackColor = $Global:BgColor
$tab3.Controls.Add($panelApps)

$Global:AppChk = [ordered]@{}
$PngFolder = Join-Path $scriptDir "png"

# Ordre garanti via [ordered] (PS 5.1 hashtable non ordonne)
$appCatColors = [ordered]@{
    "NAVIGATEUR"  = [System.Drawing.Color]::FromArgb(26,42,74)
    "MULTIMEDIA"  = [System.Drawing.Color]::FromArgb(100,50,160)
    "COMPRESSION" = [System.Drawing.Color]::FromArgb(160,70,10)
    "BUREAUTIQUE" = [System.Drawing.Color]::FromArgb(15,90,55)
    "UTILITAIRE"  = [System.Drawing.Color]::FromArgb(30,80,150)
    "SECURITE"    = [System.Drawing.Color]::FromArgb(150,25,25)
    "ACCES DIST"  = [System.Drawing.Color]::FromArgb(70,70,70)
}

function Build-AppGrid {
    param([bool]$Refresh = $false)
    if ($Refresh) { $Global:UninstallCache=$null; $Global:AppChk.Clear(); $panelApps.Controls.Clear() }
    if (-not $Refresh -and $panelApps.Controls.Count -gt 0) { return }

    # UI 0.77 : cartes logiciels compactes, coherentes avec Bloatwares.
    # Plus de grosses initiales colorees : icone reelle si disponible, sinon marqueur discret.
    $panelApps.BackColor = [System.Drawing.Color]::FromArgb(236,240,246)
    $usableW  = if($tab3.ClientSize.Width -gt 700){ $tab3.ClientSize.Width - 28 } else { $L["InnerW"] - 16 }
    $nCols    = if($usableW -lt 1050){ 2 } elseif($usableW -lt 1400){ 3 } else { 4 }
    $gap      = 10
    $margin   = 10
    $colW     = [int](($usableW - (($nCols-1)*$gap) - (2*$margin)) / $nCols)
    if($colW -lt 270){ $colW = 270 }
    $headerH  = 26
    $cardH    = 44
    $rowGap   = 5
    $iconSz   = 28

    # Grouper les apps par categorie
    $cats = @($appCatColors.Keys)
    $catApps = @{}
    foreach ($cat in $cats) { $catApps[$cat] = [System.Collections.Generic.List[object]]::new() }
    foreach ($App in $AppsList) {
        $cat = if ($App.Cat) { $App.Cat } else { "AUTRE" }
        if ($null -ne $catApps[$cat]) { $catApps[$cat].Add($App) }
    }

    # Distribution des blocs dans les colonnes les moins hautes
    $colY = @()
    for($i=0;$i -lt $nCols;$i++){ $colY += 0 }

    foreach($cat in $cats){
        $items = @($catApps[$cat])
        if($items.Count -eq 0){ continue }
        $ci = 0
        for($i=1;$i -lt $nCols;$i++){ if($colY[$i] -lt $colY[$ci]){ $ci = $i } }
        $xCol = $margin + $ci * ($colW + $gap)
        $yCol = $colY[$ci]
        $ac   = if ($appCatColors.Contains($cat)) { $appCatColors[$cat] } else { $Global:AccentColor }
        $blockH = $headerH + 6 + ($items.Count * ($cardH + $rowGap)) + 8

        $block = New-Object System.Windows.Forms.Panel
        $block.Location = New-Object System.Drawing.Point($xCol,$yCol)
        $block.Size = New-Object System.Drawing.Size($colW,$blockH)
        $block.BackColor = [System.Drawing.Color]::White
        $block.BorderStyle = 'FixedSingle'
        $panelApps.Controls.Add($block)

        $ban = New-Object System.Windows.Forms.Label
        $ban.Text = "  $cat"
        $ban.Location = New-Object System.Drawing.Point(0,0)
        $ban.Size = New-Object System.Drawing.Size($colW,$headerH)
        $ban.BackColor = $ac; $ban.ForeColor = [System.Drawing.Color]::White
        $ban.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
        $ban.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
        $block.Controls.Add($ban)

        $count = New-Object System.Windows.Forms.Label
        $count.Text = "$($items.Count)"
        $count.Size = New-Object System.Drawing.Size(28,16)
        $count.Location = New-Object System.Drawing.Point(($colW-36),5)
        $count.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $count.Font = New-Object System.Drawing.Font("Segoe UI",7,[System.Drawing.FontStyle]::Bold)
        $count.BackColor = [System.Drawing.Color]::FromArgb(40,255,255,255)
        $count.ForeColor = [System.Drawing.Color]::White
        $block.Controls.Add($count)

        $yItem = $headerH + 6
        foreach($App in $items){
            if ($Global:AppChk.Contains($App.Name)) { $yItem += ($cardH + $rowGap); continue }
            $isInst = Test-AppInstalled $App
            $bgDef  = if ($isInst) { [System.Drawing.Color]::FromArgb(245,255,248) } else { [System.Drawing.Color]::FromArgb(248,250,253) }
            $bgSel  = [System.Drawing.Color]::White

            $box = New-Object System.Windows.Forms.Panel
            $box.Size = New-Object System.Drawing.Size(($colW-12),$cardH)
            $box.Location = New-Object System.Drawing.Point(6,$yItem)
            $box.BackColor = $bgDef
            $box.BorderStyle = 'FixedSingle'
            $box.Cursor = [System.Windows.Forms.Cursors]::Hand

            $bar = New-Object System.Windows.Forms.Panel
            $bar.Size = New-Object System.Drawing.Size(4,$cardH)
            $bar.Location = New-Object System.Drawing.Point(0,0)
            $bar.BackColor = $ac

            $imgPath = Join-Path $PngFolder $App.Img
            $img = $null
            if(Test-Path $imgPath){
                $img = New-Object System.Windows.Forms.PictureBox
                try { $img.Image = [System.Drawing.Image]::FromFile($imgPath) } catch { $img = $null }
                if($img){
                    $img.Size = New-Object System.Drawing.Size($iconSz,$iconSz)
                    $img.Location = New-Object System.Drawing.Point(10,8)
                    $img.SizeMode = "Zoom"
                    $img.BackColor = $bgDef
                }
            }
            if(-not $img){
                $img = New-Object System.Windows.Forms.Panel
                $img.Size = New-Object System.Drawing.Size(1,1)
                $img.Location = New-Object System.Drawing.Point(18,20)
                $img.BackColor = $bgDef
                $img.BorderStyle = 'None'
            }

            $lblN = New-Object System.Windows.Forms.Label
            $lblN.Text = $App.Name
            $lblN.Location = New-Object System.Drawing.Point(44,7)
            $lblN.Size = New-Object System.Drawing.Size(($colW-138),16)
            $lblN.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Bold)
            $lblN.ForeColor = [System.Drawing.Color]::FromArgb(35,42,54)
            $lblN.BackColor = $bgDef
            $lblN.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

            $lblSub = New-Object System.Windows.Forms.Label
            $lblSub.Text = if($isInst){"Deja installe"}else{"Pret a installer"}
            $lblSub.Location = New-Object System.Drawing.Point(44,24)
            $lblSub.Size = New-Object System.Drawing.Size(($colW-138),13)
            $lblSub.Font = New-Object System.Drawing.Font("Segoe UI",6.8)
            $lblSub.ForeColor = [System.Drawing.Color]::FromArgb(95,104,116)
            $lblSub.BackColor = $bgDef

            $badge = New-Object System.Windows.Forms.Label
            $badge.Text = if($isInst){"INSTALLE"}else{"DISPO"}
            $badge.Size = New-Object System.Drawing.Size(58,16)
            $badge.Location = New-Object System.Drawing.Point(($colW-76),6)
            $badge.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $badge.Font = New-Object System.Drawing.Font("Segoe UI",6.4,[System.Drawing.FontStyle]::Bold)
            if($isInst){
                $badge.BackColor = [System.Drawing.Color]::FromArgb(218,245,226)
                $badge.ForeColor = [System.Drawing.Color]::FromArgb(0,115,55)
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Detection : $($App.Name) installe" -ForegroundColor Green
            } else {
                $badge.BackColor = [System.Drawing.Color]::FromArgb(232,236,242)
                $badge.ForeColor = [System.Drawing.Color]::FromArgb(90,96,105)
            }

            $selMark = New-Object System.Windows.Forms.Label
            $selMark.Text = [char]0x2713
            $selMark.Visible = $false
            $selMark.Size = New-Object System.Drawing.Size(18,18)
            $selMark.Location = New-Object System.Drawing.Point(($colW-36),24)
            $selMark.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $selMark.Font = New-Object System.Drawing.Font("Segoe UI Symbol",9,[System.Drawing.FontStyle]::Bold)
            $selMark.BackColor = [System.Drawing.Color]::White
            $selMark.ForeColor = [System.Drawing.Color]::FromArgb(24,94,160)

            $chk = New-Object System.Windows.Forms.CheckBox
            $chk.Visible=$false; $chk.Size=New-Object System.Drawing.Size(1,1)
            $Global:AppChk[$App.Name]=$chk

            $applyVisual = {
                param([bool]$Selected)
                $bg = if($Selected){$bgSel}else{$bgDef}
                $box.BackColor=$bg; $lblN.BackColor=$bg; $lblSub.BackColor=$bg
                if($img -is [System.Windows.Forms.PictureBox]){ $img.BackColor=$bg }
                $bar.Width = if($Selected){7}else{4}
                $selMark.Visible = $Selected
            }.GetNewClosure()
            $clickH={
                $chk.Checked=-not $chk.Checked
                & $applyVisual $chk.Checked
                $selectedCount = 0
                foreach($c in $Global:AppChk.Values){ if($c.Checked){ $selectedCount++ } }
                $btnT3.Text = if($selectedCount -eq $Global:AppChk.Count -and $Global:AppChk.Count -gt 0){"Tout decocher"}else{"Tout cocher"}
            }.GetNewClosure()
            foreach ($ctrl in @($box,$img,$lblN,$lblSub,$badge,$selMark)) { if($ctrl){ $ctrl.Add_Click($clickH) } }
            $box.Controls.AddRange(@($bar,$img,$lblN,$lblSub,$badge,$selMark,$chk))
            $block.Controls.Add($box)
            $yItem += ($cardH + $rowGap)
        }
        $colY[$ci] = $yCol + $blockH + $gap
    }

    $maxY = ($colY | Measure-Object -Maximum).Maximum + 20
    $panelApps.AutoScrollMinSize = New-Object System.Drawing.Size(1,[math]::Max(1,$maxY))
} # fin Build-AppGrid

Build-AppGrid
$btnAppRefresh.Add_Click({
    $btnAppRefresh.Enabled=$false; $btnAppRefresh.Text="Scan en cours..."
    $script:form.Refresh(); Build-AppGrid -Refresh $true
    $btnAppRefresh.Text="Actualiser detection"; $btnAppRefresh.Enabled=$true
})
# ============================================================

