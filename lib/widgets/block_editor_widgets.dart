import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/protocol_model.dart';

/// Widget pour sélectionner le type de bloc à ajouter
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
          children: [
            const _BlockTypeOption(
              icon: Icons.folder_open,
              label: 'Section',
              description: 'Conteneur pliable avec sous-blocs',
              type: BlockType.section,
            ),
            const _BlockTypeOption(
              icon: Icons.text_fields,
              label: 'Texte',
              description: 'Texte formaté (gras, italique...)',
              type: BlockType.texte,
            ),
            const _BlockTypeOption(
              icon: Icons.table_chart,
              label: 'Tableau',
              description: 'Tableau de données',
              type: BlockType.tableau,
            ),
            const _BlockTypeOption(
              icon: Icons.image,
              label: 'Image',
              description: 'Image (fichier ou URL)',
              type: BlockType.image,
            ),
            const _BlockTypeOption(
              icon: Icons.medication,
              label: 'Médicament',
              description: 'Référence avec calcul de dose',
              type: BlockType.medicament,
            ),
            const _BlockTypeOption(
              icon: Icons.calculate,
              label: 'Formulaire / Score',
              description: 'Calcul interactif de score clinique',
              type: BlockType.formulaire,
            ),
            const _BlockTypeOption(
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

/// Crée un nouveau bloc du type spécifié
ProtocolBlock createBlockOfType(BlockType type, int ordre) {
  switch (type) {
    case BlockType.section:
      return SectionBlock(titre: 'Nouvelle section', contenu: [], ordre: ordre);
    case BlockType.texte:
      return TexteBlock(contenu: '', ordre: ordre);
    case BlockType.tableau:
      return TableauBlock(colonnes: ['Colonne 1'], lignes: [['']], ordre: ordre);
    case BlockType.image:
      return ImageBlock(source: '', ordre: ordre);
    case BlockType.medicament:
      return MedicamentBlock(nomMedicament: '', ordre: ordre);
    case BlockType.formulaire:
      return FormulaireBlock(titre: 'Nouveau formulaire', champs: [], ordre: ordre);
    case BlockType.alerte:
      return AlerteBlock(contenu: '', niveau: AlerteNiveau.info, ordre: ordre);
  }
}

/// Éditeur générique de bloc
class BlockEditorWidget extends StatelessWidget {
  final ProtocolBlock block;
  final Function(ProtocolBlock) onChanged;
  final VoidCallback onDelete;
  final List<String>? medicamentNames;

  const BlockEditorWidget({
    super.key,
    required this.block,
    required this.onChanged,
    required this.onDelete,
    this.medicamentNames,
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
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
                const SizedBox(width: 4),
                Icon(_getBlockIcon(block.type), size: 20, color: _getBlockColor(block.type)),
                const SizedBox(width: 8),
                Text(_getBlockLabel(block.type),
                    style: TextStyle(fontWeight: FontWeight.bold, color: _getBlockColor(block.type))),
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
        return SectionBlockEditor(block: block as SectionBlock, onChanged: onChanged, medicamentNames: medicamentNames);
      case BlockType.texte:
        return TexteBlockEditor(block: block as TexteBlock, onChanged: onChanged);
      case BlockType.tableau:
        return TableauBlockEditor(block: block as TableauBlock, onChanged: onChanged);
      case BlockType.image:
        return ImageBlockEditor(block: block as ImageBlock, onChanged: onChanged);
      case BlockType.medicament:
        return MedicamentBlockEditor(block: block as MedicamentBlock, onChanged: onChanged, medicamentNames: medicamentNames ?? []);
      case BlockType.formulaire:
        return FormulaireBlockEditor(block: block as FormulaireBlock, onChanged: onChanged);
      case BlockType.alerte:
        return AlerteBlockEditor(block: block as AlerteBlock, onChanged: onChanged);
    }
  }

  IconData _getBlockIcon(BlockType type) {
    switch (type) {
      case BlockType.section: return Icons.folder_open;
      case BlockType.texte: return Icons.text_fields;
      case BlockType.tableau: return Icons.table_chart;
      case BlockType.image: return Icons.image;
      case BlockType.medicament: return Icons.medication;
      case BlockType.formulaire: return Icons.calculate;
      case BlockType.alerte: return Icons.warning;
    }
  }

  String _getBlockLabel(BlockType type) {
    switch (type) {
      case BlockType.section: return 'Section';
      case BlockType.texte: return 'Texte';
      case BlockType.tableau: return 'Tableau';
      case BlockType.image: return 'Image';
      case BlockType.medicament: return 'Médicament';
      case BlockType.formulaire: return 'Formulaire';
      case BlockType.alerte: return 'Alerte';
    }
  }

  Color _getBlockColor(BlockType type) {
    switch (type) {
      case BlockType.section: return Colors.blue;
      case BlockType.texte: return Colors.grey;
      case BlockType.tableau: return Colors.teal;
      case BlockType.image: return Colors.orange;
      case BlockType.medicament: return Colors.purple;
      case BlockType.formulaire: return Colors.green;
      case BlockType.alerte: return Colors.red;
    }
  }
}

/// Éditeur de section
class SectionBlockEditor extends StatefulWidget {
  final SectionBlock block;
  final Function(ProtocolBlock) onChanged;
  final List<String>? medicamentNames;

  const SectionBlockEditor({super.key, required this.block, required this.onChanged, this.medicamentNames});

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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titreController,
          decoration: const InputDecoration(labelText: 'Titre de la section', border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tempsController,
                decoration: const InputDecoration(labelText: 'Temps (optionnel)', hintText: 'Ex: 5 min', border: OutlineInputBorder()),
                onChanged: (_) => _updateBlock(),
              ),
            ),
            const SizedBox(width: 12),
            Row(
              children: [
                const Text('Ouvert par défaut'),
                Switch(
                  value: widget.block.initialementOuvert,
                  onChanged: (value) => widget.onChanged(widget.block.copyWith(initialementOuvert: value)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        Row(
          children: [
            const Text('Contenu de la section', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter'), onPressed: () => _addSubBlock(context)),
          ],
        ),
        const SizedBox(height: 8),
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.block.contenu.length,
          onReorder: _reorderSubBlocks,
          itemBuilder: (context, index) {
            final subBlock = widget.block.contenu[index];
            return BlockEditorWidget(
              key: ValueKey('${subBlock.type}_$index'),
              block: subBlock,
              medicamentNames: widget.medicamentNames,
              onChanged: (updated) => _updateSubBlock(index, updated),
              onDelete: () => _deleteSubBlock(index),
            );
          },
        ),
      ],
    );
  }

  Future<void> _addSubBlock(BuildContext context) async {
    final type = await showDialog<BlockType>(context: context, builder: (_) => const BlockTypeSelectorDialog());
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
    final updatedContenu = List<ProtocolBlock>.from(widget.block.contenu)..removeAt(index);
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
}

/// Éditeur de texte
class TexteBlockEditor extends StatefulWidget {
  final TexteBlock block;
  final Function(ProtocolBlock) onChanged;

  const TexteBlockEditor({super.key, required this.block, required this.onChanged});

  @override
  State<TexteBlockEditor> createState() => _TexteBlockEditorState();
}

class _TexteBlockEditorState extends State<TexteBlockEditor> {
  late TextEditingController _contenuController;
  late TexteFormat _format;

  @override
  void initState() {
    super.initState();
    _contenuController = TextEditingController(text: widget.block.contenu);
    _format = widget.block.format ?? TexteFormat();
  }

  @override
  void dispose() {
    _contenuController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(contenu: _contenuController.text, format: _format));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: [
            _FormatToggle(icon: Icons.format_bold, isActive: _format.gras, onToggle: () {
              setState(() => _format = _format.copyWith(gras: !_format.gras));
              _updateBlock();
            }),
            _FormatToggle(icon: Icons.format_italic, isActive: _format.italique, onToggle: () {
              setState(() => _format = _format.copyWith(italique: !_format.italique));
              _updateBlock();
            }),
            _FormatToggle(icon: Icons.format_underline, isActive: _format.souligne, onToggle: () {
              setState(() => _format = _format.copyWith(souligne: !_format.souligne));
              _updateBlock();
            }),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contenuController,
          decoration: const InputDecoration(labelText: 'Contenu', border: OutlineInputBorder(), alignLabelWithHint: true),
          maxLines: 5,
          onChanged: (_) => _updateBlock(),
        ),
      ],
    );
  }
}

