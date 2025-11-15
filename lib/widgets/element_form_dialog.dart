import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import '../services/medication_provider.dart';
import '../models/protocol.dart' as model;

class ElementFormDialog extends StatefulWidget {
  final int? index;
  const ElementFormDialog({super.key, this.index});

  @override
  State<ElementFormDialog> createState() => _ElementFormDialogState();
}

class _ElementFormDialogState extends State<ElementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _isTexte = true;

  // Controllers pour texte
  final _texteController = TextEditingController();

  // Controllers pour médicament
  final _nomMedicamentController = TextEditingController();
  final _indicationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);
      final element = provider.currentEtape!.elements[widget.index!];

      if (element is model.ElementTexte) {
        _isTexte = true;
        _texteController.text = element.texte;
      } else if (element is model.ElementMedicament) {
        _isTexte = false;
        _nomMedicamentController.text = element.medicament.nom;
        _indicationController.text = element.medicament.indication;
      }
    }
  }

  @override
  void dispose() {
    _texteController.dispose();
    _nomMedicamentController.dispose();
    _indicationController.dispose();
    super.dispose();
  }

  // Récupère la liste des noms de médicaments uniques
  List<String> _getMedicationNames(MedicationProvider provider) {
    return provider.medications
        .map((med) => med.nom)
        .toSet()
        .toList()
      ..sort();
  }

  // Récupère la liste des indications pour un médicament donné
  List<String> _getIndicationsForMedication(
      MedicationProvider provider, String medicationName) {
    final medication = provider.medications
        .firstWhere((med) => med.nom == medicationName, orElse: () => provider.medications.first);
    
    return medication.indications
        .map((ind) => ind.label)
        .toList();
  }

  void _saveElement() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);

      model.Element element;
      if (_isTexte) {
        element = model.ElementTexte(texte: _texteController.text.trim());
      } else {
        element = model.ElementMedicament(
          medicament: model.MedicamentReference(
            nom: _nomMedicamentController.text.trim(),
            indication: _indicationController.text.trim(),
          ),
        );
      }

      if (widget.index == null) {
        provider.addElementToEtape(element);
      } else {
        provider.updateElement(widget.index!, element);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final medicationProvider = Provider.of<MedicationProvider>(context);
    final medicationNames = _getMedicationNames(medicationProvider);

    return AlertDialog(
      title: Text(widget.index == null
          ? 'Ajouter un élément'
          : 'Modifier l\'élément'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toggle Type d'élément
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: true,
                    label: Text('Texte'),
                    icon: Icon(Icons.text_fields),
                  ),
                  ButtonSegment(
                    value: false,
                    label: Text('Médicament'),
                    icon: Icon(Icons.medication),
                  ),
                ],
                selected: {_isTexte},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _isTexte = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Formulaire pour texte
              if (_isTexte) ...[
                const Text(
                  'Instructions textuelles',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _texteController,
                  decoration: const InputDecoration(
                    labelText: 'Texte de l\'instruction',
                    hintText:
                        'Ex: • Libération des voies aériennes\n• Oxygénothérapie',
                    border: OutlineInputBorder(),
                    helperText: 'Utilisez • pour les puces, \\n pour les sauts de ligne',
                  ),
                  maxLines: 6,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le texte est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.blue.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Conseil: Utilisez les puces (•) pour les listes d\'instructions',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ]

              // Formulaire pour médicament
              else ...[
                const Text(
                  'Référence médicament',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                // Nom du médicament avec autocomplétion
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _nomMedicamentController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return medicationNames;
                    }
                    return medicationNames.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    setState(() {
                      _nomMedicamentController.text = selection;
                      // Effacer l'indication pour forcer l'utilisateur à en choisir une nouvelle
                      _indicationController.clear();
                    });
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    // Synchroniser avec notre controller
                    if (fieldTextEditingController.text != _nomMedicamentController.text) {
                      fieldTextEditingController.text = _nomMedicamentController.text;
                    }
                    
                    // Écouter les changements
                    fieldTextEditingController.addListener(() {
                      _nomMedicamentController.text = fieldTextEditingController.text;
                    });

                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Nom du médicament *',
                        hintText: 'Ex: Midazolam',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.medication),
                        helperText: 'Sélectionnez depuis la liste ou saisissez',
                      ),
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Le nom est obligatoire';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 12),
                
                // Indication avec autocomplétion basée sur le médicament sélectionné
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: _indicationController.text),
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (_nomMedicamentController.text.trim().isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    
                    final indications = _getIndicationsForMedication(
                        medicationProvider, _nomMedicamentController.text.trim());
                    
                    if (textEditingValue.text.isEmpty) {
                      return indications;
                    }
                    
                    return indications.where((String option) {
                      return option
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _indicationController.text = selection;
                  },
                  fieldViewBuilder: (BuildContext context,
                      TextEditingController fieldTextEditingController,
                      FocusNode fieldFocusNode,
                      VoidCallback onFieldSubmitted) {
                    // Synchroniser avec notre controller
                    if (fieldTextEditingController.text != _indicationController.text) {
                      fieldTextEditingController.text = _indicationController.text;
                    }
                    
                    // Écouter les changements
                    fieldTextEditingController.addListener(() {
                      _indicationController.text = fieldTextEditingController.text;
                    });

                    return TextFormField(
                      controller: fieldTextEditingController,
                      focusNode: fieldFocusNode,
                      decoration: const InputDecoration(
                        labelText: 'Indication *',
                        hintText: 'Ex: Convulsions',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.info_outline),
                        helperText: 'Sélectionnez l\'indication depuis la liste',
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'L\'indication est obligatoire';
                        }
                        return null;
                      },
                    );
                  },
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'L\'app recherchera automatiquement ce médicament avec cette indication et affichera toutes les posologies disponibles',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveElement,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: Text(widget.index == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}