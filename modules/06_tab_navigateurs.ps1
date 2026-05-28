# ============================================================
# ONGLET 5 : NAVIGATEURS -- Nettoyage + Analyse espace
# Cartes horizontales compactes, analyse via IO.Directory
# ============================================================
$tab5Nav = New-Object System.Windows.Forms.TabPage
$tab5Nav.Text = " Navigateurs "; $tab5Nav.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab5Nav)

$btnNavLaunch = New-Object System.Windows.Forms.Button
$btnNavLaunch.Text = "Nettoyer la selection"
$btnNavLaunch.Location = New-Object System.Drawing.Point(10,8); $btnNavLaunch.Size = New-Object System.Drawing.Size(180,26)
$btnNavLaunch.BackColor = [System.Drawing.Color]::FromArgb(58,90,140); $btnNavLaunch.ForeColor = "White"
$btnNavLaunch.FlatStyle = "Flat"; $btnNavLaunch.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$tab5Nav.Controls.Add($btnNavLaunch)

$btnNavAnalyse = New-Object System.Windows.Forms.Button
$btnNavAnalyse.Text = "Analyser l espace"
$btnNavAnalyse.Location = New-Object System.Drawing.Point(200,8); $btnNavAnalyse.Size = New-Object System.Drawing.Size(155,26)
$btnNavAnalyse.BackColor = [System.Drawing.Color]::FromArgb(39,103,73); $btnNavAnalyse.ForeColor = "White"
$btnNavAnalyse.FlatStyle = "Flat"; $btnNavAnalyse.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$tab5Nav.Controls.Add($btnNavAnalyse)

$lblNavStatus = New-Object System.Windows.Forms.Label
$lblNavStatus.Text = "Selectionnez les elements a nettoyer puis cliquez Nettoyer."
$lblNavStatus.Location = New-Object System.Drawing.Point(365,12); $lblNavStatus.Size = New-Object System.Drawing.Size(600,18)
$lblNavStatus.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
$lblNavStatus.ForeColor = [System.Drawing.Color]::FromArgb(100,100,100)
$tab5Nav.Controls.Add($lblNavStatus)

# ============================================================
# ANALYSE ESPACE -- moteur IO.Directory non bloquant
# ============================================================
function Get-FolderSize([string]$path) {
    if (-not (Test-Path $path)) { return 0L }
    try {
        $total = 0L
        foreach ($f in [System.IO.Directory]::EnumerateFiles($path,"*",[System.IO.SearchOption]::AllDirectories)) {
            try { $total += (New-Object System.IO.FileInfo($f)).Length } catch {}
        }
        return $total
    } catch { return 0L }
}
function Get-FileSize([string]$path) {
    if (-not (Test-Path $path -PathType Leaf)) { return 0L }
    try { return (New-Object System.IO.FileInfo($path)).Length } catch { return 0L }
}
function Format-Size([long]$bytes) {
    if ($bytes -ge 1GB)  { return "$([math]::Round($bytes/1GB,2)) Go" }
    if ($bytes -ge 1MB)  { return "$([math]::Round($bytes/1MB,1)) Mo" }
    if ($bytes -ge 1KB)  { return "$([math]::Round($bytes/1KB,0)) Ko" }
    return "$bytes o"
}

