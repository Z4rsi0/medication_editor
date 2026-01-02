import 'dart:convert';
import 'package:flutter/foundation.dart'; // Pour compute
import '../models/protocol_model.dart';
import 'github_service.dart';

// --- FONCTIONS TOP-LEVEL POUR COMPUTE ---

String _encodeProtocol(Protocol protocol) {
  return const JsonEncoder.withIndent('  ').convert(protocol.toJson());
}

// Fonction isolée pour parser une liste entière de protocoles
List<Protocol> _parseProtocolList(List<Map<String, String?>> rawDataList) {
  final List<Protocol> results = [];
  
  for (final item in rawDataList) {
    final content = item['content'];
    final fileName = item['fileName'];
    
    if (content != null && content.isNotEmpty) {
      try {
        final jsonMap = jsonDecode(content);
        results.add(Protocol.fromJson(jsonMap, sourceFileName: fileName));
      } catch (e) {
        debugPrint("Erreur parsing $fileName dans isolate: $e");
      }
    }
  }
  return results;
}

// ----------------------------------------

class ProtocolProvider extends ChangeNotifier {
  final GitHubService _gitHub = GitHubService();
  
  final List<Protocol> _protocols = [];
  List<Protocol> get protocols => List.unmodifiable(_protocols);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadAllProtocolsFromGitHub() async {
    if (_isLoading) return;
    _setLoading(true);
    
    try {
      _protocols.clear();
      final fileNames = await _gitHub.listProtocols();
      
      // Récupération parallèle de tous les contenus bruts
      final futures = fileNames.map((fileName) async {
        final content = await _gitHub.fetchProtocol(fileName);
        return {'fileName': fileName, 'content': content};
      });
      
      final results = await Future.wait(futures);
      
      // Parsing lourd dans un Isolate unique pour ne pas bloquer l'UI
      if (results.isNotEmpty) {
        final loadedProtocols = await compute(_parseProtocolList, results);
        _protocols.addAll(loadedProtocols);
        _protocols.sort((a, b) => a.titre.compareTo(b.titre));
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("❌ Erreur globale chargement protocoles: $e");
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveProtocol(Protocol protocol) async {
    _setLoading(true);
    try {
      final fileName = protocol.generateFileName();
      final protocolToSave = protocol.copyWith(
        fileName: fileName,
        dateModification: DateTime.now(),
      );

      // Encodage JSON en background
      final jsonContent = await compute(_encodeProtocol, protocolToSave);

      final success = await _gitHub.publishProtocol(
        fileName: fileName,
        jsonContent: jsonContent,
        commitMessage: "Mise à jour protocole: ${protocol.titre}",
      );

      if (success) {
        final index = _protocols.indexWhere((p) => p.fileName == fileName || (p.fileName == null && p.titre == protocol.titre));
        if (index >= 0) {
          _protocols[index] = protocolToSave;
        } else {
          _protocols.add(protocolToSave);
        }
        _protocols.sort((a, b) => a.titre.compareTo(b.titre));
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint("❌ Erreur sauvegarde: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProtocol(Protocol protocol) async {
    if (protocol.fileName == null) return false;
    _setLoading(true);
    try {
      final success = await _gitHub.deleteProtocol(
        fileName: protocol.fileName!,
        commitMessage: "Suppression protocole: ${protocol.titre}",
      );

      if (success) {
        _protocols.removeWhere((p) => p.fileName == protocol.fileName);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint("❌ Erreur suppression: $e");
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Protocol createNewProtocol() {
    return Protocol(
      titre: 'Nouveau protocole',
      version: '1.0',
      dateModification: DateTime.now(),
      blocs: [],
    );
  }

  Protocol duplicateProtocol(Protocol original) {
    // Clonage via JSON pour éviter les références (Deep Copy)
    final json = original.toJson();
    final copy = Protocol.fromJson(json);
    return copy.copyWith(
      titre: '${original.titre} (copie)',
      fileName: null, // Nouveau fichier
      dateModification: DateTime.now(),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}