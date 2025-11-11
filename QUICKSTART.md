# 🚀 Guide de Démarrage Rapide

## Installation et lancement en 3 étapes

### 1. Installer les dépendances
```bash
cd medication_editor
flutter pub get
```

### 2. Lancer l'application

**Sur mobile (Android/iOS) :**
```bash
flutter run
```

**Sur desktop :**
```bash
# Windows
flutter run -d windows

# macOS  
flutter run -d macos

# Linux
flutter run -d linux
```

### 3. Utiliser l'application

1. **Nouveau médicament** → Remplir les 4 étapes
2. **Enregistrer & Nouveau** → Ajouter d'autres médicaments
3. **Voir les médicaments** → Exporter JSON complet
4. Copier le JSON dans `medications.json` de ped_app

---

## Exemple d'utilisation

### Ajouter l'Amoxicilline

**Étape 1 - Infos générales :**
- Nom : Amoxicilline
- Nom commercial : Clamoxyl
- Famille : Antibiotique

**Étape 2 - Posologies :**
- Cliquer "Ajouter"
- Indication : Infection bactérienne
- Dose : 50
- Unité : mg/kg/j
- Fréquence : 3x/j
- Voie : PO

**Étape 3 - Précautions :**
- Cocher "Ajuster selon fonction rénale"

**Étape 4 - Export :**
- Vérifier l'aperçu
- Copier le JSON ou Enregistrer

---

## Raccourcis utiles

- **Ctrl/Cmd + C** : Copier le JSON
- **Retour** : Revenir à l'étape précédente
- **Échap** : Fermer les dialogues

## Support

Pour toute question sur l'utilisation, référez-vous au README.md complet.
