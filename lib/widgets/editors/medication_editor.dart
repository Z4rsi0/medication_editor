import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';
import '../../services/medication_provider.dart';

class MedicamentBlockEditor extends StatefulWidget {
  final MedicamentBlock block;
  final Function(ProtocolBlock) onChanged;
  final MedicationProvider? medicationProvider;

  const MedicamentBlockEditor({
    super.key,
    required this.block,
    required this.onChanged,
    this.medicationProvider,
  });

  @override
  State<MedicamentBlockEditor> createState() => _MedicamentBlockEditorState();
}

class _MedicamentBlockEditorState extends State<MedicamentBlockEditor> {
  late final TextEditingController _nomController;
  late final TextEditingController _indicationController;
  late final TextEditingController _voieController;
  late final TextEditingController _commentaireController;

  late final FocusNode _nomFocusNode;
  late final FocusNode _indicationFocusNode;

  String _selectedMedicationName = '';

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.block.nomMedicament);
    _indicationController =
        TextEditingController(text: widget.block.indication ?? '');
    _voieController = TextEditingController(text: widget.block.voie ?? '');
    _commentaireController =
        TextEditingController(text: widget.block.commentaire ?? '');

    _nomFocusNode = FocusNode();
    _indicationFocusNode = FocusNode();

    _selectedMedicationName = widget.block.nomMedicament;

    _nomFocusNode.addListener(_onNomFocusChange);
  }

  void _onNomFocusChange() {
    if (!_nomFocusNode.hasFocus) {
      if (_selectedMedicationName != _nomController.text) {
        setState(() {
          _selectedMedicationName = _nomController.text;
        });
      }
    }
  }

  @override
  void dispose() {
    _nomFocusNode.removeListener(_onNomFocusChange);
    _nomController.dispose();
    _indicationController.dispose();
    _voieController.dispose();
    _commentaireController.dispose();
    _nomFocusNode.dispose();
    _indicationFocusNode.dispose();
    super.dispose();
  }

  List<String> _getMedicationNames() {
    if (widget.medicationProvider == null) return [];
    return widget.medicationProvider!.medications
        .map((med) => med.nom)
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getIndicationsForMedication(String medicationName) {
    if (widget.medicationProvider == null) return [];
    if (medicationName.trim().isEmpty) return [];

    try {
      final medication = widget.medicationProvider!.medications.firstWhere(
        (med) => med.nom.toLowerCase() == medicationName.toLowerCase(),
      );

      return medication.indications.map((ind) => ind.label).toList();
    } catch (e) {
      return [];
    }
  }

  void _updateBlockSilently() {
    widget.onChanged(widget.block.copyWith(
      nomMedicament: _nomController.text,
      indication: _indicationController.text.isEmpty
          ? null
          : _indicationController.text,
      voie: _voieController.text.isEmpty ? null : _voieController.text,
      commentaire: _commentaireController.text.isEmpty
          ? null
          : _commentaireController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final medicationNames = _getMedicationNames();
    final indications = _getIndicationsForMedication(_selectedMedicationName);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<String>(
          textEditingController: _nomController,
          focusNode: _nomFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) {
              return medicationNames;
            }
            return medicationNames.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _nomController.text = selection;
            _nomController.selection = TextSelection.fromPosition(
              TextPosition(offset: selection.length),
            );
            _indicationController.clear();
            setState(() {
              _selectedMedicationName = selection;
            });
            _updateBlockSilently();
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Nom du médicament *',
                hintText: 'Ex: Midazolam',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.medication),
                helperText: medicationNames.isEmpty
                    ? 'Aucun médicament chargé'
                    : '${medicationNames.length} médicament(s) disponible(s)',
              ),
              textCapitalization: TextCapitalization.words,
              onChanged: (value) {
                _updateBlockSilently();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 200, maxWidth: 350),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isHighlighted =
                          AutocompleteHighlightedOption.of(context) == index;
                      return ListTile(
                        leading: const Icon(Icons.medication, size: 20),
                        title: Text(option),
                        dense: true,
                        tileColor:
                            isHighlighted ? Theme.of(context).focusColor : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        RawAutocomplete<String>(
          textEditingController: _indicationController,
          focusNode: _indicationFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            final currentName = _nomController.text.trim();
            if (currentName.isEmpty) {
              return const Iterable<String>.empty();
            }

            final availableIndications =
                _getIndicationsForMedication(currentName);

            if (textEditingValue.text.isEmpty) {
              return availableIndications;
            }

            return availableIndications.where((String option) {
              return option
                  .toLowerCase()
                  .contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _indicationController.text = selection;
            _indicationController.selection = TextSelection.fromPosition(
              TextPosition(offset: selection.length),
            );
            _updateBlockSilently();
          },
          fieldViewBuilder: (BuildContext context,
              TextEditingController textEditingController,
              FocusNode focusNode,
              VoidCallback onFieldSubmitted) {
            final isEnabled = _nomController.text.trim().isNotEmpty;
            return TextFormField(
              controller: textEditingController,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Indication',
                hintText: !isEnabled
                    ? 'Sélectionnez d\'abord un médicament'
                    : 'Ex: Convulsions',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info_outline),
                helperText: !isEnabled
                    ? null
                    : indications.isEmpty
                        ? 'Saisie libre (aucune indication pré-définie)'
                        : '${indications.length} indication(s) disponible(s)',
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: isEnabled,
              onChanged: (value) {
                _updateBlockSilently();
              },
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxHeight: 200, maxWidth: 350),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      final isHighlighted =
                          AutocompleteHighlightedOption.of(context) == index;
                      return ListTile(
                        leading:
                            const Icon(Icons.medical_information, size: 20),
                        title: Text(option),
                        dense: true,
                        tileColor:
                            isHighlighted ? Theme.of(context).focusColor : null,
                        onTap: () => onSelected(option),
                      );
                    },
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _voieController,
          decoration: const InputDecoration(
            labelText: 'Voie d\'administration (optionnel)',
            hintText: 'Ex: IV, PO, IM...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services),
          ),
          onChanged: (_) => _updateBlockSilently(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentaireController,
          decoration: const InputDecoration(
            labelText: 'Commentaire (optionnel)',
            hintText: 'Instructions supplémentaires...',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
          onChanged: (_) => _updateBlockSilently(),
        ),
        const SizedBox(height: 8),
        Card(
          color: Colors.purple.shade50,
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'L\'app recherchera automatiquement ce médicament avec cette indication et affichera toutes les posologies disponibles',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}