import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/medication.dart';

class MedicationListItem extends StatelessWidget {
  final Medication medication;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const MedicationListItem({
    super.key,
    required this.medication,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Calcul préable pour éviter de le faire dans le build
    final totalPosologies = medication.indications.fold(0, (sum, i) => sum + i.posologies.length);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
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
            if (medication.nomCommercial != null && medication.nomCommercial!.isNotEmpty)
              Text(medication.nomCommercial!),
            Chip(
              label: Text(
                medication.galenique,
                style: const TextStyle(fontSize: 12),
              ),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Colors.teal.shade50,
              padding: EdgeInsets.zero,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: onEdit,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Posologies: $totalPosologies',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Liste des posologies optimisée
                ...medication.indications.expand((indication) {
                  return indication.posologies.map((posology) => _PosologyRow(
                    indicationLabel: indication.label,
                    posology: posology,
                  ));
                }),

                if (medication.contreIndications != null && medication.contreIndications!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Contre-indications: ${medication.contreIndications!.length} char(s)',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ],
                const SizedBox(height: 12),
                
                // Actions du bas
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: medication.toJsonString()));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('JSON copié'), backgroundColor: Colors.green),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('JSON'),
                    ),
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Supprimer'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Sous-widget privé et const pour l'affichage d'une ligne de posologie
class _PosologyRow extends StatelessWidget {
  final String indicationLabel;
  final Posology posology;

  const _PosologyRow({
    required this.indicationLabel,
    required this.posology,
  });

  @override
  Widget build(BuildContext context) {
    final mainDosage = _buildDosageString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $indicationLabel (${posology.voie}): $mainDosage',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
          if (posology.tranches != null)
            ...posology.tranches!.map((tranche) => Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 2),
                  child: Text(
                    '  - ${_buildTrancheLabel(tranche)}: ${_buildTrancheDosage(tranche)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                )),
        ],
      ),
    );
  }

  String _buildDosageString() {
    if (posology.doses != null && posology.doses!.isNotEmpty) return posology.doses!;
    if (posology.doseKg != null) return '${posology.doseKg} ${posology.unite} / kg';
    if (posology.doseKgMin != null || posology.doseKgMax != null) {
      return '${posology.doseKgMin ?? 0}-${posology.doseKgMax ?? 'max'} ${posology.unite} / kg';
    }
    return 'Dosage non spécifié';
  }

  String _buildTrancheLabel(Tranche tranche) {
    if (tranche.poidsMin != null || tranche.poidsMax != null) {
      return 'Poids: ${tranche.poidsMin ?? '<'}–${tranche.poidsMax ?? '>'} kg';
    }
    if (tranche.ageMin != null || tranche.ageMax != null) {
      return 'Âge: ${tranche.ageMin ?? '<'}–${tranche.ageMax ?? '>'} mois';
    }
    return 'Tranche spécifique';
  }

  String _buildTrancheDosage(Tranche tranche) {
    final unite = tranche.unite ?? posology.unite;
    if (tranche.doses != null) return tranche.doses!;
    if (tranche.doseKg != null) return '${tranche.doseKg} $unite / kg';
    if (tranche.doseKgMin != null || tranche.doseKgMax != null) {
      return '${tranche.doseKgMin ?? 0}-${tranche.doseKgMax ?? 'max'} $unite / kg';
    }
    return '';
  }
}