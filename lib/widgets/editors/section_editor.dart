import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';
import '../../services/medication_provider.dart';
import '../block_editor_widget.dart';
import 'block_factory.dart';
import 'block_type_selector.dart';

class SectionBlockEditor extends StatefulWidget {
  final SectionBlock block;
  final Function(ProtocolBlock) onChanged;
  final MedicationProvider? medicationProvider;

  const SectionBlockEditor({
    super.key,
    required this.block,
    required this.onChanged,
    this.medicationProvider,
  });

  @override
  State<SectionBlockEditor> createState() => _SectionBlockEditorState();
}

class _SectionBlockEditorState extends State<SectionBlockEditor> {
  late TextEditingController _titreController;
  late TextEditingController _tempsController;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.block.titre);
    _tempsController = TextEditingController(text: widget.block.temps ?? '');
  }

  @override
  void dispose() {
    _titreController.dispose();
    _tempsController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      titre: _titreController.text,
      temps: _tempsController.text.isEmpty ? null : _tempsController.text,
    ));
  }

  Future<void> _addSubBlock(BuildContext context) async {
    final type = await showDialog<BlockType>(
        context: context, builder: (_) => const BlockTypeSelectorDialog());
    if (type == null) return;
    final newBlock = createBlockOfType(type, widget.block.contenu.length);
    final updatedContenu = [...widget.block.contenu, newBlock];
    widget.onChanged(widget.block.copyWith(contenu: updatedContenu));
  }

  void _updateSubBlock(int index, ProtocolBlock updated) {
    final updatedContenu = List<ProtocolBlock>.from(widget.block.contenu);
    updatedContenu[index] = updated;
    widget.onChanged(widget.block.copyWith(contenu: updatedContenu));
  }

  void _deleteSubBlock(int index) {
    final updatedContenu = List<ProtocolBlock>.from(widget.block.contenu)
      ..removeAt(index);
    for (int i = 0; i < updatedContenu.length; i++) {
      updatedContenu[i] = updatedContenu[i].copyWithOrdre(i);
    }
    widget.onChanged(widget.block.copyWith(contenu: updatedContenu));
  }

  void _reorderSubBlocks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final updatedContenu = List<ProtocolBlock>.from(widget.block.contenu);
    final item = updatedContenu.removeAt(oldIndex);
    updatedContenu.insert(newIndex, item);
    for (int i = 0; i < updatedContenu.length; i++) {
      updatedContenu[i] = updatedContenu[i].copyWithOrdre(i);
    }
    widget.onChanged(widget.block.copyWith(contenu: updatedContenu));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titreController,
          decoration: const InputDecoration(
              labelText: 'Titre de la section', border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tempsController,
                decoration: const InputDecoration(
                    labelText: 'Temps (optionnel)',
                    hintText: 'Ex: 5 min',
                    border: OutlineInputBorder()),
                onChanged: (_) => _updateBlock(),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Text('Ouvert par défaut'),
                Switch(
                  value: widget.block.initialementOuvert,
                  onChanged: (value) => widget.onChanged(
                      widget.block.copyWith(initialementOuvert: value)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        Row(
          children: [
            const Text('Contenu de la section',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                onPressed: () => _addSubBlock(context)),
          ],
        ),
        const SizedBox(height: 8),
        
        // Liste interne : On garde shrinkWrap ici car nous sommes à l'intérieur 
        // d'un élément qui est déjà géré par un Sliver parent.
        // L'impact performance est négligeable car le parent ne rend ce widget
        // que s'il est visible.
        if (widget.block.contenu.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text("Vide", style: TextStyle(color: Colors.grey))),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            // buildDefaultDragHandles est important pour éviter les conflits
            // de drag avec la liste parente si nécessaire
            buildDefaultDragHandles: true, 
            itemCount: widget.block.contenu.length,
            onReorder: _reorderSubBlocks,
            itemBuilder: (context, index) {
              final subBlock = widget.block.contenu[index];
              return Container(
                 // Clé unique indispensable pour le ReorderableListView
                key: ValueKey('${subBlock.type}_${subBlock.hashCode}'),
                margin: const EdgeInsets.only(bottom: 8),
                child: BlockEditorWidget(
                  block: subBlock,
                  medicationProvider: widget.medicationProvider,
                  onChanged: (updated) => _updateSubBlock(index, updated),
                  onDelete: () => _deleteSubBlock(index),
                ),
              );
            },
          ),
      ],
    );
  }
}