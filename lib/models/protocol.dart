import 'dart:convert';

class Protocol {
  String nom;
  String description;
  List<Etape> etapes;

  Protocol({
    required this.nom,
    required this.description,
    this.etapes = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'description': description,
      'etapes': etapes.map((e) => e.toJson()).toList(),
    };
  }

  String toJsonString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }

  factory Protocol.fromJson(Map<String, dynamic> json) {
    return Protocol(
      nom: json['nom'] ?? '',
      description: json['description'] ?? '',
      etapes: (json['etapes'] as List<dynamic>?)
              ?.map((e) => Etape.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  // Génère un nom de fichier sécurisé pour le protocole
  String get fileName {
    // 1. Normalisation des accents et caractères français (Correction pour GitHub)
    String normalized = nom
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .toLowerCase(); // Passage en minuscule

    // 2. Traitement des espaces et autres caractères spéciaux (logique originale)
    String sanitized = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_') // Remplace tout ce qui n'est pas a-z ou 0-9 par '_'
        .replaceAll(RegExp(r'_+'), '_')       // Supprime les underscores multiples
        .replaceAll(RegExp(r'^_|_$'), '');    // Supprime les underscores en début/fin

    // Cas du nom vide après nettoyage
    if (sanitized.isEmpty) {
      return 'protocole_sans_nom.json';
    }

    return '$sanitized.json';
  }
}

class Etape {
  String titre;
  String? temps; // Optionnel (T0, T5, T10, etc.)
  List<Element> elements;
  String? attention; // Optionnel (alerte/warning)

  Etape({
    required this.titre,
    this.temps,
    this.elements = const [],
    this.attention,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'titre': titre,
      'elements': elements.map((e) => e.toJson()).toList(),
    };

    if (temps != null && temps!.isNotEmpty) {
      data['temps'] = temps;
    }

    if (attention != null && attention!.isNotEmpty) {
      data['attention'] = attention;
    }

    return data;
  }

  factory Etape.fromJson(Map<String, dynamic> json) {
    return Etape(
      titre: json['titre'] ?? '',
      temps: json['temps'],
      elements: (json['elements'] as List<dynamic>?)
              ?.map((e) => Element.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attention: json['attention'],
    );
  }
}

// Classe abstraite pour les éléments
abstract class Element {
  String get type;
  Map<String, dynamic> toJson();

  factory Element.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    if (type == 'texte') {
      return ElementTexte.fromJson(json);
    } else if (type == 'medicament') {
      return ElementMedicament.fromJson(json);
    }
    throw Exception('Type d\'élément inconnu: $type');
  }
}

class ElementTexte implements Element {
  @override
  String get type => 'texte';
  
  String texte;

  ElementTexte({required this.texte});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'texte': texte,
    };
  }

  factory ElementTexte.fromJson(Map<String, dynamic> json) {
    return ElementTexte(
      texte: json['texte'] ?? '',
    );
  }
}

class ElementMedicament implements Element {
  @override
  String get type => 'medicament';
  
  MedicamentReference medicament;

  ElementMedicament({required this.medicament});

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'medicament': medicament.toJson(),
    };
  }

  factory ElementMedicament.fromJson(Map<String, dynamic> json) {
    return ElementMedicament(
      medicament: MedicamentReference.fromJson(
          json['medicament'] as Map<String, dynamic>),
    );
  }
}

class MedicamentReference {
  String nom;
  String indication;
  String voie;

  MedicamentReference({
    required this.nom,
    required this.indication,
    required this.voie,
  });

  Map<String, dynamic> toJson() {
    return {
      'nom': nom,
      'indication': indication,
      'voie': voie,
    };
  }

  factory MedicamentReference.fromJson(Map<String, dynamic> json) {
    return MedicamentReference(
      nom: json['nom'] ?? '',
      indication: json['indication'] ?? '',
      voie: json['voie'] ?? '',
    );
  }
}