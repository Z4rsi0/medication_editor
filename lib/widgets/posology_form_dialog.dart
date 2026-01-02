// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../models/medication.dart';
import '../utils/constants.dart';
// Imports des nouveaux sous-composants
import 'posology/dose_input.dart';
import 'posology/tranche_editor.dart';

class PosologyFormDialog extends StatefulWidget {
  final int? index;
  const PosologyFormDialog({super.key, this.index});

  @override
  State<PosologyFormDialog> createState() => _PosologyFormDialogState();
}

class _PosologyFormDialogState extends State<PosologyFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers principaux
  final _voieController = TextEditingController();
  final _preparationController = TextEditingController();
  final _dosesController = TextEditingController();
  final _doseMaxController = TextEditingController();

  // Controllers pour dose simple (hors tranches)
  final _doseKgController = TextEditingController();
  final _doseKgMinController = TextEditingController();
  final _doseKgMaxController = TextEditingController();

  // État
  String? _selectedUnite;
  bool _useDoseRange = false;
  bool _useTranches = false;
  bool _useComplexScheme = false;

  // Liste des tranches (ViewModel)
  final List<TrancheData> _tranches = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final posology = widget.index != null
        ? provider.currentIndication!.posologies[widget.index!]
        : null;

    if (posology != null) {
      _voieController.text = posology.voie;
      _selectedUnite = posology.unite;
      _preparationController.text = posology.preparation ?? '';
      _doseMaxController.text = posology.doseMax?.toString() ?? '';

      if (posology.doses != null) {
        _useComplexScheme = true;
        _dosesController.text = posology.doses!;
      } else if (posology.tranches != null && posology.tranches!.isNotEmpty) {
        _useTranches = true;
        for (var t in posology.tranches!) {
          _tranches.add(TrancheData.fromTranche(t));
        }
      } else if (posology.doseKgMin != null) {
        _useDoseRange = true;
        _doseKgMinController.text = posology.doseKgMin.toString();
        _doseKgMaxController.text = posology.doseKgMax.toString();
      } else if (posology.doseKg != null) {
        _doseKgController.text = posology.doseKg.toString();
      }
    }
  }

  @override
  void dispose() {
    _voieController.dispose();
    _preparationController.dispose();
    _dosesController.dispose();
    _doseMaxController.dispose();
    _doseKgController.dispose();
    _doseKgMinController.dispose();
    _doseKgMaxController.dispose();
    for (var t in _tranches) t.dispose();
    super.dispose();
  }

  dynamic _parseNumber(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? int.tryParse(text);
  }

  void _savePosology() {
    if (!_formKey.currentState!.validate()) return;

    // Validation spécifique Tranches
    if (_useTranches) {
      if (_tranches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ajoutez au moins une tranche.')));
        return;
      }
      // Vérifier que chaque tranche a au moins une info
      // (La validation fine est faite par les FormFields, mais on peut ajouter une sécurité ici)
    }

    final posology = Posology(
      voie: _voieController.text.trim(),
      unite: _selectedUnite!,
      preparation: _preparationController.text.trim().isEmpty ? null : _preparationController.text.trim(),
      doseMax: _parseNumber(_doseMaxController.text),
      doses: _useComplexScheme ? _dosesController.text.trim() : null,
      tranches: _useTranches ? _tranches.map((td) => td.toTranche()).toList() : null,
      doseKg: (!_useComplexScheme && !_useTranches && !_useDoseRange) ? _parseNumber(_doseKgController.text) : null,
      doseKgMin: (!_useComplexScheme && !_useTranches && _useDoseRange) ? _parseNumber(_doseKgMinController.text) : null,
      doseKgMax: (!_useComplexScheme && !_useTranches && _useDoseRange) ? _parseNumber(_doseKgMaxController.text) : null,
    );

    final provider = Provider.of<MedicationProvider>(context, listen: false);
    if (widget.index == null) {
      provider.addPosology(posology);
    } else {
      provider.updatePosology(widget.index!, posology);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      title: Text(widget.index == null ? 'Ajouter une Posologie' : 'Modifier la Posologie'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Voie & Unité
            _buildAutocompleteVoie(),
            const SizedBox(height: 16),
            _buildDropdownUnite(),
            const SizedBox(height: 16),
            
            // 2. Préparation
            TextFormField(
              controller: _preparationController,
              decoration: const InputDecoration(
                labelText: 'Préparation / Reconstitution',
                border: OutlineInputBorder(),
                hintText: 'Ex: Diluer dans 100mL de S.I.',
                prefixIcon: Icon(Icons.science_outlined),
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),

            // 3. Type de dosage (Switchs)
            // On utilise un Radio-like UI avec des SwitchListTiles pour simplifier l'UX
            _buildModeSelector(),

            const SizedBox(height: 16),

            // 4. Champs dynamiques selon le mode
            if (_useComplexScheme)
              _buildComplexSchemeField()
            else if (_useTranches)
              _buildTranchesEditor()
            else
              _buildSimpleDoseEditor(),
              
            const SizedBox(height: 16),
            
            // 5. Dose Max Globale
             TextFormField(
                controller: _doseMaxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Dose maximale absolue (${_selectedUnite ?? 'unité'})',
                  border: const OutlineInputBorder(),
                  helperText: 'Plafond à ne jamais dépasser',
                ),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(
          onPressed: _voieController.text.isEmpty || _selectedUnite == null ? null : _savePosology,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }

  // --- SOUS-WIDGETS DE CONSTRUCTION ---

  Widget _buildAutocompleteVoie() {
    return Autocomplete<String>(
      initialValue: TextEditingValue(text: _voieController.text),
      optionsBuilder: (textEditingValue) {
        if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
        return MedicationConstants.voies.where((opt) => opt.toLowerCase().contains(textEditingValue.text.toLowerCase()));
      },
      onSelected: (selection) => _voieController.text = selection,
      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
        if (controller.text != _voieController.text) controller.text = _voieController.text;
        controller.addListener(() => _voieController.text = controller.text);
        return TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: const InputDecoration(
            labelText: 'Voie d\'administration *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.medical_services),
          ),
          validator: (val) => val == null || val.isEmpty ? 'Requis' : null,
        );
      },
    );
  }

  Widget _buildDropdownUnite() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(labelText: 'Unité *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.scale)),
      value: _selectedUnite,
      items: MedicationConstants.unites.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
      onChanged: (v) => setState(() => _selectedUnite = v),
      validator: (v) => v == null ? 'Requis' : null,
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Schéma complexe (texte libre)'),
          subtitle: const Text('Pour les protocoles dégressifs ou atypiques'),
          value: _useComplexScheme,
          onChanged: (val) {
            setState(() {
              _useComplexScheme = val;
              if (val) {
                _useTranches = false; 
                _useDoseRange = false;
              }
            });
          },
        ),
        if (!_useComplexScheme) ...[
          SwitchListTile(
            title: const Text('Doser par tranches (Poids/Âge)'),
            subtitle: const Text('Pour varier la dose selon le patient'),
            value: _useTranches,
            onChanged: (val) {
              setState(() {
                _useTranches = val;
                if (val) _useDoseRange = false;
                if (val && _tranches.isEmpty) _tranches.add(TrancheData());
              });
            },
          ),
        ]
      ],
    );
  }

  Widget _buildComplexSchemeField() {
    return TextFormField(
      controller: _dosesController,
      decoration: const InputDecoration(
        labelText: 'Description du schéma',
        border: OutlineInputBorder(),
        hintText: 'Ex: J1: 10mg/kg, J2: 5mg/kg...',
      ),
      maxLines: 4,
      validator: (v) => _useComplexScheme && (v == null || v.isEmpty) ? 'Requis' : null,
    );
  }

  Widget _buildSimpleDoseEditor() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Intervalle de dose (Min-Max)'),
          value: _useDoseRange,
          onChanged: (val) => setState(() => _useDoseRange = val),
        ),
        const SizedBox(height: 8),
        DoseInputWidget(
          unite: '${_selectedUnite ?? 'unité'}/kg',
          useDoseRange: _useDoseRange,
          doseController: _doseKgController,
          minController: _doseKgMinController,
          maxController: _doseKgMaxController,
        ),
      ],
    );
  }

  Widget _buildTranchesEditor() {
    return Column(
      children: [
        ..._tranches.asMap().entries.map((entry) {
          return TrancheEditor(
            key: ObjectKey(entry.value), // Important pour éviter les bugs de reorder/delete
            tranche: entry.value,
            unite: _selectedUnite,
            onDelete: () => setState(() => _tranches.removeAt(entry.key)),
            onTrancheChange: (t) {}, // La ref est passée par référence, pas besoin d'update complexe
          );
        }),
        OutlinedButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Ajouter une tranche'),
          onPressed: () => setState(() => _tranches.add(TrancheData())),
        ),
      ],
    );
  }
}