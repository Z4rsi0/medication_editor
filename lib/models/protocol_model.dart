// Types de blocs disponibles
enum BlockType {
  section,      // Tuile collapsible
  texte,        // Texte formaté
  tableau,      // Tableau de données
  image,        // Image (base64 ou URL)
  medicament,   // Référence médicament avec calcul de dose
  formulaire,   // Formulaire interactif avec calcul de score
  alerte,       // Alerte/avertissement
}

// Niveaux d'alerte
enum AlerteNiveau {
  info,
  attention,
  danger,
  critique,
}

// Niveaux d'interprétation de score
enum InterpretationNiveau {
  faible,
  modere,
  eleve,
  critique,
}

// Types de champs pour les formulaires
enum ChampType {
  nombre,
  selection,
  checkbox,
  radio,
}

/// Classe principale du protocole
class Protocol {
  final String titre;
  final String? description;
  final String? auteur;
  final String? version;
  final DateTime? dateModification;
  final List<ProtocolBlock> blocs;
  final String? fileName; // Nom du fichier source (pour éviter les doublons)

  Protocol({
    required this.titre,
    this.description,
    this.auteur,
    this.version,
    this.dateModification,
    required this.blocs,
    this.fileName,
  });

  factory Protocol.fromJson(Map<String, dynamic> json, {String? sourceFileName}) {
    // Conversion des blocs
    List<ProtocolBlock> blocs = [];
    
    if (json['blocs'] != null) {
      blocs = (json['blocs'] as List)
          .map((bloc) => ProtocolBlock.fromJson(bloc))
          .toList();
    } else if (json['etapes'] != null) {
      // Rétrocompatibilité avec l'ancien format
      blocs = _convertOldFormat(json['etapes'] as List);
    }

    return Protocol(
      titre: json['titre'] ?? 'Sans titre',
      description: json['description'],
      auteur: json['auteur'],
      version: json['version'],
      dateModification: json['dateModification'] != null
          ? DateTime.tryParse(json['dateModification'])
          : null,
      blocs: blocs,
      fileName: sourceFileName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'titre': titre,
      if (description != null) 'description': description,
      if (auteur != null) 'auteur': auteur,
      if (version != null) 'version': version,
      'dateModification': DateTime.now().toIso8601String(),
      'blocs': blocs.map((b) => b.toJson()).toList(),
    };
  }

  /// Génère un nom de fichier sécurisé à partir du titre
  String generateFileName() {
    if (fileName != null && fileName!.isNotEmpty) {
      return fileName!;
    }
    
    // Convertir les accents et caractères spéciaux
    String safe = titre
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ýÿ]'), 'y')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[œ]'), 'oe')
        .replaceAll(RegExp(r'[æ]'), 'ae')
        .replaceAll(RegExp(r"[''`]"), '')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    
    return '$safe.json';
  }

  Protocol copyWith({
    String? titre,
    String? description,
    String? auteur,
    String? version,
    DateTime? dateModification,
    List<ProtocolBlock>? blocs,
    String? fileName,
  }) {
    return Protocol(
      titre: titre ?? this.titre,
      description: description ?? this.description,
      auteur: auteur ?? this.auteur,
      version: version ?? this.version,
      dateModification: dateModification ?? this.dateModification,
      blocs: blocs ?? this.blocs,
      fileName: fileName ?? this.fileName,
    );
  }

  /// Convertit l'ancien format (étapes) vers le nouveau format (blocs)
  static List<ProtocolBlock> _convertOldFormat(List<dynamic> etapes) {
    List<ProtocolBlock> blocs = [];
    int ordre = 0;

    for (var etape in etapes) {
      final Map<String, dynamic> e = etape as Map<String, dynamic>;
      
      // Créer une section pour chaque étape
      List<ProtocolBlock> contenu = [];
      int subOrdre = 0;

      // Ajouter le contenu texte si présent
      if (e['contenu'] != null) {
        contenu.add(TexteBlock(
          contenu: e['contenu'],
          ordre: subOrdre++,
        ));
      }

      // Ajouter les médicaments si présents
      if (e['medicaments'] != null) {
        for (var med in e['medicaments']) {
          contenu.add(MedicamentBlock(
            nomMedicament: med['nom'] ?? med['medicament'],
            indication: med['indication'],
            voie: med['voie'],
            commentaire: med['commentaire'],
            ordre: subOrdre++,
          ));
        }
      }

      // Ajouter les tableaux si présents
      if (e['tableau'] != null) {
        final tableau = e['tableau'];
        contenu.add(TableauBlock(
          titre: tableau['titre'],
          colonnes: List<String>.from(tableau['colonnes'] ?? []),
          lignes: (tableau['lignes'] as List?)
              ?.map((l) => List<String>.from(l))
              .toList() ?? [],
          ordre: subOrdre++,
        ));
      }

      // Créer la section
      blocs.add(SectionBlock(
        titre: e['titre'] ?? 'Étape ${ordre + 1}',
        temps: e['temps'],
        initialementOuvert: ordre == 0,
        contenu: contenu,
        ordre: ordre++,
      ));
    }

    return blocs;
  }
}

