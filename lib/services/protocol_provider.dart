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
  
  // Liste unique contenant TOUS les protocoles (Standards + Pocus)
  final List<Protocol> _protocols = [];
  
  List<Protocol> get protocols => List.unmodifiable(_protocols);
  
  // --- NOUVEAUX GETTERS FILTRÉS ---
  /// Retourne uniquement les protocoles POCUS
  List<Protocol> get pocusProtocols => 
      _protocols.where((p) => p.categorie == 'POCUS').toList();

  /// Retourne les protocoles standards (tout sauf POCUS)
  List<Protocol> get standardProtocols => 
      _protocols.where((p) => p.categorie != 'POCUS').toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// Charge les protocoles depuis les DEUX sources (assets/protocoles et assets/pocus)
  Future<void> loadAllProtocolsFromGitHub() async {
    if (_isLoading) return;
    _setLoading(true);
    
    try {
      _protocols.clear();
      
      // 1. Lister les fichiers des deux dossiers en parallèle
      final results = await Future.wait([
        _gitHub.listProtocols(folder: 'assets/protocoles'),
        _gitHub.listProtocols(folder: 'assets/pocus'),
      ]);
      
      final standardFiles = results[0];
      final pocusFiles = results[1];

      // 2. Préparer le téléchargement du contenu
      // On passe le dossier source pour savoir où fetcher
      final futures = <Future<Map<String, String?>>>[];

      for (var fileName in standardFiles) {
        futures.add(_fetchFileContent(fileName, 'assets/protocoles'));
      }
      for (var fileName in pocusFiles) {
        futures.add(_fetchFileContent(fileName, 'assets/pocus'));
      }
      
      // 3. Télécharger tout en parallèle
      final rawContents = await Future.wait(futures);
      
      // 4. Parser dans un Isolate (lourd)
      if (rawContents.isNotEmpty) {
        final loadedProtocols = await compute(_parseProtocolList, rawContents);
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

  // Helper pour fetcher avec le dossier
  Future<Map<String, String?>> _fetchFileContent(String fileName, String folder) async {
    final content = await _gitHub.fetchProtocol(fileName, folder: folder);
    return {'fileName': fileName, 'content': content};
  }

  /// Sauvegarde intelligente : dirige vers le bon dossier selon la catégorie
  Future<bool> saveProtocol(Protocol protocol) async {
    _setLoading(true);
    try {
      final fileName = protocol.generateFileName();
      final protocolToSave = protocol.copyWith(
        fileName: fileName,
        dateModification: DateTime.now(),
      );

      // Détermination du dossier cible
      final targetFolder = (protocol.categorie == 'POCUS') 
          ? 'assets/pocus' 
          : 'assets/protocoles';

      // Encodage JSON en background
      final jsonContent = await compute(_encodeProtocol, protocolToSave);

      final success = await _gitHub.publishProtocol(
        fileName: fileName,
        jsonContent: jsonContent,
        commitMessage: "Mise à jour protocole (${protocol.categorie ?? 'Standard'}): ${protocol.titre}",
        folder: targetFolder, // Argument folder ajouté
      );

      if (success) {
        // Mise à jour de la liste locale
        final index = _protocols.indexWhere((p) => 
            p.fileName == fileName || (p.fileName == null && p.titre == protocol.titre));
        
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

  /// Supprime le protocole du bon dossier
  Future<bool> deleteProtocol(Protocol protocol) async {
    if (protocol.fileName == null) return false;
    _setLoading(true);
    try {
      // Détermination du dossier cible
      final targetFolder = (protocol.categorie == 'POCUS') 
          ? 'assets/pocus' 
          : 'assets/protocoles';

      final success = await _gitHub.deleteProtocol(
        fileName: protocol.fileName!,
        commitMessage: "Suppression protocole: ${protocol.titre}",
        folder: targetFolder, // Argument folder ajouté
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
      // Pas de catégorie par défaut, l'utilisateur choisira
    );
  }

  Protocol duplicateProtocol(Protocol original) {
    final json = original.toJson();
    final copy = Protocol.fromJson(json);
    return copy.copyWith(
      titre: '${original.titre} (copie)',
      fileName: null,
      dateModification: DateTime.now(),
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}