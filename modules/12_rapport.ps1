# ============================================================
# 12_rapport.ps1
# Export manuel des rapports Charonne Boost
# IMPORTANT : aucune tache planifiee, aucune ouverture au redemarrage.
# ============================================================

function Remove-CBReportScheduledTasks {
    param([switch]$Silent)
    try {
        $tasks = @(Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object {
            $_.TaskName -like '*CharonneBuro_Rapport*' -or
            $_.TaskName -like '*CharonneBoost*Rapport*' -or
            $_.TaskName -like '*Charonne*Rapport*'
        })
        foreach($t in $tasks){
            try {
                Unregister-ScheduledTask -TaskName $t.TaskName -TaskPath $t.TaskPath -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                if(-not $Silent){ Write-Log "Tache rapport supprimee : $($t.TaskPath)$($t.TaskName)" "Yellow" }
            } catch {}
        }
    } catch {}
}

function Export-CBSessionLog {
    param([double]$DisqueBefore = 0)

    if (-not $Global:RapportEntries -or $Global:RapportEntries.Count -eq 0) {
        Write-Log "Aucune action effectuee -- log de session non sauvegarde." "Gray"
        return $null
    }

    try {
        $logDir = Join-Path $scriptDir "logs"
        if (!(Test-Path $logDir)) { New-Item $logDir -ItemType Directory -Force | Out-Null }

        $sessionDate = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
        $logPath = Join-Path $logDir "session_$sessionDate.log"

        $diskAfterLog = Get-PSDrive C -ErrorAction SilentlyContinue
        $diskAfterVal = if ($diskAfterLog) { [math]::Round($diskAfterLog.Used / 1GB, 2) } else { 0 }
        $beforeVal = if($DisqueBefore -gt 0){ $DisqueBefore } elseif($Global:DisqueBefore){ $Global:DisqueBefore } else { 0 }
        $liberLogRaw  = [math]::Round($beforeVal - $diskAfterVal, 2)
        $liberLog     = if ($liberLogRaw -lt 0) { 0 } else { $liberLogRaw }
        $liberLogNote = if ($beforeVal -eq 0) { " (non mesure : DisqueBefore = 0)" } `
                        elseif ($liberLogRaw -lt 0) { " (disque occupe apres : $([math]::Abs($liberLogRaw)) Go d installs)" } `
                        else { "" }

        $logLines = @()
        $logLines += "============================================================"
        $logLines += "  CHARONNE BOOST -- Journal de session"
        $logLines += "  Charonne Buro | 129 bd de Charonne, 75011 Paris"
        $logLines += "============================================================"
        $logLines += "Date         : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
        $logLines += "Ordinateur   : $env:COMPUTERNAME"
        $logLines += "Utilisateur  : $env:USERNAME"
        $logLines += "Disque type  : $Global:DiskType"
        $logLines += "Espace avant : $beforeVal Go"
        $logLines += "Espace apres : $diskAfterVal Go"
        $logLines += "Espace libere: $liberLog Go$liberLogNote"
        $logLines += "------------------------------------------------------------"
        $logLines += "ACTIONS REUSSIES"
        $logLines += "------------------------------------------------------------"
        foreach ($entry in $Global:RapportEntries | Where-Object { $_.Status -eq "OK" }) {
            $logLines += "[$($entry.Time)] [OK]     $($entry.Msg)"
        }
        $logLines += "------------------------------------------------------------"
        $logLines += "BLOATWARES PURGES"
        $logLines += "------------------------------------------------------------"
        foreach ($entry in $Global:RapportEntries | Where-Object { $_.Status -eq "PURGE" }) {
            $logLines += "[$($entry.Time)] [PURGE]  $($entry.Msg)"
        }
        $logLines += "------------------------------------------------------------"
        $logLines += "ERREURS"
        $logLines += "------------------------------------------------------------"
        $erreurs = @($Global:RapportEntries | Where-Object { $_.Status -eq "ERREUR" })
        if ($erreurs.Count -eq 0) { $logLines += "Aucune erreur." }
        else { foreach ($entry in $erreurs) { $logLines += "[$($entry.Time)] [ERREUR] $($entry.Msg)" } }
        $logLines += "------------------------------------------------------------"
        $logLines += "JOURNAL COMPLET ($($Global:RapportEntries.Count) entrees)"
        $logLines += "------------------------------------------------------------"
        foreach ($entry in $Global:RapportEntries) {
            $logLines += "[$($entry.Time)] [$($entry.Status.PadRight(6))] $($entry.Msg)"
        }
        $logLines += "============================================================"
        $logLines += "  Fin de session -- Charonne Boost"
        $logLines += "============================================================"

        [System.IO.File]::WriteAllLines($logPath, $logLines, (New-Object System.Text.UTF8Encoding $false))
        Write-Log "Log de session sauvegarde : $logPath" "Green"
        return $logPath
    } catch {
        Write-Log "[!] Impossible de sauvegarder le log : $_" "Red"
        return $null
    }
}