/// Classe abstraite pour tous les blocs
abstract class ProtocolBlock {
  final BlockType type;
  final int ordre;
  final String? id;

  ProtocolBlock({
    required this.type,
    required this.ordre,
    this.id,
  });

  factory ProtocolBlock.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String;
    final type = BlockType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => BlockType.texte,
    );

    switch (type) {
      case BlockType.section:
        return SectionBlock.fromJson(json);
      case BlockType.texte:
        return TexteBlock.fromJson(json);
      case BlockType.tableau:
        return TableauBlock.fromJson(json);
      case BlockType.image:
        return ImageBlock.fromJson(json);
      case BlockType.medicament:
        return MedicamentBlock.fromJson(json);
      case BlockType.formulaire:
        return FormulaireBlock.fromJson(json);
      case BlockType.alerte:
        return AlerteBlock.fromJson(json);
    }
  }

  Map<String, dynamic> toJson();

  ProtocolBlock copyWithOrdre(int newOrdre);
}

/// Section collapsible contenant d'autres blocs
class SectionBlock extends ProtocolBlock {
  final String titre;
  final String? temps;
  final bool initialementOuvert;
  final List<ProtocolBlock> contenu;

  SectionBlock({
    required this.titre,
    this.temps,
    this.initialementOuvert = false,
    required this.contenu,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.section);

  factory SectionBlock.fromJson(Map<String, dynamic> json) {
    return SectionBlock(
      titre: json['titre'] ?? 'Section',
      temps: json['temps'],
      initialementOuvert: json['initialementOuvert'] ?? false,
      contenu: (json['contenu'] as List?)
          ?.map((b) => ProtocolBlock.fromJson(b))
          .toList() ?? [],
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'section',
      'titre': titre,
      if (temps != null) 'temps': temps,
      'initialementOuvert': initialementOuvert,
      'contenu': contenu.map((b) => b.toJson()).toList(),
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  SectionBlock copyWithOrdre(int newOrdre) {
    return SectionBlock(
      titre: titre,
      temps: temps,
      initialementOuvert: initialementOuvert,
      contenu: contenu,
      ordre: newOrdre,
      id: id,
    );
  }

  SectionBlock copyWith({
    String? titre,
    String? temps,
    bool? initialementOuvert,
    List<ProtocolBlock>? contenu,
    int? ordre,
    String? id,
  }) {
    return SectionBlock(
      titre: titre ?? this.titre,
      temps: temps ?? this.temps,
      initialementOuvert: initialementOuvert ?? this.initialementOuvert,
      contenu: contenu ?? this.contenu,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}

/// Format de texte
class TexteFormat {
  final bool gras;
  final bool italique;
  final bool souligne;
  final String? couleur; // Couleur hex (#RRGGBB)
  final int? taillePolicePx;

  TexteFormat({
    this.gras = false,
    this.italique = false,
    this.souligne = false,
    this.couleur,
    this.taillePolicePx,
  });

  factory TexteFormat.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TexteFormat();
    return TexteFormat(
      gras: json['gras'] ?? false,
      italique: json['italique'] ?? false,
      souligne: json['souligne'] ?? false,
      couleur: json['couleur'],
      taillePolicePx: json['taillePolicePx'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (gras) 'gras': gras,
      if (italique) 'italique': italique,
      if (souligne) 'souligne': souligne,
      if (couleur != null) 'couleur': couleur,
      if (taillePolicePx != null) 'taillePolicePx': taillePolicePx,
    };
  }

  TexteFormat copyWith({
    bool? gras,
    bool? italique,
    bool? souligne,
    String? couleur,
    int? taillePolicePx,
  }) {
    return TexteFormat(
      gras: gras ?? this.gras,
      italique: italique ?? this.italique,
      souligne: souligne ?? this.souligne,
      couleur: couleur ?? this.couleur,
      taillePolicePx: taillePolicePx ?? this.taillePolicePx,
    );
  }
}

/// Bloc de texte formaté
class TexteBlock extends ProtocolBlock {
  final String contenu;
  final TexteFormat? format;

  TexteBlock({
    required this.contenu,
    this.format,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.texte);

  factory TexteBlock.fromJson(Map<String, dynamic> json) {
    return TexteBlock(
      contenu: json['contenu'] ?? '',
      format: json['format'] != null 
          ? TexteFormat.fromJson(json['format']) 
          : null,
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'texte',
      'contenu': contenu,
      if (format != null) 'format': format!.toJson(),
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  TexteBlock copyWithOrdre(int newOrdre) {
    return TexteBlock(
      contenu: contenu,
      format: format,
      ordre: newOrdre,
      id: id,
    );
  }

  TexteBlock copyWith({
    String? contenu,
    TexteFormat? format,
    int? ordre,
    String? id,
  }) {
    return TexteBlock(
      contenu: contenu ?? this.contenu,
      format: format ?? this.format,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}

/// Bloc tableau de données
class TableauBlock extends ProtocolBlock {
  final String? titre;
  final List<String> colonnes;
  final List<List<String>> lignes;
  final bool avecEntete;

  TableauBlock({
    this.titre,
    required this.colonnes,
    required this.lignes,
    this.avecEntete = true,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.tableau);

  factory TableauBlock.fromJson(Map<String, dynamic> json) {
    return TableauBlock(
      titre: json['titre'],
      colonnes: List<String>.from(json['colonnes'] ?? []),
      lignes: (json['lignes'] as List?)
          ?.map((l) => List<String>.from(l))
          .toList() ?? [],
      avecEntete: json['avecEntete'] ?? true,
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'tableau',
      if (titre != null) 'titre': titre,
      'colonnes': colonnes,
      'lignes': lignes,
      'avecEntete': avecEntete,
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  TableauBlock copyWithOrdre(int newOrdre) {
    return TableauBlock(
      titre: titre,
      colonnes: colonnes,
      lignes: lignes,
      avecEntete: avecEntete,
      ordre: newOrdre,
      id: id,
    );
  }

  TableauBlock copyWith({
    String? titre,
    List<String>? colonnes,
    List<List<String>>? lignes,
    bool? avecEntete,
    int? ordre,
    String? id,
  }) {
    return TableauBlock(
      titre: titre ?? this.titre,
      colonnes: colonnes ?? this.colonnes,
      lignes: lignes ?? this.lignes,
      avecEntete: avecEntete ?? this.avecEntete,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}

/// Bloc image (URL ou base64)
class ImageBlock extends ProtocolBlock {
  final String source; // URL ou données base64
  final bool estBase64;
  final String? legende;
  final int? largeurPourcent; // Largeur en pourcentage (1-100)

  ImageBlock({
    required this.source,
    this.estBase64 = false,
    this.legende,
    this.largeurPourcent,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.image);

  factory ImageBlock.fromJson(Map<String, dynamic> json) {
    return ImageBlock(
      source: json['source'] ?? '',
      estBase64: json['estBase64'] ?? false,
      legende: json['legende'],
      largeurPourcent: json['largeurPourcent'],
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'image',
      'source': source,
      'estBase64': estBase64,
      if (legende != null) 'legende': legende,
      if (largeurPourcent != null) 'largeurPourcent': largeurPourcent,
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  ImageBlock copyWithOrdre(int newOrdre) {
    return ImageBlock(
      source: source,
      estBase64: estBase64,
      legende: legende,
      largeurPourcent: largeurPourcent,
      ordre: newOrdre,
      id: id,
    );
  }

  ImageBlock copyWith({
    String? source,
    bool? estBase64,
    String? legende,
    int? largeurPourcent,
    int? ordre,
    String? id,
  }) {
    return ImageBlock(
      source: source ?? this.source,
      estBase64: estBase64 ?? this.estBase64,
      legende: legende ?? this.legende,
      largeurPourcent: largeurPourcent ?? this.largeurPourcent,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}

/// Bloc référence médicament
class MedicamentBlock extends ProtocolBlock {
  final String nomMedicament;
  final String? indication;
  final String? voie;
  final String? commentaire;

  MedicamentBlock({
    required this.nomMedicament,
    this.indication,
    this.voie,
    this.commentaire,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.medicament);

  factory MedicamentBlock.fromJson(Map<String, dynamic> json) {
    return MedicamentBlock(
      nomMedicament: json['nomMedicament'] ?? json['nom'] ?? '',
      indication: json['indication'],
      voie: json['voie'],
      commentaire: json['commentaire'],
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'medicament',
      'nomMedicament': nomMedicament,
      if (indication != null) 'indication': indication,
      if (voie != null) 'voie': voie,
      if (commentaire != null) 'commentaire': commentaire,
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  MedicamentBlock copyWithOrdre(int newOrdre) {
    return MedicamentBlock(
      nomMedicament: nomMedicament,
      indication: indication,
      voie: voie,
      commentaire: commentaire,
      ordre: newOrdre,
      id: id,
    );
  }

  MedicamentBlock copyWith({
    String? nomMedicament,
    String? indication,
    String? voie,
    String? commentaire,
    int? ordre,
    String? id,
  }) {
    return MedicamentBlock(
      nomMedicament: nomMedicament ?? this.nomMedicament,
      indication: indication ?? this.indication,
      voie: voie ?? this.voie,
      commentaire: commentaire ?? this.commentaire,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}

/// Option pour un champ de formulaire
class FormulaireOption {
  final String label;
  final dynamic valeur; // peut être un nombre ou une string

  FormulaireOption({
    required this.label,
    required this.valeur,
  });

  factory FormulaireOption.fromJson(Map<String, dynamic> json) {
    return FormulaireOption(
      label: json['label'] ?? '',
      valeur: json['valeur'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'valeur': valeur,
    };
  }

  FormulaireOption copyWith({
    String? label,
    dynamic valeur,
  }) {
    return FormulaireOption(
      label: label ?? this.label,
      valeur: valeur ?? this.valeur,
    );
  }
}

/// Champ d'un formulaire
class FormulaireChamp {
  final String id;
  final String label;
  final ChampType type;
  final List<FormulaireOption>? options; // Pour selection, radio
  final num? min;
  final num? max;
  final dynamic defaut;
  final int? points; // Points attribués si checkbox cochée

  FormulaireChamp({
    required this.id,
    required this.label,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.defaut,
    this.points,
  });

  factory FormulaireChamp.fromJson(Map<String, dynamic> json) {
    return FormulaireChamp(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      type: ChampType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => ChampType.nombre,
      ),
      options: (json['options'] as List?)
          ?.map((o) => FormulaireOption.fromJson(o))
          .toList(),
      min: json['min'],
      max: json['max'],
      defaut: json['defaut'],
      points: json['points'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'type': type.name,
      if (options != null) 'options': options!.map((o) => o.toJson()).toList(),
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (defaut != null) 'defaut': defaut,
      if (points != null) 'points': points,
    };
  }

  FormulaireChamp copyWith({
    String? id,
    String? label,
    ChampType? type,
    List<FormulaireOption>? options,
    num? min,
    num? max,
    dynamic defaut,
    int? points,
  }) {
    return FormulaireChamp(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      options: options ?? this.options,
      min: min ?? this.min,
      max: max ?? this.max,
      defaut: defaut ?? this.defaut,
      points: points ?? this.points,
    );
  }
}

/// Interprétation d'un score
class FormulaireInterpretation {
  final num min;
  final num max;
  final String texte;
  final String? couleur; // Couleur hex
  final InterpretationNiveau? niveau;

  FormulaireInterpretation({
    required this.min,
    required this.max,
    required this.texte,
    this.couleur,
    this.niveau,
  });

  factory FormulaireInterpretation.fromJson(Map<String, dynamic> json) {
    return FormulaireInterpretation(
      min: json['min'] ?? 0,
      max: json['max'] ?? 100,
      texte: json['texte'] ?? '',
      couleur: json['couleur'],
      niveau: json['niveau'] != null
          ? InterpretationNiveau.values.firstWhere(
              (n) => n.name == json['niveau'],
              orElse: () => InterpretationNiveau.faible,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'min': min,
      'max': max,
      'texte': texte,
      if (couleur != null) 'couleur': couleur,
      if (niveau != null) 'niveau': niveau!.name,
    };
  }

  FormulaireInterpretation copyWith({
    num? min,
    num? max,
    String? texte,
    String? couleur,
    InterpretationNiveau? niveau,
  }) {
    return FormulaireInterpretation(
      min: min ?? this.min,
      max: max ?? this.max,
      texte: texte ?? this.texte,
      couleur: couleur ?? this.couleur,
      niveau: niveau ?? this.niveau,
    );
  }
}

/// Bloc formulaire interactif avec calcul de score
class FormulaireBlock extends ProtocolBlock {
  final String titre;
  final String? description;
  final List<FormulaireChamp> champs;
  final String? formuleCalcul; // Formule pour calculer le score (optionnel, sinon somme)
  final List<FormulaireInterpretation>? interpretations;

  FormulaireBlock({
    required this.titre,
    this.description,
    required this.champs,
    this.formuleCalcul,
    this.interpretations,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.formulaire);

  factory FormulaireBlock.fromJson(Map<String, dynamic> json) {
    return FormulaireBlock(
      titre: json['titre'] ?? 'Formulaire',
      description: json['description'],
      champs: (json['champs'] as List?)
          ?.map((c) => FormulaireChamp.fromJson(c))
          .toList() ?? [],
      formuleCalcul: json['formuleCalcul'],
      interpretations: (json['interpretations'] as List?)
          ?.map((i) => FormulaireInterpretation.fromJson(i))
          .toList(),
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'formulaire',
      'titre': titre,
      if (description != null) 'description': description,
      'champs': champs.map((c) => c.toJson()).toList(),
      if (formuleCalcul != null) 'formuleCalcul': formuleCalcul,
      if (interpretations != null)
        'interpretations': interpretations!.map((i) => i.toJson()).toList(),
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  FormulaireBlock copyWithOrdre(int newOrdre) {
    return FormulaireBlock(
      titre: titre,
      description: description,
      champs: champs,
      formuleCalcul: formuleCalcul,
      interpretations: interpretations,
      ordre: newOrdre,
      id: id,
    );
  }

  FormulaireBlock copyWith({
    String? titre,
    String? description,
    List<FormulaireChamp>? champs,
    String? formuleCalcul,
    List<FormulaireInterpretation>? interpretations,
    int? ordre,
    String? id,
  }) {
    return FormulaireBlock(
      titre: titre ?? this.titre,
      description: description ?? this.description,
      champs: champs ?? this.champs,
      formuleCalcul: formuleCalcul ?? this.formuleCalcul,
      interpretations: interpretations ?? this.interpretations,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}

/// Bloc alerte/avertissement
class AlerteBlock extends ProtocolBlock {
  final String contenu;
  final AlerteNiveau niveau;

  AlerteBlock({
    required this.contenu,
    this.niveau = AlerteNiveau.info,
    required super.ordre,
    super.id,
  }) : super(type: BlockType.alerte);

  factory AlerteBlock.fromJson(Map<String, dynamic> json) {
    return AlerteBlock(
      contenu: json['contenu'] ?? '',
      niveau: AlerteNiveau.values.firstWhere(
        (n) => n.name == json['niveau'],
        orElse: () => AlerteNiveau.info,
      ),
      ordre: json['ordre'] ?? 0,
      id: json['id'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'alerte',
      'contenu': contenu,
      'niveau': niveau.name,
      'ordre': ordre,
      if (id != null) 'id': id,
    };
  }

  @override
  AlerteBlock copyWithOrdre(int newOrdre) {
    return AlerteBlock(
      contenu: contenu,
      niveau: niveau,
      ordre: newOrdre,
      id: id,
    );
  }

  AlerteBlock copyWith({
    String? contenu,
    AlerteNiveau? niveau,
    int? ordre,
    String? id,
  }) {
    return AlerteBlock(
      contenu: contenu ?? this.contenu,
      niveau: niveau ?? this.niveau,
      ordre: ordre ?? this.ordre,
      id: id ?? this.id,
    );
  }
}