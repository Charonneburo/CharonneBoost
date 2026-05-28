# ONGLET 7 : DIAGNOSTIC SYSTEME
# ============================================================
$tab7Diag = New-Object System.Windows.Forms.TabPage
$tab7Diag.Text = " Diagnostic "; $tab7Diag.BackColor = $Global:PanelColor
$tabControl.TabPages.Add($tab7Diag)

$btnDiagRun = New-Object System.Windows.Forms.Button
$btnDiagRun.Text = "Lancer le diagnostic"
$btnDiagRun.Location = New-Object System.Drawing.Point(10,8); $btnDiagRun.Size = New-Object System.Drawing.Size(170,25)
$btnDiagRun.BackColor = [System.Drawing.Color]::FromArgb(58,90,140); $btnDiagRun.ForeColor = "White"; $btnDiagRun.FlatStyle = "Flat"
$tab7Diag.Controls.Add($btnDiagRun)

$btnDiagHTML = New-Object System.Windows.Forms.Button
$btnDiagHTML.Text = "Exporter en HTML"
$btnDiagHTML.Location = New-Object System.Drawing.Point(190,8); $btnDiagHTML.Size = New-Object System.Drawing.Size(150,25)
$btnDiagHTML.FlatStyle = "Flat"; $btnDiagHTML.Enabled = $false
$tab7Diag.Controls.Add($btnDiagHTML)

$btnFiabilite = New-Object System.Windows.Forms.Button
$btnFiabilite.Text = "Moniteur de fiabilite"
$btnFiabilite.Location = New-Object System.Drawing.Point(350,8); $btnFiabilite.Size = New-Object System.Drawing.Size(160,25)
$btnFiabilite.FlatStyle = "Flat"
$btnFiabilite.Add_Click({ Start-Process "perfmon.exe" -ArgumentList "/rel" })
$tab7Diag.Controls.Add($btnFiabilite)

$btnFiabiliteHTML = New-Object System.Windows.Forms.Button
$btnFiabiliteHTML.Text = "Rapport fiabilite HTML"
$btnFiabiliteHTML.Location = New-Object System.Drawing.Point(520,8); $btnFiabiliteHTML.Size = New-Object System.Drawing.Size(170,25)
$btnFiabiliteHTML.FlatStyle = "Flat"
$tab7Diag.Controls.Add($btnFiabiliteHTML)

# Zone de resultats
$rtDiag = New-Object System.Windows.Forms.RichTextBox
$rtDiag.Location = New-Object System.Drawing.Point(10,42); $rtDiag.Size = New-Object System.Drawing.Size(($L["TabW"] - 30),$L["DiagBoxH"])
$rtDiag.Font = New-Object System.Drawing.Font("Consolas",9)
$rtDiag.BackColor = [System.Drawing.Color]::FromArgb(30,30,30); $rtDiag.ForeColor = [System.Drawing.Color]::FromArgb(200,220,200)
$rtDiag.ReadOnly = $true; $rtDiag.BorderStyle = "None"
$tab7Diag.Controls.Add($rtDiag)

$Global:DiagData = @{}

function Add-DiagLine($text, $color = "White") {
    $rtDiag.SelectionStart = $rtDiag.TextLength
    $rtDiag.SelectionLength = 0
    switch ($color) {
        "Green"  { $rtDiag.SelectionColor = [System.Drawing.Color]::FromArgb(100,220,100) }
        "Yellow" { $rtDiag.SelectionColor = [System.Drawing.Color]::FromArgb(255,210,80) }
        "Red"    { $rtDiag.SelectionColor = [System.Drawing.Color]::FromArgb(255,100,100) }
        "Cyan"   { $rtDiag.SelectionColor = [System.Drawing.Color]::FromArgb(100,200,255) }
        "Gray"   { $rtDiag.SelectionColor = [System.Drawing.Color]::FromArgb(150,150,150) }
        default  { $rtDiag.SelectionColor = [System.Drawing.Color]::FromArgb(200,220,200) }
    }
    $rtDiag.AppendText("$text`n")
}

