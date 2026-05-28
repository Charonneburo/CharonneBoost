# ============================================================
# ONGLET 2 : PURGE BLOATWARES
# Style onglet 1 : cartes horizontales 38px, 2 colonnes
# Groupees par categorie avec bandeau colore
# ============================================================
$tab2 = New-Object System.Windows.Forms.TabPage
$tab2.Text = " Purge Bloatwares "; $tab2.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab2)

$bloatMap = [ordered]@{
    # APPLICATION
    "Outlook New"            = @{ Pkg="Microsoft.OutlookForWindows";                          Cat="APPLICATION"; Desc="Nouvel Outlook integre Windows 11" }
    "Microsoft Teams"        = @{ Pkg="MicrosoftTeams;MSTeams";                              Cat="APPLICATION"; Desc="Teams et toutes ses dependances" }
    "Teams Machine Wide"     = @{ Pkg="*Teams*";                                              Cat="APPLICATION"; Desc="Composant deploiement Teams entreprise" }
    "Clipchamp"              = @{ Pkg="Clipchamp.Clipchamp";                                  Cat="APPLICATION"; Desc="Editeur video Microsoft" }
    "Photos Microsoft"       = @{ Pkg="Microsoft.Windows.Photos;Microsoft.Photos.Image";     Cat="APPLICATION"; Desc="Application Photos Windows 10/11" }
    "Actualites (Bing)"      = @{ Pkg="Microsoft.BingNews";                                  Cat="APPLICATION"; Desc="Flux d actualites Bing" }
    "Microsoft Bing"         = @{ Pkg="Microsoft.BingSearch;Microsoft.Bing";                 Cat="APPLICATION"; Desc="Bing integre Windows 11" }
    "Meteo"                  = @{ Pkg="Microsoft.BingWeather";                               Cat="APPLICATION"; Desc="Application meteo Microsoft" }
    "Cartes (Maps)"          = @{ Pkg="Microsoft.WindowsMaps";                               Cat="APPLICATION"; Desc="Cartographie Microsoft" }
    "Courrier et Calendrier" = @{ Pkg="microsoft.windowscommunicationsapps";                 Cat="APPLICATION"; Desc="Client mail/agenda legacy" }
    "Films et TV"            = @{ Pkg="Microsoft.ZuneVideo";                                 Cat="APPLICATION"; Desc="Lecteur video du Store" }
    "Cortana"                = @{ Pkg="Microsoft.Windows.Cortana;Microsoft.549981C32F157";   Cat="APPLICATION"; Desc="Assistante vocale Microsoft" }
    "Microsoft 365 Copilot"  = @{ Pkg="Microsoft.Copilot;Microsoft.Windows.Ai.Copilot";     Cat="APPLICATION"; Desc="IA Copilot integree Windows 11" }
    "Power Automate"         = @{ Pkg="Microsoft.PowerAutomateDesktop";                      Cat="APPLICATION"; Desc="Automatisation bureau Microsoft" }
    # SYSTEME
    "Feedback Hub / Aide"    = @{ Pkg="Microsoft.WindowsFeedbackHub;Microsoft.GetHelp";      Cat="SYSTEME";     Desc="Rapports de diagnostic Microsoft" }
    "Suggestions / Pubs"     = @{ Pkg="Ads";                                                  Cat="SYSTEME";     Desc="Publicites dans le menu Demarrer" }
    # SOCIAL
    "Facebook"               = @{ Pkg="*Facebook*";                                           Cat="SOCIAL";      Desc="Application Facebook preinstallee" }
    "Instagram"              = @{ Pkg="*Instagram*";                                          Cat="SOCIAL";      Desc="Application Instagram preinstallee" }
    "TikTok"                 = @{ Pkg="*TikTok*";                                             Cat="SOCIAL";      Desc="Application TikTok preinstallee" }
    # JEUX
    "Solitaire Collection"   = @{ Pkg="Microsoft.MicrosoftSolitaireCollection";              Cat="JEUX";        Desc="Jeux de cartes Microsoft" }
    "Xbox (Game Bar)"        = @{ Pkg="Microsoft.GamingApp;Microsoft.Xbox*";                 Cat="JEUX";        Desc="Surcouche gaming Xbox" }
    # STREAMING
    "Netflix"                = @{ Pkg="*Netflix*";                                            Cat="STREAMING";   Desc="Application Netflix preinstallee" }
    "Disney+"                = @{ Pkg="*Disney*";                                             Cat="STREAMING";   Desc="Application Disney+ preinstallee" }
    "Spotify"                = @{ Pkg="*Spotify*";                                            Cat="STREAMING";   Desc="Application Spotify preinstallee" }
}

