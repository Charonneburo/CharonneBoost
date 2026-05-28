# ONGLET 6 : DEMARRAGE -- Gestionnaire
# ============================================================
$tab6Start = New-Object System.Windows.Forms.TabPage
$tab6Start.Text = " Demarrage "; $tab6Start.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab6Start)

$btnStartRefresh = New-Object System.Windows.Forms.Button
$btnStartRefresh.Text = "Actualiser"; $btnStartRefresh.Location = New-Object System.Drawing.Point(10,8); $btnStartRefresh.Size = New-Object System.Drawing.Size(90,25)
$tab6Start.Controls.Add($btnStartRefresh)

$btnStartDisable = New-Object System.Windows.Forms.Button
$btnStartDisable.Text = "Desactiver selection"; $btnStartDisable.Location = New-Object System.Drawing.Point(110,8); $btnStartDisable.Size = New-Object System.Drawing.Size(160,25)
$btnStartDisable.BackColor = [System.Drawing.Color]::FromArgb(200,80,30); $btnStartDisable.ForeColor = "White"; $btnStartDisable.FlatStyle = "Flat"
$tab6Start.Controls.Add($btnStartDisable)

$btnStartEnable = New-Object System.Windows.Forms.Button
$btnStartEnable.Text = "Reactiver selection"; $btnStartEnable.Location = New-Object System.Drawing.Point(280,8); $btnStartEnable.Size = New-Object System.Drawing.Size(160,25)
$btnStartEnable.BackColor = [System.Drawing.Color]::FromArgb(15,110,86); $btnStartEnable.ForeColor = "White"; $btnStartEnable.FlatStyle = "Flat"
$tab6Start.Controls.Add($btnStartEnable)

$lblStartInfo = New-Object System.Windows.Forms.Label
$lblStartInfo.Text = "Liste des programmes lances au demarrage de Windows."
$lblStartInfo.Location = New-Object System.Drawing.Point(10,($L["LvH"] + 48)); $lblStartInfo.Size = New-Object System.Drawing.Size(($L["TabW"] - 30),18)
$lblStartInfo.Font = New-Object System.Drawing.Font("Segoe UI",8,[System.Drawing.FontStyle]::Italic)
$lblStartInfo.ForeColor = [System.Drawing.Color]::FromArgb(80,80,80)
$tab6Start.Controls.Add($lblStartInfo)

# ListView
$lvStart = New-Object System.Windows.Forms.ListView
$lvStart.Location = New-Object System.Drawing.Point(10,40); $lvStart.Size = New-Object System.Drawing.Size(($L["TabW"] - 30),$L["LvH"])
$lvStart.View = [System.Windows.Forms.View]::Details
$lvStart.FullRowSelect = $true; $lvStart.CheckBoxes = $true; $lvStart.GridLines = $true
$lvStart.Font = New-Object System.Drawing.Font("Segoe UI", 8.5); $lvStart.BackColor = $Global:PanelColor; $lvStart.ForeColor = $Global:FgColor
# Largeurs colonnes proportionnelles a la fenetre
$colCmd = $L["TabW"] - 30 - 200 - 180 - 90 - 30
$lvStart.Columns.Add("Nom", 200) | Out-Null
$lvStart.Columns.Add("Commande", $colCmd) | Out-Null
$lvStart.Columns.Add("Source", 180) | Out-Null
$lvStart.Columns.Add("Statut", 90) | Out-Null
$tab6Start.Controls.Add($lvStart)

