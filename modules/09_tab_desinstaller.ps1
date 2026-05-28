# ONGLET 8 : DESINSTALLEUR DE LOGICIELS
# ============================================================
$tab8Uninst = New-Object System.Windows.Forms.TabPage
$tab8Uninst.Text = " Desinstaller "; $tab8Uninst.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab8Uninst)

$btnUninstRefresh = New-Object System.Windows.Forms.Button
$btnUninstRefresh.Text = "Actualiser la liste"; $btnUninstRefresh.Location = New-Object System.Drawing.Point(10,8); $btnUninstRefresh.Size = New-Object System.Drawing.Size(140,25)
$btnUninstRefresh.FlatStyle = "Flat"
$tab8Uninst.Controls.Add($btnUninstRefresh)

$txtUninstSearch = New-Object System.Windows.Forms.TextBox
$txtUninstSearch.Location = New-Object System.Drawing.Point(160,8); $txtUninstSearch.Size = New-Object System.Drawing.Size(220,25)
$txtUninstSearch.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$txtUninstSearch.Text = "Rechercher un logiciel..."
$txtUninstSearch.ForeColor = [System.Drawing.Color]::Gray; $txtUninstSearch.BackColor = $Global:PanelColor
$tab8Uninst.Controls.Add($txtUninstSearch)

$btnUninstGo = New-Object System.Windows.Forms.Button
$btnUninstGo.Text = "Desinstaller"; $btnUninstGo.Location = New-Object System.Drawing.Point(($L["TabW"] - 300),8); $btnUninstGo.Size = New-Object System.Drawing.Size(130,25)
$btnUninstGo.BackColor = [System.Drawing.Color]::FromArgb(180,30,30); $btnUninstGo.ForeColor = "White"; $btnUninstGo.FlatStyle = "Flat"
$btnUninstGo.Font = New-Object System.Drawing.Font("Segoe UI", 8.5, [System.Drawing.FontStyle]::Bold)
$tab8Uninst.Controls.Add($btnUninstGo)

$btnWinApps = New-Object System.Windows.Forms.Button
$btnWinApps.Text = "Apps Windows 11"
$btnWinApps.Location = New-Object System.Drawing.Point(($L["TabW"] - 160),8)
$btnWinApps.Size = New-Object System.Drawing.Size(145,25)
$btnWinApps.FlatStyle = "Flat"
$btnWinApps.BackColor = [System.Drawing.Color]::FromArgb(58,90,140)
$btnWinApps.ForeColor = "White"
$btnWinApps.Font = New-Object System.Drawing.Font("Segoe UI", 8, [System.Drawing.FontStyle]::Bold)
$btnWinApps.Add_Click({ Start-Process "ms-settings:appsfeatures" })
$tab8Uninst.Controls.Add($btnWinApps)

$lblUninstCount = New-Object System.Windows.Forms.Label
$lblUninstCount.Text = "Cliquez sur Actualiser pour charger la liste."
$lblUninstCount.Location = New-Object System.Drawing.Point(390,12); $lblUninstCount.Size = New-Object System.Drawing.Size(300,18)
$lblUninstCount.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
$lblUninstCount.ForeColor = [System.Drawing.Color]::FromArgb(100,100,100)
$tab8Uninst.Controls.Add($lblUninstCount)

$lvUninst = New-Object System.Windows.Forms.ListView
$lvUninst.Location = New-Object System.Drawing.Point(10,40); $lvUninst.Size = New-Object System.Drawing.Size(($L["TabW"] - 30),$L["UninstLvH"])
$lvUninst.View = [System.Windows.Forms.View]::Details
$lvUninst.FullRowSelect = $true; $lvUninst.CheckBoxes = $true; $lvUninst.GridLines = $true
$lvUninst.Font = New-Object System.Drawing.Font("Segoe UI", 8.5); $lvUninst.BackColor = $Global:PanelColor; $lvUninst.ForeColor = $Global:FgColor
# Colonnes proportionnelles
$uninstEditW = $L["TabW"] - 30 - 300 - 100 - 110 - 90 - 30
$lvUninst.Columns.Add("Nom du logiciel", 300) | Out-Null
$lvUninst.Columns.Add("Version", 100) | Out-Null
$lvUninst.Columns.Add("Editeur", $uninstEditW) | Out-Null
$lvUninst.Columns.Add("Date", 110) | Out-Null
$lvUninst.Columns.Add("Taille", 90) | Out-Null
$tab8Uninst.Controls.Add($lvUninst)

$Global:UninstallData = @()