# Chemins par navigateur et type
$navAnalysisDef = [ordered]@{
    "Microsoft Edge" = @{
        Roots   = @("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default")
        Cache   = @("Cache\Cache_Data","Code Cache","GPUCache")
        Cookies = @("Network\Cookies","Cookies")
        History = @("History")
        Sessions= @("Sessions","Session Storage")
    }
    "Google Chrome" = @{
        Roots   = @("$env:LOCALAPPDATA\Google\Chrome\User Data\Default")
        Cache   = @("Cache\Cache_Data","Code Cache","GPUCache")
        Cookies = @("Network\Cookies","Cookies")
        History = @("History")
        Sessions= @("Sessions","Session Storage")
    }
    "Firefox" = @{
        Roots     = @("$env:APPDATA\Mozilla\Firefox\Profiles")
        IsFirefox = $true
    }
    "Opera" = @{
        # Les donnees sont dans Opera Stable\Default\ (comme Chrome/Edge)
        Roots   = @(
            "$env:APPDATA\Opera Software\Opera Stable\Default",
            "$env:APPDATA\Opera Software\Opera GX Stable\Default"
        )
        Cache   = @("Cache\Cache_Data","Code Cache","GPUCache")
        Cookies = @("Network\Cookies","Cookies")
        History = @("History")
        Sessions= @("Sessions","Session Storage")
    }
    "Brave" = @{
        Roots   = @("$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default")
        Cache   = @("Cache\Cache_Data","Code Cache")
        Cookies = @("Network\Cookies","Cookies")
        History = @("History")
        Sessions= @("Sessions","Session Storage")
    }
}

# Compter les cookies dans un fichier SQLite (lecture binaire simple)
function Get-CookieCount([string]$path) {
    if (-not (Test-Path $path -PathType Leaf)) { return 0 }
    try {
        # Les fichiers SQLite Chromium contiennent "cookies" comme nom de table
        # Lecture rapide : compter les occurrences du marqueur de ligne SQLite
        $bytes = [System.IO.File]::ReadAllBytes($path)
        # Chercher la signature de l entete SQLite (SQLite format 3\000)
        if ($bytes.Count -lt 100) { return 0 }
        # Compter les enregistrements : la page 1 offset 28 = nbre de pages
        # Methode simple : taille du fichier / taille record estimee (~200 octets)
        return [math]::Max(0, [int]($bytes.Count / 200))
    } catch { return 0 }
}

