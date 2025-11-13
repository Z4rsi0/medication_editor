// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import '../models/protocol.dart';

class ProtocolPreviewScreen extends StatelessWidget {
  const ProtocolPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aperçu & Export'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<ProtocolProvider>(
        builder: (context, provider, child) {
          final protocol = provider.currentProtocol;
          if (protocol == null) {
            return const Center(child: Text('Aucun protocole en cours'));
          }

          final jsonString = protocol.toJsonString();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Étape 3/3',
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
                          const AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // En-tête du protocole
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.description,
                                    color: Colors.blue, size: 32),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    protocol.nom,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              protocol.description,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Chip(
                              label: Text('${protocol.etapes.length} étape(s)'),
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Étapes
                    const Text(
                      'Étapes du protocole',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...protocol.etapes.asMap().entries.map((entry) {
                      final index = entry.key;
                      final etape = entry.value;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Colors.blue,
                                    child: Text(
                                      '${index + 1}',
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          etape.titre,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (etape.temps != null)
                                          Text(
                                            '⏱️ ${etape.temps}',
                                            style: TextStyle(
                                                color: Colors.grey[600]),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              ...etape.elements.map((element) {
                                if (element is ElementTexte) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.text_fields,
                                            size: 20, color: Colors.green),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            element.texte,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                } else if (element is ElementMedicament) {
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(Icons.medication,
                                            size: 20, color: Colors.orange),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                element.medicament.nom,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                              ),
                                              Text(
                                                '${element.medicament.indication} - ${element.medicament.voie}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }).toList(),
                              if (etape.attention != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning,
                                          color: Colors.red),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          etape.attention!,
                                          style: const TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 16),

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

                    // Nom du fichier
                    Card(
                      color: Colors.blue.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            const Icon(Icons.file_present, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Nom du fichier généré:',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  Text(
                                    protocol.fileName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                        backgroundColor: Colors.grey,
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
                        // 👈 MODIFICATION CLÉ ICI
                        onPressed: () async {
                          // 1. Capture de la référence et du mode AVANT d'appeler addProtocolToList()
                          final protocolToPublish = protocol;
                          final isEditing = provider.isEditingProtocol;

                          // 2. Enregistrement local (ajoute à la liste ou met à jour)
                          provider.addProtocolToList();

                          // 3. Publication sur GitHub
                          final success =
                              await provider.publishProtocolToGitHub(
                                  protocolToPublish,
                                  isEditing
                                      ? 'Mise à jour du protocole: ${protocolToPublish.nom}'
                                      : 'Nouveau protocole: ${protocolToPublish.nom}');

                          // 4. Affichage du feedback et retour
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '✅ Protocole publié sur GitHub avec succès !'
                                      : '⚠️ Protocole enregistré localement, mais la publication sur GitHub a échoué.',
                                ),
                                backgroundColor:
                                    success ? Colors.green : Colors.orange,
                              ),
                            );
                            Navigator.popUntil(context, (route) => route.isFirst);
                          }
                        },
                        // 👆 FIN DE LA MODIFICATION CLÉ
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(provider.isEditingProtocol
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