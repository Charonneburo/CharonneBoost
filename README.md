# Charonne Boost 0.77.2
### Optimiseur Windows professionnel — Charonne Buro Paris 11e

> Developpe par M. Condamine | Propulse par Claude IA
> Charonne Buro — 129 boulevard de Charonne, 75011 Paris — 01 43 79 35 40
> www.charonneburo.com

---

## Qu est-ce que Charonne Boost ?

Charonne Boost est un outil d optimisation Windows developpe en PowerShell.
Il permet en quelques clics de :

- Nettoyer un poste Windows de ses fichiers inutiles et bloatwares
- Installer les logiciels essentiels du quotidien
- Optimiser les performances et la confidentialite
- Diagnostiquer materiel, securite, et etat systeme
- Reparer les problemes reseau
- Renforcer la securite du systeme

---

## Structure des fichiers

```
CharonneBoost\
  Purge.ps1                    Point d entree (charge les modules)
  Lancer_CharonneBoost_Admin.cmd  Lanceur principal avec elevation UAC
  prefs.json                   Preferences utilisateur (auto-genere)
  modules\
    00_init.ps1                Assemblies, layout $L[], couleurs, form
    01_helpers.ps1             Fonctions partagees (Write-Log, New-Grid...)
    02_tab_systeme.ps1         Onglet Configuration Systeme
    03_tab_bloatwares.ps1      Onglet Purge Bloatwares
    04_tab_logiciels.ps1       Onglet Logiciels
    05_tab_reseau.ps1          Onglet Reseau / Securite
    06_tab_navigateurs.ps1     Onglet Navigateurs
    07_tab_demarrage.ps1       Onglet Demarrage
    08_tab_diagnostic.ps1      Onglet Diagnostic
    09_tab_desinstaller.ps1    Onglet Desinstaller
    10_tab_historique.ps1      Onglet Historique + Qui sommes nous
    11_moteur.ps1              Moteur execution, rapport HTML, lancement
  png\
    logo2.png                  Logo Charonne Buro (requis)
    qrcode_avis.png            QR code avis Google (optionnel)
    firefox.png                Icones logiciels (optionnels)
    chrome.png
    vlc.png  gimp.png  xnview.png  winrar.png  7zip.png
    pdf24.png  acrobat.png  notepad.png  everything.png
    wise.png  libreoffice.png  office.png
    anydesk.png  teamviewer.png  malwarebytes.png  adwcleaner.png
    opera.png
  logs\                        Journaux de session (auto-generes)
  Logiciels\                   Cache installeurs telecharges (auto-genere)
```