$Global:AppxCache = $null
function Get-AppxCache {
    if ($Global:AppxCache) { return $Global:AppxCache }
    $Global:AppxCache = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
    return $Global:AppxCache
}

function Test-Bloat($entry) {
    if ($entry.Pkg -eq "Ads") { return $false }
    $cache = Get-AppxCache
    foreach ($id in ($entry.Pkg -split ";")) {
        if ($cache | Where-Object { $_ -like $id.Trim() }) { return $true }
    }
    return $false
}

# Retourne une icone locale si disponible, sinon tente l'icone Appx via AppxManifest.xml.
# Remplace l'ancien script externe bloatware.ps1 : plus besoin d'extraire manuellement les logos.
$Global:BloatIconCache = @{}
function Get-BloatwareIconPath {
    param([string]$Name, $Entry)

    if ($Global:BloatIconCache.ContainsKey($Name)) { return $Global:BloatIconCache[$Name] }

    $pngDir = Join-Path $scriptDir "png"
    $explicitIconMap = @{
        "Outlook New"            = "bloat_outlook.png"
        "Clipchamp"              = "bloat_clipchamp.png"
        "Actualites (Bing)"      = "bloat_bingnews.png"
        "Meteo"                  = "bloat_weather.png"
        "Cartes (Maps)"          = "bloat_maps.png"
        "Courrier et Calendrier" = "bloat_courrier.png"
        "Films et TV"            = "bloat_films.png"
        "Cortana"                = "bloat_cortana.png"
        "Microsoft 365 Copilot"  = "bloat_copilot.png"
        "Feedback Hub / Aide"    = "bloat_feedback.png"
        "Solitaire Collection"   = "bloat_solitaire.png"
        "Xbox (Game Bar)"        = "bloat_xbox.png"
        "Facebook"               = "bloat_facebook.png"
        "Instagram"              = "bloat_instagram.png"
        "TikTok"                 = "bloat_tiktok.png"
        "Netflix"                = "bloat_netflix.png"
        "Disney+"                = "bloat_disney.png"
        "Spotify"                = "bloat_spotify.png"
    }

    $safeName = ($Name.ToLowerInvariant() -replace '[^a-z0-9]+','_').Trim('_')
    $candidates = @()
    if ($explicitIconMap.ContainsKey($Name)) { $candidates += (Join-Path $pngDir $explicitIconMap[$Name]) }
    $candidates += (Join-Path $pngDir ("bloat_{0}.png" -f $safeName))
    $candidates += (Join-Path $pngDir ("{0}.png" -f $safeName))

    foreach($c in $candidates){
        if(Test-Path $c){ $Global:BloatIconCache[$Name] = $c; return $c }
    }

    if($null -eq $Entry -or [string]::IsNullOrWhiteSpace($Entry.Pkg) -or $Entry.Pkg -eq "Ads"){
        $Global:BloatIconCache[$Name] = $null; return $null
    }

    foreach($idRaw in ($Entry.Pkg -split ';')){
        $id = $idRaw.Trim()
        if([string]::IsNullOrWhiteSpace($id)){ continue }
        try {
            $pkg = Get-AppxPackage -AllUsers $id -ErrorAction SilentlyContinue | Select-Object -First 1
            if(-not $pkg -or -not $pkg.InstallLocation){ continue }

            $manifest = Join-Path $pkg.InstallLocation "AppxManifest.xml"
            if(-not (Test-Path $manifest)){ continue }
            [xml]$xml = Get-Content $manifest -ErrorAction SilentlyContinue

            $logoRel = $null
            try { $logoRel = [string]$xml.Package.Properties.Logo } catch {}
            if([string]::IsNullOrWhiteSpace($logoRel)){
                try {
                    $apps = @($xml.Package.Applications.Application)
                    foreach($a in $apps){
                        $ve = $a.VisualElements
                        if($ve -and $ve.Square44x44Logo){ $logoRel = [string]$ve.Square44x44Logo; break }
                        if($ve -and $ve.Logo){ $logoRel = [string]$ve.Logo; break }
                    }
                } catch {}
            }
            if([string]::IsNullOrWhiteSpace($logoRel)){ continue }

            $logoRel = $logoRel -replace '/', '\'
            $basePath = Join-Path $pkg.InstallLocation $logoRel
            $variants = @(
                $basePath,
                ($basePath -replace '\.png$', '.scale-200.png'),
                ($basePath -replace '\.png$', '.scale-150.png'),
                ($basePath -replace '\.png$', '.scale-100.png'),
                ($basePath -replace '\.png$', '.targetsize-256.png'),
                ($basePath -replace '\.png$', '.targetsize-48.png'),
                ($basePath -replace '\.png$', '.targetsize-32.png')
            )
            foreach($v in $variants){
                if(Test-Path $v){ $Global:BloatIconCache[$Name] = $v; return $v }
            }
        } catch {}
    }

    $Global:BloatIconCache[$Name] = $null
    return $null
}