$btnDiagRun.Add_Click({
    $btnDiagRun.Enabled = $false
    $rtDiag.Clear()
    $Global:DiagData = @{}

    Add-DiagLine "================================================" "Cyan"
    Add-DiagLine "  CHARONNE BOOST v12.1 -- Rapport de diagnostic" "Cyan"
    Add-DiagLine "  $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" "Gray"
    Add-DiagLine "================================================" "Cyan"
    Add-DiagLine ""

    # Systeme
    Add-DiagLine "[ SYSTEME ]" "Yellow"
    $cs   = Get-CimInstance Win32_ComputerSystem        -ErrorAction SilentlyContinue
    $csp  = Get-CimInstance Win32_ComputerSystemProduct -ErrorAction SilentlyContinue
    $os   = Get-CimInstance Win32_OperatingSystem       -ErrorAction SilentlyContinue
    $bios = Get-CimInstance Win32_BIOS                  -ErrorAction SilentlyContinue
    $mb   = Get-CimInstance Win32_BaseBoard             -ErrorAction SilentlyContinue

    # Modele machine -- 3 sources par ordre de fiabilite :
    # 1. Registre BIOS (toujours ecrit par le firmware, y compris laptops)
    # 2. Win32_ComputerSystemProduct (nom commercial constructeur)
    # 3. Win32_ComputerSystem (fallback)
    $biosReg      = Get-ItemProperty "HKLM:\HARDWARE\DESCRIPTION\System\BIOS" -ErrorAction SilentlyContinue
    $genericNames = @("System Product Name","To Be Filled By O.E.M.","To Be Filled","Default string",
                      "INVALID","N/A","None","All Series","Not Specified","OEM","OEMSB","",
                      "System manufacturer","System Product Name","Standard PC")

    $machineModel = $null

    # Source 1 : registre HKLM\HARDWARE\DESCRIPTION\System\BIOS\SystemProductName
    if ($biosReg) {
        $bRegName = $biosReg.SystemProductName.Trim()
        $bRegMfr  = if ($biosReg.SystemManufacturer) { $biosReg.SystemManufacturer.Trim() } else { "" }
        if ($bRegName -and $bRegName -notin $genericNames -and $bRegName -notmatch "^(To Be|Default|INVALID|OEM)") {
            $machineModel = if ($bRegMfr -and $bRegMfr -notin $genericNames) { "$bRegMfr $bRegName" } else { $bRegName }
            $machineModel = $machineModel.Trim() -replace "\s{2,}"," "
        }
    }
    # Source 2 : Win32_ComputerSystemProduct
    if (-not $machineModel -and $csp -and $csp.Name.Trim() -notin $genericNames) {
        $machineModel = "$($csp.Vendor) $($csp.Name)".Trim()
    }
    # Source 3 : Win32_ComputerSystem
    if (-not $machineModel -and $cs -and $cs.Model.Trim() -notin $genericNames) {
        $machineModel = "$($cs.Manufacturer) $($cs.Model)".Trim()
    }
    if (-not $machineModel) { $machineModel = "PC assemble (firmware ne renseigne pas le modele)" }

    $mbModel = if ($mb) { "$($mb.Manufacturer) $($mb.Product)".Trim() } else { "N/A" }

    $biosVersion = "$($bios.Manufacturer) v$($bios.SMBIOSBIOSVersion)".Trim()
    # ReleaseDate : objet DateTime en CIM ou string DMTF "20230415000000.000000+000"
    $biosDate = try {
        $rd = $bios.ReleaseDate
        if ($rd -is [datetime])       { $rd.ToString('dd/MM/yyyy') }
        elseif ($rd -is [string] -and $rd.Length -ge 8) {
            [datetime]::ParseExact($rd.Substring(0,8),'yyyyMMdd',$null).ToString('dd/MM/yyyy')
        } else { "N/A" }
    } catch { "N/A" }

    # Version Windows complete : registre CurrentVersion (plus fiable que CIM)
    $regWin = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion" -ErrorAction SilentlyContinue
    $winDisplayVer = if ($regWin.DisplayVersion) { $regWin.DisplayVersion } else { $regWin.ReleaseId }
    $winBuild      = if ($regWin.CurrentBuildNumber -and $regWin.UBR) { "$($regWin.CurrentBuildNumber).$($regWin.UBR)" } else { $os.BuildNumber }
    $winEdition    = $os.Caption -replace "Microsoft Windows ?", "" -replace "\s+", " "

    $Global:DiagData["Machine"]       = $machineModel
    $Global:DiagData["Carte mere"]    = $mbModel
    $Global:DiagData["OS"]            = "$winEdition $winDisplayVer (Build $winBuild)"
    $Global:DiagData["Architecture"]  = $os.OSArchitecture
    $Global:DiagData["Nom machine"]   = $env:COMPUTERNAME
    $Global:DiagData["BIOS"]          = "$biosVersion (date: $biosDate)"

    Add-DiagLine "  Machine      : $machineModel"
    Add-DiagLine "  Carte mere   : $mbModel"
    Add-DiagLine "  OS           : $winEdition $winDisplayVer (Build $winBuild)"
    Add-DiagLine "  Architecture : $($os.OSArchitecture)"
    Add-DiagLine "  Nom machine  : $env:COMPUTERNAME"
    Add-DiagLine "  BIOS         : $biosVersion"
    Add-DiagLine "  Date BIOS    : $biosDate"
    Add-DiagLine ""

    # CPU
    Add-DiagLine "[ PROCESSEUR ]" "Yellow"
    $cpuAll = @(Get-CimInstance Win32_Processor -ErrorAction SilentlyContinue)
    $cpu    = if ($cpuAll.Count -gt 0) { $cpuAll[0] } else { $null }
    # Moyenne de charge sur tous les sockets (evite System.Object[] sur machines multi-CPU)
    $cpuLoadRaw = @($cpuAll | Where-Object { $_.LoadPercentage -ne $null } | ForEach-Object { $_.LoadPercentage })
    $cpuLoad    = if ($cpuLoadRaw.Count -gt 0) { [int](($cpuLoadRaw | Measure-Object -Average).Average) } else { 0 }
    $Global:DiagData["CPU"]       = if ($cpu) { $cpu.Name } else { "Inconnu" }
    $Global:DiagData["CPU Coeurs"]= if ($cpu) { "$($cpu.NumberOfCores) coeurs / $($cpu.NumberOfLogicalProcessors) threads" } else { "N/A" }
    $cpuColor = if ($cpuLoad -gt 80) { "Red" } elseif ($cpuLoad -gt 50) { "Yellow" } else { "Green" }
    Add-DiagLine "  Modele    : $($Global:DiagData['CPU'])"
    Add-DiagLine "  Coeurs    : $($Global:DiagData['CPU Coeurs'])"
    Add-DiagLine "  Charge    : $cpuLoad % $(if ($cpuAll.Count -gt 1) { '(moyenne ' + $cpuAll.Count + ' sockets)' })" $cpuColor
    Add-DiagLine ""

    # RAM -- detail par slot
    Add-DiagLine "[ MEMOIRE RAM ]" "Yellow"
    $ramTotal = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
    $ramFree  = [math]::Round($os.FreePhysicalMemory / 1MB, 1)
    $ramUsed  = [math]::Round($ramTotal - $ramFree, 1)
    $ramPct   = [math]::Round($ramUsed / $ramTotal * 100)
    $ramColor = if ($ramPct -gt 85) { "Red" } elseif ($ramPct -gt 65) { "Yellow" } else { "Green" }
    $Global:DiagData["RAM Total"]    = "${ramTotal} Go"
    $Global:DiagData["RAM Utilisee"] = "${ramUsed} Go ($ramPct%)"
    Add-DiagLine "  Total     : $ramTotal Go"
    Add-DiagLine "  Utilisee  : $ramUsed Go ($ramPct%)" $ramColor
    Add-DiagLine "  Libre     : $ramFree Go"
    Add-DiagLine ""

    # Detail par barrette (Win32_PhysicalMemory)
    $slots = @(Get-CimInstance Win32_PhysicalMemory -ErrorAction SilentlyContinue)
    # Nombre total de slots (Win32_PhysicalMemoryArray)
    $slotArray = Get-CimInstance Win32_PhysicalMemoryArray -ErrorAction SilentlyContinue | Select-Object -First 1
    $totalSlots = if ($slotArray) { $slotArray.MemoryDevices } else { "?" }
    $usedSlots  = ($slots | Where-Object { $_.Capacity -gt 0 }).Count
    Add-DiagLine "  Slots      : $usedSlots utilise(s) / $totalSlots total" $(if($usedSlots -eq $totalSlots){"Yellow"}else{"Green"})

    if ($slots.Count -gt 0) {
        Add-DiagLine "  Detail par barrette :" "Cyan"
        foreach ($s in $slots) {
            if (-not $s.Capacity) { continue }
            $cap  = [math]::Round($s.Capacity / 1GB, 0)
            $freq = if ($s.ConfiguredClockSpeed) { "$($s.ConfiguredClockSpeed) MHz" } elseif ($s.Speed) { "$($s.Speed) MHz" } else { "? MHz" }
            $mfr  = if ($s.Manufacturer) { $s.Manufacturer.Trim() } else { "?" }
            $part = if ($s.PartNumber)    { $s.PartNumber.Trim()    } else { "?" }
            $slot = if ($s.DeviceLocator) { $s.DeviceLocator.Trim() } else { "?" }
            $bank = if ($s.BankLabel)     { $s.BankLabel.Trim()     } else { "" }

            # Type memoire : 26=DDR4, 34=DDR5, 24=DDR3, 22=DDR2, 20=DDR, 12=SDRAM
            # SMBIOSMemoryType est plus fiable que MemoryType sur la plupart des firmwares
            $memType = switch ($s.SMBIOSMemoryType) {
                34 { "DDR5" } 26 { "DDR4" } 24 { "DDR3" } 22 { "DDR2" } 20 { "DDR" } 18 { "DDR3" }
                default {
                    switch ($s.MemoryType) {
                        34 { "DDR5" } 26 { "DDR4" } 24 { "DDR3" } 22 { "DDR2" } 20 { "DDR" }
                        default {
                            # Fallback vitesse : >= 4800 MHz => DDR5, >= 2133 => DDR4, sinon DDR3
                            $spd = if ($s.ConfiguredClockSpeed -gt 0) { $s.ConfiguredClockSpeed } else { $s.Speed }
                            if ($spd -ge 4800) { "DDR5" } elseif ($spd -ge 2133) { "DDR4" } elseif ($spd -ge 800) { "DDR3" } else { "?" }
                        }
                    }
                }
            }

            # Tension et CL (pas directement dispo via WMI standard -- afficher si disponible)
            $volt = if ($s.ConfiguredVoltage) { "$([math]::Round($s.ConfiguredVoltage/1000.0,2))V" } else { "" }

            $line = "    [$slot$(if($bank){" / $bank"})] ${cap} Go $memType $freq"
            if ($mfr -ne "?")  { $line += " | $mfr" }
            if ($part -ne "?") { $line += " | $part" }
            if ($volt)         { $line += " | $volt" }
            Add-DiagLine $line "White"
            $Global:DiagData["RAM $slot"] = "$cap Go $memType $freq $mfr"
        }
    }
    Add-DiagLine ""

    # Disques -- detail technique par disque physique
    Add-DiagLine "[ DISQUES PHYSIQUES ]" "Yellow"
    try {
        $physDisks = @(Get-CimInstance -Namespace "root/Microsoft/Windows/Storage" `
                        -ClassName MSFT_PhysicalDisk `
                        -Property DeviceId,FriendlyName,MediaType,BusType,Size,HealthStatus,OperationalStatus,Manufacturer,Model,SpindleSpeed `
                        -OperationTimeoutSec 5 -ErrorAction SilentlyContinue)

        if ($physDisks.Count -gt 0) {
            foreach ($pd in ($physDisks | Sort-Object DeviceId)) {
                $szGB = if ($pd.Size) { [math]::Round($pd.Size / 1GB, 0) } else { "?" }

                # Interface / Type
                $busStr = switch ($pd.BusType) {
                    17 { "NVMe (PCIe)"   }
                    11 { "SATA"          }
                    10 { "SAS"           }
                     8 { "USB"           }
                     7 { "USB"           }
                     6 { "SATA"          }
                     3 { "ATA"           }
                    default { "Bus $($pd.BusType)" }
                }
                $mediaStr = switch ($pd.MediaType) {
                    4 { "SSD"   }
                    3 { "HDD"   }
                    5 { "SCM"   }
                    default { "?" }
                }
                # Determiner le format physique (M.2, mSATA, 2.5", 3.5")
                $formFactor = ""
                $modelName  = if ($pd.FriendlyName) { $pd.FriendlyName.Trim() } else { "?" }
                if ($pd.BusType -eq 17) {
                    $formFactor = "M.2 NVMe"
                } elseif ($modelName -match "M\.2|M2|2280|2242|2260|22110") {
                    $formFactor = "M.2 SATA"
                } elseif ($modelName -match "mSATA|mini.?SATA") {
                    $formFactor = "mSATA"
                } elseif ($pd.BusType -eq 11 -or $pd.BusType -eq 6) {
                    $formFactor = if ($mediaStr -eq "SSD") { "2.5 SATA" } else { "3.5 SATA" }
                }

                # Sante
                $healthStr = switch ($pd.HealthStatus) {
                    0 { "Sain" } 1 { "Avertissement" } 2 { "Defaillant" } default { "?" }
                }
                $healthColor = switch ($pd.HealthStatus) { 0{"Green"} 1{"Yellow"} 2{"Red"} default{"Gray"} }

                # Vitesse rotation (HDD)
                $rpmStr = if ($pd.SpindleSpeed -and $pd.SpindleSpeed -gt 0 -and $pd.SpindleSpeed -ne 4294967295) {
                    " | $($pd.SpindleSpeed) tr/min"
                } else { "" }

                $typeLabel = if ($formFactor) { "$mediaStr $formFactor" } else { "$mediaStr $busStr" }
                Add-DiagLine "  Disque $($pd.DeviceId) : $modelName" "Cyan"
                Add-DiagLine "    Type      : $typeLabel$rpmStr"
                Add-DiagLine "    Capacite  : $szGB Go"
                Add-DiagLine "    Interface : $busStr"
                Add-DiagLine "    Sante     : $healthStr" $healthColor
                $Global:DiagData["Disque physique $($pd.DeviceId)"] = "$modelName | $typeLabel | $szGB Go | $healthStr"
                Add-DiagLine ""
            }
        } else { throw "MSFT_PhysicalDisk vide" }
    } catch {
        # Fallback Win32_DiskDrive
        $wmiDisks = @(Get-CimInstance Win32_DiskDrive -ErrorAction SilentlyContinue)
        foreach ($wd in $wmiDisks) {
            $szGB  = [math]::Round($wd.Size / 1GB, 0)
            $model = $wd.Model.Trim()
            $typeGuess = if ($model -match "NVMe|PCIe")    { "SSD NVMe M.2" }
                         elseif ($model -match "SSD|Solid") { "SSD SATA"     }
                         elseif ($model -match "M\.2")      { "M.2 SATA"     }
                         else                               { "HDD"          }
            Add-DiagLine "  $model" "Cyan"
            Add-DiagLine "    Type     : $typeGuess"
            Add-DiagLine "    Capacite : $szGB Go"
            $Global:DiagData["Disque $($wd.Index)"] = "$model | $typeGuess | $szGB Go"
            Add-DiagLine ""
        }
    }

    # Partitions logiques (espace libre)
    Add-DiagLine "[ PARTITIONS ]" "Yellow"
    $logDisks = Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" -ErrorAction SilentlyContinue
    foreach ($d in $logDisks) {
        if (-not $d.Size -or $d.Size -lt 10MB) { continue }   # Ignorer partitions EFI/Recovery (< 10 Mo)
        $total = [math]::Round($d.Size / 1GB, 1)
        $free  = [math]::Round($d.FreeSpace / 1GB, 1)
        $pct   = [math]::Round(($d.Size - $d.FreeSpace) / $d.Size * 100)
        $dColor = if ($pct -gt 90) { "Red" } elseif ($pct -gt 75) { "Yellow" } else { "Green" }
        $Global:DiagData["Partition $($d.DeviceID)"] = "${total} Go / ${free} Go libre"
        Add-DiagLine "  $($d.DeviceID)  $total Go | libre: $free Go | utilise: $pct%" $dColor
    }
    Add-DiagLine ""

    # Reseau
    Add-DiagLine "[ RESEAU ]" "Yellow"
    $adapters = Get-CimInstance Win32_NetworkAdapterConfiguration -Filter "IPEnabled=True" -ErrorAction SilentlyContinue
    foreach ($a in $adapters) {
        $ip = ($a.IPAddress | Where-Object { $_ -match '^\d+\.\d+\.\d+\.\d+$' } | Select-Object -First 1)
        if ($ip) {
            Add-DiagLine "  $($a.Description) : $ip"
            $Global:DiagData["Reseau"] = "$($a.Description) : $ip"
        }
    }
    $ping = Test-Connection "8.8.8.8" -Count 1 -ErrorAction SilentlyContinue
    $connColor = if ($ping) { "Green" } else { "Red" }
    $connText = if ($ping) { "OK ($($ping.ResponseTime) ms)" } else { "ECHEC" }
    $Global:DiagData["Internet"] = $connText
    Add-DiagLine "  Internet      : $connText" $connColor
    Add-DiagLine ""

    # Windows Update -- version complete + derniere KB + mises a jour en attente
    Add-DiagLine "[ MISES A JOUR WINDOWS ]" "Yellow"

    # Derniere mise a jour cumulativeintallee (registre -- plus fiable que Get-HotFix)
    $lastInstall = try {
        $wuReg = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results\Install" -ErrorAction SilentlyContinue
        if ($wuReg -and $wuReg.LastSuccessTime) {
            [datetime]$wuReg.LastSuccessTime
        } else { $null }
    } catch { $null }

    # Fallback : Get-HotFix (lent mais fiable)
    if (-not $lastInstall) {
        $lastHf = Get-HotFix -ErrorAction SilentlyContinue | Sort-Object InstalledOn -Descending | Select-Object -First 1
        $lastInstall = if ($lastHf -and $lastHf.InstalledOn) { $lastHf.InstalledOn } else { $null }
    }
    $lastInstallStr = if ($lastInstall) { $lastInstall.ToString('dd/MM/yyyy') } else { "Inconnue" }
    $daysSince = if ($lastInstall) { [int]((Get-Date) - $lastInstall).TotalDays } else { 999 }
    $majColor = if ($daysSince -gt 90) { "Red" } elseif ($daysSince -gt 30) { "Yellow" } else { "Green" }

    # Version Windows depuis registre (deja charge plus haut)
    Add-DiagLine "  Version      : $winDisplayVer (Build $winBuild)"
    Add-DiagLine "  Derniere MAJ : $lastInstallStr (il y a $daysSince $(if($daysSince -le 1){'jour'}else{'jours'}))" $majColor

    # Verifier MAJ en attente via WU COM (non bloquant, 3s timeout)
    try {
        $wuSession = New-Object -ComObject Microsoft.Update.Session -ErrorAction Stop
        $wuSearcher= $wuSession.CreateUpdateSearcher()
        $wuJob     = $wuSearcher.BeginSearch("IsInstalled=0 and IsHidden=0", $null, $null)
        $start     = Get-Date
        while (-not $wuJob.IsCompleted -and ((Get-Date)-$start).TotalSeconds -lt 5) { Start-Sleep -Milliseconds 200 }
        if ($wuJob.IsCompleted) {
            $wuResult = $wuSearcher.EndSearch($wuJob)
            $pending  = $wuResult.Updates.Count
            $pendColor= if ($pending -gt 0) { "Yellow" } else { "Green" }
            Add-DiagLine "  En attente   : $pending mise(s) a jour disponible(s)" $pendColor
            $Global:DiagData["MAJ en attente"] = "$pending"
        } else {
            Add-DiagLine "  En attente   : verification en cours (timeout)" "Gray"
        }
    } catch {
        Add-DiagLine "  En attente   : non verifie (ouvrir Windows Update)" "Gray"
    }
    $Global:DiagData["Derniere MAJ"] = "$lastInstallStr ($daysSince jours)"
    Add-DiagLine ""

    # ============================================================
    # CARTE(S) GRAPHIQUE(S)
    # Win32_VideoController : modele, VRAM, version et date driver
    # ============================================================
    Add-DiagLine "[ CARTE(S) GRAPHIQUE(S) ]" "Yellow"
    $gpus = @(Get-CimInstance Win32_VideoController -ErrorAction SilentlyContinue)
    if ($gpus.Count -gt 0) {
        foreach ($gpu in $gpus) {
            $gpuName   = if ($gpu.Name)             { $gpu.Name.Trim() }         else { "?" }
            $vramMB    = if ($gpu.AdapterRAM -gt 0) { [math]::Round($gpu.AdapterRAM / 1MB) } else { 0 }
            $vramStr   = if ($vramMB -ge 1024) { "$([math]::Round($vramMB/1024,1)) Go" } elseif ($vramMB -gt 0) { "$vramMB Mo" } else { "N/A" }

            # Version driver : Windows stocke "10.0.19041.1234" -- extraire la partie significative
            $driverVer = if ($gpu.DriverVersion) { $gpu.DriverVersion.Trim() } else { "?" }
            # Pour NVIDIA : les 5 derniers chiffres de la version correspondent au numero NVIDIA (ex. 55234 -> 552.34)
            $driverShort = if ($driverVer -match "^\d+\.\d+\.\d+\.(\d+)$") {
                $last = $Matches[1]
                if ($gpuName -match "NVIDIA|GeForce|RTX|GTX|Quadro") {
                    "NVIDIA $($last.Substring(0,[math]::Min(3,$last.Length))).$($last.Substring([math]::Min(3,$last.Length)))"
                } else { $driverVer }
            } else { $driverVer }

            # Date driver : DriverDate est un objet DateTime ou string
            $driverDate = try {
                $dd = $gpu.DriverDate
                if ($dd -is [datetime])        { $dd.ToString('dd/MM/yyyy') }
                elseif ($dd -is [string] -and $dd.Length -ge 8) {
                    [datetime]::ParseExact($dd.Substring(0,8),'yyyyMMdd',$null).ToString('dd/MM/yyyy')
                } else { "N/A" }
            } catch { "N/A" }

            $daysDrv = try {
                $ddParsed = if ($gpu.DriverDate -is [datetime]) { $gpu.DriverDate } else {
                    [datetime]::ParseExact($gpu.DriverDate.Substring(0,8),'yyyyMMdd',$null)
                }
                [int]((Get-Date) - $ddParsed).TotalDays
            } catch { -1 }
            $driverColor = if ($daysDrv -lt 0) { "Gray" } elseif ($daysDrv -gt 365) { "Yellow" } else { "Green" }

            # Resolution actuelle
            $resStr = if ($gpu.CurrentHorizontalResolution -and $gpu.CurrentVerticalResolution) {
                "$($gpu.CurrentHorizontalResolution)x$($gpu.CurrentVerticalResolution)"
            } else { "N/A" }

            Add-DiagLine "  $gpuName" "Cyan"
            Add-DiagLine "    VRAM       : $vramStr"
            Add-DiagLine "    Resolution : $resStr"
            Add-DiagLine "    Driver     : $driverShort" $driverColor
            Add-DiagLine "    Date driver: $driverDate$(if($daysDrv -ge 0){" (il y a $daysDrv jours)"})" $driverColor
            $Global:DiagData["GPU $gpuName"] = "$vramStr | Driver $driverShort | $driverDate"
            Add-DiagLine ""
        }
    } else {
        Add-DiagLine "  Aucune carte graphique detectee" "Gray"
        Add-DiagLine ""
    }

    # ============================================================
    # SECURITE -- detection etendue
    # Sources : WMI SecurityCenter2, registre, services, AppxPackage cache
    # ============================================================
    Add-DiagLine "[ SECURITE ]" "Yellow"

    # --- Windows Defender ---
    $def = Get-MpComputerStatus -ErrorAction SilentlyContinue
    if ($def) {
        $avColor = if ($def.AntivirusEnabled) { "Green" } else { "Red" }
        $rtColor = if ($def.RealTimeProtectionEnabled) { "Green" } else { "Red" }
        $Global:DiagData["Defender"] = if ($def.AntivirusEnabled) { "Actif" } else { "Inactif" }
        Add-DiagLine "  Windows Defender   : $(if($def.AntivirusEnabled){'Actif'}else{'INACTIF'})" $avColor
        Add-DiagLine "  Protection temps r.: $(if($def.RealTimeProtectionEnabled){'Active'}else{'INACTIVE'})" $rtColor
        try { Add-DiagLine "  Signature          : $($def.AntivirusSignatureLastUpdated.ToString('dd/MM/yyyy'))" } catch {}
    }

    # --- Antivirus tiers (WMI SecurityCenter2) ---
    $sc2 = Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiVirusProduct -ErrorAction SilentlyContinue
    $avTiers = @($sc2 | Where-Object { $_.displayName -notmatch "Windows Defender|Microsoft" })
    if ($avTiers.Count -gt 0) {
        Add-DiagLine "  Antivirus tiers    :" "Cyan"
        foreach ($av in $avTiers) {
            # productState : bit 12-19 = etat (266240=actif, 397312=expire, 393472=desactive)
            $state = switch ([int]($av.productState -shr 12) -band 0xF) {
                1 { "Expire/Inactif" } 0 { "Actif" } default { "Etat inconnu" }
            }
            $avStateColor = if ($state -eq "Actif") { "Green" } else { "Yellow" }
            Add-DiagLine "    $($av.displayName.PadRight(28)) [$state]" $avStateColor
            $Global:DiagData["AV $($av.displayName)"] = $state
        }
    } else {
        Add-DiagLine "  Antivirus tiers    : Aucun detecte" "Gray"
    }

    # --- Anti-malware / Anti-spyware (SecurityCenter2 AntiSpywareProduct) ---
    $amsp = @(Get-CimInstance -Namespace "root/SecurityCenter2" -ClassName AntiSpywareProduct -ErrorAction SilentlyContinue |
              Where-Object { $_.displayName -notmatch "Windows Defender|Microsoft" })
    if ($amsp.Count -gt 0) {
        Add-DiagLine "  Anti-malware tiers :" "Cyan"
        foreach ($am in $amsp) {
            Add-DiagLine "    $($am.displayName)" "Green"
            $Global:DiagData["AntiMalware"] = $am.displayName
        }
    }

    # --- Detection etendue par registre et services ---
    # Catalogue : nom affiche -> pattern registre/service
    $secSoftware = [ordered]@{
        # Antivirus / Suites
        "Malwarebytes"          = @{ Reg="Malwarebytes";         Svc="MBAMService";            Cat="Antimalware" }
        "Kaspersky"             = @{ Reg="Kaspersky";            Svc="AVP";                    Cat="Antivirus" }
        "Bitdefender"           = @{ Reg="Bitdefender";          Svc="bdagent";                Cat="Antivirus" }
        "Norton / Symantec"     = @{ Reg="Norton|Symantec";      Svc="NortonSecurity";         Cat="Antivirus" }
        "Avast"                 = @{ Reg="Avast";                Svc="avast! Antivirus";       Cat="Antivirus" }
        "AVG"                   = @{ Reg="AVG";                  Svc="AVGSvc";                 Cat="Antivirus" }
        "Avira"                 = @{ Reg="Avira";                Svc="AntivirService";         Cat="Antivirus" }
        "ESET"                  = @{ Reg="ESET";                 Svc="ekrn";                   Cat="Antivirus" }
        "McAfee"                = @{ Reg="McAfee";               Svc="McAPExe";                Cat="Antivirus" }
        "Trend Micro"           = @{ Reg="Trend Micro";          Svc="Tmntsrv";                Cat="Antivirus" }
        "Sophos"                = @{ Reg="Sophos";               Svc="Sophos MCS Agent";       Cat="Antivirus" }
        "F-Secure"              = @{ Reg="F-Secure";             Svc="F-Secure Gatekeeper";    Cat="Antivirus" }
        "Panda"                 = @{ Reg="Panda";                Svc="PavFnSvr";               Cat="Antivirus" }
        "Comodo"                = @{ Reg="Comodo";               Svc="cmdagent";               Cat="Antivirus" }
        "DrWeb"                 = @{ Reg="Dr.Web";               Svc="drweb";                  Cat="Antivirus" }
        "360 Total Security"    = @{ Reg="360 Total";            Svc="ZhuDongFangYu";          Cat="Antivirus" }
        "Webroot"               = @{ Reg="Webroot";              Svc="WRSVC";                  Cat="Antivirus" }
        # Antimalware / Adware
        "AdwCleaner"            = @{ Reg="AdwCleaner";           Svc="";                       Cat="Antimalware" }
        "HitmanPro"             = @{ Reg="HitmanPro";            Svc="HitmanProScheduler";     Cat="Antimalware" }
        "SuperAntiSpyware"      = @{ Reg="SUPERAntiSpyware";     Svc="SASCORE64";              Cat="Antimalware" }
        "Spybot"                = @{ Reg="Spybot";               Svc="SDWSCSvc";               Cat="Antimalware" }
        # Bloqueurs de pub (navigateurs et systeme)
        "uBlock Origin"         = @{ Reg="uBlock";               Svc="";                       Cat="Bloqueur pub" }
        "AdGuard"               = @{ Reg="Adguard";              Svc="AdguardSvc";             Cat="Bloqueur pub" }
        "Pi-hole (client)"      = @{ Reg="Pi-hole";              Svc="";                       Cat="Bloqueur pub" }
        "NextDNS"               = @{ Reg="NextDNS";              Svc="NextDNS";                Cat="Bloqueur pub" }
        "Malwarebytes Browser"  = @{ Reg="Malwarebytes Browser"; Svc="";                       Cat="Bloqueur pub" }
        # VPN
        "NordVPN"               = @{ Reg="NordVPN";              Svc="NordVPN Service";        Cat="VPN" }
        "ExpressVPN"            = @{ Reg="ExpressVPN";           Svc="ExpressVpn";             Cat="VPN" }
        "ProtonVPN"             = @{ Reg="ProtonVPN";            Svc="ProtonVPN Service";      Cat="VPN" }
        "Mullvad"               = @{ Reg="Mullvad";              Svc="MullvadVPN";             Cat="VPN" }
        "CyberGhost"            = @{ Reg="CyberGhost";           Svc="CyberGhost8Service";     Cat="VPN" }
        "Surfshark"             = @{ Reg="Surfshark";            Svc="Surfshark Service";      Cat="VPN" }
        "Private Internet Access"=@{ Reg="Private Internet";     Svc="PIAService";             Cat="VPN" }
        "Windscribe"            = @{ Reg="Windscribe";           Svc="WindscribeService";      Cat="VPN" }
        "OpenVPN"               = @{ Reg="OpenVPN";              Svc="OpenVPNService";         Cat="VPN" }
        "WireGuard"             = @{ Reg="WireGuard";            Svc="WireGuardTunnel";        Cat="VPN" }
        "Cisco AnyConnect"      = @{ Reg="Cisco AnyConnect";     Svc="vpnagent";               Cat="VPN Entreprise" }
        "GlobalProtect"         = @{ Reg="Palo Alto";            Svc="PanGPS";                 Cat="VPN Entreprise" }
        # Pare-feu tiers
        "ZoneAlarm"             = @{ Reg="ZoneAlarm";            Svc="ISWSVC";                 Cat="Pare-feu" }
        "GlassWire"             = @{ Reg="GlassWire";            Svc="GWIdleMon";              Cat="Pare-feu" }
        "Little Snitch"         = @{ Reg="";                     Svc="";                       Cat="Pare-feu" }
    }

    # Lire le cache registre (deja charge -- gratuit)
    $regCache = Get-UninstallCache

    # Lire les services en une seule query (rapide)
    $allServices = @(Get-Service -ErrorAction SilentlyContinue | Select-Object Name,DisplayName)

    $foundByCategory = [ordered]@{}
    foreach ($name in $secSoftware.Keys) {
        $entry = $secSoftware[$name]
        $found = $false

        # Test registre desinstallation
        if ($entry.Reg) {
            $found = [bool]($regCache | Where-Object { $_.DisplayName -match $entry.Reg } | Select-Object -First 1)
        }
        # Test service si pas trouve par registre
        if (-not $found -and $entry.Svc) {
            $found = [bool]($allServices | Where-Object { $_.Name -match $entry.Svc -or $_.DisplayName -match $entry.Svc } | Select-Object -First 1)
        }

        if ($found) {
            $cat = $entry.Cat
            if (-not $foundByCategory.Contains($cat)) { $foundByCategory[$cat] = [System.Collections.Generic.List[string]]::new() }
            $foundByCategory[$cat].Add($name)
            $Global:DiagData["Securite $name"] = "Detecte"
        }
    }

    # Afficher par categorie
    if ($foundByCategory.Count -gt 0) {
        Add-DiagLine "  Logiciels de securite detectes :" "Cyan"
        foreach ($cat in $foundByCategory.Keys) {
            $catColor = switch ($cat) {
                "Antivirus"      { "Green" }
                "Antimalware"    { "Green" }
                "Bloqueur pub"   { "Cyan"  }
                "VPN"            { "Yellow" }
                "VPN Entreprise" { "Yellow" }
                "Pare-feu"       { "Cyan"  }
                default          { "White" }
            }
            $items = $foundByCategory[$cat] -join ", "
            Add-DiagLine "    [$cat] $items" $catColor
        }
    } else {
        Add-DiagLine "  Logiciels securite tiers : Aucun detecte" "Gray"
    }
    Add-DiagLine ""

    # --- Pare-feu Windows ---
    Add-DiagLine "  Pare-feu Windows :" "Cyan"
    $fwProfiles = Get-NetFirewallProfile -ErrorAction SilentlyContinue
    foreach ($fw in $fwProfiles) {
        $fwColor = if ($fw.Enabled) { "Green" } else { "Red" }
        Add-DiagLine "    $($fw.Name.PadRight(10)) : $(if($fw.Enabled){'Actif'}else{'INACTIF'})" $fwColor
    }
    Add-DiagLine ""

    Add-DiagLine "================================================" "Cyan"
    Add-DiagLine "  Diagnostic termine." "Cyan"
    Add-DiagLine "================================================" "Cyan"

    $btnDiagHTML.Enabled = $true
    $btnDiagRun.Enabled  = $true
})

$btnDiagHTML.Add_Click({
    $diagPath = "$scriptDir\diagnostic_$((Get-Date -Format 'yyyyMMdd_HHmmss')).html"
    $rows = ($Global:DiagData.GetEnumerator() | ForEach-Object { "<tr><td><b>$($_.Key)</b></td><td>$($_.Value)</td></tr>" }) -join "`n"
    # Construction HTML par sections logiques
    $diagSections = [ordered]@{
        "Systeme"      = @("Machine","Carte mere","OS","Architecture","Nom machine","BIOS")
        "Processeur"   = @("CPU","CPU Coeurs")
        "Memoire RAM"  = @("RAM*","RAM Total","RAM Utilisee")
        "GPU"          = @("GPU*")
        "Disques"      = @("Disque*","Partition*")
        "Reseau"       = @("Internet","Reseau")
        "Mises a jour" = @("Derniere MAJ","MAJ en attente")
        "Securite"     = @("Defender","AV *","AntiMalware","Securite *")
    }
    $usedKeys = [System.Collections.Generic.HashSet[string]]::new()
    $sectionHtml = ""
    foreach ($secName in $diagSections.Keys) {
        $patterns = @($diagSections[$secName])
        $rows2 = ""
        foreach ($k in @($Global:DiagData.Keys)) {
            if ($usedKeys.Contains($k)) { continue }
            $match = $false
            foreach ($p in $patterns) { if ($k -like $p -or $k -eq $p) { $match = $true; break } }
            if (-not $match) { continue }
            $v = [System.Web.HttpUtility]::HtmlEncode($Global:DiagData[$k])
            $cls = if ($v -match "INACTIF|ECHEC|Defaillant") { " class='err'" }
                   elseif ($v -match "^Actif|^OK|Sain") { " class='ok'" }
                   elseif ($v -match "attente|Avertissement") { " class='warn'" }
                   else { "" }
            $rows2 += "<tr><td class='k'>$([System.Web.HttpUtility]::HtmlEncode($k))</td><td$cls>$v</td></tr>`n"
            $usedKeys.Add($k) | Out-Null
        }
        if ($rows2) { $sectionHtml += "<tr class='sec'><td colspan='2'>$secName</td></tr>`n$rows2" }
    }
    # Cles non classees
    foreach ($k in @($Global:DiagData.Keys)) {
        if ($usedKeys.Contains($k)) { continue }
        $v = [System.Web.HttpUtility]::HtmlEncode($Global:DiagData[$k])
        $sectionHtml += "<tr><td class='k'>$([System.Web.HttpUtility]::HtmlEncode($k))</td><td>$v</td></tr>`n"
    }

    # Logo en base64 avant le here-string (les '' ne fonctionnent pas dans @"..."@)
    $diagLogoHtml = ""
    $lp = Join-Path $scriptDir "png\logo2.png"
    if (Test-Path $lp) {
        $b64logo = [Convert]::ToBase64String([IO.File]::ReadAllBytes($lp))
        $diagLogoHtml = "<img src=`"data:image/png;base64,$b64logo`" style=`"height:52px;filter:brightness(0) invert(1)`" alt=`"Charonne Buro`">"
    } else {
        $diagLogoHtml = "<span style=`"font-size:1.4rem;font-weight:800`">CB</span>"
    }

    $diagHtml = @"
<!DOCTYPE html>
<html lang="fr">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Diagnostic -- $env:COMPUTERNAME</title>
<style>
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:'Segoe UI',Arial,sans-serif;background:#eef2f7;color:#2d3748;font-size:14px}
header{background:linear-gradient(135deg,#1a2a4a,#243b5a);color:white;padding:22px 40px;display:flex;justify-content:space-between;align-items:center}
header h1{font-size:1.25rem;font-weight:600}
.meta{font-size:.82rem;opacity:.8;text-align:right;line-height:1.6}
.wrap{max-width:880px;margin:24px auto;padding:0 16px}
table{width:100%;border-collapse:collapse;background:white;border-radius:10px;overflow:hidden;box-shadow:0 2px 12px rgba(0,0,0,.08)}
tr.sec td{background:#1a2a4a;color:white;font-weight:700;font-size:.75rem;letter-spacing:.08em;text-transform:uppercase;padding:8px 16px}
td{padding:10px 16px;border-bottom:1px solid #e8edf5;vertical-align:top;line-height:1.4}
td.k{color:#4a5568;font-weight:500;width:36%;white-space:nowrap}
tr:last-child td{border-bottom:none}
tr:not(.sec):hover td{background:#f0f7ff}
.ok{color:#276749;font-weight:600}
.warn{color:#c27803;font-weight:600}
.err{color:#c53030;font-weight:600}
footer{text-align:center;padding:16px;color:#a0aec0;font-size:.8rem;margin-top:4px}
@media(max-width:600px){header{flex-direction:column;gap:8px}.meta{text-align:left}td.k{width:45%}}
</style>
</head>
<body>
<header>
  <div style="display:flex;align-items:center;gap:16px">
    $diagLogoHtml
    <div><h1>Rapport de diagnostic</h1><div style="font-size:.88rem;margin-top:3px;opacity:.85">Charonne Boost v12.1</div></div>
  </div>
  <div class="meta">$(Get-Date -Format 'dd/MM/yyyy HH:mm')<br>$env:COMPUTERNAME</div>
</header>
<div class="wrap">
<table><colgroup><col style="width:36%"><col></colgroup>
$sectionHtml
</table>
<footer>Charonne Buro &mdash; 129 bd de Charonne, 75011 Paris &mdash; 01&nbsp;43&nbsp;79&nbsp;35&nbsp;40 &mdash; charonneburo.com</footer>
</div>
</body></html>
"@
    [System.IO.File]::WriteAllText($diagPath, $diagHtml, (New-Object System.Text.UTF8Encoding $false))
    Start-Process $diagPath
    Write-Log "Rapport diagnostic exporte : $diagPath" "Green"
})

$btnFiabiliteHTML.Add_Click({
    $relPath = [System.IO.Path]::Combine($scriptDir, "fiabilite_$((Get-Date -Format 'yyyyMMdd_HHmmss')).html")
    $relJob = Start-Job {
        param($path, $sdir)
        try {
            $events = Get-WinEvent -LogName "Microsoft-Windows-Reliability-Analysis/Operational" -MaxEvents 100 -ErrorAction SilentlyContinue
            if (!$events) {
                $events = Get-EventLog -LogName Application -Newest 50 -EntryType Error,Warning -ErrorAction SilentlyContinue
            }
            # Deduplication : WMI IntelMEProv repete -> garder 1 seul par heure
            $seen = @{}; $filtered = @()
            foreach ($ev in $events) {
                $src = if ($ev.ProviderName) { $ev.ProviderName } else { "$($ev.Source)" }
                $dt  = if ($ev.TimeCreated) { $ev.TimeCreated } else { $ev.TimeGenerated }
                $key = "$src|$(if($dt){$dt.ToString('yyyyMMddHH')}else{'?'})"
                if (-not $seen[$key]) { $seen[$key] = 0 }
                $seen[$key]++
                if ($seen[$key] -le 1) { $filtered += $ev }
            }
            $dupTotal = $events.Count - $filtered.Count

            $rows = ($filtered | Select-Object -First 150 | ForEach-Object {
                $lvl = if ($_.LevelDisplayName) { $_.LevelDisplayName } else { "$($_.EntryType)" }
                $src = if ($_.ProviderName)     { $_.ProviderName }     else { "$($_.Source)" }
                $msg = ($_.Message -replace '<[^>]+>','' -replace '"','&quot;' -replace "'","'" -replace "
?
"," ")
                if ($msg.Length -gt 300) { $msg = $msg.Substring(0,300) + "..." }
                $dt  = if ($_.TimeCreated) { $_.TimeCreated.ToString('dd/MM/yyyy HH:mm:ss') } else { "$($_.TimeGenerated)" }
                $lvlClass = if ($lvl -match "Error|Erreur")          { "badge-err" }
                            elseif ($lvl -match "Warn|Avertissement") { "badge-warn" }
                            else { "badge-info" }
                # Signalement erreurs importantes connues
                $rowStyle = ""
                if ($src -match "Software Protection" -and $msg -match "0x80072EE7") { $rowStyle = " style='background:#fff5f5'" }
                elseif ($src -match "Application Hang") { $rowStyle = " style='background:#fff5f5'" }
                "<tr$rowStyle><td style='white-space:nowrap;color:#4a5568;font-size:11px'>$dt</td><td><span class='badge $lvlClass'>$lvl</span></td><td style='color:#718096;font-size:11px;max-width:180px;word-break:break-all'>$src</td><td class='msg'>$msg</td></tr>"
            }) -join "`n"
            if ($dupTotal -gt 0) { $rows += "<tr style='background:#f7fafc'><td colspan='4' style='text-align:center;color:#a0aec0;font-style:italic;font-size:11px'>$dupTotal evenements WMI dupliques masques</td></tr>" }
            # Stats
            $nErr  = @($events | Where-Object { ($_.LevelDisplayName + $_.EntryType) -match "Error|Erreur" }).Count
            $nWarn = @($events | Where-Object { ($_.LevelDisplayName + $_.EntryType) -match "Warn|Avert" }).Count
            $nTot  = $events.Count
            $css = "<style>*{box-sizing:border-box;margin:0;padding:0}body{font-family:'Segoe UI',Arial,sans-serif;background:#eef2f7;font-size:13px;color:#2d3748}header{background:linear-gradient(135deg,#1a2a4a,#243b5a);color:white;padding:20px 40px;display:flex;justify-content:space-between;align-items:center}header h1{font-size:1.2rem;font-weight:600}.stats{display:flex;gap:12px;max-width:95%;margin:20px auto}.stat{background:white;border-radius:8px;padding:12px 20px;flex:1;text-align:center;box-shadow:0 2px 8px rgba(0,0,0,.07)}.stat .n{font-size:1.7rem;font-weight:700}.stat .l{font-size:.78rem;color:#718096;margin-top:2px}.err-c{color:#c53030}.warn-c{color:#c27803}.ok-c{color:#276749}table{width:95%;margin:0 auto 24px;border-collapse:collapse;background:white;border-radius:10px;overflow:hidden;box-shadow:0 2px 10px rgba(0,0,0,.07)}th{background:#1a2a4a;color:white;padding:9px 14px;text-align:left;font-size:12px;font-weight:600}td{padding:8px 14px;border-bottom:1px solid #e8edf5;vertical-align:top}.badge{display:inline-block;padding:2px 7px;border-radius:4px;font-size:11px;font-weight:600}.badge-err{background:#fed7d7;color:#c53030}.badge-warn{background:#fefcbf;color:#744210}.badge-info{background:#c6f6d5;color:#22543d}.msg{max-width:460px;word-break:break-word;line-height:1.4;font-size:12px}tr:hover td{background:#f0f7ff}footer{text-align:center;padding:14px;color:#a0aec0;font-size:.8rem}</style>"
            $html = "<!DOCTYPE html><html lang='fr'><head><meta charset='UTF-8'><meta name='viewport' content='width=device-width,initial-scale=1'><title>Fiabilite -- $($env:COMPUTERNAME)</title>$css</head><body>"
            $fiabLogoHtml = ""
            $lp2 = Join-Path $sdir "png\logo2.png"
            if (Test-Path $lp2) {
                $b64f = [Convert]::ToBase64String([IO.File]::ReadAllBytes($lp2))
                $fiabLogoHtml = "<img src=`"data:image/png;base64,$b64f`" style=`"height:44px;filter:brightness(0) invert(1);margin-right:14px`" alt=`"CB`">"
            }
            $html += "<header>$fiabLogoHtml<div><h1>Journal de fiabilite</h1><div style='font-size:.82rem;opacity:.8'>Charonne Boost v12.1 &mdash; $($env:COMPUTERNAME)</div></div></header>"
            $html += "<div class='stats'><div class='stat'><div class='n err-c'>$nErr</div><div class='l'>Erreurs</div></div><div class='stat'><div class='n warn-c'>$nWarn</div><div class='l'>Avertissements</div></div><div class='stat'><div class='n ok-c'>$nTot</div><div class='l'>Evenements total</div></div></div>"
            $html += "<table><tr><th>Date</th><th>Niveau</th><th>Source</th><th>Message</th></tr>$rows</table>"
            $html += "<footer>Charonne Buro &mdash; 129 bd de Charonne, 75011 Paris &mdash; charonneburo.com</footer></body></html>"
            [System.IO.File]::WriteAllText($path, $html, (New-Object System.Text.UTF8Encoding $false))
            "OK:$path"
        } catch { "ERR:$_" }
    } -ArgumentList $relPath, $scriptDir
    while ($relJob.State -eq "Running") { Start-Sleep -Milliseconds 500 }
    $result = Receive-Job $relJob; Remove-Job $relJob
    if ($result -like "OK:*") {
        Start-Process $relPath
        Write-Log "Rapport fiabilite exporte : $relPath" "Green"
    } else {
        [System.Windows.Forms.MessageBox]::Show("Echec extraction : $result","Fiabilite",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error)
    }
})


# ============================================================