$btnNavAnalyse.Add_Click({
    $btnNavAnalyse.Enabled = $false
    $btnNavAnalyse.Text = "Analyse..."
    $lblNavStatus.Text = "Analyse en cours..."; $script:form.Refresh()

    $results = [ordered]@{}
    $totalAll = 0L

    foreach ($navName in $navAnalysisDef.Keys) {
        $def = $navAnalysisDef[$navName]

        if ($def["IsFirefox"]) {
            $ffRoot = $def["Roots"][0]
            if (-not (Test-Path $ffRoot)) { continue }
            $profiles = @(Get-ChildItem $ffRoot -Directory -ErrorAction SilentlyContinue)
            if (-not $profiles) { continue }
            $navRows = @{ Cache=0L; CookieCount=0; Historique=0L; Sessions=0L }
            foreach ($prof in $profiles) {
                $navRows["Cache"]       += Get-FolderSize (Join-Path $prof.FullName "cache2\entries")
                $navRows["CookieCount"] += [math]::Max(0, [int]((Get-FileSize (Join-Path $prof.FullName "cookies.sqlite")) / 150))
                $navRows["Historique"]  += Get-FileSize  (Join-Path $prof.FullName "places.sqlite")
                $navRows["Sessions"]    += Get-FileSize  (Join-Path $prof.FullName "sessionstore.jsonlz4")
                $navRows["Sessions"]    += Get-FolderSize(Join-Path $prof.FullName "sessionstore-backups")
            }
        } else {
            # Trouver toutes les racines existantes
            $roots = @($def["Roots"] | Where-Object { Test-Path $_ })
            if (-not $roots) { continue }

            $navRows = @{ Cache=0L; CookieCount=0; Historique=0L; Sessions=0L }
            foreach ($rootPath in $roots) {
                # Cache
                if ($def["Cache"]) {
                    foreach ($rel in $def["Cache"]) {
                        $full = Join-Path $rootPath $rel
                        if ([System.IO.Directory]::Exists($full)) { $navRows["Cache"] += Get-FolderSize $full }
                    }
                }
                # Cookies -- compter le nombre
                if ($def["Cookies"]) {
                    foreach ($rel in $def["Cookies"]) {
                        $full = Join-Path $rootPath $rel
                        if ([System.IO.File]::Exists($full)) { $navRows["CookieCount"] += Get-CookieCount $full }
                    }
                }
                # Historique
                if ($def["History"]) {
                    foreach ($rel in $def["History"]) {
                        $full = Join-Path $rootPath $rel
                        if ([System.IO.File]::Exists($full)) { $navRows["Historique"] += Get-FileSize $full }
                    }
                }
                # Sessions
                if ($def["Sessions"]) {
                    foreach ($rel in $def["Sessions"]) {
                        $full = Join-Path $rootPath $rel
                        if ([System.IO.Directory]::Exists($full)) { $navRows["Sessions"] += Get-FolderSize $full }
                        elseif ([System.IO.File]::Exists($full))  { $navRows["Sessions"] += Get-FileSize   $full }
                    }
                }
            }
        }

        $navTotal = $navRows["Cache"] + $navRows["Historique"] + $navRows["Sessions"]
        $results[$navName] = @{ Rows=$navRows; Total=$navTotal }
        $totalAll += $navTotal
    }

    $btnNavAnalyse.Enabled = $true; $btnNavAnalyse.Text = "Analyser l espace"

    if ($results.Count -eq 0) {
        $lblNavStatus.Text = "Aucun navigateur detecte ou aucun cache accessible."
        return
    }

    $Global:NavAnalysis = $results
    foreach ($nav in $results.Keys) {
        $d = $results[$nav]
        # Label total
        $keyTotal = "lbl_total_$nav"
        if ($Global:NavSizeLabels.Contains($keyTotal)) {
            $txt = if ($d.Total -gt 0) { Format-Size $d.Total } else { "Cache vide" }
            $Global:NavSizeLabels[$keyTotal].Text = $txt
            $Global:NavSizeLabels[$keyTotal].ForeColor = [System.Drawing.Color]::FromArgb(0,100,180)
        }
        # Labels par type
        $typeMap = @{
            "Cache"       = "Cache"
            "CookieCount" = "Cookies"
            "Historique"  = "Historique"
            "Sessions"    = "Sessions"
        }
        foreach ($rowKey in $typeMap.Keys) {
            $optName = $typeMap[$rowKey]
            $keyType = "lbl_${nav}_${optName}"
            if ($Global:NavSizeLabels.Contains($keyType)) {
                $val = $d.Rows[$rowKey]
                $txt = if ($rowKey -eq "CookieCount") {
                    if ($val -gt 0) { "$val cookies" } else { "0" }
                } else {
                    if ($val -gt 0) { Format-Size $val } else { "-" }
                }
                $Global:NavSizeLabels[$keyType].Text = $txt
                $Global:NavSizeLabels[$keyType].ForeColor = if ($val -gt 0) {
                    [System.Drawing.Color]::FromArgb(0,100,50)
                } else {
                    [System.Drawing.Color]::FromArgb(160,160,160)
                }
            }
        }
    }
    $totalStr = Format-Size $totalAll
    $lblNavStatus.Text = "Analyse terminee -- $totalStr recuperables sur $($results.Count) navigateur(s)."
})

# ============================================================
# CARTES NAVIGATEURS -- compactes horizontales
# ============================================================
$navOptDesc = @{
    "Cache"      = "Fichiers temporaires mis en cache"
    "Cookies"    = "Cookies (connexion, panier...) -- decocher pour garder"
    "Historique" = "Pages visitees et telechargements"
    "Sessions"   = "Onglets et fenetres sauvegardes"
    "Mots de passe" = "Identifiants sauvegardes (irreversible !)"
}

