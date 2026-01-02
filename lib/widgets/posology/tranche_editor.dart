import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/medication.dart';
import 'dose_input.dart';

/// ViewModel pour gérer l'état d'une tranche avant sauvegarde
class TrancheData {
  final TextEditingController poidsMinController = TextEditingController();
  final TextEditingController poidsMaxController = TextEditingController();
  final TextEditingController ageMinController = TextEditingController();
  final TextEditingController ageMaxController = TextEditingController();
  
  // Contrôleurs de dose
  final TextEditingController doseKgController = TextEditingController();
  final TextEditingController doseKgMinController = TextEditingController();
  final TextEditingController doseKgMaxController = TextEditingController();
  final TextEditingController dosesController = TextEditingController();

  bool useDoseRange = false;
  bool useComplexScheme = false;

  TrancheData();

  static TrancheData fromTranche(Tranche tranche) {
    final data = TrancheData();
    if (tranche.poidsMin != null) data.poidsMinController.text = tranche.poidsMin.toString();
    if (tranche.poidsMax != null) data.poidsMaxController.text = tranche.poidsMax.toString();
    if (tranche.ageMin != null) data.ageMinController.text = tranche.ageMin.toString();
    if (tranche.ageMax != null) data.ageMaxController.text = tranche.ageMax.toString();

    if (tranche.doses != null) {
      data.useComplexScheme = true;
      data.dosesController.text = tranche.doses!;
    } else if (tranche.doseKgMin != null && tranche.doseKgMax != null) {
      data.useDoseRange = true;
      data.doseKgMinController.text = tranche.doseKgMin.toString();
      data.doseKgMaxController.text = tranche.doseKgMax.toString();
    } else if (tranche.doseKg != null) {
      data.doseKgController.text = tranche.doseKg.toString();
    }
    return data;
  }

  dynamic _parseNumber(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? int.tryParse(text);
  }

  Tranche toTranche() {
    return Tranche(
      poidsMin: _parseNumber(poidsMinController.text),
      poidsMax: _parseNumber(poidsMaxController.text),
      ageMin: _parseNumber(ageMinController.text),
      ageMax: _parseNumber(ageMaxController.text),
      doses: useComplexScheme ? dosesController.text.trim() : null,
      doseKg: !useComplexScheme && !useDoseRange ? _parseNumber(doseKgController.text) : null,
      doseKgMin: !useComplexScheme && useDoseRange ? _parseNumber(doseKgMinController.text) : null,
      doseKgMax: !useComplexScheme && useDoseRange ? _parseNumber(doseKgMaxController.text) : null,
    );
  }

  void dispose() {
    poidsMinController.dispose();
    poidsMaxController.dispose();
    ageMinController.dispose();
    ageMaxController.dispose();
    doseKgController.dispose();
    doseKgMinController.dispose();
    doseKgMaxController.dispose();
    dosesController.dispose();
  }
}

class TrancheEditor extends StatefulWidget {
  final TrancheData tranche;
  final VoidCallback onDelete;
  final Function(TrancheData) onTrancheChange;
  final String? unite;

  const TrancheEditor({
    super.key,
    required this.tranche,
    required this.onDelete,
    required this.onTrancheChange,
    this.unite,
  });

  @override
  State<TrancheEditor> createState() => _TrancheEditorState();
}

class _TrancheEditorState extends State<TrancheEditor> {
  @override
  Widget build(BuildContext context) {
    final uniteLabel = widget.unite != null ? '${widget.unite}/kg' : 'unité/kg';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec bouton supprimer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.straighten, size: 20, color: Colors.teal),
                    SizedBox(width: 8),
                    Text('Définition de la tranche', style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: widget.onDelete,
                  tooltip: 'Supprimer cette tranche',
                ),
              ],
            ),
            const Divider(),
            
            // Critères (Poids et/ou Âge)
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildRangeInput(
                        minCtrl: widget.tranche.poidsMinController,
                        maxCtrl: widget.tranche.poidsMaxController,
                        label: 'Poids (kg)',
                        allowDecimal: true,
                      ),
                      const SizedBox(height: 8),
                      _buildRangeInput(
                        minCtrl: widget.tranche.ageMinController,
                        maxCtrl: widget.tranche.ageMaxController,
                        label: 'Âge (mois)',
                        allowDecimal: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Text('Posologie pour cette tranche', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),

            // Switch Schéma complexe
            SwitchListTile(
              title: const Text('Schéma complexe (Texte libre)'),
              value: widget.tranche.useComplexScheme,
              dense: true,
              contentPadding: EdgeInsets.zero,
              onChanged: (val) {
                setState(() {
                  widget.tranche.useComplexScheme = val;
                  if (val) {
                    widget.tranche.useDoseRange = false;
                    widget.tranche.doseKgController.clear();
                    widget.tranche.doseKgMinController.clear();
                    widget.tranche.doseKgMaxController.clear();
                  }
                  widget.onTrancheChange(widget.tranche);
                });
              },
            ),

            // Inputs de dosage
            if (widget.tranche.useComplexScheme)
              TextFormField(
                controller: widget.tranche.dosesController,
                decoration: const InputDecoration(
                  labelText: 'Instructions détaillées',
                  hintText: 'Ex: S0: 80 mg, puis dégressif...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
                validator: (value) =>
                    widget.tranche.useComplexScheme && (value == null || value.trim().isEmpty)
                        ? 'Requis'
                        : null,
              )
            else
              Column(
                children: [
                   SwitchListTile(
                    title: const Text('Intervalle de dose (Min-Max)'),
                    value: widget.tranche.useDoseRange,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) {
                      setState(() {
                        widget.tranche.useDoseRange = val;
                        widget.onTrancheChange(widget.tranche);
                      });
                    },
                  ),
                  DoseInputWidget(
                    unite: uniteLabel,
                    useDoseRange: widget.tranche.useDoseRange,
                    doseController: widget.tranche.doseKgController,
                    minController: widget.tranche.doseKgMinController,
                    maxController: widget.tranche.doseKgMaxController,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRangeInput({
    required TextEditingController minCtrl,
    required TextEditingController maxCtrl,
    required String label,
    required bool allowDecimal,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: minCtrl,
            keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
            decoration: InputDecoration(
              labelText: '$label Min',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            inputFormatters: [
              allowDecimal 
                  ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('-'),
        ),
        Expanded(
          child: TextFormField(
            controller: maxCtrl,
            keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
            decoration: InputDecoration(
              labelText: '$label Max',
              border: const OutlineInputBorder(),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            inputFormatters: [
              allowDecimal 
                  ? FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))
                  : FilteringTextInputFormatter.digitsOnly,
            ],
          ),
        ),
      ],
    );
  }
}