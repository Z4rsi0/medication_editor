import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';

class FormulaireBlockEditor extends StatefulWidget {
  final FormulaireBlock block;
  final Function(ProtocolBlock) onChanged;

  const FormulaireBlockEditor(
      {super.key, required this.block, required this.onChanged});

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
    _descriptionController =
        TextEditingController(text: widget.block.description ?? '');
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
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      champs: _champs,
      interpretations: _interpretations.isEmpty ? null : _interpretations,
    ));
  }

  void _addChamp() {
    setState(() => _champs.add(FormulaireChamp(
        id: 'champ_${_champs.length + 1}',
        label: 'Nouveau champ',
        type: ChampType.nombre)));
    _updateBlock();
  }

  void _addInterpretation() {
    setState(() => _interpretations.add(FormulaireInterpretation(
        min: 0,
        max: 10,
        texte: 'Interprétation',
        niveau: InterpretationNiveau.faible)));
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
              labelText: 'Titre du formulaire', border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descriptionController,
          decoration: const InputDecoration(
              labelText: 'Description (optionnel)',
              border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text('Champs', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                onPressed: _addChamp),
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
            const Text('Interprétations',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ajouter'),
                onPressed: _addInterpretation),
          ],
        ),
        ..._interpretations
            .asMap()
            .entries
            .map((entry) => _InterpretationEditor(
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
}

class _ChampEditor extends StatelessWidget {
  final FormulaireChamp champ;
  final Function(FormulaireChamp) onChanged;
  final VoidCallback onDelete;

  const _ChampEditor(
      {required this.champ, required this.onChanged, required this.onDelete});

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
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'ID',
                        border: OutlineInputBorder(),
                        isDense: true),
                    controller: TextEditingController(text: champ.id),
                    onChanged: (v) => onChanged(champ.copyWith(id: v)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'Label',
                        border: OutlineInputBorder(),
                        isDense: true),
                    controller: TextEditingController(text: champ.label),
                    onChanged: (v) => onChanged(champ.copyWith(label: v)),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ChampType>(
              value: champ.type,
              decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: ChampType.values
                  .map((t) => DropdownMenuItem(
                      value: t, child: Text(_getChampTypeLabel(t))))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(champ.copyWith(type: v));
              },
            ),
            if (champ.type == ChampType.nombre) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(),
                          isDense: true),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: champ.min?.toString() ?? ''),
                      onChanged: (v) =>
                          onChanged(champ.copyWith(min: num.tryParse(v))),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(),
                          isDense: true),
                      keyboardType: TextInputType.number,
                      controller:
                          TextEditingController(text: champ.max?.toString() ?? ''),
                      onChanged: (v) =>
                          onChanged(champ.copyWith(max: num.tryParse(v))),
                    ),
                  ),
                ],
              ),
            ],
            if (champ.type == ChampType.checkbox) ...[
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                    labelText: 'Points si coché',
                    border: OutlineInputBorder(),
                    isDense: true),
                keyboardType: TextInputType.number,
                controller: TextEditingController(
                    text: champ.points?.toString() ?? ''),
                onChanged: (v) =>
                    onChanged(champ.copyWith(points: int.tryParse(v))),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getChampTypeLabel(ChampType type) {
    switch (type) {
      case ChampType.nombre:
        return 'Nombre';
      case ChampType.selection:
        return 'Sélection (dropdown)';
      case ChampType.checkbox:
        return 'Case à cocher';
      case ChampType.radio:
        return 'Boutons radio';
    }
  }
}

class _InterpretationEditor extends StatelessWidget {
  final FormulaireInterpretation interpretation;
  final Function(FormulaireInterpretation) onChanged;
  final VoidCallback onDelete;

  const _InterpretationEditor(
      {required this.interpretation,
      required this.onChanged,
      required this.onDelete});

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
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'Min',
                        border: OutlineInputBorder(),
                        isDense: true),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: interpretation.min.toString()),
                    onChanged: (v) => onChanged(
                        interpretation.copyWith(min: num.tryParse(v) ?? 0)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                        labelText: 'Max',
                        border: OutlineInputBorder(),
                        isDense: true),
                    keyboardType: TextInputType.number,
                    controller: TextEditingController(
                        text: interpretation.max.toString()),
                    onChanged: (v) => onChanged(
                        interpretation.copyWith(max: num.tryParse(v) ?? 100)),
                  ),
                ),
                IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: onDelete,
                    color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Texte d\'interprétation',
                  border: OutlineInputBorder(),
                  isDense: true),
              controller: TextEditingController(text: interpretation.texte),
              onChanged: (v) => onChanged(interpretation.copyWith(texte: v)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<InterpretationNiveau>(
              value: interpretation.niveau ?? InterpretationNiveau.faible,
              decoration: const InputDecoration(
                  labelText: 'Niveau',
                  border: OutlineInputBorder(),
                  isDense: true),
              items: InterpretationNiveau.values
                  .map((n) => DropdownMenuItem(
                        value: n,
                        child: Row(
                          children: [
                            Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                    color: _getNiveauColor(n),
                                    shape: BoxShape.circle)),
                            const SizedBox(width: 8),
                            Text(_getNiveauLabel(n)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(interpretation.copyWith(niveau: v));
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getNiveauLabel(InterpretationNiveau niveau) {
    switch (niveau) {
      case InterpretationNiveau.faible:
        return 'Faible';
      case InterpretationNiveau.modere:
        return 'Modéré';
      case InterpretationNiveau.eleve:
        return 'Élevé';
      case InterpretationNiveau.critique:
        return 'Critique';
    }
  }

  Color _getNiveauColor(InterpretationNiveau niveau) {
    switch (niveau) {
      case InterpretationNiveau.faible:
        return Colors.green;
      case InterpretationNiveau.modere:
        return Colors.orange;
      case InterpretationNiveau.eleve:
        return Colors.deepOrange;
      case InterpretationNiveau.critique:
        return Colors.red;
    }
  }
}