function Export-CBReport {
    param(
        [double]$DisqueBefore = 0,
        [switch]$OpenReport
    )

    if (-not $Global:RapportEntries -or $Global:RapportEntries.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Aucune action n'a encore ete journalisee.`nLancez une optimisation ou un diagnostic avant d'exporter un rapport.",
            "Export rapport",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return $null
    }

    # Nettoyage defensif des anciennes taches rapport des versions precedentes.
    Remove-CBReportScheduledTasks -Silent

    $dsk2 = Get-PSDrive C -ErrorAction SilentlyContinue
    $Global:DisqueAfter = if($dsk2){ [math]::Round($dsk2.Used/1GB,2) } else { 0 }
    $beforeVal = if($DisqueBefore -gt 0){ $DisqueBefore } elseif($Global:DisqueBefore){ $Global:DisqueBefore } else { $Global:DisqueAfter }
    $libere = [math]::Round($beforeVal - $Global:DisqueAfter,2); if($libere -lt 0){ $libere = 0 }
    $totalC = if($dsk2){ [math]::Round(($dsk2.Used+$dsk2.Free)/1GB,2) } else { 100 }
    $usedA = $Global:DisqueAfter
    $freeA = [math]::Round($totalC-$usedA,2)
    $pctU = if($totalC -gt 0){ [math]::Round($usedA/$totalC*100,1) } else { 0 }
    $pctF = if($totalC -gt 0){ [math]::Round($freeA/$totalC*100,1) } else { 0 }
    $pctL = if($totalC -gt 0){ [math]::Round($libere/$totalC*100,1) } else { 0 }

    $lOK  = @($Global:RapportEntries | Where-Object { $_.Status -eq "OK" })
    $lErr = @($Global:RapportEntries | Where-Object { $_.Status -eq "ERREUR" })
    $lPrg = @($Global:RapportEntries | Where-Object { $_.Status -eq "PURGE" })

    $logoB64 = ""
    $lp = Join-Path $scriptDir "png\logo2.png"
    if(Test-Path $lp){ $logoB64 = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($lp)) }

    $osInfo = try { Get-CimInstance Win32_OperatingSystem -ErrorAction Stop } catch { $null }
    $cpuInfo = try { Get-CimInstance Win32_Processor -ErrorAction Stop | Select-Object -First 1 } catch { $null }
    $ramGo = if($osInfo){ [math]::Round($osInfo.TotalVisibleMemorySize/1MB,1) } else { 0 }
    $sel = @()
    if(Get-Command Get-CBSelectedActions -ErrorAction SilentlyContinue){ $sel = @(Get-CBSelectedActions) }
    $selectedRows = if($sel.Count -gt 0){
        ($sel | ForEach-Object { "<tr><td>$($_.Categorie)</td><td>$($_.Action)</td><td>$($_.Risque)</td></tr>" }) -join "`n"
    } else { "<tr><td colspan='3'>Aucune selection active au moment de l export.</td></tr>" }

    $html=@"