class _FormatToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onToggle;

  const _FormatToggle({required this.icon, required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onToggle,
      color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
      style: IconButton.styleFrom(backgroundColor: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null),
    );
  }
}

/// Éditeur de tableau
class TableauBlockEditor extends StatefulWidget {
  final TableauBlock block;
  final Function(ProtocolBlock) onChanged;

  const TableauBlockEditor({super.key, required this.block, required this.onChanged});

  @override
  State<TableauBlockEditor> createState() => _TableauBlockEditorState();
}

class _TableauBlockEditorState extends State<TableauBlockEditor> {
  late TextEditingController _titreController;
  late List<String> _colonnes;
  late List<List<String>> _lignes;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.block.titre ?? '');
    _colonnes = List.from(widget.block.colonnes);
    _lignes = widget.block.lignes.map((l) => List<String>.from(l)).toList();
    if (_colonnes.isEmpty) _colonnes = ['Colonne 1'];
    if (_lignes.isEmpty) _lignes = [['']];
  }

  @override
  void dispose() {
    _titreController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      titre: _titreController.text.isEmpty ? null : _titreController.text,
      colonnes: _colonnes,
      lignes: _lignes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titreController,
          decoration: const InputDecoration(labelText: 'Titre du tableau (optionnel)', border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Colonnes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add_circle, size: 20), onPressed: _addColumn, tooltip: 'Ajouter une colonne'),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_colonnes.length, (i) {
            return SizedBox(
              width: 150,
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Col ${i + 1}',
                  border: const OutlineInputBorder(),
                  suffixIcon: _colonnes.length > 1 ? IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => _removeColumn(i)) : null,
                ),
                controller: TextEditingController(text: _colonnes[i]),
                onChanged: (v) {
                  _colonnes[i] = v;
                  _updateBlock();
                },
              ),
            );
          }),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Lignes:', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(icon: const Icon(Icons.add_circle, size: 20), onPressed: _addRow, tooltip: 'Ajouter une ligne'),
          ],
        ),
        ..._lignes.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final row = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: List.generate(_colonnes.length, (colIndex) {
                      return SizedBox(
                        width: 150,
                        child: TextField(
                          decoration: InputDecoration(hintText: _colonnes[colIndex], border: const OutlineInputBorder(), isDense: true),
                          controller: TextEditingController(text: colIndex < row.length ? row[colIndex] : ''),
                          onChanged: (v) {
                            while (row.length <= colIndex) row.add('');
                            row[colIndex] = v;
                            _updateBlock();
                          },
                        ),
                      );
                    }),
                  ),
                ),
                if (_lignes.length > 1) IconButton(icon: const Icon(Icons.remove_circle, size: 20), onPressed: () => _removeRow(rowIndex), color: Colors.red),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _addColumn() {
    setState(() {
      _colonnes.add('Colonne ${_colonnes.length + 1}');
      for (var row in _lignes) row.add('');
    });
    _updateBlock();
  }

  void _removeColumn(int index) {
    setState(() {
      _colonnes.removeAt(index);
      for (var row in _lignes) if (index < row.length) row.removeAt(index);
    });
    _updateBlock();
  }

  void _addRow() {
    setState(() => _lignes.add(List.filled(_colonnes.length, '')));
    _updateBlock();
  }

  void _removeRow(int index) {
    setState(() => _lignes.removeAt(index));
    _updateBlock();
  }
}