# Boutons barre haute
$btnT2 = New-Object System.Windows.Forms.Button
$btnT2.Text = "Tout cocher"; $btnT2.Location = New-Object System.Drawing.Point(10,8)
$btnT2.Size = New-Object System.Drawing.Size(110,25); $btnT2.FlatStyle = "Flat"
$btnT2.BackColor = [System.Drawing.Color]::FromArgb(34,45,61); $btnT2.ForeColor = [System.Drawing.Color]::White; $btnT2.FlatAppearance.BorderSize = 0
$btnT2.Add_Click({
    $t=($btnT2.Text -eq "Tout cocher")
    foreach($name in $Global:BloatChk.Keys){
        $Global:BloatChk[$name].Checked=$t
        if($Global:BloatPanels.Contains($name)){
            Set-BloatPanelSelected -Panel $Global:BloatPanels[$name] -Selected $t
        }
    }
    $btnT2.Text=if($t){"Tout decocher"}else{"Tout cocher"}
})
$tab2.Controls.Add($btnT2)

$btnBloatRefresh = New-Object System.Windows.Forms.Button
$btnBloatRefresh.Text = "Actualiser detection"; $btnBloatRefresh.Size = New-Object System.Drawing.Size(140,25)
$btnBloatRefresh.Location = New-Object System.Drawing.Point(128,8)
$btnBloatRefresh.FlatStyle = "Flat"; $btnBloatRefresh.Font = New-Object System.Drawing.Font("Segoe UI",8)
$btnBloatRefresh.BackColor = [System.Drawing.Color]::FromArgb(34,45,61); $btnBloatRefresh.ForeColor = [System.Drawing.Color]::White; $btnBloatRefresh.FlatAppearance.BorderSize = 0
$tab2.Controls.Add($btnBloatRefresh)

$panelBloat = New-Object System.Windows.Forms.Panel
$panelBloat.Location = New-Object System.Drawing.Point(0,40)
$panelBloat.Size = New-Object System.Drawing.Size($L["InnerW"],($L["InnerH"]-44))
$panelBloat.AutoScroll = $true; $panelBloat.BackColor = $Global:PanelColor
$tab2.Controls.Add($panelBloat)

