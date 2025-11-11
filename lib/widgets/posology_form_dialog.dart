import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../models/medication.dart'; // Assurez-vous que Posology, Tranche sont ici
import '../utils/constants.dart'; // L'importation correcte vers votre fichier constants.dart

// ====================================================================
// WIDGET PRINCIPAL
// ====================================================================

class PosologyFormDialog extends StatefulWidget {
  final int? index;
  const PosologyFormDialog({super.key, this.index});

  @override
  State<PosologyFormDialog> createState() => _PosologyFormDialogState();
}

// ====================================================================
// ÉTAT DU WIDGET PRINCIPAL
// ====================================================================

class _PosologyFormDialogState extends State<PosologyFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _preparationController = TextEditingController();
  final _dosesController = TextEditingController(); // pour schémas complexes

  // Dose simple
  final _doseKgController = TextEditingController();
  final _doseKgMinController = TextEditingController();
  final _doseKgMaxController = TextEditingController();
  final _doseMaxController = TextEditingController();

  // Variables
  String? _selectedVoie;
  String? _selectedUnite;
  bool _useDoseRange = false; // dose fixe vs intervalle
  bool _useTranches = false; // tranches de poids/âge
  bool _useComplexScheme = false; // schéma texte

  // Tranches
  List<TrancheData> _tranches = [];

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<MedicationProvider>(context, listen: false);
    final posology = widget.index != null
        ? provider.currentIndication!.posologies[widget.index!]
        : null;

    if (posology != null) {
      _selectedVoie = posology.voie;
      _selectedUnite = posology.unite;
      _preparationController.text = posology.preparation ?? '';
      _doseMaxController.text = posology.doseMax?.toString() ?? '';

      if (posology.doses != null) {
        _useComplexScheme = true;
        _dosesController.text = posology.doses!;
      } else if (posology.tranches != null && posology.tranches!.isNotEmpty) {
        _useTranches = true;
        _tranches = posology.tranches!
            .map((t) => TrancheData.fromTranche(t))
            .toList();
      } else if (posology.doseKgMin != null) {
        _useDoseRange = true;
        _doseKgMinController.text = posology.doseKgMin.toString();
        _doseKgMaxController.text = posology.doseKgMax.toString();
      } else if (posology.doseKg != null) {
        _doseKgController.text = posology.doseKg.toString();
      }
    }
  }

  @override
  void dispose() {
    _preparationController.dispose();
    _dosesController.dispose();
    _doseKgController.dispose();
    _doseKgMinController.dispose();
    _doseKgMaxController.dispose();
    _doseMaxController.dispose();
    for (var tranche in _tranches) {
      tranche.dispose();
    }
    super.dispose();
  }

  // Helper pour parser les nombres
  dynamic _parseNumber(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? int.tryParse(text);
  }

  void _savePosology() {
    if (_formKey.currentState!.validate()) {
      if (_useTranches && _tranches.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Veuillez ajouter au moins une tranche.')),
        );
        return;
      }

      final posology = Posology(
        voie: _selectedVoie!,
        unite: _selectedUnite!,
        preparation: _preparationController.text.trim().isEmpty
            ? null
            : _preparationController.text.trim(),
        doseMax: _parseNumber(_doseMaxController.text),

        // Logique de dosage
        doses: _useComplexScheme ? _dosesController.text.trim() : null,
        tranches: _useTranches
            ? _tranches.map((td) => td.toTranche()).toList()
            : null,

        doseKg: !_useComplexScheme && !_useTranches && !_useDoseRange
            ? _parseNumber(_doseKgController.text)
            : null,
        doseKgMin: !_useComplexScheme && !_useTranches && _useDoseRange
            ? _parseNumber(_doseKgMinController.text)
            : null,
        doseKgMax: !_useComplexScheme && !_useTranches && _useDoseRange
            ? _parseNumber(_doseKgMaxController.text)
            : null,
      );

      final provider = Provider.of<MedicationProvider>(context, listen: false);
      if (widget.index == null) {
        provider.addPosology(posology);
      } else {
        provider.updatePosology(widget.index!, posology);
      }

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CORRECTION CRITIQUE : Retourner un AlertDialog pour fournir le contexte Material
    return AlertDialog(
      scrollable: true,
      title: Text(widget.index == null
          ? 'Ajouter une Posologie'
          : 'Modifier la Posologie'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Voie d'administration
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Voie d\'administration',
                border: OutlineInputBorder(),
              ),
              value: _selectedVoie,
              // Utilisation de MedicationConstants.voies
              items: MedicationConstants.voies.map((voie) {
                return DropdownMenuItem(
                  value: voie,
                  child: Text(voie),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVoie = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Sélectionnez une voie' : null,
            ),
            const SizedBox(height: 16),

            // Unité de dosage
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Unité (ex: mg, UI, mL)',
                border: OutlineInputBorder(),
              ),
              value: _selectedUnite,
              // Utilisation de MedicationConstants.unites
              items: MedicationConstants.unites.map((unite) {
                return DropdownMenuItem(
                  value: unite,
                  child: Text(unite),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUnite = value;
                });
              },
              validator: (value) =>
                  value == null ? 'Sélectionnez une unité' : null,
            ),
            const SizedBox(height: 16),

            // Préparation
            TextFormField(
              controller: _preparationController,
              decoration: const InputDecoration(
                labelText: 'Préparation / Reconstitution (Optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Ex: Diluer dans 100mL de S.I.',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),

            // Switch : Schéma complexe (texte libre)
            SwitchListTile(
              title: const Text('Schéma complexe (texte libre)'),
              subtitle: const Text(
                  'Si le dosage ne peut pas être exprimé par kg'),
              value: _useComplexScheme,
              onChanged: (bool value) {
                setState(() {
                  _useComplexScheme = value;
                  // Reset des autres options si le schéma complexe est activé
                  if (value) {
                    _useTranches = false;
                    _useDoseRange = false;
                    _doseKgController.clear();
                    _doseKgMinController.clear();
                    _doseKgMaxController.clear();
                  }
                });
              },
            ),

            // Affichage du champ "doses" si schéma complexe
            if (_useComplexScheme) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosesController,
                decoration: const InputDecoration(
                  labelText: 'Posologie (Schéma complexe)',
                  border: OutlineInputBorder(),
                  hintText: 'Ex: 1/2 cp à J1, 1 cp à J2...',
                ),
                maxLines: 3,
                validator: (value) =>
                    _useComplexScheme && (value == null || value.trim().isEmpty)
                        ? 'Saisissez la posologie complexe'
                        : null,
              ),
            ],

            // Affichage des options de dosage si schéma non-complexe
            if (!_useComplexScheme) ...[
              // Switch: Tranches d'âge/poids
              SwitchListTile(
                title: const Text('Utiliser des tranches de poids/âge'),
                value: _useTranches,
                onChanged: (bool value) {
                  setState(() {
                    _useTranches = value;
                    // Reset des champs dose si tranches activées
                    if (value) {
                      _doseKgController.clear();
                      _doseKgMinController.clear();
                      _doseKgMaxController.clear();
                      _useDoseRange = false;
                      if (_tranches.isEmpty) {
                        _tranches.add(TrancheData());
                      }
                    } else {
                      // Si désactivé, vider les tranches pour éviter des erreurs
                      _tranches.clear();
                    }
                  });
                },
              ),

              // Affichage du dosage simple
              if (!_useTranches) ...[
                // Switch: Intervalle de dose
                SwitchListTile(
                  title: const Text('Utiliser un intervalle de dose/kg'),
                  subtitle: const Text('Ex: 5-10 mg/kg'),
                  value: _useDoseRange,
                  onChanged: (bool value) {
                    setState(() {
                      _useDoseRange = value;
                      if (value) {
                        _doseKgController.clear();
                      } else {
                        _doseKgMinController.clear();
                        _doseKgMaxController.clear();
                      }
                    });
                  },
                ),

                // Champ(s) de dosage par kg
                if (_useDoseRange)
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _doseKgMinController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                'Dose Min/kg (${_selectedUnite ?? 'unité'})',
                            border: const OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) =>
                              _useDoseRange &&
                                      (value == null || value.trim().isEmpty)
                                  ? 'Requis'
                                  : null,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _doseKgMaxController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText:
                                'Dose Max/kg (${_selectedUnite ?? 'unité'})',
                            border: const OutlineInputBorder(),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*')),
                          ],
                          validator: (value) =>
                              _useDoseRange &&
                                      (value == null || value.trim().isEmpty)
                                  ? 'Requis'
                                  : null,
                        ),
                      ),
                    ],
                  )
                else
                  TextFormField(
                    controller: _doseKgController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Dose/kg (${_selectedUnite ?? 'unité'})',
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) =>
                        !_useDoseRange && (value == null || value.trim().isEmpty)
                            ? 'Requis'
                            : null,
                  ),
                const SizedBox(height: 16),
              ]

              // Affichage des champs de tranches
              else if (_useTranches) ...[
                const Text('Tranches de Poids/Âge:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ..._tranches.asMap().entries.map((entry) {
                  int trancheIndex = entry.key;
                  TrancheData tranche = entry.value;
                  return TrancheForm(
                    key: ValueKey(tranche),
                    tranche: tranche,
                    onDelete: () {
                      setState(() {
                        _tranches.removeAt(trancheIndex);
                      });
                    },
                    onTrancheChange: (TrancheData updatedTranche) {
                      _tranches[trancheIndex] = updatedTranche;
                    },
                    unite: _selectedUnite,
                  );
                }).toList(),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _tranches.add(TrancheData());
                    });
                  },
                  child: const Text('Ajouter une tranche'),
                ),
                const SizedBox(height: 16),
              ],

              // Dose Maximale (Optionnel)
              TextFormField(
                controller: _doseMaxController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText:
                      'Dose maximale (Optionnel) (${_selectedUnite ?? 'unité'})',
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed:
              _selectedVoie == null || _selectedUnite == null ? null : _savePosology,
          child: Text(widget.index == null ? 'Ajouter' : 'Enregistrer'),
        ),
      ],
    );
  }
}