/// Éditeur d'image
class ImageBlockEditor extends StatefulWidget {
  final ImageBlock block;
  final Function(ProtocolBlock) onChanged;

  const ImageBlockEditor({super.key, required this.block, required this.onChanged});

  @override
  State<ImageBlockEditor> createState() => _ImageBlockEditorState();
}

class _ImageBlockEditorState extends State<ImageBlockEditor> {
  late TextEditingController _legendeController;
  late TextEditingController _urlController;
  late int _largeur;
  bool _isBase64 = false;
  String _base64Data = '';

  @override
  void initState() {
    super.initState();
    _legendeController = TextEditingController(text: widget.block.legende ?? '');
    _urlController = TextEditingController(text: widget.block.estBase64 ? '' : widget.block.source);
    _largeur = widget.block.largeurPourcent ?? 100;
    _isBase64 = widget.block.estBase64;
    if (_isBase64) _base64Data = widget.block.source;
  }

  @override
  void dispose() {
    _legendeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      source: _isBase64 ? _base64Data : _urlController.text,
      estBase64: _isBase64,
      legende: _legendeController.text.isEmpty ? null : _legendeController.text,
      largeurPourcent: _largeur,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('URL'), icon: Icon(Icons.link)),
            ButtonSegment(value: true, label: Text('Fichier'), icon: Icon(Icons.file_upload)),
          ],
          selected: {_isBase64},
          onSelectionChanged: (set) => setState(() => _isBase64 = set.first),
        ),
        const SizedBox(height: 12),
        if (_isBase64) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.image),
            label: Text(_base64Data.isEmpty ? 'Sélectionner une image' : 'Image chargée ✓'),
            onPressed: _pickImage,
          ),
          if (_base64Data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.memory(base64Decode(_base64Data), fit: BoxFit.contain)),
            ),
          ],
        ] else
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(labelText: 'URL de l\'image', hintText: 'https://...', border: OutlineInputBorder()),
            onChanged: (_) => _updateBlock(),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _legendeController,
          decoration: const InputDecoration(labelText: 'Légende (optionnel)', border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Largeur: '),
            Expanded(
              child: Slider(value: _largeur.toDouble(), min: 20, max: 100, divisions: 8, label: '$_largeur%', onChanged: (v) {
                setState(() => _largeur = v.round());
                _updateBlock();
              }),
            ),
            Text('$_largeur%'),
          ],
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _base64Data = base64Encode(bytes);
        _isBase64 = true;
      });
      _updateBlock();
    }
  }
}

