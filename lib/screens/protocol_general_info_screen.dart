import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import 'protocol_steps_screen.dart';

class ProtocolGeneralInfoScreen extends StatefulWidget {
  const ProtocolGeneralInfoScreen({super.key});

  @override
  State<ProtocolGeneralInfoScreen> createState() =>
      _ProtocolGeneralInfoScreenState();
}

class _ProtocolGeneralInfoScreenState extends State<ProtocolGeneralInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProtocolProvider>(context, listen: false);
    final protocol = provider.currentProtocol;
    if (protocol != null) {
      _nomController.text = protocol.nom;
      _descriptionController.text = protocol.description;
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _continue() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);
      provider.updateProtocolField(
        nom: _nomController.text.trim(),
        description: _descriptionController.text.trim(),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ProtocolStepsScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations générales'),
        backgroundColor: Colors.blue,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Étape 1/3',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.33,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nomController,
              decoration: const InputDecoration(
                labelText: 'Nom du protocole *',
                hintText: 'Ex: Convulsions fébriles',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
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
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Courte description du protocole',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'La description est obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue.shade50,
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'À propos des protocoles',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Les protocoles sont des guides étape par étape pour la prise en charge des situations cliniques. '
                      'Chaque protocole est composé d\'étapes contenant des instructions textuelles et/ou des références aux médicaments.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
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
                            'Voulez-vous vraiment annuler la création de ce protocole ?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Non'),
                            ),
                            TextButton(
                              onPressed: () {
                                Provider.of<ProtocolProvider>(context,
                                        listen: false)
                                    .cancelCurrentProtocol();
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
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Suivant : Étapes'),
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