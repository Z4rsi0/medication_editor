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
  String? _selectedGalenique;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final med = provider.currentMedication;
    if (med != null) {
      _nomController.text = med.nom;
      _nomCommercialController.text = med.nomCommercial ?? '';
      _selectedGalenique = med.galenique.isEmpty ? null : med.galenique;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _nomCommercialController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<MedicationProvider>(context, listen: false);
      provider.updateMedicationField(
        nom: _nomController.text.trim(),
        nomCommercial: _nomCommercialController.text.trim(),
        galenique: _selectedGalenique ?? '',
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const IndicationsScreen(),
        ),
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
            const Text(
              'Étape 1/5',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.2,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom DCI du médicament *',
                hintText: 'Ex: Paracétamol IV',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medication),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
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
            DropdownButtonFormField<String>(
              value: _selectedGalenique,
              decoration: const InputDecoration(
                labelText: 'Forme galénique *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.science),
              ),
              items: MedicationConstants.galeniques
                  .map((galenique) => DropdownMenuItem(
                        value: galenique,
                        child: Text(galenique),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGalenique = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'La forme galénique est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Exemple: "Solution perfusion 10 mg/mL"',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Annuler ?'),
                          content: const Text(
                            'Voulez-vous vraiment annuler la création de ce médicament ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Non'),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<MedicationProvider>(context,
                                        listen: false)
                                    .cancelCurrentMedication();
                                Navigator.pop(context);
                                Navigator.pop(context);
                              },
                              child: const Text('Oui'),
                            ),
                          ],
                        ),
                      );
                    },
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
}