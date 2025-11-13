# Plan de travail - Implémentation des Protocoles dans Medication Editor

## 📋 Plan de travail complet

### 1. **Nouveaux modèles de données** (à créer)

**Fichier : `lib/models/protocol.dart`**
- Classe `Protocol` (nom, description, etapes)
- Classe `Etape` (titre, temps, elements, attention)
- Classe `Element` (classe abstraite/base)
- Classe `ElementTexte` extends Element (type, texte)
- Classe `ElementMedicament` extends Element (type, medicament)
- Classe `MedicamentReference` (nom, indication, voie)
- Méthodes `toJson()` et `fromJson()` pour chaque classe

### 2. **Service de gestion des protocoles** (à créer)

**Fichier : `lib/services/protocol_provider.dart`**
- Gestion de la liste des protocoles
- CRUD protocole (create, read, update, delete)
- Gestion du protocole en cours d'édition
- Gestion de l'étape en cours d'édition
- Import depuis GitHub
- Export JSON trié alphabétiquement
- État d'édition (comme pour medications)

### 3. **Écrans de protocoles** (à créer)

**Fichier : `lib/screens/protocol_home_screen.dart`**
- Écran d'accueil des protocoles
- Boutons : "Nouveau protocole" / "Voir les protocoles"
- Import automatique depuis GitHub au démarrage

**Fichier : `lib/screens/protocol_general_info_screen.dart`**
- Étape 1/3 : Informations générales
- Champs : nom du protocole, description

**Fichier : `lib/screens/protocol_steps_screen.dart`**
- Étape 2/3 : Gestion des étapes
- Liste des étapes créées
- Boutons : ajouter/éditer/supprimer des étapes
- Navigation vers l'éditeur d'étape

**Fichier : `lib/screens/protocol_step_editor_screen.dart`**
- Éditeur d'une étape individuelle
- Champs : titre, temps (optionnel), attention (optionnel)
- Liste des éléments de l'étape
- Boutons : ajouter élément texte / ajouter élément médicament

**Fichier : `lib/screens/protocol_preview_screen.dart`**
- Étape 3/3 : Aperçu et export
- Affichage formaté du protocole
- Affichage du JSON généré
- Bouton copier JSON
- Bouton enregistrer

**Fichier : `lib/screens/protocol_list_screen.dart`**
- Liste de tous les protocoles
- Affichage en cards avec expansion
- Bouton édition (crayon) pour chaque protocole
- Bouton suppression
- Bouton export JSON global

### 4. **Widgets de protocoles** (à créer)

**Fichier : `lib/widgets/element_form_dialog.dart`**
- Dialog pour ajouter/éditer un élément
- Toggle : Type "Texte" / "Médicament"
- Si texte : TextFormField multiligne
- Si médicament : 3 champs (nom, indication, voie)

**Fichier : `lib/widgets/element_display_card.dart`** (optionnel)
- Widget réutilisable pour afficher un élément
- Icônes différentes selon le type
- Formatage du texte avec puces

### 5. **Fichiers à modifier**

**`lib/main.dart`**
- Ajouter `ProtocolProvider` dans MultiProvider
- (Modifier ChangeNotifierProvider en MultiProvider)

**`lib/screens/home_screen.dart`**
- Ajouter un onglet ou section pour accéder aux protocoles
- Option 1 : TabBar avec 2 onglets (Médicaments / Protocoles)
- Option 2 : Deux boutons sur l'écran d'accueil

**`pubspec.yaml`**
- Déjà à jour (pas de nouvelle dépendance nécessaire)

### 6. **Structure de dossiers finale**

```
lib/
├── main.dart (MODIFIÉ)
├── models/
│   ├── medication.dart (existant)
│   └── protocol.dart (NOUVEAU)
├── services/
│   ├── medication_provider.dart (existant)
│   └── protocol_provider.dart (NOUVEAU)
├── screens/
│   ├── home_screen.dart (MODIFIÉ)
│   ├── medication_*.dart (existants)
│   ├── protocol_home_screen.dart (NOUVEAU)
│   ├── protocol_general_info_screen.dart (NOUVEAU)
│   ├── protocol_steps_screen.dart (NOUVEAU)
│   ├── protocol_step_editor_screen.dart (NOUVEAU)
│   ├── protocol_preview_screen.dart (NOUVEAU)
│   └── protocol_list_screen.dart (NOUVEAU)
├── widgets/
│   ├── posology_form_dialog.dart (existant)
│   ├── element_form_dialog.dart (NOUVEAU)
│   └── element_display_card.dart (NOUVEAU - optionnel)
└── utils/
    └── constants.dart (existant)
```

---

## 🎯 Ordre de développement recommandé

1. **Modèles** (`protocol.dart`) - base de tout
2. **Provider** (`protocol_provider.dart`) - logique métier
3. **Écrans de création** (general_info → steps → step_editor → preview)
4. **Widget dialog** (`element_form_dialog.dart`)
5. **Écran de liste** (`protocol_list_screen.dart`)
6. **Écran d'accueil** (`protocol_home_screen.dart`)
7. **Intégration** (modifier `main.dart` et `home_screen.dart`)

---

## 📝 Notes importantes

- **Réutilisation du code** : La structure est très similaire aux médicaments
- **GitHub URL** : `https://raw.githubusercontent.com/Z4rsi0/ped_app_data/main/assets/protocoles/[nom_fichier].json`
- **Liste des protocoles** : Il faudra soit hardcoder la liste des noms de fichiers, soit utiliser l'API GitHub pour lister le contenu du dossier
- **Formatage du texte** : Gérer `\n` et `•` dans l'affichage
- **Validation** : Vérifier qu'au moins une étape existe, qu'une étape a au moins un élément

---

## 📊 Structure JSON d'un protocole (rappel)

```json
{
  "nom": "Titre du protocole",
  "description": "Description courte du protocole",
  "etapes": [
    {
      "titre": "Nom de l'étape",
      "temps": "T0",
      "elements": [
        {
          "type": "texte",
          "texte": "Instructions en texte libre"
        },
        {
          "type": "medicament",
          "medicament": {
            "nom": "Nom du médicament",
            "indication": "Indication spécifique",
            "voie": "IV"
          }
        }
      ],
      "attention": "⚠️ Alerte importante"
    }
  ]
}
```

### Types d'éléments

#### 1. Élément texte
```json
{
  "type": "texte",
  "texte": "• Libération des voies aériennes\n• Oxygénothérapie\n• Position latérale de sécurité"
}
```

**Formatage du texte :**
- `\n` pour les sauts de ligne
- `•` pour les puces
- `**texte**` pour le gras (non supporté actuellement)

#### 2. Élément médicament
```json
{
  "type": "medicament",
  "medicament": {
    "nom": "Midazolam",
    "indication": "Convulsions",
    "voie": "IV"
  }
}
```

**Fonctionnement :**
- L'application recherche automatiquement le médicament dans `medicaments_pediatrie.json`
- Elle affiche la dose calculée pour le poids de l'enfant
- Elle affiche la préparation et les instructions

### Champs d'une étape

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `titre` | String | ✅ | Titre de l'étape |
| `temps` | String | ❌ | Timing (T0, T5, T10...) |
| `elements` | Array | ✅ | Liste des éléments |
| `attention` | String | ❌ | Alerte/warning important |

---

## 🚀 Prochaines étapes

Une fois le plan validé, nous commencerons par :
1. Créer `lib/models/protocol.dart`
2. Créer `lib/services/protocol_provider.dart`
3. Puis continuer avec les écrans dans l'ordre recommandé