/// Éditeur de médicament
class MedicamentBlockEditor extends StatefulWidget {
  final MedicamentBlock block;
  final Function(ProtocolBlock) onChanged;
  final List<String> medicamentNames;

  const MedicamentBlockEditor({super.key, required this.block, required this.onChanged, required this.medicamentNames});

  @override
  State<MedicamentBlockEditor> createState() => _MedicamentBlockEditorState();
}

class _MedicamentBlockEditorState extends State<MedicamentBlockEditor> {
  late TextEditingController _nomController;
  late TextEditingController _indicationController;
  late TextEditingController _voieController;
  late TextEditingController _commentaireController;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.block.nomMedicament);
    _indicationController = TextEditingController(text: widget.block.indication ?? '');
    _voieController = TextEditingController(text: widget.block.voie ?? '');
    _commentaireController = TextEditingController(text: widget.block.commentaire ?? '');
  }

  @override
  void dispose() {
    _nomController.dispose();
    _indicationController.dispose();
    _voieController.dispose();
    _commentaireController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      nomMedicament: _nomController.text,
      indication: _indicationController.text.isEmpty ? null : _indicationController.text,
      voie: _voieController.text.isEmpty ? null : _voieController.text,
      commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<String>(
          initialValue: TextEditingValue(text: widget.block.nomMedicament),
          optionsBuilder: (textEditingValue) {
            if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
            return widget.medicamentNames.where((name) => name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
          },
          onSelected: (selection) {
            _nomController.text = selection;
            _updateBlock();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(labelText: 'Nom du médicament *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.medication)),
              onChanged: (v) {
                _nomController.text = v;
                _updateBlock();
              },
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(controller: _indicationController, decoration: const InputDecoration(labelText: 'Indication (optionnel)', border: OutlineInputBorder()), onChanged: (_) => _updateBlock()),
        const SizedBox(height: 12),
        TextField(controller: _voieController, decoration: const InputDecoration(labelText: 'Voie d\'administration (optionnel)', border: OutlineInputBorder()), onChanged: (_) => _updateBlock()),
        const SizedBox(height: 12),
        TextField(controller: _commentaireController, decoration: const InputDecoration(labelText: 'Commentaire (optionnel)', border: OutlineInputBorder()), maxLines: 2, onChanged: (_) => _updateBlock()),
      ],
    );
  }
}

/// Éditeur de formulaire
class FormulaireBlockEditor extends StatefulWidget {
  final FormulaireBlock block;
  final Function(ProtocolBlock) onChanged;

  const FormulaireBlockEditor({super.key, required this.block, required this.onChanged});

  @override
  State<FormulaireBlockEditor> createState() => _FormulaireBlockEditorState();
}

class _FormulaireBlockEditorState extends State<FormulaireBlockEditor> {
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late List<FormulaireChamp> _champs;
  late List<FormulaireInterpretation> _interpretations;

  @override
  void initState() {
    super.initState();
    _titreController = TextEditingController(text: widget.block.titre);
    _descriptionController = TextEditingController(text: widget.block.description ?? '');
    _champs = List.from(widget.block.champs);
    _interpretations = List.from(widget.block.interpretations ?? []);
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      titre: _titreController.text,
      description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
      champs: _champs,
      interpretations: _interpretations.isEmpty ? null : _interpretations,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _titreController, decoration: const InputDecoration(labelText: 'Titre du formulaire', border: OutlineInputBorder()), onChanged: (_) => _updateBlock()),
        const SizedBox(height: 12),
        TextField(controller: _descriptionController, decoration: const InputDecoration(labelText: 'Description (optionnel)', border: OutlineInputBorder()), onChanged: (_) => _updateBlock()),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Champs', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter'), onPressed: _addChamp),
          ],
        ),
        ..._champs.asMap().entries.map((entry) => _ChampEditor(
              champ: entry.value,
              onChanged: (c) {
                _champs[entry.key] = c;
                _updateBlock();
              },
              onDelete: () {
                setState(() => _champs.removeAt(entry.key));
                _updateBlock();
              },
            )),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Interprétations', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(icon: const Icon(Icons.add, size: 18), label: const Text('Ajouter'), onPressed: _addInterpretation),
          ],
        ),
        ..._interpretations.asMap().entries.map((entry) => _InterpretationEditor(
              interpretation: entry.value,
              onChanged: (i) {
                _interpretations[entry.key] = i;
                _updateBlock();
              },
              onDelete: () {
                setState(() => _interpretations.removeAt(entry.key));
                _updateBlock();
              },
            )),
      ],
    );
  }

  void _addChamp() {
    setState(() => _champs.add(FormulaireChamp(id: 'champ_${_champs.length + 1}', label: 'Nouveau champ', type: ChampType.nombre)));
    _updateBlock();
  }

  void _addInterpretation() {
    setState(() => _interpretations.add(FormulaireInterpretation(min: 0, max: 10, texte: 'Interprétation', niveau: InterpretationNiveau.faible)));
    _updateBlock();
  }
}

