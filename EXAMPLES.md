# Exemples de JSON générés

Ces exemples montrent le format JSON généré par l'application pour différents types de médicaments.

---

## Exemple 1 : Médicament simple avec dose fixe

**Paracétamol (Doliprane)**

```json
{
  "nom": "Paracétamol",
  "nom_commercial": "Doliprane",
  "famille": "Antipyrétique",
  "posologies": [
    {
      "indication": "Fièvre",
      "dose": 15,
      "unite": "mg/kg/dose",
      "frequency": "toutes les 6h",
      "admin_route": "PO"
    },
    {
      "indication": "Douleur légère à modérée",
      "dose": 15,
      "unite": "mg/kg/dose",
      "frequency": "toutes les 6h",
      "admin_route": "PO",
      "remarques": "Max 60 mg/kg/j"
    }
  ],
  "precautions": [
    "Ajuster selon fonction hépatique"
  ]
}
```

---

## Exemple 2 : Antibiotique avec plage de doses

**Amoxicilline (Clamoxyl)**

```json
{
  "nom": "Amoxicilline",
  "nom_commercial": "Clamoxyl",
  "famille": "Antibiotique",
  "posologies": [
    {
      "indication": "Infection bactérienne",
      "min_dose": 40,
      "max_dose": 50,
      "unite": "mg/kg/j",
      "frequency": "3x/j",
      "admin_route": "PO"
    },
    {
      "indication": "Otite moyenne aiguë",
      "min_dose": 80,
      "max_dose": 90,
      "unite": "mg/kg/j",
      "frequency": "2x/j",
      "admin_route": "PO",
      "remarques": "Forte dose en cas de résistance"
    }
  ],
  "precautions": [
    "Ajuster selon fonction rénale"
  ],
  "contre_indications": [
    "Allergie connue",
    "Mononucléose infectieuse"
  ]
}
```

---

## Exemple 3 : Médicament complexe avec multiples indications

**Prednisolone (Solupred)**

```json
{
  "nom": "Prednisolone",
  "nom_commercial": "Solupred",
  "famille": "Corticoïde",
  "posologies": [
    {
      "indication": "Asthme",
      "dose": 1,
      "unite": "mg/kg/j",
      "frequency": "1x/j",
      "admin_route": "PO",
      "remarques": "3-5 jours"
    },
    {
      "indication": "Laryngite",
      "dose": 1,
      "unite": "mg/kg/dose",
      "frequency": "en dose unique",
      "admin_route": "PO"
    },
    {
      "indication": "Syndrome néphrotique",
      "dose": 60,
      "unite": "mg/m²/j",
      "frequency": "1x/j",
      "admin_route": "PO",
      "remarques": "Dose d'attaque, puis dégressif"
    }
  ],
  "precautions": [
    "Surveillance de la glycémie",
    "Surveillance de la tension artérielle",
    "À prendre pendant les repas",
    "Éviter l'arrêt brutal"
  ],
  "contre_indications": [
    "Infection non contrôlée",
    "Vaccination par virus vivant"
  ],
  "remarques": "Décroissance progressive nécessaire si traitement > 7 jours"
}
```

---

## Exemple 4 : Antiépileptique avec monitoring

**Valproate de sodium (Dépakine)**

```json
{
  "nom": "Valproate de sodium",
  "nom_commercial": "Dépakine",
  "famille": "Antiépileptique",
  "posologies": [
    {
      "indication": "Épilepsie",
      "min_dose": 20,
      "max_dose": 30,
      "unite": "mg/kg/j",
      "frequency": "2x/j",
      "admin_route": "PO",
      "remarques": "Augmentation progressive"
    },
    {
      "indication": "Convulsions fébriles",
      "dose": 20,
      "unite": "mg/kg/j",
      "frequency": "2x/j",
      "admin_route": "PO"
    }
  ],
  "precautions": [
    "Ajuster selon fonction hépatique",
    "Surveillance des électrolytes",
    "Monitoring thérapeutique recommandé",
    "Interaction médicamenteuse possible",
    "À prendre pendant les repas"
  ],
  "contre_indications": [
    "Insuffisance hépatique sévère",
    "Grossesse",
    "Déficit en cycle de l'urée"
  ],
  "remarques": "Dosage plasmatique : 50-100 mg/L"
}
```

