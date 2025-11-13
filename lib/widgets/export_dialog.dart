// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/medication_provider.dart';

void showExportDialog(BuildContext context, MedicationProvider provider) {
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('JSON complet copié'),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showGitHubPublishDialog(context, provider, jsonString);
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Publier sur GitHub'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
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

void _showGitHubPublishDialog(
    BuildContext context, MedicationProvider provider, String jsonContent) {
  final commitMessageController = TextEditingController(
    text: 'Mise à jour des médicaments depuis Medication Editor',
  );
  bool isPublishing = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Row(
          children: const [
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
              'Vous allez publier ${provider.medications.length} médicament(s) sur GitHub.',
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
                      'Cette action va écraser le fichier sur GitHub. Assurez-vous d\'avoir sauvegardé vos modifications locales.',
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
                      final success = await provider.publishToGitHub(
                        commitMessageController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? '✅ Médicaments publiés avec succès sur GitHub !'
                                  : '❌ Échec de la publication sur GitHub',
                            ),
                            backgroundColor: success ? Colors.green : Colors.red,
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