import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';

class BlockTypeSelectorDialog extends StatelessWidget {
  const BlockTypeSelectorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un bloc'),
      content: SizedBox(
        width: 300,
        child: ListView(
          shrinkWrap: true,
          children: const [
            _BlockTypeOption(
              icon: Icons.folder_open,
              label: 'Section',
              description: 'Conteneur pliable avec sous-blocs',
              type: BlockType.section,
            ),
            _BlockTypeOption(
              icon: Icons.text_fields,
              label: 'Texte',
              description: 'Texte formaté (gras, italique...)',
              type: BlockType.texte,
            ),
            _BlockTypeOption(
              icon: Icons.table_chart,
              label: 'Tableau',
              description: 'Tableau de données',
              type: BlockType.tableau,
            ),
            _BlockTypeOption(
              icon: Icons.image,
              label: 'Image',
              description: 'Image (fichier ou URL)',
              type: BlockType.image,
            ),
            _BlockTypeOption(
              icon: Icons.medication,
              label: 'Médicament',
              description: 'Référence avec calcul de dose',
              type: BlockType.medicament,
            ),
            _BlockTypeOption(
              icon: Icons.calculate,
              label: 'Formulaire / Score',
              description: 'Calcul interactif de score clinique',
              type: BlockType.formulaire,
            ),
            _BlockTypeOption(
              icon: Icons.warning,
              label: 'Alerte',
              description: 'Message d\'avertissement',
              type: BlockType.alerte,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
      ],
    );
  }
}

class _BlockTypeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final BlockType type;

  const _BlockTypeOption({
    required this.icon,
    required this.label,
    required this.description,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: Text(description, style: const TextStyle(fontSize: 12)),
      onTap: () => Navigator.of(context).pop(type),
    );
  }
}