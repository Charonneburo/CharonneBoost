# ============================================================
# CHARONNE BOOST 0.77
# Optimiseur Windows atelier -- Charonne Buro Paris 11e
# Developpe par M. Condamine | Propulse par Claude IA
# www.charonneburo.com -- 01 43 79 35 40
# ============================================================
# POINT D ENTREE -- charge les modules dans l ordre strict
# Aucune logique applicative ici.
# ============================================================

param()

# ============================================================
# AUTO-ELEVATION ADMIN : si le script n'est pas lance en admin,
# Windows affiche uniquement la fenetre UAC puis relance le programme.
# ============================================================
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    $psi.WorkingDirectory = $PSScriptRoot
    $psi.Verb = "runas"
    try { [System.Diagnostics.Process]::Start($psi) | Out-Null } catch { }
    exit
}

# Verifier PowerShell 5.1 minimum (avant tout chargement)
if ($PSVersionTable.PSVersion.Major -lt 5 -or
   ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        "PowerShell 5.1 minimum requis.`nVersion detectee : $($PSVersionTable.PSVersion)`n`nMettre a jour via Windows Update.",
        "Charonne Boost -- Erreur",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}

# $scriptDir : racine du projet, transmis a tous les modules par dot-sourcing
# Remplace $PSScriptRoot qui n est pas disponible dans les scripts dot-sources
$scriptDir = $PSScriptRoot

# Verifier que le dossier modules existe
$modulesDir = Join-Path $scriptDir "modules"
if (-not (Test-Path $modulesDir)) {
    Add-Type -AssemblyName System.Windows.Forms | Out-Null
    [System.Windows.Forms.MessageBox]::Show(
        "Dossier 'modules\' introuvable dans :`n$scriptDir`n`nVerifiez que vous avez extrait l archive complete.",
        "Charonne Boost -- Structure manquante",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    exit 1
}

# ============================================================
# CHARGEMENT DES MODULES -- ordre strict, dependances lineaires
# ============================================================

# 1. Assemblies .NET + layout $L[] + couleurs globales + form + tabControl
. "$modulesDir\00_init.ps1"

# 2. Fonctions partagees : Write-Log, Get-DiskType, New-RestorePointSafe,
#    New-Grid, HtmlRows, Get-UninstallCache, Get-AppxCache
. "$modulesDir\01_helpers.ps1"

# 3. Onglets UI (chacun ajoute ses TabPages + logique interne)
. "$modulesDir\02_tab_systeme.ps1"       # Config Systeme
. "$modulesDir\03_tab_bloatwares.ps1"    # Purge Bloatwares
. "$modulesDir\04_tab_logiciels.ps1"     # Logiciels
. "$modulesDir\05_tab_reseau.ps1"        # Reseau / Securite (accordeon)
. "$modulesDir\06_tab_navigateurs.ps1"   # Navigateurs + analyse espace
. "$modulesDir\07_tab_demarrage.ps1"     # Demarrage
. "$modulesDir\08_tab_diagnostic.ps1"    # Diagnostic + GPU + AV + RAM
. "$modulesDir\09_tab_desinstaller.ps1"  # Desinstaller
. "$modulesDir\10_tab_historique.ps1"    # Historique + Qui sommes nous


# 3b. Nouveaux modules V7 Option C
. "$modulesDir\13_tab_raccourcis_windows.ps1"
. "$modulesDir\14_v7_shell.ps1"

# 4. Rapport HTML (fonction Invoke-Rapport appelee par le moteur)
. "$modulesDir\12_rapport.ps1"

# 4b. Moteur de rollback systeme (Save-SystemSnapshot / Restore-SystemSnapshot)
. "$modulesDir\12b_rollback.ps1"

# 5. Moteur d execution, session log, ShowDialog
. "$modulesDir\11_moteur.ps1"