// ====================================================================
// CLASSES DE SUPPORT POUR LES TRANCHES (TrancheData et TrancheForm)
// *Ces classes doivent être définies dans ce fichier pour le rendre autonome*
// ====================================================================

class TrancheData {
  final TextEditingController poidsMinController = TextEditingController();
  final TextEditingController poidsMaxController = TextEditingController();
  final TextEditingController ageMinController = TextEditingController();
  final TextEditingController ageMaxController = TextEditingController();
  final TextEditingController doseKgController = TextEditingController();
  final TextEditingController doseKgMinController = TextEditingController();
  final TextEditingController doseKgMaxController = TextEditingController();
  final TextEditingController dosesController = TextEditingController();

  bool useDoseRange = false;
  bool useComplexScheme = false;

  TrancheData();

  // Constructeur pour charger les données d'une Tranche existante
  static TrancheData fromTranche(Tranche tranche) {
    final data = TrancheData();
    if (tranche.poidsMin != null) {
      data.poidsMinController.text = tranche.poidsMin.toString();
    }
    if (tranche.poidsMax != null) {
      data.poidsMaxController.text = tranche.poidsMax.toString();
    }
    if (tranche.ageMin != null) {
      data.ageMinController.text = tranche.ageMin.toString();
    }
    if (tranche.ageMax != null) {
      data.ageMaxController.text = tranche.ageMax.toString();
    }

    if (tranche.doses != null) {
      data.useComplexScheme = true;
      data.dosesController.text = tranche.doses!;
    } else if (tranche.doseKgMin != null && tranche.doseKgMax != null) {
      data.useDoseRange = true;
      data.doseKgMinController.text = tranche.doseKgMin.toString();
      data.doseKgMaxController.text = tranche.doseKgMax.toString();
    } else if (tranche.doseKg != null) {
      data.doseKgController.text = tranche.doseKg.toString();
    }
    return data;
  }