function Load-StartupItems {
    $lvStart.Items.Clear()

    # --- Registre Run actif ---
    $sources = @(
        @{ Key="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";            Label="HKLM Run" }
        @{ Key="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run";            Label="HKCU Run" }
        @{ Key="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce";        Label="HKLM RunOnce" }
        @{ Key="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce";        Label="HKCU RunOnce" }
        @{ Key="HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run"; Label="HKLM Run (32)" }
    )
    foreach ($src in $sources) {
        $props = Get-ItemProperty -Path $src.Key -ErrorAction SilentlyContinue
        if (!$props) { continue }
        foreach ($prop in ($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" })) {
            $item = New-Object System.Windows.Forms.ListViewItem($prop.Name)
            $item.SubItems.Add($prop.Value) | Out-Null
            $item.SubItems.Add($src.Label) | Out-Null
            $item.SubItems.Add("Actif") | Out-Null
            $item.ForeColor = [System.Drawing.Color]::FromArgb(15,110,86)
            $item.Tag = @{ Type="Reg"; RegKey=$src.Key; ValueName=$prop.Name; Statut="Actif" }
            $lvStart.Items.Add($item) | Out-Null
        }
    }

    # --- Registre Run desactive (cle backup) ---
    $disabledKeys = @(
        @{ Key="HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run-disabled"; Label="HKLM Run (desactive)" }
        @{ Key="HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run-disabled"; Label="HKCU Run (desactive)" }
    )
    foreach ($src in $disabledKeys) {
        $props = Get-ItemProperty -Path $src.Key -ErrorAction SilentlyContinue
        if (!$props) { continue }
        foreach ($prop in ($props.PSObject.Properties | Where-Object { $_.Name -notmatch "^PS" })) {
            $item = New-Object System.Windows.Forms.ListViewItem($prop.Name)
            $item.SubItems.Add($prop.Value) | Out-Null
            $item.SubItems.Add($src.Label) | Out-Null
            $item.SubItems.Add("Desactive") | Out-Null
            $item.ForeColor = [System.Drawing.Color]::FromArgb(160,100,0)
            $item.Tag = @{ Type="RegDisabled"; RegKey=$src.Key; ValueName=$prop.Name
                          ActiveKey=($src.Key -replace "-disabled",""); Statut="Desactive" }
            $lvStart.Items.Add($item) | Out-Null
        }
    }

    # --- Dossier Startup (actif et .disabled) ---
    $startupFolders = @(
        @{ Path="$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup";    Label="Startup User" }
        @{ Path="$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"; Label="Startup All" }
    )
    foreach ($sf in $startupFolders) {
        if (!(Test-Path $sf.Path)) { continue }
        foreach ($f in (Get-ChildItem $sf.Path -File -ErrorAction SilentlyContinue)) {
            $isDisabled = $f.Name -like "*.disabled"
            $item = New-Object System.Windows.Forms.ListViewItem($f.Name)
            $item.SubItems.Add($f.FullName) | Out-Null
            $item.SubItems.Add($sf.Label) | Out-Null
            $statut = if ($isDisabled) { "Desactive" } else { "Actif" }
            $item.SubItems.Add($statut) | Out-Null
            $item.ForeColor = if ($isDisabled) { [System.Drawing.Color]::FromArgb(160,100,0) } else { [System.Drawing.Color]::FromArgb(15,110,86) }
            $item.Tag = @{ Type="File"; FilePath=$f.FullName; Statut=$statut }
            $lvStart.Items.Add($item) | Out-Null
        }
    }

    # --- Taches planifiees au demarrage ---
    # Filtrer sur les classes CIM reelles de trigger logon/boot (MSFT_TaskLogonTrigger / MSFT_TaskBootTrigger)
    # et exclure les taches Microsoft systeme (\Microsoft\*) pour ne garder que les taches tierces/utilisateur
    $tasks = Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
        $_.TaskPath -notlike "\Microsoft\*" -and
        ($_.Triggers | Where-Object {
            $_ -is [Microsoft.Management.Infrastructure.CimInstance] -and
            ($_.CimClass.CimClassName -match "LogonTrigger|BootTrigger|MSFT_TaskLogonTrigger|MSFT_TaskBootTrigger")
        })
    }
    foreach ($task in $tasks) {
        $statut = if ($task.State -eq "Disabled") { "Desactive" } else { "Actif" }
        $item = New-Object System.Windows.Forms.ListViewItem($task.TaskName)
        $item.SubItems.Add($task.TaskPath) | Out-Null
        $item.SubItems.Add("Tache planifiee") | Out-Null
        $item.SubItems.Add($statut) | Out-Null
        $item.ForeColor = if ($task.State -eq "Disabled") { [System.Drawing.Color]::FromArgb(160,100,0) } else { [System.Drawing.Color]::FromArgb(26,42,74) }
        $item.Tag = @{ Type="Task"; TaskName=$task.TaskName; TaskPath=$task.TaskPath; Statut=$statut }
        $lvStart.Items.Add($item) | Out-Null
    }

    $actifs   = @($lvStart.Items | Where-Object { $_.SubItems[3].Text -eq "Actif" }).Count
    $desactiv = @($lvStart.Items | Where-Object { $_.SubItems[3].Text -eq "Desactive" }).Count
    $lblStartInfo.Text = "$($lvStart.Items.Count) entrees : $actifs actives (vert) / $desactiv desactivees (orange)"
}

