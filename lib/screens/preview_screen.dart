// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';

class PreviewScreen extends StatelessWidget {
  const PreviewScreen({super.key});

  // Vérifie si l'unité contient déjà /kg
  bool _unitContainsPerKg(String? unite) {
    if (unite == null) return false;
    return unite.contains('/kg');
  }

  // Formate l'affichage de la dose
  String _formatDoseDisplay(dynamic dose, String? unite, bool perKg) {
    if (unite == null) return '$dose';
    if (_unitContainsPerKg(unite) || !perKg) {
      return '$dose $unite';
    }
    return '$dose $unite/kg';
  }

  // Formate l'affichage de l'unité
  String _formatUnitDisplay(String? unite, bool perKg) {
    if (unite == null) return '';
    if (_unitContainsPerKg(unite) || !perKg) {
      return unite;
    }
    return '$unite/kg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu & Export'),
        backgroundColor: Colors.teal,
      ),
      body: Consumer<MedicationProvider>(
        builder: (context, provider, child) {
          final medication = provider.currentMedication;
          if (medication == null) {
            return const Center(child: Text('Aucun médicament en cours'));
          }

          final jsonString = medication.toJsonString();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étape 4/4',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: 1.0,
                      backgroundColor: Colors.grey[300],
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.teal),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Résumé du médicament
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.medication,
                                    color: Colors.teal, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medication.nom,
                                        style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (medication.nomCommercial != null &&
                                          medication.nomCommercial!.isNotEmpty)
                                        Text(
                                          medication.nomCommercial!,
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Afficher galenique
                            Chip(
                              label: Text(medication.galenique),
                              backgroundColor: Colors.teal.shade50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Indications et Posologies
                    const Text(
                      'Indications & Posologies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...medication.indications.map((indication) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(indication.label,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              const Divider(),
                              ...indication.posologies.map((pos) {
                                return ListTile(
                                  visualDensity: VisualDensity.compact,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.colorize,
                                      color: Colors.teal),
                                  title: Text('Voie: ${pos.voie}'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Logique d'affichage des tranches ou doses
                                      if (pos.tranches != null &&
                                          pos.tranches!.isNotEmpty)
                                        Text('${pos.tranches!.length} tranche(s)')
                                      else if (pos.doses != null)
                                        Text('Schéma: ${pos.doses}')
                                      else if (pos.doseKg != null)
                                        Text(_formatDoseDisplay(pos.doseKg, pos.unite, true))
                                      else if (pos.doseKgMin != null && pos.doseKgMax != null)
                                        Text('${pos.doseKgMin} - ${pos.doseKgMax} ${_formatUnitDisplay(pos.unite, true)}'),
                                      
                                      if (pos.doseMax != null)
                                        Text(
                                            'Max: ${pos.doseMax} ${pos.unite}'),
                                      if (pos.preparation != null)
                                        Text('Préparation: ${pos.preparation}'),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                    // Fin des Indications et Posologies

                    // Contre-indications (affichage texte simple)
                    if (medication.contreIndications != null &&
                        medication.contreIndications!.isNotEmpty) ...[
                      const Text(
                        'Contre-indications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.red.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            medication.contreIndications!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Surdosage (affichage texte simple)
                    if (medication.surdosage != null &&
                        medication.surdosage!.isNotEmpty) ...[
                      const Text(
                        'Surdosage',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(medication.surdosage!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // À savoir (affichage texte simple)
                    if (medication.aSavoir != null &&
                        medication.aSavoir!.isNotEmpty) ...[
                      const Text(
                        'À savoir',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(medication.aSavoir!),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Divider(),
                    const SizedBox(height: 16),

                    // JSON Preview
                    const Text(
                      'JSON généré',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
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
                    const SizedBox(height: 16),

                    // Bouton copier
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: jsonString));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('JSON copié dans le presse-papier'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copier le JSON'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
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
                        onPressed: () {
                          provider.addMedicationToList();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(provider.isEditingMode 
                                  ? 'Médicament mis à jour'
                                  : 'Médicament ajouté à la liste'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          Navigator.popUntil(context, (route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(provider.isEditingMode 
                            ? 'Enregistrer les modifications'
                            : 'Enregistrer & Nouveau'),
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
}