function Load-InstalledApps {
    $lvUninst.Items.Clear()
    $lblUninstCount.Text = "Chargement en cours..."
    $tab8Uninst.FindForm().Refresh()
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $apps = @()
    foreach ($rp in $regPaths) {
        $entries = Get-ItemProperty $rp -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName -and $_.DisplayName -notmatch "^KB\d+" -and $_.SystemComponent -ne 1 }
        foreach ($e in $entries) {
            $apps += [PSCustomObject]@{
                Name       = $e.DisplayName
                Version    = if ($e.DisplayVersion) { $e.DisplayVersion } else { "" }
                Publisher  = if ($e.Publisher) { $e.Publisher } else { "" }
                InstallDate= if ($e.InstallDate -and $e.InstallDate -match "^(\d{4})(\d{2})(\d{2})$") {
                                    "$($Matches[3])/$($Matches[2])/$($Matches[1])"
                                } elseif ($e.InstallDate) { $e.InstallDate } else { "" }
                Size       = if ($e.EstimatedSize -and $e.EstimatedSize -gt 0) {
                                if ($e.EstimatedSize -gt 1024) { "$([math]::Round($e.EstimatedSize/1024,1)) Mo" }
                                else { "$($e.EstimatedSize) Ko" }
                             } else { "" }
                UninstStr  = $e.UninstallString
                QuietUnist = $e.QuietUninstallString
            }
        }
    }
    $seen = @{}
    $Global:UninstallData = @()
    foreach ($a in ($apps | Sort-Object Name)) {
        if (!$seen[$a.Name]) { $seen[$a.Name] = $true; $Global:UninstallData += $a }
    }
    foreach ($app in $Global:UninstallData) {
        $item = New-Object System.Windows.Forms.ListViewItem($app.Name)
        $item.SubItems.Add($app.Version) | Out-Null
        $item.SubItems.Add($app.Publisher) | Out-Null
        $item.SubItems.Add($app.InstallDate) | Out-Null
        $item.SubItems.Add($app.Size) | Out-Null
        $item.Tag = $app
        $lvUninst.Items.Add($item) | Out-Null
    }
    $lblUninstCount.Text = "$($lvUninst.Items.Count) logiciels trouves."

}

function Invoke-CBUninstallProcess {
    param(
        [string]$FilePath,
        [string]$Arguments = "",
        [switch]$UseShell
    )
    try {
        if (-not $FilePath) { return $false }
        if ($UseShell) {
            $proc = Start-Process $FilePath -ArgumentList $Arguments -PassThru -ErrorAction SilentlyContinue
        } else {
            $proc = Start-Process $FilePath -ArgumentList $Arguments -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
        }
        if (-not $proc) { return $false }
        while (!$proc.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() }
        return ($proc.ExitCode -eq 0 -or $proc.ExitCode -eq 3010 -or $proc.ExitCode -eq 1605)
    } catch { return $false }
}