Load-StartupItems

$btnStartRefresh.Add_Click({ Load-StartupItems })

$btnStartDisable.Add_Click({
    $selected = @($lvStart.CheckedItems | Where-Object { $_.Tag.Statut -eq "Actif" })
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Cocher des entrees ACTIVES a desactiver.","Demarrage",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information); return }
    $conf = [System.Windows.Forms.MessageBox]::Show("Desactiver $($selected.Count) entree(s) ?","Confirmation",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
    if ($conf -ne "Yes") { return }
    foreach ($item in $selected) {
        $tag = $item.Tag
        switch ($tag.Type) {
            "Reg" {
                $disKey = $tag.RegKey + "-disabled"
                if (!(Test-Path $disKey)) { New-Item -Path $disKey -Force | Out-Null }
                $val = Get-ItemPropertyValue -Path $tag.RegKey -Name $tag.ValueName -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $disKey -Name $tag.ValueName -Value $val -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $tag.RegKey -Name $tag.ValueName -Force -ErrorAction SilentlyContinue
                Write-Log "Demarrage desactive (registre) : $($item.Text)" "Green"
            }
            "File" {
                $dest = $tag.FilePath + ".disabled"
                Rename-Item $tag.FilePath $dest -ErrorAction SilentlyContinue
                Write-Log "Demarrage desactive (fichier) : $($item.Text)" "Green"
            }
            "Task" {
                Disable-ScheduledTask -TaskName $tag.TaskName -TaskPath $tag.TaskPath -ErrorAction SilentlyContinue | Out-Null
                Write-Log "Tache planifiee desactivee : $($item.Text)" "Green"
            }
        }
    }
    Load-StartupItems
})

$btnStartEnable.Add_Click({
    $selected = @($lvStart.CheckedItems | Where-Object { $_.Tag.Statut -eq "Desactive" })
    if ($selected.Count -eq 0) { [System.Windows.Forms.MessageBox]::Show("Cocher des entrees DESACTIVEES a reactiver.","Demarrage",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information); return }
    foreach ($item in $selected) {
        $tag = $item.Tag
        switch ($tag.Type) {
            "RegDisabled" {
                $val = Get-ItemPropertyValue -Path $tag.RegKey -Name $tag.ValueName -ErrorAction SilentlyContinue
                if (!(Test-Path $tag.ActiveKey)) { New-Item -Path $tag.ActiveKey -Force | Out-Null }
                Set-ItemProperty -Path $tag.ActiveKey -Name $tag.ValueName -Value $val -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path $tag.RegKey -Name $tag.ValueName -Force -ErrorAction SilentlyContinue
                Write-Log "Demarrage reactive (registre) : $($item.Text)" "Green"
            }
            "File" {
                $newPath = $tag.FilePath -replace "\.disabled$", ""
                Rename-Item $tag.FilePath $newPath -ErrorAction SilentlyContinue
                Write-Log "Demarrage reactive (fichier) : $($item.Text)" "Green"
            }
            "Task" {
                Enable-ScheduledTask -TaskName $tag.TaskName -TaskPath $tag.TaskPath -ErrorAction SilentlyContinue | Out-Null
                Write-Log "Tache planifiee reactivee : $($item.Text)" "Green"
            }
        }
    }
    Load-StartupItems
})

# ============================================================