$browserDefs = [ordered]@{
    "Microsoft Edge" = @{ Paths=@("$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default"); Proc="msedge";   Color=[System.Drawing.Color]::FromArgb(0,120,215);   Initial="E" }
    "Google Chrome"  = @{ Paths=@("$env:LOCALAPPDATA\Google\Chrome\User Data\Default");  Proc="chrome";   Color=[System.Drawing.Color]::FromArgb(66,133,244);  Initial="C" }
    "Firefox"        = @{ Paths=@("$env:APPDATA\Mozilla\Firefox\Profiles");              Proc="firefox";  Color=[System.Drawing.Color]::FromArgb(255,95,0);    Initial="F" }
    "Opera"          = @{ Paths=@(
                            "$env:APPDATA\Opera Software\Opera Stable",
                            "$env:APPDATA\Opera Software\Opera GX Stable"
                          ); Proc="opera"; Color=[System.Drawing.Color]::FromArgb(220,30,50); Initial="O" }
    "Brave"          = @{ Paths=@("$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data\Default"); Proc="brave"; Color=[System.Drawing.Color]::FromArgb(255,80,0); Initial="B" }
}

$Global:NavChecks = [ordered]@{}
$Global:NavSizeLabels = [ordered]@{}

foreach ($bname in $browserDefs.Keys) {
    $def = $browserDefs[$bname]
    $def["Installed"] = $def.Paths | Where-Object { Test-Path $_ } | Select-Object -First 1
}

$installedCount = ($browserDefs.Values | Where-Object { $_.Installed }).Count
$lblNavStatus.Text = "$installedCount navigateur(s) detecte(s). Cochez les elements puis cliquez Nettoyer."

$scrollNav = New-Object System.Windows.Forms.Panel
$scrollNav.Location = New-Object System.Drawing.Point(0,40)
$scrollNav.Size = New-Object System.Drawing.Size($L["InnerW"],($L["InnerH"]-44))
$scrollNav.AutoScroll = $true; $scrollNav.BackColor = $Global:BgColor
$tab5Nav.Controls.Add($scrollNav)

$cardY = 0
$navCardW = $L["InnerW"] - 12

