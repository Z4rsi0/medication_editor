import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import '../models/protocol.dart';
import '../widgets/element_form_dialog.dart';

class ProtocolStepEditorScreen extends StatefulWidget {
  const ProtocolStepEditorScreen({super.key});

  @override
  State<ProtocolStepEditorScreen> createState() =>
      _ProtocolStepEditorScreenState();
}

class _ProtocolStepEditorScreenState extends State<ProtocolStepEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _tempsController = TextEditingController();
  final _attentionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<ProtocolProvider>(context, listen: false);
    final etape = provider.currentEtape;
    if (etape != null) {
      _titreController.text = etape.titre;
      _tempsController.text = etape.temps ?? '';
      _attentionController.text = etape.attention ?? '';
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _tempsController.dispose();
    _attentionController.dispose();
    super.dispose();
  }

  void _saveEtape() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);
      
      if (provider.currentEtape!.elements.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ajoutez au moins un élément à l\'étape'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      provider.updateEtapeField(
        titre: _titreController.text.trim(),
        temps: _tempsController.text.trim().isEmpty
            ? null
            : _tempsController.text.trim(),
        attention: _attentionController.text.trim().isEmpty
            ? null
            : _attentionController.text.trim(),
      );

      provider.saveCurrentEtape();
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer l\'étape'),
        backgroundColor: Colors.blue,
      ),
      body: Consumer<ProtocolProvider>(
        builder: (context, provider, child) {
          final etape = provider.currentEtape;
          if (etape == null) {
            return const Center(child: Text('Erreur: aucune étape en cours'));
          }

          return Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      TextFormField(
                        controller: _titreController,
                        decoration: const InputDecoration(
                          labelText: 'Titre de l\'étape *',
                          hintText: 'Ex: Évaluation initiale',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.title),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le titre est obligatoire';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _tempsController,
                        decoration: const InputDecoration(
                          labelText: 'Temps (optionnel)',
                          hintText: 'Ex: T0, T5, T10',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.timer),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _attentionController,
                        decoration: const InputDecoration(
                          labelText: 'Alerte / Attention (optionnel)',
                          hintText: 'Ex: Surveillance des constantes vitales',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.warning, color: Colors.red),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          const Text(
                            'Éléments de l\'étape',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () {
                              _showAddElementDialog(context, null);
                            },
                            icon: const Icon(Icons.add_circle),
                            color: Colors.blue,
                            tooltip: 'Ajouter un élément',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (etape.elements.isEmpty)
                        Card(
                          color: Colors.grey[100],
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.list_alt,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucun élément ajouté',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...etape.elements.asMap().entries.map((entry) {
                          final index = entry.key;
                          final element = entry.value;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: element is ElementTexte
                                    ? Colors.green
                                    : Colors.orange,
                                child: Icon(
                                  element is ElementTexte
                                      ? Icons.text_fields
                                      : Icons.medication,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: element is ElementTexte
                                  ? Text(
                                      element.texte,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : Text(
                                      (element as ElementMedicament)
                                          .medicament
                                          .nom,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                              subtitle: element is ElementMedicament
                                  ? Text(element.medicament.indication)
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, size: 20),
                                    color: Colors.blue,
                                    onPressed: () {
                                      _showAddElementDialog(context, index);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, size: 20),
                                    color: Colors.red,
                                    onPressed: () {
                                      provider.removeElement(index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            provider.cancelCurrentEtape();
                            Navigator.pop(context);
                          },
                          child: const Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _saveEtape,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(provider.isEditingEtape
                              ? 'Enregistrer les modifications'
                              : 'Enregistrer l\'étape'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddElementDialog(BuildContext context, int? index) {
    showDialog(
      context: context,
      builder: (context) => ElementFormDialog(index: index),
    );
  }
}