<!DOCTYPE html><html lang="fr"><head><meta charset="UTF-8"><title>Rapport - Charonne Boost</title>
<style>
:root{--navy:#101827;--blue:#1f3658;--accent:#307cd2;--ok:#36be7d;--err:#d24e4e;--muted:#8ea0b8}
*{box-sizing:border-box;margin:0;padding:0}body{font-family:'Segoe UI',Arial,sans-serif;background:#eef3f8;color:#243041}
header{background:var(--navy);color:#fff;padding:20px 40px;display:flex;align-items:center;gap:20px}header img{height:52px}header h1{font-size:1.55rem}header p{font-size:.85rem;color:#b8c3d4;margin-top:4px}
.badges{display:flex;gap:14px;padding:18px 40px;flex-wrap:wrap}.badge{background:#fff;border-radius:10px;padding:14px 20px;flex:1;min-width:145px;box-shadow:0 2px 8px rgba(0,0,0,.08);border-left:5px solid var(--accent)}.badge.ok{border-color:var(--ok)}.badge.err{border-color:var(--err)}.badge.lib{border-color:#805ad5}.badge h3{font-size:1.5rem}.badge p{font-size:.8rem;color:#687588;margin-top:3px}
.chart-wrap{background:#fff;border-radius:10px;margin:0 40px 20px;padding:20px;box-shadow:0 2px 8px rgba(0,0,0,.08);display:flex;align-items:center;gap:36px;flex-wrap:wrap}.chart-wrap h2{width:100%;color:var(--navy);margin-bottom:6px}.legend{display:flex;flex-direction:column;gap:7px;font-size:.9rem}.legend-item{display:flex;align-items:center;gap:9px}.legend-dot{width:13px;height:13px;border-radius:50%}
.info-grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(220px,1fr));gap:12px;margin:0 40px 20px}.info-card{background:#fff;border-radius:10px;padding:13px 16px;box-shadow:0 2px 8px rgba(0,0,0,.08)}.info-card strong{display:block;color:var(--navy);font-size:.82rem;margin-bottom:4px}.info-card span{font-size:.92rem;color:#465365}
.accordion{margin:0 40px 12px}.acc-btn{width:100%;background:var(--navy);color:#fff;border:none;border-radius:8px;padding:12px 18px;text-align:left;font-size:.95rem;font-weight:600;cursor:pointer;display:flex;justify-content:space-between}.acc-btn:hover{background:var(--blue)}.acc-content{display:none;background:#fff;border-radius:0 0 8px 8px;box-shadow:0 2px 8px rgba(0,0,0,.08)}.acc-content.open{display:block}
table{width:100%;border-collapse:collapse;font-size:.83rem}th{background:var(--navy);color:#fff;padding:9px 13px;text-align:left}td{padding:7px 13px;border-bottom:1px solid #e2e8f0}tr.ok td:last-child{color:#237a50;font-weight:700}tr.erreur td{background:#fff5f5}tr.erreur td:last-child{color:#a33;font-weight:700}tr.purge td:last-child{color:#6b46c1;font-weight:700}tr:hover td{background:#edf5ff}footer{text-align:center;padding:18px;color:#8ea0b8;font-size:.78rem}
</style></head><body>
<header>$(if($logoB64){"<img src='data:image/png;base64,$logoB64'>"})<div><h1>Rapport d'optimisation</h1><p>Export manuel - $(Get-Date -Format 'dd/MM/yyyy HH:mm') - Charonne Boost</p></div></header>
<div class="badges"><div class="badge ok"><h3>$($lOK.Count)</h3><p>Actions reussies</p></div><div class="badge err"><h3>$($lErr.Count)</h3><p>Erreurs</p></div><div class="badge"><h3>$($lPrg.Count)</h3><p>Bloatwares purges</p></div><div class="badge lib"><h3>${libere} Go</h3><p>Espace libere</p></div></div>
<div class="info-grid"><div class="info-card"><strong>Ordinateur</strong><span>$env:COMPUTERNAME / $env:USERNAME</span></div><div class="info-card"><strong>Windows</strong><span>$(if($osInfo){$osInfo.Caption + ' build ' + $osInfo.BuildNumber}else{'Non detecte'})</span></div><div class="info-card"><strong>CPU</strong><span>$(if($cpuInfo){$cpuInfo.Name}else{'Non detecte'})</span></div><div class="info-card"><strong>RAM / Disque</strong><span>${ramGo} Go RAM - $Global:DiskType</span></div></div>
<div class="accordion"><button class="acc-btn" onclick="tog(this)">Actions selectionnees avant export ($($sel.Count)) <span>+</span></button><div class="acc-content"><table><tr><th>Categorie</th><th>Action</th><th>Risque</th></tr>$selectedRows</table></div></div>
<div class="chart-wrap"><h2>Espace disque C:</h2><canvas id="dc" width="200" height="200"></canvas><div class="legend"><div class="legend-item"><div class="legend-dot" style="background:#d24e4e"></div>Utilise : ${usedA} Go ($pctU%)</div><div class="legend-item"><div class="legend-dot" style="background:#36be7d"></div>Libre : ${freeA} Go ($pctF%)</div><div class="legend-item"><div class="legend-dot" style="background:#805ad5"></div>Libere : ${libere} Go ($pctL%)</div></div></div>
<div class="accordion"><button class="acc-btn" onclick="tog(this)">Actions reussies ($($lOK.Count)) <span>+</span></button><div class="acc-content open"><table><tr><th>Heure</th><th>Message</th><th>Statut</th></tr>$(HtmlRows $lOK)</table></div></div>
<div class="accordion"><button class="acc-btn" onclick="tog(this)">Bloatwares purges ($($lPrg.Count)) <span>+</span></button><div class="acc-content"><table><tr><th>Heure</th><th>Message</th><th>Statut</th></tr>$(HtmlRows $lPrg)</table></div></div>
<div class="accordion"><button class="acc-btn" onclick="tog(this)">Erreurs ($($lErr.Count)) <span>+</span></button><div class="acc-content"><table><tr><th>Heure</th><th>Message</th><th>Statut</th></tr>$(HtmlRows $lErr)</table></div></div>
<div class="accordion"><button class="acc-btn" onclick="tog(this)">Journal complet ($($Global:RapportEntries.Count)) <span>+</span></button><div class="acc-content"><table><tr><th>Heure</th><th>Message</th><th>Statut</th></tr>$(HtmlRows $Global:RapportEntries)</table></div></div>
<footer>Charonne Buro - 129 boulevard de Charonne, 75011 Paris - 01 43 79 35 40 - charonneburo.com</footer>
<script>function tog(b){var c=b.nextElementSibling,s=b.querySelector('span');c.classList.toggle('open');s.textContent=c.classList.contains('open')?'-':'+';}var ctx=document.getElementById('dc').getContext('2d');var d=[$($usedA-$libere),$libere,$freeA],cols=['#d24e4e','#805ad5','#36be7d'],sum=d.reduce(function(a,b){return a+b;},0),s=-Math.PI/2;d.forEach(function(v,i){var a=sum>0?v/sum*2*Math.PI:0;ctx.beginPath();ctx.moveTo(100,100);ctx.arc(100,100,90,s,s+a);ctx.closePath();ctx.fillStyle=cols[i];ctx.fill();s+=a;});ctx.beginPath();ctx.arc(100,100,50,0,2*Math.PI);ctx.fillStyle='#fff';ctx.fill();ctx.fillStyle='#243041';ctx.font='bold 12px Segoe UI';ctx.textAlign='center';ctx.fillText('${totalC} Go',100,97);ctx.font='10px Segoe UI';ctx.fillStyle='#687588';ctx.fillText('total',100,111);</script>
</body></html>
"@

    try {
        $logDir = Join-Path $scriptDir "logs"
        if(!(Test-Path $logDir)){ New-Item $logDir -ItemType Directory -Force | Out-Null }
        $rp = Join-Path $logDir ("rapport_optimisation_{0}.html" -f (Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'))
        [System.IO.File]::WriteAllText($rp,$html,(New-Object System.Text.UTF8Encoding $false))
        Write-Log "Rapport exporte manuellement : $rp" "Green"
        if($OpenReport){ Start-Process $rp }
        return $rp
    } catch {
        Write-Log "[!] Impossible d'exporter le rapport : $_" "Red"
        return $null
    }
}

# Compatibilite avec les anciens appels. Ne planifie rien et ne force rien.
function Invoke-Rapport {
    param([double]$DisqueBefore = 0)
    Export-CBReport -DisqueBefore $DisqueBefore -OpenReport | Out-Null
}

# Nettoyage automatique des anciennes taches des versions precedentes.
Remove-CBReportScheduledTasks -Silent