$catAccent = @{
    "APPLICATION" = [System.Drawing.Color]::FromArgb(41,128,185)
    "SYSTEME"     = [System.Drawing.Color]::FromArgb(100,60,170)
    "SOCIAL"      = [System.Drawing.Color]::FromArgb(192,57,43)
    "JEUX"        = [System.Drawing.Color]::FromArgb(39,150,70)
    "STREAMING"   = [System.Drawing.Color]::FromArgb(180,80,10)
}

$Global:BloatChk    = [ordered]@{}
$Global:BloatPanels = [ordered]@{}

function Set-BloatPanelSelected {
    param(
        [System.Windows.Forms.Panel]$Panel,
        [bool]$Selected
    )
    if($null -eq $Panel){ return }
    $baseBg = $Panel.Tag
    $bg = if($Selected){ [System.Drawing.Color]::White } else { $baseBg }
    $Panel.BackColor = $bg
    foreach($ctrl in $Panel.Controls){
        if($ctrl -is [System.Windows.Forms.Label]){
            if($ctrl.Name -eq "BloatStatus") { continue }
            if($ctrl.Name -eq "BloatSelectMark") { $ctrl.Visible = $Selected; $ctrl.BackColor = [System.Drawing.Color]::White; continue }
            $ctrl.BackColor = $bg
        } elseif($ctrl -is [System.Windows.Forms.PictureBox]) {
            $ctrl.BackColor = $bg
        } elseif($ctrl -is [System.Windows.Forms.Panel] -and $ctrl.Name -eq "BloatAccent") {
            $ctrl.Width = if($Selected){7}else{4}
        }
    }
}