class _ChampEditor extends StatelessWidget {
  final FormulaireChamp champ;
  final Function(FormulaireChamp) onChanged;
  final VoidCallback onDelete;

  const _ChampEditor({required this.champ, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'ID', border: OutlineInputBorder(), isDense: true), controller: TextEditingController(text: champ.id), onChanged: (v) => onChanged(champ.copyWith(id: v)))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: TextField(decoration: const InputDecoration(labelText: 'Label', border: OutlineInputBorder(), isDense: true), controller: TextEditingController(text: champ.label), onChanged: (v) => onChanged(champ.copyWith(label: v)))),
                IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: onDelete, color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ChampType>(
              value: champ.type,
              decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder(), isDense: true),
              items: ChampType.values.map((t) => DropdownMenuItem(value: t, child: Text(_getChampTypeLabel(t)))).toList(),
              onChanged: (v) { if (v != null) onChanged(champ.copyWith(type: v)); },
            ),
            if (champ.type == ChampType.nombre) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, controller: TextEditingController(text: champ.min?.toString() ?? ''), onChanged: (v) => onChanged(champ.copyWith(min: num.tryParse(v))))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, controller: TextEditingController(text: champ.max?.toString() ?? ''), onChanged: (v) => onChanged(champ.copyWith(max: num.tryParse(v))))),
                ],
              ),
            ],
            if (champ.type == ChampType.checkbox) ...[
              const SizedBox(height: 8),
              TextField(decoration: const InputDecoration(labelText: 'Points si coché', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, controller: TextEditingController(text: champ.points?.toString() ?? ''), onChanged: (v) => onChanged(champ.copyWith(points: int.tryParse(v)))),
            ],
          ],
        ),
      ),
    );
  }

  String _getChampTypeLabel(ChampType type) {
    switch (type) {
      case ChampType.nombre: return 'Nombre';
      case ChampType.selection: return 'Sélection (dropdown)';
      case ChampType.checkbox: return 'Case à cocher';
      case ChampType.radio: return 'Boutons radio';
    }
  }
}

class _InterpretationEditor extends StatelessWidget {
  final FormulaireInterpretation interpretation;
  final Function(FormulaireInterpretation) onChanged;
  final VoidCallback onDelete;

