import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../widgets/export_dialog.dart';
import '../widgets/medication_list_item.dart'; // Import du nouveau widget
import 'general_info_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des médicaments'),
        backgroundColor: Colors.teal,
        actions: [
          Consumer<MedicationProvider>(
            builder: (context, provider, child) {
              if (provider.medications.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _confirmDeleteAll(context, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.medications.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medication_outlined, size: 100, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Aucun médicament', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${provider.medications.length} médicament(s)',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => showExportDialog(context, provider),
                      icon: const Icon(Icons.download),
                      label: const Text('Exporter JSON'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.medications.length,
                  itemBuilder: (context, index) {
                    final medication = provider.medications[index];
                    return MedicationListItem(
                      key: ValueKey(medication.nom), // Optimisation pour le diffing de liste
                      medication: medication,
                      onEdit: () {
                        provider.editMedication(index);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const GeneralInfoScreen()),
                        );
                      },
                      onDelete: () => _confirmDeleteOne(context, provider, index, medication.nom),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDeleteAll(BuildContext context, MedicationProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tout supprimer ?'),
        content: const Text('Voulez-vous supprimer tous les médicaments de la liste ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              provider.clearAll();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Tout supprimer'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteOne(BuildContext context, MedicationProvider provider, int index, String nom) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer $nom ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              provider.removeMedication(index);
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