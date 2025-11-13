// medication_list_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../models/medication.dart';
import 'general_info_screen.dart';

class MedicationListScreen extends StatelessWidget {
  const MedicationListScreen({super.key});

  // --- Fonctions utilitaires pour le formatage ---

  /// Construit la chaîne de dosage pour une posologie ou une tranche.
  String _buildDosageString({
    required dynamic doseKg,
    required dynamic doseKgMin,
    required dynamic doseKgMax,
    required String? doses,
    required dynamic doseMax,
    required String unite,
  }) {
    String baseDose;

    if (doses != null && doses.isNotEmpty) {
      // Schémas complexes (Texte libre)
      baseDose = doses;
    } else if (doseKg != null) {
      // Dose simple par kg
      baseDose = '${doseKg.toString()} $unite / kg';
    } else if (doseKgMin != null || doseKgMax != null) {
      // Dose min/max par kg
      String min = doseKgMin != null ? doseKgMin.toString() : '0';
      String max = doseKgMax != null ? doseKgMax.toString() : 'max';
      baseDose = '$min-$max $unite / kg';
    } else {
      baseDose = 'Dosage non spécifié';
    }

    // Ajout de la dose maximale si présente
    if (doseMax != null) {
      baseDose += ' (Max: ${doseMax.toString()} $unite)';
    }
    return baseDose;
  }
  
  // --- Fonction pour construire la liste des widgets de posologie/tranche ---

  List<Widget> _buildPosologyWidgets(Medication medication) {
    final List<Widget> widgets = [];
    
    // Parcourir chaque indication dans le médicament
    for (final indication in medication.indications) {
      // Parcourir chaque posologie dans l'indication
      for (final posology in indication.posologies) {
        
        // 1. Ajouter le widget principal de Posology
        final mainDosage = _buildDosageString(
          doseKg: posology.doseKg,
          doseKgMin: posology.doseKgMin,
          doseKgMax: posology.doseKgMax,
          doses: posology.doses,
          doseMax: posology.doseMax,
          unite: posology.unite,
        );
        
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              '• ${indication.label} (${posology.voie}): $mainDosage',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        );

        // 2. Ajouter les widgets pour les tranches de poids/âge (si elles existent)
        if (posology.tranches != null) {
          for (final tranche in posology.tranches!) {
            String range;
            if (tranche.poidsMin != null || tranche.poidsMax != null) {
                String min = tranche.poidsMin != null ? tranche.poidsMin.toString() : '<';
                String max = tranche.poidsMax != null ? tranche.poidsMax.toString() : '>';
                range = 'Poids: $min–$max kg';
            } else if (tranche.ageMin != null || tranche.ageMax != null) {
                String min = tranche.ageMin != null ? tranche.ageMin.toString() : '<';
                String max = tranche.ageMax != null ? tranche.ageMax.toString() : '>';
                range = 'Âge: $min–$max ans';
            } else {
                range = 'Tranche spécifique';
            }

            final trancheDosage = _buildDosageString(
              doseKg: tranche.doseKg,
              doseKgMin: tranche.doseKgMin,
              doseKgMax: tranche.doseKgMax,
              doses: tranche.doses,
              doseMax: null,
              unite: tranche.unite ?? posology.unite,
            );

            widgets.add(
              Padding(
                padding: const EdgeInsets.only(left: 32, bottom: 2),
                child: Text(
                  '  - $range: $trancheDosage',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            );
          }
        }
      }
    }
    return widgets;
  }
  
  // --- Le code du build principal du widget ---

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
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tout supprimer ?'),
                      content: const Text(
                        'Voulez-vous supprimer tous les médicaments de la liste ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.clearAll();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                          ),
                          child: const Text('Tout supprimer'),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          if (provider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun médicament dans la liste',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des médicaments pour les voir ici',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          // Le corps principal de la liste des médicaments
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${provider.medications.length} médicament(s)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showExportDialog(context, provider),
                      icon: const Icon(Icons.download),
                      label: const Text('Exporter JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                      ),
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
                    
                    // Calculer le nombre total de posologies pour l'affichage du titre
                    final totalPosologies = medication.indications
                        .expand((i) => i.posologies)
                        .length;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.teal,
                          child: Icon(Icons.medication, color: Colors.white),
                        ),
                        title: Text(
                          medication.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (medication.nomCommercial != null &&
                                medication.nomCommercial!.isNotEmpty)
                              Text(medication.nomCommercial!),
                            Chip(
                              label: Text(
                                medication.galenique,
                                style: const TextStyle(fontSize: 12),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.teal.shade50,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: () {
                            provider.editMedication(index);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const GeneralInfoScreen(),
                              ),
                            );
                          },
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Affichage du nombre total de posologies
                                Text(
                                  'Posologies: $totalPosologies',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Utilisation de la fonction pour générer les widgets d'affichage des posologies
                                ..._buildPosologyWidgets(medication),

                                // Affichage des contre-indications
                                if (medication.contreIndications != null &&
                                    medication.contreIndications!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Contre-indications: ${medication.contreIndications!.length}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: medication.toJsonString()));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'JSON copié dans le presse-papier'),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.copy),
                                      label: const Text('Copier JSON'),
                                    ),
                                    TextButton.icon(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text('Supprimer ?'),
                                            content: Text(
                                              'Voulez-vous supprimer ${medication.nom} ?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Annuler'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  provider
                                                      .removeMedication(index);
                                                  Navigator.pop(context);
                                                },
                                                style: TextButton.styleFrom(
                                                  foregroundColor: Colors.red,
                                                ),
                                                child: const Text('Supprimer'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: const Icon(Icons.delete),
                                      label: const Text('Supprimer'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

  // --- Le code de la boîte de dialogue d'exportation ---

  void _showExportDialog(BuildContext context, MedicationProvider provider) {
    final jsonString = provider.exportToJsonSorted();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.teal,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(4),
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Export JSON complet (trié alphabétiquement)',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SelectableText(
                      jsonString,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: jsonString));
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('JSON complet copié (prêt pour GitHub)'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Copier tout'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}