  const _InterpretationEditor({required this.interpretation, required this.onChanged, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Min', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, controller: TextEditingController(text: interpretation.min.toString()), onChanged: (v) => onChanged(interpretation.copyWith(min: num.tryParse(v) ?? 0)))),
                const SizedBox(width: 8),
                Expanded(child: TextField(decoration: const InputDecoration(labelText: 'Max', border: OutlineInputBorder(), isDense: true), keyboardType: TextInputType.number, controller: TextEditingController(text: interpretation.max.toString()), onChanged: (v) => onChanged(interpretation.copyWith(max: num.tryParse(v) ?? 100)))),
                IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: onDelete, color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            TextField(decoration: const InputDecoration(labelText: 'Texte d\'interprétation', border: OutlineInputBorder(), isDense: true), controller: TextEditingController(text: interpretation.texte), onChanged: (v) => onChanged(interpretation.copyWith(texte: v))),
            const SizedBox(height: 8),
            DropdownButtonFormField<InterpretationNiveau>(
              value: interpretation.niveau ?? InterpretationNiveau.faible,
              decoration: const InputDecoration(labelText: 'Niveau', border: OutlineInputBorder(), isDense: true),
              items: InterpretationNiveau.values.map((n) => DropdownMenuItem(value: n, child: Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: _getNiveauColor(n), shape: BoxShape.circle)), const SizedBox(width: 8), Text(_getNiveauLabel(n))]))).toList(),
              onChanged: (v) { if (v != null) onChanged(interpretation.copyWith(niveau: v)); },
            ),
          ],
        ),
      ),
    );
  }

  String _getNiveauLabel(InterpretationNiveau niveau) {
    switch (niveau) {
      case InterpretationNiveau.faible: return 'Faible';
      case InterpretationNiveau.modere: return 'Modéré';
      case InterpretationNiveau.eleve: return 'Élevé';
      case InterpretationNiveau.critique: return 'Critique';
    }
  }

  Color _getNiveauColor(InterpretationNiveau niveau) {
    switch (niveau) {
      case InterpretationNiveau.faible: return Colors.green;
      case InterpretationNiveau.modere: return Colors.orange;
      case InterpretationNiveau.eleve: return Colors.deepOrange;
      case InterpretationNiveau.critique: return Colors.red;
    }
  }
}

/// Éditeur d'alerte
class AlerteBlockEditor extends StatefulWidget {
  final AlerteBlock block;
  final Function(ProtocolBlock) onChanged;

  const AlerteBlockEditor({super.key, required this.block, required this.onChanged});

  @override
  State<AlerteBlockEditor> createState() => _AlerteBlockEditorState();
}

class _AlerteBlockEditorState extends State<AlerteBlockEditor> {
  late TextEditingController _contenuController;

  @override
  void initState() {
    super.initState();
    _contenuController = TextEditingController(text: widget.block.contenu);
  }

  @override
  void dispose() {
    _contenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AlerteNiveau>(
          value: widget.block.niveau,
          decoration: const InputDecoration(labelText: 'Niveau d\'alerte', border: OutlineInputBorder()),
          items: AlerteNiveau.values.map((n) => DropdownMenuItem(value: n, child: Row(children: [Icon(_getAlertIcon(n), color: _getAlertColor(n), size: 20), const SizedBox(width: 8), Text(_getAlertLabel(n))]))).toList(),
          onChanged: (v) { if (v != null) widget.onChanged(widget.block.copyWith(niveau: v)); },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contenuController,
          decoration: const InputDecoration(labelText: 'Contenu de l\'alerte', border: OutlineInputBorder(), alignLabelWithHint: true),
          maxLines: 3,
          onChanged: (_) => widget.onChanged(widget.block.copyWith(contenu: _contenuController.text)),
        ),
      ],
    );
  }

  IconData _getAlertIcon(AlerteNiveau niveau) {
    switch (niveau) {
      case AlerteNiveau.info: return Icons.info;
      case AlerteNiveau.attention: return Icons.warning_amber;
      case AlerteNiveau.danger: return Icons.error;
      case AlerteNiveau.critique: return Icons.dangerous;
    }
  }

  Color _getAlertColor(AlerteNiveau niveau) {
    switch (niveau) {
      case AlerteNiveau.info: return Colors.blue;
      case AlerteNiveau.attention: return Colors.orange;
      case AlerteNiveau.danger: return Colors.deepOrange;
      case AlerteNiveau.critique: return Colors.red;
    }
  }

  String _getAlertLabel(AlerteNiveau niveau) {
    switch (niveau) {
      case AlerteNiveau.info: return 'Information';
      case AlerteNiveau.attention: return 'Attention';
      case AlerteNiveau.danger: return 'Danger';
      case AlerteNiveau.critique: return 'Critique';
    }
  }
}