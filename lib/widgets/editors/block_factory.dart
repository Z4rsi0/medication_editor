import '../../models/protocol_model.dart';

/// Crée un nouveau bloc du type spécifié
ProtocolBlock createBlockOfType(BlockType type, int ordre) {
  switch (type) {
    case BlockType.section:
      return SectionBlock(titre: 'Nouvelle section', contenu: [], ordre: ordre);
    case BlockType.texte:
      return TexteBlock(contenu: '', ordre: ordre);
    case BlockType.tableau:
      return TableauBlock(
          colonnes: ['Colonne 1'], lignes: [['']], ordre: ordre);
    case BlockType.image:
      return ImageBlock(source: '', ordre: ordre);
    case BlockType.medicament:
      return MedicamentBlock(nomMedicament: '', ordre: ordre);
    case BlockType.formulaire:
      return FormulaireBlock(
          titre: 'Nouveau formulaire', champs: [], ordre: ordre);
    case BlockType.alerte:
      return AlerteBlock(contenu: '', niveau: AlerteNiveau.info, ordre: ordre);
  }
}