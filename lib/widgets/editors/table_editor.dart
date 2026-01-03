import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';

class TableauBlockEditor extends StatefulWidget {
  final TableauBlock block;
  final Function(ProtocolBlock) onChanged;

  const TableauBlockEditor(
      {super.key, required this.block, required this.onChanged});

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
    _initData();
  }

  void _initData() {
    _titreController = TextEditingController(text: widget.block.titre ?? '');
    _colonnes = List.from(widget.block.colonnes);
    _lignes = widget.block.lignes.map((l) => List<String>.from(l)).toList();
    if (_colonnes.isEmpty) _colonnes = ['Colonne 1'];
    if (_lignes.isEmpty) _lignes = [['']];
  }

  @override
  void didUpdateWidget(TableauBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync titre
    if (widget.block.titre != _titreController.text) {
      _titreController.text = widget.block.titre ?? '';
    }
    // Sync structure si changée drastiquement (ex: undo/redo)
    if (widget.block.colonnes.length != _colonnes.length || 
        widget.block.lignes.length != _lignes.length) {
       _colonnes = List.from(widget.block.colonnes);
       _lignes = widget.block.lignes.map((l) => List<String>.from(l)).toList();
    }
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

  void _addColumn() {
    setState(() {
      _colonnes.add('Colonne ${_colonnes.length + 1}');
      for (var row in _lignes) {
        row.add('');
      }
    });
    _updateBlock();
  }

  void _removeColumn(int index) {
    setState(() {
      _colonnes.removeAt(index);
      for (var row in _lignes) {
        if (index < row.length) row.removeAt(index);
      }
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titreController,
          decoration: const InputDecoration(
              labelText: 'Titre du tableau (optionnel)',
              border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Colonnes:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.add_circle, size: 20),
                onPressed: _addColumn,
                tooltip: 'Ajouter une colonne'),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(_colonnes.length, (i) {
            return SizedBox(
              width: 150,
              child: TextFormField(
                // Clé unique pour éviter la perte de focus si on supprime une colonne avant
                key: ValueKey('col_$i'),
                initialValue: _colonnes[i],
                decoration: InputDecoration(
                  labelText: 'Col ${i + 1}',
                  border: const OutlineInputBorder(),
                  suffixIcon: _colonnes.length > 1
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () => _removeColumn(i))
                      : null,
                ),
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
            const Text('Lignes:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
                icon: const Icon(Icons.add_circle, size: 20),
                onPressed: _addRow,
                tooltip: 'Ajouter une ligne'),
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
                        child: TextFormField(
                          key: ValueKey('cell_${rowIndex}_$colIndex'),
                          initialValue: colIndex < row.length ? row[colIndex] : '',
                          decoration: InputDecoration(
                              hintText: colIndex < _colonnes.length ? _colonnes[colIndex] : '',
                              border: const OutlineInputBorder(),
                              isDense: true),
                          onChanged: (v) {
                            while (row.length <= colIndex) {
                              row.add('');
                            }
                            row[colIndex] = v;
                            _updateBlock();
                          },
                        ),
                      );
                    }),
                  ),
                ),
                if (_lignes.length > 1)
                  IconButton(
                      icon: const Icon(Icons.remove_circle, size: 20),
                      onPressed: () => _removeRow(rowIndex),
                      color: Colors.red),
              ],
            ),
          );
        }),
      ],
    );
  }
}