### Dossiers auto-generes au premier lancement
- `logs\` -- journaux de session (uniquement si actions effectuees)
- `Logiciels\` -- cache des installeurs telecharges

## Lancement

**Ne pas double-cliquer sur `Purge.ps1` directement.**

1. Clic droit sur `Lancer_CharonneBoost_Admin.cmd`
2. Executer en tant qu administrateur

> Le programme necessite les droits administrateur.

---

## Onglets disponibles

| Onglet | Contenu |
|--------|---------|
| Configuration Systeme | 14 actions : nettoyage, confidentialite, performances |
| Purge Bloatwares | 24 bloatwares Microsoft / reseaux sociaux / streaming |
| Logiciels | 19 logiciels par categorie, installation automatique |
| Reseau / Securite | Accordeon pliable, ping interactif |
| Navigateurs | Nettoyage cache/cookies + analyse espace recuperable |
| Demarrage | Gestion des programmes au demarrage |
| Diagnostic | Systeme, CPU, RAM slots, GPU, disques physiques, AV |
| Desinstaller | Desinstallation avec recherche |
| Historique | Logs de session + rollback services |
| Qui sommes nous | Coordonnees + QR code |

---

## Securite et compatibilite

- **Droits requis** : Administrateur
- **PowerShell minimum** : 5.1
- **Compatibilite** : Windows 10 / Windows 11 (toutes editions)
- **Rollback services** : JSON sauvegarde avant toute desactivation
- **Log de session** : sauvegarde uniquement si actions effectuees

---

## Architecture technique (v7 Option C)

### Modularisation
Le fichier unique de 230 Ko est decoupage en 12 modules :
- `Purge.ps1` est un point d entree de 50 lignes (dot-sourcing)
- Chaque module = 100-850 lignes, responsabilite unique
- `$scriptDir` transmis depuis `Purge.ps1` a tous les modules
- Ajout d un onglet = creer un fichier dans `modules\`

### Performances
- `Get-UninstallCache` : registre lu une seule fois
- `Get-AppxCache` : `Get-AppxPackage -AllUsers` en `Start-Job` (non-bloquant)
- `[IO.Directory]::EnumerateFiles()` pour le scan de cache navigateurs
- `Get-DiskType` via `MSFT_PhysicalDisk` (BusType=17 = NVMe)

### Securite
- Validation regex anti-injection sur `UninstallString`
- Rollback services JSON avant toute desactivation
- Systeme de risque `low / medium / high` sur chaque action

---

## Historique des versions

### v7 Option C -- Mai 2026
- Modularisation : 12 fichiers au lieu de 1 (230 Ko -> modules de 5-52 Ko)
- Onglet 1 : cartes horizontales compactes 2 colonnes, codes couleur risque
- Onglet 3 : logiciels tries par categorie avec bandeaux
- Onglet 4 : accordeon pliable Reseau / Securite
- Diagnostic : GPU (driver, date, VRAM), RAM slots DDR, disques physiques NVMe
- Analyse espace navigateurs non bloquante (IO.Directory.EnumerateFiles)
- Log de session conditionnel (uniquement si actions effectuees)
- Nouveau : XnView, Opera dans les logiciels
- Nouveau : Teams, Bing, Photos, Power Automate dans les bloatwares
- Nouveau : bouton "Installation basique CB" (VLC + 7-Zip + Firefox + Wise)

### v12.0 -- Mai 2025
- Refonte complete de l interface Windows Forms
- Diagnostic systeme complet
- Rapport HTML avec sections groupees et logo inline

### v11.0 -- Avril 2025
- Premiere version stable avec rapport HTML

---

## Contact

**Charonne Buro**
129 boulevard de Charonne, 75011 Paris
Metro Ligne 2 -- Station Alexandre Dumas
Tel : 01 43 79 35 40
Email : contact@charonneburo.com
Web : www.charonneburo.com

*Maintenance sur PC, Mac et Linux | Vente materiel d occasion*
*Installation, configuration, nettoyage et optimisation*
*Intervention a domicile ou en boutique*

---
*Charonne Boost 0.77 -- Developpe par M. Condamine -- Propulse par Claude IA*
*Charonne Buro 2026 -- Tous droits reserves*


## Durcissement sécurité ajouté

- Les lanceurs ne forcent plus `-ExecutionPolicy Bypass`.
- Les téléchargements passent par `Invoke-CBSafeDownload` quand le moteur principal est utilisé.
- Les exécutables téléchargés sont contrôlés par signature Authenticode avant lancement. Si la signature n'est pas valide, l'utilisateur doit confirmer explicitement ou l'action est annulée.
- Les actions sensibles affichent une confirmation globale avant exécution.
- WinSxS/CBS/servicing stack restent exclus du nettoyage manuel.

Pour distribution client, signer `Purge.ps1`, les modules `.ps1` et le lanceur principal. Sans signature publique, Windows peut toujours afficher des alertes SmartScreen.


## Lancement recommandé
Utiliser `Lancer_CharonneBoost_Admin.cmd`. Le lanceur demande l'UAC Windows et applique `ExecutionPolicy Bypass` uniquement au processus lancé, afin d'éviter les blocages classiques PowerShell sur les scripts locaux non signés.

## V7.4 Pro - stabilisation atelier

Ajouts par rapport a la V7.3 responsive :

- **Pre-check securite** : verifie les droits admin, Windows, espace disque, Windows Update, service cryptographique, antivirus, Internet, batterie/secteur et dernier snapshot.
- **Simulation** : affiche les actions cochees sans rien modifier. Utile avant intervention client.
- **Reparer Windows** : lance uniquement les commandes propres `DISM /Online /Cleanup-Image /RestoreHealth` puis `sfc /scannow`. Aucun nettoyage manuel WinSxS.
- **Logs live enrichis** : niveaux `[INFO]`, `[OK]`, `[WARNING]`, `[ERROR]`, `[PURGE]` dans la console.
- **Rapport HTML manuel ameliore** : ajoute les infos machine, Windows, CPU, RAM/disque et la liste des actions selectionnees au moment de l export.

Recommandation atelier : lancer **Pre-check**, puis **Simulation**, puis seulement ensuite l optimisation.


## V7.5 optimisation interface
- Header compact pour gagner de la hauteur en 1366x768.
- Sidebar reduite et navigation plus dense.
- Console live reduite, en RichTextBox, avec couleurs par niveau : INFO / OK / WARNING / ERROR.
- Bouton de refresh rollback remplace par le texte `Actualiser` pour eviter les problemes Unicode WinForms.
- Boutons rapides plus compacts.
- Aucun changement fonctionnel dangereux : optimisation UI uniquement.


## Nettoyage structurel V7.7

Fichiers supprimes pour eviter les doublons et la confusion :

- `Lancer_Purge.bat` : doublon de `Lancer_CharonneBoost_Admin.cmd`.
- `bloatware.ps1` : logique fusionnee dans `modules/03_tab_bloatwares.ps1`.
- `modules/00_icons.ps1` : gros fichier Base64 inutile, remplace par le dossier `png`.
- `CharonneBoost_Radial.ps1`, `Lancer_Radial.bat`, `RadialMenu.dll`, `RadialMenu.dll.sha256` : interface radiale optionnelle retiree du pack propre.

Pourquoi supprimer `00_icons.ps1` ?

Il embarquait les icones en Base64 dans PowerShell, ce qui alourdissait le projet d'environ 2,7 Mo et dupliquait le dossier `png`. Comme l'interface charge deja les images depuis `png`, garder les deux sources creait un risque d'icones differentes selon les modules. Le dossier `png` devient la source unique.

Les icones bloatwares sont maintenant gerees automatiquement : locale `png/bloat_*.png`, sinon lecture AppxManifest.xml, sinon fallback graphique.


## Version 0.76 - base propre avant 1.0

Objectif : repartir sur une numerotation credible avant la future 1.0 stable. Les changements majeurs incrementent la version 0.xx.

Changements :

- Suppression de Total Commander de la liste des logiciels. Installation manuelle au cas par cas.
- Suppression de `tc_install.inf`, devenu inutile.
- Suppression de `png/total.png`, icone non utilisee apres retrait de Total Commander.
- Suppression de `Orbitron-Bold.ttf` du pack : l interface utilise Segoe UI, deja presente dans Windows.
- Raccourcis Windows redesignes : tuiles compactes, accents couleur par categorie, sans grosses lettres incomprehensibles.
- Raccourcis plus fiables : Affichage utilise `control.exe desk.cpl`, Son utilise `control.exe mmsys.cpl`, Programmes utilise `appwiz.cpl`.
- Menu gauche corrige : Historique reste Historique ; la partie presentation reste dans "Qui sommes nous".
- Boutons Historique recolores pour corriger les cas blanc sur blanc.

Politique de version :

- 0.76 : base atelier nettoyee.
- 0.77+ : modifications fonctionnelles ou UI importantes.
- 0.90+ : phase pre-1.0, gel progressif des fonctions.
- 1.0 : version stable signee et documentee.


## Version 0.76.1

Correctif : les raccourcis Windows n’envoient plus les objets WinForms `Label` / `MouseEventArgs` comme arguments aux commandes (`regedit`, `control.exe`, `diskmgmt.msc`, etc.).

## Historique versions recentes

- 0.77 : affichage bloatwares corrige, selection blanche lisible, badges Present/Absent, suppression des grosses lettres fallback.
- 0.76.1 : correctif raccourcis Windows, suppression des arguments parasites MouseEventArgs.
- 0.76 : base propre, Total Commander retire, raccourcis Windows compactes.

## Version 0.77 - refonte visuelle coherente

- Refonte de la grille Logiciels en cartes compactes et lisibles.
- Suppression des grosses initiales et des paves colores inutiles.
- Bloatwares : retrait des boutons de categorie en haut, sections visuelles plus claires.
- Interface plus homogene avec le style atelier / console technicien.
- Version 0.77 reservee aux grosses transformations UI avant 1.0.