---

## Exemple 5 : Médicament IV avec conversion d'unités

**Gentamicine**

```json
{
  "nom": "Gentamicine",
  "famille": "Antibiotique",
  "posologies": [
    {
      "indication": "Infection bactérienne sévère",
      "dose": 5,
      "unite": "mg/kg/j",
      "frequency": "1x/j",
      "admin_route": "IV",
      "remarques": "Perfusion lente 30 min"
    },
    {
      "indication": "Nouveau-né < 1 mois",
      "dose": 4,
      "unite": "mg/kg/dose",
      "frequency": "toutes les 24h",
      "admin_route": "IV"
    }
  ],
  "precautions": [
    "Ajuster selon fonction rénale",
    "Monitoring thérapeutique recommandé",
    "Surveillance de l'audition"
  ],
  "contre_indications": [
    "Insuffisance rénale sévère",
    "Myasthénie"
  ]
}
```

---

## Exemple 6 : Médicament sans nom commercial

**Ibuprofène**

```json
{
  "nom": "Ibuprofène",
  "famille": "Anti-inflammatoire",
  "posologies": [
    {
      "indication": "Fièvre",
      "dose": 10,
      "unite": "mg/kg/dose",
      "frequency": "toutes les 8h",
      "admin_route": "PO"
    },
    {
      "indication": "Douleur modérée",
      "min_dose": 20,
      "max_dose": 30,
      "unite": "mg/kg/j",
      "frequency": "3x/j",
      "admin_route": "PO"
    }
  ],
  "precautions": [
    "À prendre pendant les repas",
    "Surveillance de la fonction rénale"
  ],
  "contre_indications": [
    "Insuffisance rénale sévère",
    "Ulcère gastro-duodénal",
    "Déshydratation",
    "Nouveau-né < 3 mois"
  ]
}
```

---

## Exemple 7 : Export multiple (array JSON)

**Liste de 3 médicaments**

```json
[
  {
    "nom": "Paracétamol",
    "nom_commercial": "Doliprane",
    "famille": "Antipyrétique",
    "posologies": [
      {
        "indication": "Fièvre",
        "dose": 15,
        "unite": "mg/kg/dose",
        "frequency": "toutes les 6h",
        "admin_route": "PO"
      }
    ]
  },
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
    ]
  },
  {
    "nom": "Ibuprofène",
    "famille": "Anti-inflammatoire",
    "posologies": [
      {
        "indication": "Fièvre",
        "dose": 10,
        "unite": "mg/kg/dose",
        "frequency": "toutes les 8h",
        "admin_route": "PO"
      }
    ],
    "contre_indications": [
      "Nouveau-né < 3 mois"
    ]
  }
]
```

---

## Structure générale du JSON

### Champs obligatoires
- `nom` : string
- `famille` : string
- `posologies` : array (minimum 1 élément)

### Champs optionnels (omis si vides)
- `nom_commercial` : string
- `remarques` : string
- `precautions` : array of strings
- `contre_indications` : array of strings

### Structure d'une posologie
**Champs optionnels :**
- `indication` : string
- `dose` : number ou string (pour dose fixe)
- `min_dose` : number ou string (pour plage)
- `max_dose` : number ou string (pour plage)
- `unite` : string
- `frequency` : string
- `admin_route` : string
- `remarques` : string

### Règles de validation
1. Si dose fixe : utiliser `dose`
2. Si plage : utiliser `min_dose` et `max_dose` (pas `dose`)
3. `max_dose` doit être > `min_dose`
4. Tous les champs vides sont omis du JSON final

---

## Utilisation dans ped_app

Une fois le JSON généré, il peut être directement intégré dans `medications.json` :

```json
{
  "medications": [
    // ... médicaments existants
    {
      "nom": "Nouveau médicament",
      // ... données générées par l'éditeur
    }
  ]
}
```

L'application assure que le format est compatible avec le modèle de données de ped_app !