foreach ($bname in $browserDefs.Keys) {
    $def = $browserDefs[$bname]
    $isInst = [bool]$def.Installed
    $cardH  = if ($isInst) { $L["NavCardInstalledH"] } else { $L["NavCardMissingH"] }

    $card = New-Object System.Windows.Forms.Panel
    $card.Location = New-Object System.Drawing.Point(6,$cardY)
    $card.Size = New-Object System.Drawing.Size($navCardW,$cardH)
    $card.BackColor = if ($isInst) { [System.Drawing.Color]::White } else { [System.Drawing.Color]::FromArgb(248,248,248) }
    $card.BorderStyle = "FixedSingle"
    $scrollNav.Controls.Add($card)

    # Badge initiale colore
    $badge = New-Object System.Windows.Forms.Label
    $badge.Text = $def.Initial; $badge.Size = New-Object System.Drawing.Size(48,48)
    $badge.Location = New-Object System.Drawing.Point(8,[int](($cardH-48)/2))
    $badge.BackColor = if ($isInst) { $def.Color } else { [System.Drawing.Color]::FromArgb(200,200,200) }
    $badge.ForeColor = "White"
    $badge.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $badge.Font = New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Bold)
    $card.Controls.Add($badge)

    # Nom + statut
    $lblBN = New-Object System.Windows.Forms.Label
    $lblBN.Text = $bname; $lblBN.Location = New-Object System.Drawing.Point(64,8)
    $lblBN.AutoSize = $true
    $lblBN.Font = New-Object System.Drawing.Font("Segoe UI",10,[System.Drawing.FontStyle]::Bold)
    $lblBN.ForeColor = if ($isInst) { $Global:FgColor } else { [System.Drawing.Color]::FromArgb(160,160,160) }
    $card.Controls.Add($lblBN)

    if ($isInst) {
        $lblSt = New-Object System.Windows.Forms.Label
        $lblSt.Text = "Installe"; $lblSt.Location = New-Object System.Drawing.Point(64,28)
        $lblSt.AutoSize = $true
        $lblSt.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
        $lblSt.ForeColor = [System.Drawing.Color]::FromArgb(0,120,50)
        $card.Controls.Add($lblSt)

        # Label taille total (mis a jour par l analyse)
        $lblTotal = New-Object System.Windows.Forms.Label
        $lblTotal.Text = "---"; $lblTotal.Location = New-Object System.Drawing.Point(64,($cardH-18))
        $lblTotal.Size = New-Object System.Drawing.Size(100,14)
        $lblTotal.Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
        $lblTotal.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
        $card.Controls.Add($lblTotal)
        $Global:NavSizeLabels["lbl_total_$bname"] = $lblTotal

        # Options checkboxes en colonnes compactes
        $opts = @("Cache","Cookies","Historique","Sessions","Mots de passe")
        $optX = 170; $optSpacing = [int](($navCardW - 170 - 20) / $opts.Count)
        foreach ($opt in $opts) {
            $key = "$bname|$opt"
            $grpH = $cardH - 14
            $grpOpt = New-Object System.Windows.Forms.Panel
            $grpOpt.Location = New-Object System.Drawing.Point($optX,6)
            $grpOpt.Size = New-Object System.Drawing.Size(($optSpacing-4),$grpH)
            $grpOpt.BackColor = [System.Drawing.Color]::Transparent
            $card.Controls.Add($grpOpt)

            $chk = New-Object System.Windows.Forms.CheckBox
            $chk.Text = $opt; $chk.Location = New-Object System.Drawing.Point(2,2)
            $chk.Size = New-Object System.Drawing.Size(($optSpacing-8),18)
            $chk.Font = New-Object System.Drawing.Font("Segoe UI",8.5,[System.Drawing.FontStyle]::Bold)
            $chk.ForeColor = if ($opt -eq "Mots de passe") { [System.Drawing.Color]::FromArgb(180,30,30) } else { $Global:FgColor }
            # Cookies et Mots de passe decoches par defaut (donnees sensibles)
            $chk.Checked = ($opt -ne "Mots de passe" -and $opt -ne "Cookies")
            $Global:NavChecks[$key] = $chk
            $grpOpt.Controls.Add($chk)

            $lbDesc = New-Object System.Windows.Forms.Label
            $lbDesc.Text = $navOptDesc[$opt]
            $lbDesc.Location = New-Object System.Drawing.Point(2,22)
            $lbDesc.Size = New-Object System.Drawing.Size(($optSpacing-8),14)
            $lbDesc.Font = New-Object System.Drawing.Font("Segoe UI",7,[System.Drawing.FontStyle]::Italic)
            $lbDesc.ForeColor = [System.Drawing.Color]::FromArgb(100,100,100)
            $grpOpt.Controls.Add($lbDesc)

            # Label taille (mis a jour par l analyse, affiche sous la description)
            $lbSz = New-Object System.Windows.Forms.Label
            $lbSz.Text = ""; $lbSz.Location = New-Object System.Drawing.Point(2,38)
            $lbSz.Size = New-Object System.Drawing.Size(($optSpacing-8),13)
            $lbSz.Font = New-Object System.Drawing.Font("Segoe UI",7.5,[System.Drawing.FontStyle]::Bold)
            $lbSz.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
            $grpOpt.Controls.Add($lbSz)
            $Global:NavSizeLabels["lbl_${bname}_${opt}"] = $lbSz

            # Adapter la hauteur du panel option pour inclure le label taille
            $grpOpt.Size = New-Object System.Drawing.Size(($optSpacing-4), ($grpH))

            $optX += $optSpacing
        }
        $cardY += $cardH + 6
    } else {
        $lblSt2 = New-Object System.Windows.Forms.Label
        $lblSt2.Text = "$bname  (non installe)"
        $lblSt2.Location = New-Object System.Drawing.Point(64,[int](($cardH-16)/2))
        $lblSt2.AutoSize = $true; $lblSt2.Font = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Italic)
        $lblSt2.ForeColor = [System.Drawing.Color]::FromArgb(160,160,160)
        $card.Controls.Add($lblSt2)
        $cardY += $cardH + 4
    }
}

