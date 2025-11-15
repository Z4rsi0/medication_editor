// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import '../models/protocol.dart';
import 'protocol_general_info_screen.dart';

class ProtocolListScreen extends StatelessWidget {
  const ProtocolListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste des protocoles'),
        backgroundColor: Colors.blue,
        actions: [
          Consumer<ProtocolProvider>(
            builder: (context, provider, child) {
              if (provider.protocols.isEmpty) return const SizedBox();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Tout supprimer ?'),
                      content: const Text(
                        'Voulez-vous supprimer tous les protocoles de la liste ?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Annuler'),
                        ),
                        TextButton(
                          onPressed: () {
                            provider.clearAllProtocols();
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
      body: Consumer<ProtocolProvider>(
        builder: (context, provider, child) {
          if (provider.protocols.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 100,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun protocole dans la liste',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ajoutez des protocoles pour les voir ici',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
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
                        '${provider.protocols.length} protocole(s)',
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
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: provider.protocols.length,
                  itemBuilder: (context, index) {
                    final protocol = provider.protocols[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text(
                          protocol.nom,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(protocol.description),
                            const SizedBox(height: 4),
                            Chip(
                              label: Text(
                                '${protocol.etapes.length} étape(s)',
                                style: const TextStyle(fontSize: 12),
                              ),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: Colors.blue.shade50,
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: () {
                            provider.editProtocol(index);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProtocolGeneralInfoScreen(),
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
                                const Text(
                                  'Étapes:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...protocol.etapes.asMap().entries.map((entry) {
                                  final etapeIndex = entry.key;
                                  final etape = entry.value;
                                  return Padding(
                                    padding:
                                        const EdgeInsets.only(left: 16, bottom: 4),
                                    child: Text(
                                      '${etapeIndex + 1}. ${etape.titre}${etape.temps != null ? " (${etape.temps})" : ""} - ${etape.elements.length} élément(s)',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  );
                                }).toList(),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: protocol.toJsonString()));
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
                                        _showDeleteDialog(
                                            context, provider, index, protocol);
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

  void _showExportDialog(BuildContext context, ProtocolProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Colors.blue),
            SizedBox(width: 12),
            Text('Exporter les protocoles'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous avez ${provider.protocols.length} protocole(s) à exporter.',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Que souhaitez-vous faire ?',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showGitHubPublishDialog(context, provider);
            },
            icon: const Icon(Icons.cloud_upload),
            label: const Text('Publier sur GitHub'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showGitHubPublishDialog(
      BuildContext context, ProtocolProvider provider) {
    final commitMessageController = TextEditingController(
      text: 'Mise à jour des protocoles depuis Medication Editor',
    );
    bool isPublishing = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.cloud_upload, color: Colors.blue),
              SizedBox(width: 12),
              Text('Publier sur GitHub'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Publication de ${provider.protocols.length} protocole(s) sur GitHub.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Message de commit :',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: commitMessageController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Décrivez les modifications...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                enabled: !isPublishing,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Chaque protocole sera publié dans assets/protocoles/.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isPublishing
                  ? null
                  : () {
                      commitMessageController.dispose();
                      Navigator.pop(context);
                    },
              child: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: isPublishing
                  ? null
                  : () async {
                      if (commitMessageController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Le message de commit est requis'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isPublishing = true);

                      try {
                        int successCount = 0;
                        int failCount = 0;

                        for (final protocol in provider.protocols) {
                          final success =
                              await provider.publishProtocolToGitHub(
                            protocol,
                            commitMessageController.text.trim(),
                          );
                          if (success) {
                            successCount++;
                          } else {
                            failCount++;
                          }
                        }

                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                failCount == 0
                                    ? '✅ $successCount protocole(s) publié(s) avec succès !'
                                    : '⚠️ $successCount succès, $failCount échec(s)',
                              ),
                              backgroundColor: failCount == 0
                                  ? Colors.green
                                  : Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          Navigator.pop(context);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('❌ Erreur: $e'),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 5),
                            ),
                          );
                        }
                      } finally {
                        commitMessageController.dispose();
                      }
                    },
              icon: isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.publish),
              label: Text(isPublishing ? 'Publication...' : 'Publier'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, ProtocolProvider provider,
      int index, Protocol protocol) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text('Voulez-vous supprimer "${protocol.nom}" de la liste ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              provider.removeProtocol(index);
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
  }
}