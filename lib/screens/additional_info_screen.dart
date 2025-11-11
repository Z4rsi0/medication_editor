import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import 'preview_screen.dart';

class AdditionalInfoScreen extends StatefulWidget {
  const AdditionalInfoScreen({super.key});

  @override
  State<AdditionalInfoScreen> createState() => _AdditionalInfoScreenState();
}

class _AdditionalInfoScreenState extends State<AdditionalInfoScreen> {
  final _contreIndicationsController = TextEditingController();
  final _surdosageController = TextEditingController();
  final _aSavoirController = TextEditingController();
  
  // NOTE: Les contrôleurs pour 'remarques' et 'precautions' ne sont pas ajoutés
  // car les champs n'existent pas dans le modèle Medication.

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final med = provider.currentMedication;
    if (med != null) {
      _contreIndicationsController.text = med.contreIndications ?? '';
      _surdosageController.text = med.surdosage ?? '';
      _aSavoirController.text = med.aSavoir ?? '';
      // NOTE: Ne pas tenter d'accéder à med.remarques ou med.precautions
    }
  }

  @override
  void dispose() {
    _contreIndicationsController.dispose();
    _surdosageController.dispose();
    _aSavoirController.dispose();
    super.dispose();
  }

  void _continue() {
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    provider.updateMedicationField(
      contreIndications: _contreIndicationsController.text.trim().isNotEmpty
          ? _contreIndicationsController.text.trim()
          : null,
      surdosage: _surdosageController.text.trim().isNotEmpty
          ? _surdosageController.text.trim()
          : null,
      aSavoir: _aSavoirController.text.trim().isNotEmpty
          ? _aSavoirController.text.trim()
          : null,
      // NOTE: 'remarques' et 'precautions' ne sont pas mis à jour ici
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PreviewScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations supplémentaires'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Étape 3/4',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: Colors.grey[300],
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Section Contre-indications
                TextFormField(
                  controller: _contreIndicationsController,
                  decoration: const InputDecoration(
                    labelText: 'Contre-indications',
                    hintText: 'Ex: Insuffisance rénale sévère, Hypersensibilité',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Section Surdosage
                TextFormField(
                  controller: _surdosageController,
                  decoration: const InputDecoration(
                    labelText: 'Surdosage',
                    hintText: 'Ex: Symptômes, Traitement du surdosage',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Section À savoir
                TextFormField(
                  controller: _aSavoirController,
                  decoration: const InputDecoration(
                    labelText: 'À savoir',
                    hintText:
                        'Ex: Conservation, Précautions d\'emploi spécifiques',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                // Ancienne section Précautions (Retirée pour coller à Medication.dart)
                // Ancienne section Remarques (Retirée pour coller à Medication.dart)

                Card(
                  color: Colors.teal.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Note sur les autres informations',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          // Texte mis à jour pour ne pas mentionner les champs manquants
                          'Les champs "Contre-indications", "Surdosage" et "À savoir" sont optionnels et permettent d\'ajouter des informations textuelles importantes avant l\'export.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
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
                    child: const Text('Suivant : Aperçu'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}