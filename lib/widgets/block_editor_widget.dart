import 'package:flutter/material.dart';
import '../models/protocol_model.dart';
import '../services/medication_provider.dart';

// Imports des éditeurs modulaires
import 'editors/section_editor.dart';
import 'editors/text_editor.dart';
import 'editors/table_editor.dart';
import 'editors/image_editor.dart';
import 'editors/medication_editor.dart';
import 'editors/form_editor.dart';
import 'editors/alert_editor.dart';

/// Éditeur générique de bloc (Wrapper)
class BlockEditorWidget extends StatelessWidget {
  final ProtocolBlock block;
  final Function(ProtocolBlock) onChanged;
  final VoidCallback onDelete;
  final MedicationProvider? medicationProvider;

  const BlockEditorWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onDelete,
    this.medicationProvider,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _getBlockColor(block.type).withOpacity(0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Icon(_getBlockIcon(block.type),
                    size: 20, color: _getBlockColor(block.type)),
                const SizedBox(width: 8),
                Text(_getBlockLabel(block.type),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getBlockColor(block.type))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: onDelete,
                  color: Colors.red,
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: _buildBlockEditor(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockEditor(BuildContext context) {
    switch (block.type) {
      case BlockType.section:
        return SectionBlockEditor(
          block: block as SectionBlock,
          onChanged: onChanged,
          medicationProvider: medicationProvider,
        );
      case BlockType.texte:
        return TexteBlockEditor(
            block: block as TexteBlock, onChanged: onChanged);
      case BlockType.tableau:
        return TableauBlockEditor(
            block: block as TableauBlock, onChanged: onChanged);
      case BlockType.image:
        return ImageBlockEditor(
            block: block as ImageBlock, onChanged: onChanged);
      case BlockType.medicament:
        return MedicamentBlockEditor(
          block: block as MedicamentBlock,
          onChanged: onChanged,
          medicationProvider: medicationProvider,
        );
      case BlockType.formulaire:
        return FormulaireBlockEditor(
            block: block as FormulaireBlock, onChanged: onChanged);
      case BlockType.alerte:
        return AlerteBlockEditor(
            block: block as AlerteBlock, onChanged: onChanged);
    }
  }

  IconData _getBlockIcon(BlockType type) {
    switch (type) {
      case BlockType.section:
        return Icons.folder_open;
      case BlockType.texte:
        return Icons.text_fields;
      case BlockType.tableau:
        return Icons.table_chart;
      case BlockType.image:
        return Icons.image;
      case BlockType.medicament:
        return Icons.medication;
      case BlockType.formulaire:
        return Icons.calculate;
      case BlockType.alerte:
        return Icons.warning;
    }
  }

  String _getBlockLabel(BlockType type) {
    switch (type) {
      case BlockType.section:
        return 'Section';
      case BlockType.texte:
        return 'Texte';
      case BlockType.tableau:
        return 'Tableau';
      case BlockType.image:
        return 'Image';
      case BlockType.medicament:
        return 'Médicament';
      case BlockType.formulaire:
        return 'Formulaire';
      case BlockType.alerte:
        return 'Alerte';
    }
  }

  Color _getBlockColor(BlockType type) {
    switch (type) {
      case BlockType.section:
        return Colors.blue;
      case BlockType.texte:
        return Colors.grey;
      case BlockType.tableau:
        return Colors.teal;
      case BlockType.image:
        return Colors.orange;
      case BlockType.medicament:
        return Colors.purple;
      case BlockType.formulaire:
        return Colors.green;
      case BlockType.alerte:
        return Colors.red;
    }
  }
}