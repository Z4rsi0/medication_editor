import 'dart:convert';

class Medication {
  String nom;
  String? nomCommercial;
  String galenique;
  List<Indication> indications;
  String? contreIndications;
  String? surdosage;
  String? aSavoir;

  Medication({
    required this.nom,
    this.nomCommercial,
    required this.galenique,
    this.indications = const [],
    this.contreIndications,
    this.surdosage,
    this.aSavoir,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nom': nom,
      'galenique': galenique,
    };

    if (nomCommercial != null && nomCommercial!.isNotEmpty) {
      data['nomCommercial'] = nomCommercial;
    }

    if (indications.isNotEmpty) {
      data['indications'] = indications.map((i) => i.toJson()).toList();
    }

    if (contreIndications != null && contreIndications!.isNotEmpty) {
      data['contreIndications'] = contreIndications;
    }

    if (surdosage != null && surdosage!.isNotEmpty) {
      data['surdosage'] = surdosage;
    }

    if (aSavoir != null && aSavoir!.isNotEmpty) {
      data['aSavoir'] = aSavoir;
    }

    return data;
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory Medication.fromJson(Map<String, dynamic> json) {
    return Medication(
      nom: json['nom'] ?? '',
      nomCommercial: json['nomCommercial'],
      galenique: json['galenique'] ?? '',
      indications: (json['indications'] as List<dynamic>?)
              ?.map((i) => Indication.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      contreIndications: json['contreIndications'],
      surdosage: json['surdosage'],
      aSavoir: json['aSavoir'],
    );
  }
}

class Indication {
  String label;
  List<Posology> posologies;

  Indication({
    required this.label,
    this.posologies = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'posologies': posologies.map((p) => p.toJson()).toList(),
    };
  }

  factory Indication.fromJson(Map<String, dynamic> json) {
    return Indication(
      label: json['label'] ?? '',
      posologies: (json['posologies'] as List<dynamic>?)
              ?.map((p) => Posology.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class Posology {
  String voie;
  // Dose simple
  dynamic doseKg; // peut être num ou null
  dynamic doseKgMin; // peut être num ou null
  dynamic doseKgMax; // peut être num ou null
  dynamic doseMax; // peut être num ou null
  String? doses; // pour schémas complexes (ex: "S0: 80 mg, S2: 40 mg...")
  // Tranches de poids/âge
  List<Tranche>? tranches;
  // Commun
  String unite;
  String? preparation;

  Posology({
    required this.voie,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.doseMax,
    this.doses,
    this.tranches,
    required this.unite,
    this.preparation,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'voie': voie,
      'unite': unite,
    };

    // Tranches (priorité sur dose simple)
    if (tranches != null && tranches!.isNotEmpty) {
      data['tranches'] = tranches!.map((t) => t.toJson()).toList();
    } else {
      // Dose simple
      if (doseKg != null) {
        data['doseKg'] = doseKg;
      }

      if (doseKgMin != null) {
        data['doseKgMin'] = doseKgMin;
      }

      if (doseKgMax != null) {
        data['doseKgMax'] = doseKgMax;
      }

      if (doseMax != null) {
        data['doseMax'] = doseMax;
      }

      if (doses != null && doses!.isNotEmpty) {
        data['doses'] = doses;
      }
    }

    if (preparation != null && preparation!.isNotEmpty) {
      data['preparation'] = preparation;
    }

    return data;
  }

  factory Posology.fromJson(Map<String, dynamic> json) {
    return Posology(
      voie: json['voie'] ?? '',
      doseKg: json['doseKg'],
      doseKgMin: json['doseKgMin'],
      doseKgMax: json['doseKgMax'],
      doseMax: json['doseMax'],
      doses: json['doses'],
      tranches: (json['tranches'] as List<dynamic>?)
          ?.map((t) => Tranche.fromJson(t as Map<String, dynamic>))
          .toList(),
      unite: json['unite'] ?? '',
      preparation: json['preparation'],
    );
  }
}

class Tranche {
  // Limites de poids
  dynamic poidsMin; // en kg
  dynamic poidsMax; // en kg
  // Limites d'âge
  dynamic ageMin; // en années
  dynamic ageMax; // en années
  // Dose pour cette tranche
  dynamic doseKg;
  dynamic doseKgMin;
  dynamic doseKgMax;
  String? doses; // pour schémas complexes dans cette tranche
  String? unite; // peut override l'unité principale

  Tranche({
    this.poidsMin,
    this.poidsMax,
    this.ageMin,
    this.ageMax,
    this.doseKg,
    this.doseKgMin,
    this.doseKgMax,
    this.doses,
    this.unite,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    if (poidsMin != null) {
      data['poidsMin'] = poidsMin;
    }
    if (poidsMax != null) {
      data['poidsMax'] = poidsMax;
    }
    if (ageMin != null) {
      data['ageMin'] = ageMin;
    }
    if (ageMax != null) {
      data['ageMax'] = ageMax;
    }
    if (doseKg != null) {
      data['doseKg'] = doseKg;
    }
    if (doseKgMin != null) {
      data['doseKgMin'] = doseKgMin;
    }
    if (doseKgMax != null) {
      data['doseKgMax'] = doseKgMax;
    }
    if (doses != null && doses!.isNotEmpty) {
      data['doses'] = doses;
    }
    if (unite != null && unite!.isNotEmpty) {
      data['unite'] = unite;
    }

    return data;
  }

  factory Tranche.fromJson(Map<String, dynamic> json) {
    return Tranche(
      poidsMin: json['poidsMin'],
      poidsMax: json['poidsMax'],
      ageMin: json['ageMin'],
      ageMax: json['ageMax'],
      doseKg: json['doseKg'],
      doseKgMin: json['doseKgMin'],
      doseKgMax: json['doseKgMax'],
      doses: json['doses'],
      unite: json['unite'],
    );
  }
}