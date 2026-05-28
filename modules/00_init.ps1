#Requires -RunAsAdministrator
# ============================================================
# CHARONNE BURO - Charonne Boost 0.77
# Developpe par M. Condamine | Propulse par Claude IA
# ============================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Pas de SetProcessDpiAwareness : PowerShell herite du manifest system-aware de cmd.exe.
# WinForms recoit les coordonnees en pixels logiques (deja mis a l echelle par Windows).
# On travaille donc directement en pixels logiques -- pas de conversion a faire.

[System.Windows.Forms.Application]::EnableVisualStyles()

# ============================================================
# LAYOUT ADAPTATIF -- pixels logiques, toutes resolutions
# ============================================================
$L = @{}

# Espace disponible en pixels logiques (ce que WinForms voit)
$sw = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$sh = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Fenetre : occupe 90% de l ecran logique, plafonnee a 1020x680, plancher a 700x500
$fwTarget = [math]::Min(1020, [int]($sw * 0.90))
$fhTarget = [math]::Min(680,  [int]($sh * 0.90))
$L["FormW"] = [math]::Max(700, $fwTarget)
$L["FormH"] = [math]::Max(500, $fhTarget)

# Echelle de mise en page (reference : 1020x680)
$sc = [math]::Min([double]$L["FormW"] / 1020.0, [double]$L["FormH"] / 680.0)
$sc = [math]::Max(0.65, [math]::Min(1.0, $sc))

# Header
$L["TitleSize"] = [math]::Max(1, [int](18 * $sc))
$L["VerSize"]   = [math]::Max(1, [int](9  * $sc))
$L["HeaderH"]   = [int](75 * $sc)

# TabControl -- bouton dans le header donc seul progressbar+status en bas (44px)
$L["TabX"]      = 6
$L["TabY"]      = $L["HeaderH"]
$L["TabW"]      = $L["FormW"] - 12     # colle aux bords, -12 pour les bordures form
$bottomH        = 44                    # progressbar(20) + status(20) + marges(4)
$L["TabH"]      = $L["FormH"] - $L["HeaderH"] - $bottomH - 4

# Contenu interieur tab (bordure tab ~22px haut, ~4px bas, ~6px cotes)
$L["InnerW"]    = $L["TabW"] - 12
$L["InnerH"]    = $L["TabH"] - 26

# Grille 3 colonnes -- symetrie parfaite
# On calcule ColW exact puis on centre le bloc de 3 colonnes dans InnerW
$L["ColW"]      = [int](($L["InnerW"] - 16) / 3)          # -16 = 2 marges x 4px + 2 gaps x 4px
$L["ColGap"]    = 4                                         # ecart fixe entre colonnes
$L["ColMargin"] = [int](($L["InnerW"] - 3 * $L["ColW"] - 2 * $L["ColGap"]) / 2)  # marge laterale egale des 2 cotes
$L["ColStep"]   = $L["ColW"] + $L["ColGap"]
$L["CardW"]     = $L["ColW"]                               # la carte occupe toute la largeur de colonne

# Hauteurs de cartes : padding vertical uniforme, hauteur calculee depuis l espace dispo
$cardPad = 6                                                # padding vertical entre cartes
$availH  = $L["InnerH"] - 44 - $cardPad                    # 44 = barre boutons haut, cardPad = marge basse
$L["SysCardH"]   = [math]::Max(48, [int](($availH - 4 * $cardPad) / 5))
$L["SysRowH"]    = $L["SysCardH"] + $cardPad
# BloatCardH fixe : 58px compact, scroll actif sur le panel
$L["BloatCardH"] = 58
$L["BloatRowH"]  = $L["BloatCardH"] + 4
$L["AppCardH"]   = 72     # cartes icones : icone 40px + nom + marge
$L["AppRowH"]    = $L["AppCardH"] + $cardPad

# Reseau/Securite
$L["GrpNetH"]    = [int](0.34 * $L["InnerH"])
$L["PingH"]      = [int](0.20 * $L["InnerH"])
$L["GrpSecH"]    = $L["InnerH"] - $L["GrpNetH"] - $L["PingH"] - 8
$L["NetColW"]    = [int](($L["InnerW"] - 8) / 3)
$L["NetColStep"] = $L["NetColW"] + $L["ColGap"]
$L["NetColMargin"]= [int](($L["InnerW"] - 3 * $L["NetColW"] - 2 * $L["ColGap"]) / 2)

# Navigateurs
$L["NavCardInstalledH"] = [math]::Max(70, [int](90 * $sc))
$L["NavCardMissingH"]   = [math]::Max(44, [int](54 * $sc))
$L["NavOptW"]           = [int](($L["InnerW"] - 100) / 5 - 6)   # 5 opts dans la largeur dispo, gap 4px inclus
$L["NavOptStep"]        = $L["NavOptW"] + 4

# ListViews et zones texte
$L["LvH"]       = $L["InnerH"] - 46
$L["DiagBoxH"]  = $L["InnerH"] - 36
$L["UninstLvH"] = $L["InnerH"] - 44
$L["HistBoxH"]  = $L["InnerH"] - 44
$L["QuiBodyH"]  = [math]::Max(80, $L["InnerH"] - 0)

# Barre du bas (progressbar + status seulement)
$L["ProgY"]     = $L["TabY"] + $L["TabH"] + 4
$L["StatusY"]   = $L["ProgY"] + 22


# Verification version PowerShell (minimum 5.1)
if ($PSVersionTable.PSVersion.Major -lt 5 -or
    ($PSVersionTable.PSVersion.Major -eq 5 -and $PSVersionTable.PSVersion.Minor -lt 1)) {
    [System.Windows.Forms.MessageBox]::Show(
        "PowerShell 5.1 minimum requis.`nVersion detectee : $($PSVersionTable.PSVersion)`n`nMettez a jour Windows ou installez WMF 5.1.",
        "Version incompatible",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error)
    exit 1
}

# Verification admin explicite (double securite)
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    [System.Windows.Forms.MessageBox]::Show(
        "Ce programme doit etre execute en tant qu Administrateur.`nClic droit -> Executer en tant qu administrateur.",
        "Droits insuffisants",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    )
    exit 1
}

# Fonction : creer un point de restauration avec verification
