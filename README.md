# Medication Editor - Éditeur de Médicaments pour ped_app

Application Flutter cross-platform (mobile et desktop) pour faciliter l'ajout de médicaments dans ped_app.

## 🎯 Fonctionnalités

- **Interface guidée en 4 étapes** :
  1. Informations générales (nom, famille, remarques)
  2. Posologies multiples avec validation
  3. Précautions et contre-indications
  4. Prévisualisation et export JSON

- **Gestion des posologies** :
  - Ajout/modification/suppression
  - Choix entre dose fixe ou plage (min-max)
  - Validation automatique (max > min)
  - Vue d'ensemble des posologies ajoutées

- **Données standardisées** :
  - Familles thérapeutiques
  - Unités de dose (mg/kg/j, µg/kg/dose, etc.)
  - Fréquences d'administration
  - Voies d'administration
  - Précautions et contre-indications courantes

- **Export flexible** :
  - Copie JSON d'un médicament individuel
  - Export JSON complet de tous les médicaments
  - Format prêt pour medications.json de ped_app

## 🚀 Installation

### Prérequis
- Flutter SDK >= 3.0.0
- Dart SDK >= 3.0.0

### Configuration
```bash
cd medication_editor
flutter pub get
```

## 📱 Lancement

### Mobile (Android/iOS)
```bash
# Android
flutter run

# iOS
flutter run -d ios
```

### Desktop

```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos

# Linux
flutter run -d linux
```

## 📖 Guide d'utilisation

### 1. Créer un nouveau médicament
- Cliquez sur "Nouveau médicament"
- Remplissez les informations générales (nom obligatoire, famille obligatoire)
- Passez à l'étape suivante

### 2. Ajouter des posologies
- Cliquez sur "Ajouter" pour créer une posologie
- Remplissez les champs (indication, dose, unité, fréquence)
- Choisissez entre :
  - **Dose fixe** : une seule valeur de dose
  - **Plage de doses** : min et max (avec validation automatique)
- Sélectionnez l'unité dans la liste standardisée
- Les posologies ajoutées apparaissent dans la liste
- Vous pouvez éditer ou supprimer chaque posologie

### 3. Précautions et contre-indications
- Cochez les précautions applicables dans la liste
- Ajoutez des précautions personnalisées si nécessaire
- Même processus pour les contre-indications
- Les éléments sélectionnés apparaissent sous forme de chips

### 4. Prévisualisation et export
- Vérifiez toutes les informations dans l'aperçu
- Visualisez le JSON généré
- **Copier le JSON** : copie dans le presse-papier
- **Enregistrer & Nouveau** : ajoute à la liste et permet d'ajouter un autre médicament

### 5. Gestion de la liste
- Accédez à "Voir les médicaments" depuis l'accueil
- Consultez tous les médicaments ajoutés
- Développez chaque carte pour voir les détails
- Actions disponibles :
  - Copier le JSON d'un médicament
  - Supprimer un médicament
  - Exporter tous les médicaments en JSON

## 📋 Format JSON généré

Le JSON généré est compatible avec le format de ped_app :

```json
{
  "nom": "Amoxicilline",
  "nom_commercial": "Clamoxyl",
  "famille": "Antibiotique",
  "posologies": [
    {
      "indication": "Infection bactérienne",
      "dose": 50,
      "unite": "mg/kg/j",
      "frequency": "3x/j",
      "admin_route": "PO"
    }
  ],
  "precautions": [
    "Ajuster selon fonction rénale"
  ],
  "contre_indications": [
    "Allergie connue"
  ]
}
```

## 🎨 Interface

- **Design Material 3** avec thème Teal
- **Responsive** : s'adapte aux différentes tailles d'écran
- **Barre de progression** : visualisation de l'avancement
- **Validation en temps réel** : messages d'erreur clairs
- **Feedback visuel** : SnackBars pour confirmer les actions

## 🔧 Structure du projet

```
lib/
├── main.dart                           # Point d'entrée
├── models/
│   └── medication.dart                 # Modèles de données
├── screens/
│   ├── home_screen.dart                # Écran d'accueil
│   ├── general_info_screen.dart        # Étape 1
│   ├── posology_screen.dart            # Étape 2
│   ├── precautions_screen.dart         # Étape 3
│   ├── preview_screen.dart             # Étape 4
│   └── medication_list_screen.dart     # Liste complète
├── widgets/
│   └── posology_form_dialog.dart       # Formulaire de posologie
├── services/
│   └── medication_provider.dart        # Gestion d'état
└── utils/
    └── constants.dart                  # Données standardisées
```

## 🔄 Workflow typique

1. Créer plusieurs médicaments via "Nouveau médicament"
2. Chaque médicament est ajouté à la liste après "Enregistrer & Nouveau"
3. Une fois tous les médicaments créés, aller dans "Voir les médicaments"
4. Cliquer sur "Exporter JSON" pour obtenir le JSON complet
5. Copier le contenu dans `medications.json` de ped_app

## ⚠️ Validations intégrées

- Nom du médicament obligatoire
- Famille thérapeutique obligatoire
- Au moins une posologie requise
- max_dose > min_dose (si plage de doses)
- Unités standardisées pour cohérence

## 💡 Conseils d'utilisation

- Utilisez les **données standardisées** pour garantir la cohérence
- Les **précautions courantes** sont pré-remplies, vous pouvez en ajouter des personnalisées
- Le **JSON est automatiquement formaté** avec indentation
- Vous pouvez **éditer les posologies** après les avoir ajoutées
- La **liste des médicaments persiste** durant la session de l'application

## 🚧 Futures améliorations possibles

- [ ] Sauvegarde persistante des médicaments
- [ ] Import de JSON existant pour édition
- [ ] Push automatique vers GitHub
- [ ] Recherche et filtrage dans la liste
- [ ] Export en CSV
- [ ] Templates de médicaments courants
- [ ] Duplication de médicaments similaires

## 📄 Licence

Ce projet est un outil interne pour ped_app.
