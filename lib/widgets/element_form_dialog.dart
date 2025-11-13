import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import '../models/protocol.dart' as model; // 👈 CORRECTION : Ajout du préfixe 'as model'

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
  final _voieController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.index != null) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);
      final element = provider.currentEtape!.elements[widget.index!];

      // CORRECTION : Utilisation de model.ElementTexte
      if (element is model.ElementTexte) {
        _isTexte = true;
        _texteController.text = element.texte;
      // CORRECTION : Utilisation de model.ElementMedicament
      } else if (element is model.ElementMedicament) {
        _isTexte = false;
        _nomMedicamentController.text = element.medicament.nom;
        _indicationController.text = element.medicament.indication;
        _voieController.text = element.medicament.voie;
      }
    }
  }

  @override
  void dispose() {
    _texteController.dispose();
    _nomMedicamentController.dispose();
    _indicationController.dispose();
    _voieController.dispose();
    super.dispose();
  }

  void _saveElement() {
    if (_formKey.currentState!.validate()) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);

      // CORRECTION : Déclaration avec model.Element
      model.Element element;
      if (_isTexte) {
        // CORRECTION : Instanciation avec model.ElementTexte
        element = model.ElementTexte(texte: _texteController.text.trim());
      } else {
        // CORRECTION : Instanciation avec model.ElementMedicament
        element = model.ElementMedicament(
          // CORRECTION : Instanciation avec model.MedicamentReference
          medicament: model.MedicamentReference(
            nom: _nomMedicamentController.text.trim(),
            indication: _indicationController.text.trim(),
            voie: _voieController.text.trim(),
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
                TextFormField(
                  controller: _nomMedicamentController,
                  decoration: const InputDecoration(
                    labelText: 'Nom du médicament',
                    hintText: 'Ex: Midazolam',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Le nom est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _indicationController,
                  decoration: const InputDecoration(
                    labelText: 'Indication',
                    hintText: 'Ex: Convulsions',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.info_outline),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'L\'indication est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _voieController,
                  decoration: const InputDecoration(
                    labelText: 'Voie d\'administration',
                    hintText: 'Ex: IV',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.route),
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'La voie est obligatoire';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                Card(
                  color: Colors.orange.shade50,
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'L\'app recherchera automatiquement ce médicament et affichera la posologie calculée',
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