# ============================================================
# MOTEUR NETTOYAGE NAVIGATEURS
# ============================================================
$btnNavLaunch.Add_Click({
    $btnNavLaunch.Enabled = $false
    $lblNavStatus.Text = "Nettoyage en cours..."; $scrollNav.FindForm().Refresh()

    foreach ($bname in $browserDefs.Keys) {
        $def = $browserDefs[$bname]
        if (-not $def.Installed) { continue }

        $doCache  = $Global:NavChecks["$bname|Cache"]     -and $Global:NavChecks["$bname|Cache"].Checked
        $doCook   = $Global:NavChecks["$bname|Cookies"]   -and $Global:NavChecks["$bname|Cookies"].Checked
        $doHist   = $Global:NavChecks["$bname|Historique"]-and $Global:NavChecks["$bname|Historique"].Checked
        $doSess   = $Global:NavChecks["$bname|Sessions"]  -and $Global:NavChecks["$bname|Sessions"].Checked
        $doPass   = $Global:NavChecks["$bname|Mots de passe"] -and $Global:NavChecks["$bname|Mots de passe"].Checked

        if (-not ($doCache -or $doCook -or $doHist -or $doSess -or $doPass)) { continue }

        # Fermer le navigateur
        Stop-Process -Name $def.Proc -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 800

        $bases = $def.Paths | Where-Object { Test-Path $_ }

        foreach ($base in $bases) {
            if ($bname -eq "Firefox") {
                $profiles = @(Get-ChildItem $base -Directory -ErrorAction SilentlyContinue)
                foreach ($prof in $profiles) {
                    if ($doCache) { Remove-Item (Join-Path $prof.FullName "cache2\entries\*") -Recurse -Force -EA SilentlyContinue }
                    if ($doCook)  { Remove-Item (Join-Path $prof.FullName "cookies.sqlite")  -Force -EA SilentlyContinue }
                    if ($doHist)  { Remove-Item (Join-Path $prof.FullName "places.sqlite")   -Force -EA SilentlyContinue }
                    if ($doSess) {
                        Remove-Item (Join-Path $prof.FullName "sessionstore.jsonlz4") -Force -EA SilentlyContinue
                        $sbDir = Join-Path $prof.FullName "sessionstore-backups"
                        if (Test-Path $sbDir) { Remove-Item $sbDir -Recurse -Force -EA SilentlyContinue }
                    }
                }
            } else {
                if ($doCache) {
                    foreach ($p in @("Cache\Cache_Data","Code Cache","GPUCache")) {
                        Remove-Item (Join-Path $base $p) -Recurse -Force -EA SilentlyContinue
                    }
                }
                if ($doCook) {
                    Remove-Item (Join-Path $base "Cookies")         -Force -EA SilentlyContinue
                    Remove-Item (Join-Path $base "Network\Cookies") -Force -EA SilentlyContinue
                }
                if ($doHist) { Remove-Item (Join-Path $base "History") -Force -EA SilentlyContinue }
                if ($doSess) {
                    Remove-Item (Join-Path $base "Sessions")         -Recurse -Force -EA SilentlyContinue
                    Remove-Item (Join-Path $base "Session Storage")  -Recurse -Force -EA SilentlyContinue
                }
                if ($doPass) { Remove-Item (Join-Path $base "Login Data") -Force -EA SilentlyContinue }
            }
        }
        Write-Log "Navigateur nettoye : $bname" "Green"
        $lblNavStatus.Text = "Nettoye : $bname"; $scrollNav.FindForm().Refresh()
    }

    $btnNavLaunch.Enabled = $true
    $lblNavStatus.Text = "Nettoyage termine."
})
# ============================================================