function Invoke-CBAppSpecificUninstall {
    param($app)
    $n = $app.Name

    # winget est souvent plus fiable pour les logiciels grand public, quand disponible.
    $winget = (Get-Command winget.exe -ErrorAction SilentlyContinue)
    $wgIds = @()
    if ($n -match '(?i)AnyDesk')       { $wgIds += 'AnyDeskSoftwareGmbH.AnyDesk' }
    if ($n -match '(?i)Everything')    { $wgIds += 'voidtools.Everything' }
    if ($n -match '(?i)TeamViewer')    { $wgIds += 'TeamViewer.TeamViewer' }
    if ($n -match '(?i)Malwarebytes')  { $wgIds += 'Malwarebytes.Malwarebytes' }
    if ($n -match '(?i)Bitdefender')   { $wgIds += 'Bitdefender.Bitdefender' }

    if ($winget -and $wgIds.Count -gt 0) {
        foreach ($id in $wgIds) {
            Write-Log "Tentative winget : $n ($id)" "Cyan"
            if (Invoke-CBUninstallProcess -FilePath "winget.exe" -Arguments "uninstall --id $id --silent --accept-source-agreements --disable-interactivity") { return $true }
        }
        if (Invoke-CBUninstallProcess -FilePath "winget.exe" -Arguments "uninstall --name `"$n`" --silent --accept-source-agreements --disable-interactivity") { return $true }
    }

    # Fallbacks connus. Certains editeurs changent les chemins comme des gobelins sous cafeine.
    $candidates = @()
    if ($n -match '(?i)AnyDesk') {
        $candidates += @(
            @{Path="$env:ProgramFiles\AnyDesk\AnyDesk.exe"; Args='--remove --silent'},
            @{Path="${env:ProgramFiles(x86)}\AnyDesk\AnyDesk.exe"; Args='--remove --silent'}
        )
    }
    if ($n -match '(?i)Everything') {
        $candidates += @(
            @{Path="$env:ProgramFiles\Everything\Uninstall.exe"; Args='/S'},
            @{Path="${env:ProgramFiles(x86)}\Everything\Uninstall.exe"; Args='/S'}
        )
    }
    if ($n -match '(?i)TeamViewer') {
        $candidates += @(
            @{Path="$env:ProgramFiles\TeamViewer\uninstall.exe"; Args='/S'},
            @{Path="${env:ProgramFiles(x86)}\TeamViewer\uninstall.exe"; Args='/S'}
        )
    }
    if ($n -match '(?i)Malwarebytes') {
        $candidates += @(
            @{Path="$env:ProgramFiles\Malwarebytes\Anti-Malware\mbuns.exe"; Args='/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'},
            @{Path="${env:ProgramFiles(x86)}\Malwarebytes\Anti-Malware\mbuns.exe"; Args='/VERYSILENT /SUPPRESSMSGBOXES /NORESTART'}
        )
    }

    foreach ($c in $candidates) {
        if (Test-Path $c.Path) {
            Write-Log "Tentative desinstallation directe : $n" "Cyan"
            if (Invoke-CBUninstallProcess -FilePath $c.Path -Arguments $c.Args) { return $true }
        }
    }

    if ($n -match '(?i)Bitdefender') {
        Write-Log "[!] Bitdefender Agent/Endpoint peut exiger un mot de passe ou l outil officiel Bitdefender. Ouverture de Applications installees conseillee." "Yellow"
    }
    return $false
}

$btnUninstRefresh.Add_Click({ Load-InstalledApps })

$txtUninstSearch.Add_GotFocus({
    if ($txtUninstSearch.ForeColor -eq [System.Drawing.Color]::Gray) {
        $txtUninstSearch.Text = ""; $txtUninstSearch.ForeColor = $Global:FgColor
    }
})
$txtUninstSearch.Add_LostFocus({
    if ($txtUninstSearch.Text -eq "") {
        $txtUninstSearch.Text = "Rechercher un logiciel..."; $txtUninstSearch.ForeColor = [System.Drawing.Color]::Gray; $txtUninstSearch.BackColor = $Global:PanelColor
    }
})
$txtUninstSearch.Add_TextChanged({
    if ($txtUninstSearch.ForeColor -eq [System.Drawing.Color]::Gray) { return }
    $filter = $txtUninstSearch.Text.ToLower()
    $lvUninst.Items.Clear()
    foreach ($app in $Global:UninstallData) {
        if ($filter -and !$app.Name.ToLower().Contains($filter)) { continue }
        $item = New-Object System.Windows.Forms.ListViewItem($app.Name)
        $item.SubItems.Add($app.Version) | Out-Null
        $item.SubItems.Add($app.Publisher) | Out-Null
        $item.SubItems.Add($app.InstallDate) | Out-Null
        $item.SubItems.Add($app.Size) | Out-Null
        $item.Tag = $app
        $lvUninst.Items.Add($item) | Out-Null
    }
    $lblUninstCount.Text = "$($lvUninst.Items.Count) logiciels affiches."
})

$btnUninstGo.Add_Click({
    $checked = @($lvUninst.CheckedItems)
    if ($checked.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Cochez les logiciels a desinstaller.","Desinstaller",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information)
        return
    }
    $names = ($checked | ForEach-Object { $_.Text }) -join "`n"
    $conf = [System.Windows.Forms.MessageBox]::Show(
        "Desinstaller $($checked.Count) logiciel(s) ?`n`n$names`n`nCette action est irreversible.",
        "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo, [System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($conf -ne "Yes") { return }
    $btnUninstGo.Enabled = $false
    foreach ($item in $checked) {
        $app = $item.Tag
        $lblUninstCount.Text = "Desinstallation : $($app.Name)..."
        $tab8Uninst.FindForm().Refresh()
        try {
            $uninstDone = $false

            # ---- CAS SPECIAL : logiciels qui refusent souvent le fallback generique ----
            if ($app.Name -match "(?i)AnyDesk|Everything|Malwarebytes|TeamViewer|Bitdefender") {
                $uninstDone = Invoke-CBAppSpecificUninstall -app $app
            }

            # ---- CAS SPECIAL : Adobe Acrobat (toutes editions) ----
            # Adobe utilise un setup.exe proprietaire OU un GUID MSI selon la version
            if ($app.Name -match "Adobe Acrobat|Adobe Reader") {
                # Methode 1 : GUID MSI direct depuis le registre (le plus fiable)
                if ($app.UninstStr -match '\{[0-9A-Fa-f\-]+\}') {
                    $guid = [regex]::Match($app.UninstStr, '\{[0-9A-Fa-f\-]+\}').Value
                    $proc = Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -PassThru -WindowStyle Hidden -Verb RunAs -ErrorAction SilentlyContinue
                    if ($proc) { while (!$proc.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() } }
                    if ($proc.ExitCode -eq 0) { $uninstDone = $true }
                }
                # Methode 2 : winget (fallback, gere toutes les versions y compris 64-bit)
                if (-not $uninstDone) {
                    $wg = Start-Process "winget" -ArgumentList "uninstall --id Adobe.Acrobat.Reader.64-bit --silent --accept-source-agreements --force" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                    if (-not $wg) { $wg = Start-Process "winget" -ArgumentList "uninstall --name `"$($app.Name)`" --silent --accept-source-agreements" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue }
                    if ($wg) {
                        while (!$wg.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() }
                        $uninstDone = ($wg.ExitCode -eq 0)
                    }
                }
                # Methode 3 : Setup.exe Adobe dans Program Files
                if (-not $uninstDone) {
                    $setupExe = Get-ChildItem "${env:ProgramFiles(x86)}\Adobe","${env:ProgramFiles}\Adobe" -Recurse -Filter "Setup.exe" -ErrorAction SilentlyContinue |
                        Where-Object { $_.FullName -match "Acrobat" } | Select-Object -First 1
                    if ($setupExe) {
                        $proc = Start-Process $setupExe.FullName -ArgumentList "/uninstall /quiet /norestart" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                        if ($proc) { while (!$proc.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() } }
                        $uninstDone = $true
                    }
                }
                if (-not $uninstDone) {
                    Write-Log "[!] Adobe Acrobat : toutes les methodes ont echoue. Desinstallation manuelle requise." "Yellow"
                    $uninstDone = $true   # Eviter le fallback generique
                }
            }
            if ($app.QuietUnist -and !$uninstDone) {
                $proc = Start-Process "cmd.exe" -ArgumentList "/c `"$($app.QuietUnist)`"" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                if ($proc) { while (!$proc.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() } }
                $uninstDone = $true
            }

            # 2. UninstallString MSI -> msiexec /x {GUID} /qn
            if (!$uninstDone -and $app.UninstStr -match "msiexec") {
                # Extraire le GUID du produit
                $guid = [regex]::Match($app.UninstStr, '\{[0-9A-Fa-f\-]+\}').Value
                if ($guid) {
                    $proc = Start-Process "msiexec.exe" -ArgumentList "/x $guid /qn /norestart" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                    if ($proc) { while (!$proc.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() } }
                    $uninstDone = $true
                }
            }

            # 3. UninstallString EXE -> ajouter flag silencieux
            if (!$uninstDone -and $app.UninstStr) {
                $silent     = $app.UninstStr.Trim('"').Trim("'")
                $hasInject  = $silent -match '(?<![/A-Z])&&|\|\||[;<>]'
                $hasExec    = $silent -match '\.(exe|msi|cmd|bat)\b'
                if ($hasExec -and -not $hasInject -and $silent -notmatch "msiexec") {
                    if ($silent -notmatch "/S|/SILENT|/silent|/quiet|/uninstall") { $silent += " /S" }
                    $proc = Start-Process "cmd.exe" -ArgumentList "/c `"$silent`"" -PassThru -WindowStyle Hidden -ErrorAction SilentlyContinue
                    if ($proc) { while (!$proc.HasExited) { Start-Sleep -Milliseconds 300; $tab8Uninst.FindForm().Refresh() } }
                    $uninstDone = $true
                } elseif ($hasInject) {
                    Write-Log "[SECURITE] UninstallString rejete : $($app.Name)" "Red"
                }
            }

            if ($uninstDone) {
                Write-Log "Desinstalle : $($app.Name)" "Green"
            } else {
                Write-Log "[!] Impossible de desinstaller silencieusement : $($app.Name)" "Yellow"
            }
        } catch {
            Write-Log "[!] Echec desinstallation : $($app.Name)" "Red"
        }
    }
    $lblUninstCount.Text = "Desinstallation terminee. Actualisation..."
    Start-Sleep -Milliseconds 500
    Load-InstalledApps
    $btnUninstGo.Enabled = $true
})

# ============================================================