  dynamic _parseNumber(String text) {
    if (text.isEmpty) return null;
    return double.tryParse(text) ?? int.tryParse(text);
  }

  Tranche toTranche() {
    return Tranche(
      poidsMin: _parseNumber(poidsMinController.text),
      poidsMax: _parseNumber(poidsMaxController.text),
      ageMin: _parseNumber(ageMinController.text),
      ageMax: _parseNumber(ageMaxController.text),

      doses: useComplexScheme ? dosesController.text.trim() : null,

      doseKg: !useComplexScheme && !useDoseRange
          ? _parseNumber(doseKgController.text)
          : null,
      doseKgMin: !useComplexScheme && useDoseRange
          ? _parseNumber(doseKgMinController.text)
          : null,
      doseKgMax: !useComplexScheme && useDoseRange
          ? _parseNumber(doseKgMaxController.text)
          : null,
    );
  }

  void dispose() {
    poidsMinController.dispose();
    poidsMaxController.dispose();
    ageMinController.dispose();
    ageMaxController.dispose();
    doseKgController.dispose();
    doseKgMinController.dispose();
    doseKgMaxController.dispose();
    dosesController.dispose();
  }
}

class TrancheForm extends StatefulWidget {
  final TrancheData tranche;
  final VoidCallback onDelete;
  final Function(TrancheData) onTrancheChange;
  final String? unite;

  const TrancheForm({
    super.key,
    required this.tranche,
    required this.onDelete,
    required this.onTrancheChange,
    this.unite,
  });

  @override
  State<TrancheForm> createState() => _TrancheFormState();
}

class _TrancheFormState extends State<TrancheForm> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tranche de Poids/Âge',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Champs Poids (Min/Max)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.tranche.poidsMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poids Min (kg)',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: widget.tranche.poidsMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Poids Max (kg)',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Champs Âge (Min/Max)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.tranche.ageMinController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Âge Min (Mois)',
                      border: OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: widget.tranche.ageMaxController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Âge Max (Mois)',
                      border: const OutlineInputBorder(),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dose simple vs Intervalle de dose
            SwitchListTile(
              title: const Text('Utiliser un intervalle de dose/kg'),
              subtitle: Text('Ex: 5-10 ${widget.unite ?? 'unité'}/kg'),
              value: widget.tranche.useDoseRange,
              onChanged: (bool value) {
                setState(() {
                  widget.tranche.useDoseRange = value;
                  widget.onTrancheChange(widget.tranche);
                });
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (widget.tranche.useDoseRange)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: widget.tranche.doseKgMinController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Dose Min/kg (${widget.unite ?? 'unité'})',
                        border: const OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: widget.tranche.doseKgMaxController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText:
                            'Dose Max/kg (${widget.unite ?? 'unité'})',
                        border: const OutlineInputBorder(),
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                    ),
                  ),
                ],
              )
            else
              TextFormField(
                controller: widget.tranche.doseKgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Dose/kg (${widget.unite ?? 'unité'})',
                  border: const OutlineInputBorder(),
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}