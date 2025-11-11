import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/medication.dart';

class MedicationProvider extends ChangeNotifier {
  final List<Medication> _medications = [];
  Medication? _currentMedication;
  Indication? _currentIndication;

  List<Medication> get medications => _medications;
  Medication? get currentMedication => _currentMedication;
  Indication? get currentIndication => _currentIndication;

  void startNewMedication() {
    _currentMedication = Medication(
      nom: '',
      galenique: '',
      indications: [],
    );
    _currentIndication = null;
    notifyListeners();
  }

  void updateMedicationField({
    String? nom,
    String? nomCommercial,
    String? galenique,
    String? contreIndications,
    String? surdosage,
    String? aSavoir,
  }) {
    if (_currentMedication == null) return;

    if (nom != null) _currentMedication!.nom = nom;
    if (nomCommercial != null) _currentMedication!.nomCommercial = nomCommercial;
    if (galenique != null) _currentMedication!.galenique = galenique;
    if (contreIndications != null) _currentMedication!.contreIndications = contreIndications;
    if (surdosage != null) _currentMedication!.surdosage = surdosage;
    if (aSavoir != null) _currentMedication!.aSavoir = aSavoir;

    notifyListeners();
  }

  void startNewIndication(String label) {
    _currentIndication = Indication(
      label: label,
      posologies: [],
    );
    notifyListeners();
  }

  void addPosology(Posology posology) {
    if (_currentIndication == null) return;
    _currentIndication!.posologies.add(posology);
    notifyListeners();
  }

  void updatePosology(int index, Posology posology) {
    if (_currentIndication == null) return;
    if (index >= 0 && index < _currentIndication!.posologies.length) {
      _currentIndication!.posologies[index] = posology;
      notifyListeners();
    }
  }

  void removePosology(int index) {
    if (_currentIndication == null) return;
    if (index >= 0 && index < _currentIndication!.posologies.length) {
      _currentIndication!.posologies.removeAt(index);
      notifyListeners();
    }
  }

  void saveCurrentIndication() {
    if (_currentMedication == null || _currentIndication == null) return;
    if (_currentIndication!.posologies.isEmpty) return;
    
    _currentMedication!.indications.add(_currentIndication!);
    _currentIndication = null;
    notifyListeners();
  }

  void removeIndication(int index) {
    if (_currentMedication == null) return;
    if (index >= 0 && index < _currentMedication!.indications.length) {
      _currentMedication!.indications.removeAt(index);
      notifyListeners();
    }
  }

  void editIndication(int index) {
    if (_currentMedication == null) return;
    if (index >= 0 && index < _currentMedication!.indications.length) {
      _currentIndication = _currentMedication!.indications[index];
      _currentMedication!.indications.removeAt(index);
      notifyListeners();
    }
  }

  void cancelCurrentIndication() {
    _currentIndication = null;
    notifyListeners();
  }

  void addMedicationToList() {
    if (_currentMedication == null) return;
    _medications.add(_currentMedication!);
    _currentMedication = null;
    _currentIndication = null;
    notifyListeners();
  }

  void removeMedication(int index) {
    if (index >= 0 && index < _medications.length) {
      _medications.removeAt(index);
      notifyListeners();
    }
  }

  void editMedication(int index) {
    if (index >= 0 && index < _medications.length) {
      _currentMedication = _medications[index];
      _medications.removeAt(index);
      _currentIndication = null;
      notifyListeners();
    }
  }

  void clearAll() {
    _medications.clear();
    _currentMedication = null;
    _currentIndication = null;
    notifyListeners();
  }

  void cancelCurrentMedication() {
    _currentMedication = null;
    _currentIndication = null;
    notifyListeners();
  }

  String exportToJson() {
    final list = _medications.map((m) => m.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  void loadFromJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      if (decoded is List) {
        _medications.clear();
        for (var item in decoded) {
          _medications.add(Medication.fromJson(item));
        }
        notifyListeners();
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement du JSON: $e');
    }
  }
}