import 'dart:convert';
import 'package:flutter/foundation.dart'; // Nécessaire pour compute
import '../models/medication.dart';
import 'github_service.dart';

// --- FONCTIONS TOP-LEVEL POUR COMPUTE ---
// Elles doivent être en dehors de la classe pour être isolées proprement

List<Medication> _parseMedications(String jsonString) {
  final decoded = jsonDecode(jsonString);
  if (decoded is List) {
    return decoded.map((item) => Medication.fromJson(item)).toList();
  }
  return [];
}

String _encodeMedications(List<Medication> medications) {
  // On trie avant d'encoder pour garder une cohérence
  final sortedMeds = List<Medication>.from(medications);
  sortedMeds.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
  return const JsonEncoder.withIndent('  ').convert(sortedMeds.map((m) => m.toJson()).toList());
}

// ----------------------------------------

class MedicationProvider extends ChangeNotifier {
  final List<Medication> _medications = [];
  Medication? _currentMedication;
  Indication? _currentIndication;
  int? _editingIndex;
  final GitHubService _gitHub = GitHubService();

  List<Medication> get medications => List.unmodifiable(_medications);
  Medication? get currentMedication => _currentMedication;
  Indication? get currentIndication => _currentIndication;
  bool get isEditingMode => _editingIndex != null;

  // ... [Méthodes de gestion d'état UI inchangées : startNewMedication, updateMedicationField, etc.] ...
  // Je remets les méthodes courtes pour la complétude, mais le focus est sur load/save

  void startNewMedication() {
    _currentMedication = Medication(nom: '', galenique: '', indications: []);
    _currentIndication = null;
    _editingIndex = null;
    notifyListeners();
  }

  void updateMedicationField({String? nom, String? nomCommercial, String? galenique, String? contreIndications, String? surdosage, String? aSavoir}) {
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
    _currentIndication = Indication(label: label, posologies: []);
    notifyListeners();
  }

  void addPosology(Posology posology) {
    if (_currentIndication != null) {
      _currentIndication!.posologies.add(posology);
      notifyListeners();
    }
  }

  void updatePosology(int index, Posology posology) {
    if (_currentIndication != null && index >= 0 && index < _currentIndication!.posologies.length) {
      _currentIndication!.posologies[index] = posology;
      notifyListeners();
    }
  }

  void removePosology(int index) {
    if (_currentIndication != null && index >= 0 && index < _currentIndication!.posologies.length) {
      _currentIndication!.posologies.removeAt(index);
      notifyListeners();
    }
  }

  void saveCurrentIndication() {
    if (_currentMedication != null && _currentIndication != null && _currentIndication!.posologies.isNotEmpty) {
      _currentMedication!.indications.add(_currentIndication!);
      _currentIndication = null;
      notifyListeners();
    }
  }

  void removeIndication(int index) {
    if (_currentMedication != null && index >= 0 && index < _currentMedication!.indications.length) {
      _currentMedication!.indications.removeAt(index);
      notifyListeners();
    }
  }

  void editIndication(int index) {
    if (_currentMedication != null && index >= 0 && index < _currentMedication!.indications.length) {
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
    if (_editingIndex != null) {
      _medications[_editingIndex!] = _currentMedication!;
      _editingIndex = null;
    } else {
      _medications.add(_currentMedication!);
    }
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
      _editingIndex = index;
      _currentMedication = Medication.fromJson(_medications[index].toJson()); // Deep copy via JSON (simple pour l'instant)
      _currentIndication = null;
      notifyListeners();
    }
  }

  void clearAll() {
    _medications.clear();
    _currentMedication = null;
    _currentIndication = null;
    _editingIndex = null;
    notifyListeners();
  }

  void cancelCurrentMedication() {
    _currentMedication = null;
    _currentIndication = null;
    _editingIndex = null;
    notifyListeners();
  }

  // --- OPTIMISATION : EXPORT & LOAD ASYNC ---

  // Gardé synchrone pour l'UI rapide (petit volume), mais utilise _encodeMedications si besoin
  String exportToJsonSorted() {
    // Version synchrone pour l'affichage UI immédiat (PreviewScreen)
    final sortedMeds = List<Medication>.from(_medications);
    sortedMeds.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
    return const JsonEncoder.withIndent('  ').convert(sortedMeds.map((m) => m.toJson()).toList());
  }

  Future<void> loadFromGitHub() async {
    try {
      final jsonString = await _gitHub.fetchMedications();
      if (jsonString != null) {
        // Parsing dans un Isolate
        final meds = await compute(_parseMedications, jsonString);
        _medications.clear();
        _medications.addAll(meds);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur loadFromGitHub: $e');
      rethrow;
    }
  }

  Future<bool> publishToGitHub(String commitMessage) async {
    try {
      // Encodage dans un Isolate
      final jsonContent = await compute(_encodeMedications, _medications);
      return await _gitHub.publishMedications(
        jsonContent: jsonContent,
        commitMessage: commitMessage,
      );
    } catch (e) {
      debugPrint('Erreur publishToGitHub: $e');
      return false;
    }
  }
}