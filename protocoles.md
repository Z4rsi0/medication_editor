# Guide de Création des Protocoles Médicaux

## Introduction

L'éditeur de protocoles permet de créer des procédures médicales structurées et interactives. Les protocoles sont composés de **blocs** modulaires qui peuvent être réorganisés, imbriqués et personnalisés.

## Structure d'un Protocole

### Métadonnées

Chaque protocole contient :
- **Titre** (obligatoire) : Nom du protocole
- **Description** : Résumé du protocole
- **Auteur** : Créateur/responsable du protocole
- **Version** : Numéro de version (ex: "1.0", "2.1")
- **Date de modification** : Mise à jour automatiquement à chaque sauvegarde

---

## Les Types de Blocs

### 1. Section (📁)

Conteneur pliable permettant d'organiser le protocole en étapes.

**Propriétés :**
- `titre` : Nom de la section
- `temps` : Durée estimée (optionnel, ex: "5 min")
- `initialementOuvert` : Si la section est dépliée par défaut
- `contenu` : Liste de sous-blocs

---

### 2. Texte (📝)

Bloc de texte avec formatage (gras, italique, souligné).

---

### 3. Tableau (📊)

Tableau de données avec colonnes et lignes configurables.

---

### 4. Image (🖼️)

Image par URL ou fichier local (base64).

---

### 5. Médicament (💊)

Référence à un médicament avec **conditions d'affichage par poids/âge**.

**Propriétés :**
- `nomMedicament` : Nom DCI (autocomplétion)
- `indication` : Indication thérapeutique (autocomplétion)
- `voie` : Voie d'administration (autocomplétion)
- `commentaire` : Note libre
- `condition` : Condition d'affichage

#### ⭐ Conditions de Poids/Âge

Permet d'afficher un médicament uniquement pour certaines tranches.

**Structure :**
```json
{
  "condition": {
    "poidsMin": 0,
    "poidsMax": 20,
    "ageMinMois": 0,
    "ageMaxMois": 72
  }
}
```

**Exemple : Corticothérapie Asthme**
- < 20 kg → Célestène gouttes (`poidsMax: 20`)
- ≥ 20 kg → Solupred comprimés (`poidsMin: 20`)

---

### 6. Formulaire / Score (🧮)

Score clinique interactif avec champs et interprétations.

**Types de champs :** nombre, selection, checkbox, radio

**Niveaux d'interprétation :** faible (vert), modere (orange), eleve (orange foncé), critique (rouge)

---

### 7. Alerte (⚠️)

Message d'avertissement.

**Niveaux :** info, attention, danger, critique

---

## Autocomplétion

L'éditeur propose une autocomplétion pour :
1. **Nom du médicament** : recherche dans la base
2. **Indication** : Douleur, Fièvre, Asthme, Épilepsie...
3. **Voie** : PO, IV, IM, SC, Inhalation, Rectale...

---

## Bonnes Pratiques

1. **Structurer en sections logiques** (Évaluation, Traitement, Surveillance)
2. **Utiliser les conditions de poids** pour les alternatives thérapeutiques
3. **Éviter les chevauchements** de conditions (poidsMax: 20 ET poidsMin: 20)
4. **Documenter** dans les commentaires

---

## Exemple Complet

```json
{
  "titre": "Asthme Aigu Grave",
  "description": "Prise en charge pédiatrique",
  "auteur": "Service de Pédiatrie",
  "version": "2.0",
  "blocs": [
    {
      "type": "alerte",
      "ordre": 0,
      "contenu": "Appel réanimateur si SpO2 < 90%",
      "niveau": "critique"
    },
    {
      "type": "section",
      "ordre": 1,
      "titre": "Corticothérapie",
      "contenu": [
        {
          "type": "medicament",
          "nomMedicament": "Bétaméthasone",
          "voie": "PO",
          "commentaire": "Célestène gouttes",
          "condition": {"poidsMax": 20}
        },
        {
          "type": "medicament",
          "nomMedicament": "Prednisolone",
          "voie": "PO",
          "commentaire": "Solupred",
          "condition": {"poidsMin": 20}
        }
      ]
    }
  ]
}
```