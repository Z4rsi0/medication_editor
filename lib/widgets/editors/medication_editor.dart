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
  late TextEditingController _nomController;
  late TextEditingController _indicationController;
  late TextEditingController _voieController;
  late TextEditingController _commentaireController;

  late FocusNode _nomFocusNode;
  late FocusNode _indicationFocusNode;

  String _selectedMedicationName = '';

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.block.nomMedicament);
    _indicationController = TextEditingController(text: widget.block.indication ?? '');
    _voieController = TextEditingController(text: widget.block.voie ?? '');
    _commentaireController = TextEditingController(text: widget.block.commentaire ?? '');

    _nomFocusNode = FocusNode();
    _indicationFocusNode = FocusNode();
    _selectedMedicationName = widget.block.nomMedicament;

    _nomFocusNode.addListener(_onNomFocusChange);
  }

  @override
  void didUpdateWidget(MedicamentBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Synchronisation modèle -> vue (seulement si nécessaire)
    if (widget.block.nomMedicament != oldWidget.block.nomMedicament && 
        widget.block.nomMedicament != _nomController.text) {
      _nomController.text = widget.block.nomMedicament;
    }
    if (widget.block.indication != oldWidget.block.indication &&
        (widget.block.indication ?? '') != _indicationController.text) {
      _indicationController.text = widget.block.indication ?? '';
    }
    if (widget.block.voie != oldWidget.block.voie &&
        (widget.block.voie ?? '') != _voieController.text) {
      _voieController.text = widget.block.voie ?? '';
    }
    if (widget.block.commentaire != oldWidget.block.commentaire &&
        (widget.block.commentaire ?? '') != _commentaireController.text) {
      _commentaireController.text = widget.block.commentaire ?? '';
    }
  }

  void _onNomFocusChange() {
    if (!_nomFocusNode.hasFocus) {
      if (_selectedMedicationName != _nomController.text) {
        setState(() => _selectedMedicationName = _nomController.text);
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
    // Mise à jour du parent SANS setState local (géré par les contrôleurs)
    widget.onChanged(widget.block.copyWith(
      nomMedicament: _nomController.text,
      indication: _indicationController.text.isEmpty ? null : _indicationController.text,
      voie: _voieController.text.isEmpty ? null : _voieController.text,
      commentaire: _commentaireController.text.isEmpty ? null : _commentaireController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final medicationNames = _getMedicationNames();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<String>(
          textEditingController: _nomController,
          focusNode: _nomFocusNode,
          optionsBuilder: (TextEditingValue textEditingValue) {
            if (textEditingValue.text.isEmpty) return medicationNames;
            return medicationNames.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _nomController.text = selection;
            _indicationController.clear();
            setState(() => _selectedMedicationName = selection);
            _updateBlockSilently();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
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
              onChanged: (_) => _updateBlockSilently(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.medication, size: 20),
                        title: Text(option),
                        dense: true,
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
            if (currentName.isEmpty) return const Iterable<String>.empty();
            final availableIndications = _getIndicationsForMedication(currentName);
            if (textEditingValue.text.isEmpty) return availableIndications;
            return availableIndications.where((String option) {
              return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
            });
          },
          onSelected: (String selection) {
            _indicationController.text = selection;
            _updateBlockSilently();
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            final isEnabled = _nomController.text.trim().isNotEmpty;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              decoration: InputDecoration(
                labelText: 'Indication',
                hintText: !isEnabled ? 'Sélectionnez d\'abord un médicament' : 'Ex: Convulsions',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.info_outline),
              ),
              textCapitalization: TextCapitalization.sentences,
              enabled: isEnabled,
              onChanged: (_) => _updateBlockSilently(),
            );
          },
          optionsViewBuilder: (context, onSelected, options) {
            return Align(
              alignment: Alignment.topLeft,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200, maxWidth: 350),
                  child: ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final option = options.elementAt(index);
                      return ListTile(
                        leading: const Icon(Icons.medical_information, size: 20),
                        title: Text(option),
                        dense: true,
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
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _voieController,
                decoration: const InputDecoration(
                  labelText: 'Voie',
                  hintText: 'IV, PO...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_services),
                ),
                onChanged: (_) => _updateBlockSilently(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _commentaireController,
          decoration: const InputDecoration(
            labelText: 'Commentaire',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.comment),
          ),
          maxLines: 2,
          onChanged: (_) => _updateBlockSilently(),
        ),
      ],
    );
  }
}