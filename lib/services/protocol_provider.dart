import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/protocol.dart';
import 'github_service.dart';

class ProtocolProvider extends ChangeNotifier {
  final List<Protocol> _protocols = [];
  Protocol? _currentProtocol;
  Etape? _currentEtape;
  int? _editingProtocolIndex;
  int? _editingEtapeIndex;
  final GitHubService _gitHub = GitHubService();

  List<Protocol> get protocols => _protocols;
  Protocol? get currentProtocol => _currentProtocol;
  Etape? get currentEtape => _currentEtape;
  bool get isEditingProtocol => _editingProtocolIndex != null;
  bool get isEditingEtape => _editingEtapeIndex != null;

  // ============================================================
  // GESTION DES PROTOCOLES
  // ============================================================

  void startNewProtocol() {
    _currentProtocol = Protocol(
      nom: '',
      description: '',
      etapes: [],
    );
    _currentEtape = null;
    _editingProtocolIndex = null;
    _editingEtapeIndex = null;
    notifyListeners();
  }

  void updateProtocolField({
    String? nom,
    String? description,
  }) {
    if (_currentProtocol == null) return;

    if (nom != null) _currentProtocol!.nom = nom;
    if (description != null) _currentProtocol!.description = description;

    notifyListeners();
  }

  void addProtocolToList() {
    if (_currentProtocol == null) return;

    if (_editingProtocolIndex != null) {
      // Mode édition : remplacer le protocole existant
      _protocols[_editingProtocolIndex!] = _currentProtocol!;
      _editingProtocolIndex = null;
    } else {
      // Mode création : ajouter un nouveau protocole
      _protocols.add(_currentProtocol!);
    }

    _currentProtocol = null;
    _currentEtape = null;
    notifyListeners();
  }

  void editProtocol(int index) {
    if (index >= 0 && index < _protocols.length) {
      _editingProtocolIndex = index;
      _currentProtocol = Protocol(
        nom: _protocols[index].nom,
        description: _protocols[index].description,
        etapes: List.from(_protocols[index].etapes),
      );
      _currentEtape = null;
      notifyListeners();
    }
  }

  void removeProtocol(int index) {
    if (index >= 0 && index < _protocols.length) {
      _protocols.removeAt(index);
      notifyListeners();
    }
  }

  void cancelCurrentProtocol() {
    _currentProtocol = null;
    _currentEtape = null;
    _editingProtocolIndex = null;
    _editingEtapeIndex = null;
    notifyListeners();
  }

  void clearAllProtocols() {
    _protocols.clear();
    _currentProtocol = null;
    _currentEtape = null;
    _editingProtocolIndex = null;
    _editingEtapeIndex = null;
    notifyListeners();
  }

  // ============================================================
  // GESTION DES ÉTAPES
  // ============================================================

  void startNewEtape() {
    _currentEtape = Etape(
      titre: '',
      elements: [],
    );
    _editingEtapeIndex = null;
    notifyListeners();
  }

  void updateEtapeField({
    String? titre,
    String? temps,
    String? attention,
  }) {
    if (_currentEtape == null) return;

    if (titre != null) _currentEtape!.titre = titre;
    if (temps != null) _currentEtape!.temps = temps;
    if (attention != null) _currentEtape!.attention = attention;

    notifyListeners();
  }

  void addElementToEtape(Element element) {
    if (_currentEtape == null) return;
    _currentEtape!.elements.add(element);
    notifyListeners();
  }

  void updateElement(int index, Element element) {
    if (_currentEtape == null) return;
    if (index >= 0 && index < _currentEtape!.elements.length) {
      _currentEtape!.elements[index] = element;
      notifyListeners();
    }
  }

  void removeElement(int index) {
    if (_currentEtape == null) return;
    if (index >= 0 && index < _currentEtape!.elements.length) {
      _currentEtape!.elements.removeAt(index);
      notifyListeners();
    }
  }

  void saveCurrentEtape() {
    if (_currentProtocol == null || _currentEtape == null) return;
    if (_currentEtape!.elements.isEmpty) return;

    if (_editingEtapeIndex != null) {
      // Mode édition : remplacer l'étape existante
      _currentProtocol!.etapes[_editingEtapeIndex!] = _currentEtape!;
      _editingEtapeIndex = null;
    } else {
      // Mode création : ajouter une nouvelle étape
      _currentProtocol!.etapes.add(_currentEtape!);
    }

    _currentEtape = null;
    notifyListeners();
  }

  void editEtape(int index) {
    if (_currentProtocol == null) return;
    if (index >= 0 && index < _currentProtocol!.etapes.length) {
      _editingEtapeIndex = index;
      final etape = _currentProtocol!.etapes[index];
      _currentEtape = Etape(
        titre: etape.titre,
        temps: etape.temps,
        elements: List.from(etape.elements),
        attention: etape.attention,
      );
      notifyListeners();
    }
  }

  void removeEtape(int index) {
    if (_currentProtocol == null) return;
    if (index >= 0 && index < _currentProtocol!.etapes.length) {
      _currentProtocol!.etapes.removeAt(index);
      notifyListeners();
    }
  }

  void cancelCurrentEtape() {
    _currentEtape = null;
    _editingEtapeIndex = null;
    notifyListeners();
  }

  // ============================================================
  // EXPORT / IMPORT JSON
  // ============================================================

  String exportProtocolToJson(Protocol protocol) {
    return protocol.toJsonString();
  }

  void loadProtocolFromJson(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString);
      final protocol = Protocol.fromJson(decoded);
      _protocols.add(protocol);
      notifyListeners();
    } catch (e) {
      throw Exception('Erreur lors du chargement du protocole: $e');
    }
  }

  // ============================================================
  // GITHUB
  // ============================================================

  /// Charge tous les protocoles depuis GitHub
  Future<void> loadAllProtocolsFromGitHub() async {
    try {
      // NOUVEAU : Vider la liste avant de la recharger
      _protocols.clear(); // 👈 LIGNE AJOUTÉE/MODIFIÉE

      // Liste tous les fichiers de protocoles
      final fileNames = await _gitHub.listProtocols();

      // Charge chaque protocole
      for (final fileName in fileNames) {
        final jsonContent = await _gitHub.fetchProtocol(fileName);
        if (jsonContent != null) {
          loadProtocolFromJson(jsonContent);
        }
      }
    } catch (e) {
      throw Exception('Erreur lors du chargement des protocoles: $e');
    }
  }

  /// Publie un protocole sur GitHub
  Future<bool> publishProtocolToGitHub(Protocol protocol, String commitMessage) async {
    try {
      final jsonContent = protocol.toJsonString();
      final fileName = protocol.fileName;

      final success = await _gitHub.publishProtocol(
        fileName: fileName,
        jsonContent: jsonContent,
        commitMessage: commitMessage,
      );

      return success;
    } catch (e) {
      print('Erreur lors de la publication du protocole: $e');
      return false;
    }
  }

  /// Supprime un protocole de GitHub
  Future<bool> deleteProtocolFromGitHub(Protocol protocol, String commitMessage) async {
    try {
      final fileName = protocol.fileName;

      final success = await _gitHub.deleteProtocol(
        fileName: fileName,
        commitMessage: commitMessage,
      );

      return success;
    } catch (e) {
      print('Erreur lors de la suppression du protocole: $e');
      return false;
    }
  }
}