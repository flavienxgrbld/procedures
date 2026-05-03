# Script PowerShell pour générer les README.md pour chaque solution

$workspacePath = "r:\git\procedures"

Get-ChildItem -Path $workspacePath -Directory | Where-Object { $_.Name -ne ".git" } | ForEach-Object {
    $dir = $_.FullName
    $scriptFile = Get-ChildItem -Path $dir -Filter "install_*.sh" | Select-Object -First 1
    if ($scriptFile) {
        $content = Get-Content -Path $scriptFile.FullName -Raw
        # Extraire la description après "info "
        $descriptionMatch = [regex]::Match($content, 'info "([^"]*)"')
        $description = if ($descriptionMatch.Success) { $descriptionMatch.Groups[1].Value } else { "Description non trouvée" }
        
        # Extraire les sections echo ===
        $sections = [regex]::Matches($content, 'echo "=== ([^=]+) ==="') | ForEach-Object { $_.Groups[1].Value }
        
        # Générer le README.md
        $readmeContent = @"
# Installation $($_.Name)

## Description
$description

## Prérequis
- Ubuntu/Debian Linux (ou autre distribution supportée)
- Accès root ou sudo
- Connexion Internet

## Installation

Exécutez le script d'installation :

```bash
bash install_$($_.Name).sh
```

### Étapes détaillées

"@
        
        foreach ($section in $sections) {
            $readmeContent += "### $section`n`n- [Détails à ajouter]`n`n"
        }
        
        $readmeContent += @"

## Configuration
[Ajouter les étapes de configuration manuelle si nécessaire]

## Vérification
- Vérifiez que le service est actif : `systemctl status [service]`
- Accédez à l'URL si applicable

## Documentation
- [Site officiel]()
- [Documentation]()

## Notes
[Ajouter vos notes ici]
"@

        $readmePath = Join-Path $dir "README.md"
        Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
    }
}