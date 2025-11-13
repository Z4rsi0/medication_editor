class MedicationConstants {
  // Formes galéniques courantes
  static const List<String> galeniques = [
    'Comprimé',
    'Gélule',
    'Solution buvable',
    'Suspension buvable',
    'Sirop',
    'Solution injectable',
    'Solution perfusion',
    'Poudre pour solution injectable',
    'Poudre pour suspension buvable',
    'Suppositoire',
    'Crème',
    'Pommade',
    'Gel',
    'Solution pour inhalation',
    'Suspension pour inhalation',
    'Collyre',
    'Gouttes auriculaires',
    'Spray nasal',
    'Patch transdermique',
  ];

  // Unités (SANS /kg - calculé par l'app)
  static const List<String> unites = [
    'mg',
    'µg',
    'g',
    'UI',
    'mL',
    'gouttes',
    'UI/kg/h',
    'µg/kg/min',
    'mg/kg/h',
    'ng/kg/min',
  ];

  // Voies d'administration
  static const List<String> voies = [
    'PO',
    'IV',
    'IV/IO',
    'IM',
    'SC',
    'Inhalation',
    'Rectale',
    'Topique',
    'Ophtalmique',
    'Auriculaire',
    'Nasale',
    'Sublinguale',
    'Transdermique',
    'IV lente',
    'IV bolus',
    'Perfusion continue',
  ];

  // Indications thérapeutiques courantes
  static const List<String> indicationsCourantes = [
    'Infection bactérienne',
    'Infection virale',
    'Infection fongique',
    'Fièvre',
    'Douleur légère à modérée',
    'Douleur sévère',
    'Inflammation',
    'Allergie',
    'Asthme',
    'Bronchiolite',
    'Épilepsie',
    'Convulsions fébriles',
    'Vomissements',
    'Nausées',
    'Diarrhée',
    'Constipation',
    'RGO',
    'Prophylaxie',
    'Traitement d\'entretien',
    'Traitement de crise',
    'Sédation',
    'Anesthésie',
    'Anticoagulation',
    'Traitement substitutif',
  ];

  // Exemples de préparations
  static const List<String> preparationsCourantes = [
    'Prêt à l\'emploi',
    'IV lente 15 min',
    'IV lente 30 min',
    'IV bolus lent',
    'Dilution NaCl 0,9%',
    'Dilution G5%',
    'Perfusion continue',
    'À prendre pendant les repas',
    'À prendre à jeun',
    'À distance des repas',
    'Reconstitution avec eau PPI',
    'Nébulisation',
  ];
}