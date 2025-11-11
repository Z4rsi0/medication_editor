import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../widgets/posology_form_dialog.dart';

class PosologyScreen extends StatelessWidget {
  const PosologyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Le 'context' ici n'est pas utilisé pour les dialogues.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posologies'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          // Ce 'context' est le descendant direct du Scaffold et doit être utilisé pour les dialogues.
          final scaffoldContext = context;

          final indication = provider.currentIndication;
          
          if (indication == null) {
            return const Center(child: Text('Erreur: aucune indication en cours'));
          }

          final posologies = indication.posologies;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étape 3/5',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 0.6,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.medical_information, color: Colors.teal),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Indication: ${indication.label}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                // Réf. à 'remarques' (lignes 97-101) RÉTIRÉE
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Posologies: ${posologies.length}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            // CORRECTION CONTEXTE : Utilisation de scaffoldContext
                            _showPosologyDialog(scaffoldContext, null); 
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ajouter'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: posologies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medication_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune posologie ajoutée',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Ajoutez au moins une posologie',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: posologies.length,
                        itemBuilder: (context, index) {
                          final posology = posologies[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                'Voie: ${posology.voie}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  // Réf. à 'frequency' (ligne 144) RÉTIRÉE
                                  if (posology.tranches != null && posology.tranches!.isNotEmpty)
                                    Text('${posology.tranches!.length} tranche(s) de poids/âge')
                                  else if (posology.doses != null)
                                    Text('Schéma: ${posology.doses}')
                                  else if (posology.doseKg != null)
                                    Text('Dose: ${posology.doseKg} ${posology.unite}/kg')
                                  else if (posology.doseKgMin != null)
                                    Text('Dose: ${posology.doseKgMin}-${posology.doseKgMax} ${posology.unite}/kg'),
                                  if (posology.doseMax != null)
                                    Text('Max: ${posology.doseMax} ${posology.unite}'),
                                  if (posology.preparation != null)
                                    Text('Préparation: ${posology.preparation}'),
                                  
                                  // Réf. à 'precautions' (lignes 178, 179, 193) RÉTIRÉE
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    color: Colors.blue,
                                    onPressed: () {
                                      // CORRECTION CONTEXTE : Utilisation de scaffoldContext
                                      _showPosologyDialog(scaffoldContext, index);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    onPressed: () {
                                      // CORRECTION CONTEXTE : Utilisation de scaffoldContext
                                      _confirmDelete(scaffoldContext, provider, index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          provider.cancelCurrentIndication();
                          Navigator.pop(context);
                        },
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: posologies.isEmpty
                            ? null
                            : () {
                                provider.saveCurrentIndication();
                                Navigator.pop(context);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Enregistrer l\'indication'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPosologyDialog(BuildContext context, int? index) {
    showDialog(
      // Ce contexte est maintenant garanti d'avoir un Scaffold parent
      context: context, 
      builder: (context) => PosologyFormDialog(index: index),
    );
  }

  void _confirmDelete(
      BuildContext context, MedicationProvider provider, int index) {
    showDialog(
      // Ce contexte est maintenant garanti d'avoir un Scaffold parent
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: const Text('Voulez-vous supprimer cette posologie ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.removePosology(index);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}