function Build-BloatGrid {
    param([bool]$Refresh = $false)
    if ($Refresh) {
        $Global:AppxCache = $null
        $panelBloat.Controls.Clear()
        $Global:BloatChk.Clear()
        $Global:BloatPanels.Clear()
    }

    # Layout optimise atelier : 4 colonnes utiles.
    # - APPLICATION est divise en 2 colonnes pour eviter une colonne interminable.
    # - SYSTEME + JEUX sont empiles verticalement dans la meme colonne.
    # - SOCIAL + STREAMING sont empiles verticalement dans la meme colonne.
    # Les boutons du haut restent des boutons de selection, pas des filtres.
    $cats = @("APPLICATION","SYSTEME","SOCIAL","JEUX","STREAMING")
    $colGap   = 8
    $banH     = 22
    $cardH    = 42
    $rowH     = $cardH + 4
    $margin2  = 10
    $usableW  = if($tab2.ClientSize.Width -gt 600){ $tab2.ClientSize.Width - 24 } else { 940 }
    $nColsB   = 4
    $colW     = [int](($usableW - ($nColsB-1)*$colGap - (2*$margin2)) / $nColsB)
    if($colW -lt 190){ $colW = 190 }

    $catItems = @{}
    foreach($cat in $cats){ $catItems[$cat] = [System.Collections.Generic.List[object]]::new() }
    foreach($n in $bloatMap.Keys){
        $e = $bloatMap[$n]
        if($null -ne $catItems[$e.Cat]){ $catItems[$e.Cat].Add(@{Name=$n; Entry=$e}) }
    }

    $appCount = $catItems["APPLICATION"].Count
    $splitAt  = [int][math]::Ceiling($appCount / 2)
    $apps1    = @($catItems["APPLICATION"] | Select-Object -First $splitAt)
    $apps2    = @($catItems["APPLICATION"] | Select-Object -Skip $splitAt)

    $colHeights = @(
        ($banH + 6 + ($apps1.Count * $rowH)),
        ($banH + 6 + ($apps2.Count * $rowH)),
        (($banH + 6 + ($catItems["SYSTEME"].Count * $rowH)) + 10 + ($banH + 6 + ($catItems["JEUX"].Count * $rowH))),
        (($banH + 6 + ($catItems["SOCIAL"].Count * $rowH)) + 10 + ($banH + 6 + ($catItems["STREAMING"].Count * $rowH)))
    )
    $totalH = ($colHeights | Measure-Object -Maximum).Maximum + 20
    $panelBloat.AutoScrollMinSize = New-Object System.Drawing.Size(1,[math]::Max(1,$totalH))

    function Add-BloatColumnGroup {
        param(
            [int]$X,
            [int]$Y,
            [int]$W,
            [string]$Title,
            [object[]]$Items,
            [System.Drawing.Color]$Accent
        )
        $ban = New-Object System.Windows.Forms.Label
        $ban.Text = $Title
        $ban.Location = New-Object System.Drawing.Point($X,$Y)
        $ban.Size = New-Object System.Drawing.Size($W,$banH)
        $ban.BackColor = $Accent
        $ban.ForeColor = [System.Drawing.Color]::White
        $ban.Font = New-Object System.Drawing.Font("Segoe UI",7,[System.Drawing.FontStyle]::Bold)
        $ban.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
        $panelBloat.Controls.Add($ban)

        $yItem = $Y + $banH + 6
        foreach($obj in $Items){
            $name = [string]$obj.Name
            $entry = $obj.Entry
            if($Global:BloatPanels.Contains($name)){ $yItem += $rowH; continue }
            $present = Test-Bloat $entry

            $bgDef = if($present){[System.Drawing.Color]::FromArgb(250,255,250)}else{[System.Drawing.Color]::FromArgb(246,248,251)}
            # Selection volontairement blanche : lisible et coherente avec le reste de l'UI.
            $bgSel = [System.Drawing.Color]::White

            $box = New-Object System.Windows.Forms.Panel
            $box.Size = New-Object System.Drawing.Size($W,$cardH)
            $box.Location = New-Object System.Drawing.Point($X,$yItem)
            $box.BackColor = $bgDef
            $box.Cursor = [System.Windows.Forms.Cursors]::Hand
            $box.BorderStyle = 'FixedSingle'
            $box.Tag = $bgDef

            $bar = New-Object System.Windows.Forms.Panel
            $bar.Name = "BloatAccent"
            $bar.Size = New-Object System.Drawing.Size(4,$cardH)
            $bar.Location = New-Object System.Drawing.Point(0,0)
            $bar.BackColor = $Accent

            $chk = New-Object System.Windows.Forms.CheckBox
            $chk.Visible = $false
            $chk.Size = New-Object System.Drawing.Size(1,1)
            $Global:BloatChk[$name] = $chk

            $iconPath = Get-BloatwareIconPath -Name $name -Entry $entry
            $iconBox = $null
            if($iconPath -and (Test-Path $iconPath)){
                $iconBox = New-Object System.Windows.Forms.PictureBox
                try { $iconBox.Image = [System.Drawing.Image]::FromFile($iconPath) } catch { $iconBox = $null }
                if($iconBox){
                    $iconBox.Size = New-Object System.Drawing.Size(28,28)
                    $iconBox.Location = New-Object System.Drawing.Point(9,7)
                    $iconBox.SizeMode = "Zoom"
                    $iconBox.BackColor = $bgDef
                }
            }
            if(-not $iconBox){
                # Fallback discret : plus de grosse lettre blanche illisible.
                $iconBox = New-Object System.Windows.Forms.Label
                $iconBox.Text = ""
                $iconBox.Size = New-Object System.Drawing.Size(14,14)
                $iconBox.Location = New-Object System.Drawing.Point(16,14)
                $iconBox.BackColor = $Accent
                $iconBox.BorderStyle = 'FixedSingle'
            }

            $lblN = New-Object System.Windows.Forms.Label
            $lblN.Text = $name
            $lblN.Location = New-Object System.Drawing.Point(43,5)
            $lblN.Size = New-Object System.Drawing.Size(($W-118),16)
            $lblN.Font = New-Object System.Drawing.Font("Segoe UI",7.6,[System.Drawing.FontStyle]::Bold)
            $lblN.ForeColor = $Global:FgColor
            $lblN.BackColor = $bgDef
            $lblN.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft

            $lblD = New-Object System.Windows.Forms.Label
            $lblD.Text = $entry.Desc
            $lblD.Location = New-Object System.Drawing.Point(43,23)
            $lblD.Size = New-Object System.Drawing.Size(($W-62),13)
            $lblD.Font = New-Object System.Drawing.Font("Segoe UI",6.6)
            $lblD.ForeColor = [System.Drawing.Color]::FromArgb(80,85,95)
            $lblD.BackColor = $bgDef

            $lblStatus = New-Object System.Windows.Forms.Label
            $lblStatus.Name = "BloatStatus"
            $lblStatus.Text = if($present){ "Present" } else { "Absent" }
            $lblStatus.Size = New-Object System.Drawing.Size(58,16)
            $lblStatus.Location = New-Object System.Drawing.Point(($W-66),5)
            $lblStatus.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $lblStatus.Font = New-Object System.Drawing.Font("Segoe UI",6.6,[System.Drawing.FontStyle]::Bold)
            if($present){
                $lblStatus.BackColor = [System.Drawing.Color]::FromArgb(218,245,226)
                $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(0,115,55)
                Write-Host "[$(Get-Date -Format 'HH:mm:ss')] Detection : $name present" -ForegroundColor Yellow
            } else {
                $lblStatus.BackColor = [System.Drawing.Color]::FromArgb(232,236,242)
                $lblStatus.ForeColor = [System.Drawing.Color]::FromArgb(90,96,105)
            }

            $selMark = New-Object System.Windows.Forms.Label
            $selMark.Name = "BloatSelectMark"
            $selMark.Text = [char]0x2713
            $selMark.Visible = $false
            $selMark.Size = New-Object System.Drawing.Size(18,18)
            $selMark.Location = New-Object System.Drawing.Point(($W-22),22)
            $selMark.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
            $selMark.Font = New-Object System.Drawing.Font("Segoe UI Symbol",9,[System.Drawing.FontStyle]::Bold)
            $selMark.BackColor = [System.Drawing.Color]::White
            $selMark.ForeColor = [System.Drawing.Color]::FromArgb(24,94,160)

            $applyVisual = {
                param([bool]$Selected)
                $bg = if($Selected){$bgSel}else{$bgDef}
                $box.BackColor = $bg
                $lblN.BackColor = $bg
                $lblD.BackColor = $bg
                if($iconBox){ $iconBox.BackColor = $bg }
                $bar.Width = if($Selected){7}else{4}
                $selMark.Visible = $Selected
            }.GetNewClosure()

            $clickH = {
                $chk.Checked = -not $chk.Checked
                & $applyVisual $chk.Checked
                $selectedCount = 0
                foreach($c in $Global:BloatChk.Values){ if($c.Checked){ $selectedCount++ } }
                $btnT2.Text = if($selectedCount -eq $Global:BloatChk.Count -and $Global:BloatChk.Count -gt 0){"Tout decocher"}else{"Tout cocher"}
            }.GetNewClosure()
            foreach($ctrl in @($box,$iconBox,$lblN,$lblD,$lblStatus,$selMark)){ if($ctrl){ $ctrl.Add_Click($clickH) } }

            $box.Controls.AddRange(@($bar,$iconBox,$lblN,$lblD,$lblStatus,$selMark,$chk))
            $panelBloat.Controls.Add($box)
            $Global:BloatPanels[$name] = $box
            $yItem += $rowH
        }
        return $yItem
    }

    $x0 = $margin2
    $x1 = $x0 + $colW + $colGap
    $x2 = $x1 + $colW + $colGap
    $x3 = $x2 + $colW + $colGap

    Add-BloatColumnGroup -X $x0 -Y 0 -W $colW -Title "APPLICATIONS 1" -Items $apps1 -Accent $catAccent["APPLICATION"] | Out-Null
    Add-BloatColumnGroup -X $x1 -Y 0 -W $colW -Title "APPLICATIONS 2" -Items $apps2 -Accent $catAccent["APPLICATION"] | Out-Null

    $ySysEnd = Add-BloatColumnGroup -X $x2 -Y 0 -W $colW -Title "SYSTEME" -Items @($catItems["SYSTEME"]) -Accent $catAccent["SYSTEME"]
    Add-BloatColumnGroup -X $x2 -Y ([int]$ySysEnd + 8) -W $colW -Title "JEUX" -Items @($catItems["JEUX"]) -Accent $catAccent["JEUX"] | Out-Null

    $ySocEnd = Add-BloatColumnGroup -X $x3 -Y 0 -W $colW -Title "SOCIAL" -Items @($catItems["SOCIAL"]) -Accent $catAccent["SOCIAL"]
    Add-BloatColumnGroup -X $x3 -Y ([int]$ySocEnd + 8) -W $colW -Title "STREAM" -Items @($catItems["STREAMING"]) -Accent $catAccent["STREAMING"] | Out-Null
}

