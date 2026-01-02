import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../utils/constants.dart';
import 'indications_screen.dart';

class GeneralInfoScreen extends StatefulWidget {
  const GeneralInfoScreen({super.key});

  @override
  State<GeneralInfoScreen> createState() => _GeneralInfoScreenState();
}

class _GeneralInfoScreenState extends State<GeneralInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _nomCommercialController = TextEditingController();
  final _galeniqueController = TextEditingController();
  final _galeniqueFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final med = provider.currentMedication;
    if (med != null) {
      _nomController.text = med.nom;
      _nomCommercialController.text = med.nomCommercial ?? '';
      _galeniqueController.text = med.galenique;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _nomCommercialController.dispose();
    _galeniqueController.dispose();
    _galeniqueFocusNode.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      provider.updateMedicationField(
        nom: _nomController.text.trim(),
        nomCommercial: _nomCommercialController.text.trim(),
        galenique: _galeniqueController.text.trim(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const IndicationsScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations générales'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const _StepProgress(),
            const SizedBox(height: 24),
            
            // Nom DCI
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom DCI du médicament *',
                hintText: 'Ex: Paracétamol IV',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) => (value == null || value.trim().isEmpty) ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            
            // Nom Commercial
            TextFormField(
              controller: _nomCommercialController,
              decoration: const InputDecoration(
                labelText: 'Nom commercial (optionnel)',
                hintText: 'Ex: PERFALGAN',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_pharmacy),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 16),

            // Autocomplete Galénique Optimisé
            RawAutocomplete<String>(
              textEditingController: _galeniqueController,
              focusNode: _galeniqueFocusNode,
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return MedicationConstants.galeniques.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                _galeniqueController.text = selection;
              },
              fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: const InputDecoration(
                    labelText: 'Forme galénique *',
                    hintText: 'Ex: Solution perfusion',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.science),
                    helperText: 'Tapez pour voir les suggestions',
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty) ? 'Requis' : null,
                );
              },
              optionsViewBuilder: (context, onSelected, options) {
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final option = options.elementAt(index);
                          return ListTile(
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
            
            const SizedBox(height: 32),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmCancel(context),
                    child: const Text('Annuler'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _continue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Suivant : Indications'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler ?'),
        content: const Text('Voulez-vous vraiment annuler la création ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Non')),
          TextButton(
            onPressed: () {
              Provider.of<MedicationProvider>(context, listen: false).cancelCurrentMedication();
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Exit screen
            },
            child: const Text('Oui'),
          ),
        ],
      ),
    );
  }
}

class _StepProgress extends StatelessWidget {
  const _StepProgress();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Étape 1/5', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: 0.2,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
        ),
      ],
    );
  }
}