Build-BloatGrid

# Boutons de selection par categorie -- NE FILTRENT PAS L'AFFICHAGE
# Ils cochent uniquement les cases de la categorie choisie et gardent toute la liste visible.
$catFilterDefs = [ordered]@{
    "Apps"    = @{ Cat="APPLICATION"; Color=[System.Drawing.Color]::FromArgb(41,128,185) }
    "Systeme" = @{ Cat="SYSTEME";     Color=[System.Drawing.Color]::FromArgb(100,60,170) }
    "Social"  = @{ Cat="SOCIAL";      Color=[System.Drawing.Color]::FromArgb(192,57,43) }
    "Jeux"    = @{ Cat="JEUX";        Color=[System.Drawing.Color]::FromArgb(39,150,70) }
    "Stream"  = @{ Cat="STREAMING";   Color=[System.Drawing.Color]::FromArgb(180,80,10) }
}

# Boutons categorie = TOGGLE : premier clic coche la categorie, second clic la decoche.
# La grille reste visible. Rien ne disparait. Oui, c'etait pourtant le minimum syndical.
$Global:BloatCategoryState = @{}
function Toggle-BloatCategory {
    param([string]$Category)

    if ([string]::IsNullOrWhiteSpace($Category)) { return }
    $currentlyOn = $false
    if ($Global:BloatCategoryState.ContainsKey($Category)) { $currentlyOn = [bool]$Global:BloatCategoryState[$Category] }
    $newState = -not $currentlyOn
    $Global:BloatCategoryState[$Category] = $newState

    foreach ($name in $bloatMap.Keys) {
        if (-not $Global:BloatChk.Contains($name)) { continue }
        $entry = $bloatMap[$name]
        if ($entry.Cat -eq $Category) {
            $Global:BloatChk[$name].Checked = $newState
            if ($Global:BloatPanels.Contains($name)) {
                Set-BloatPanelSelected -Panel $Global:BloatPanels[$name] -Selected $newState
            }
        }
    }

    $selectedCount = 0
    foreach($c in $Global:BloatChk.Values){ if($c.Checked){ $selectedCount++ } }
    $btnT2.Text = if ($selectedCount -eq $Global:BloatChk.Count) { "Tout decocher" } else { "Tout cocher" }
    $panelBloat.Refresh()
}

# 0.77 : les anciens boutons Apps/Systeme/Social/Jeux/Stream sont retires.
# Les sections visuelles suffisent et evitent la double navigation.
# La fonction Toggle-BloatCategory reste disponible pour une future barre d actions compacte.

$btnBloatRefresh.Add_Click({
    $btnBloatRefresh.Enabled=$false; $btnBloatRefresh.Text="Scan en cours..."
    $script:form.Refresh()
    Build-BloatGrid -Refresh $true
    $btnBloatRefresh.Text="Actualiser detection"; $btnBloatRefresh.Enabled=$true
})

# ============================================================
