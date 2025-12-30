import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/protocol_model.dart'; // Le NOUVEAU modèle
import 'github_service.dart';

class ProtocolProvider extends ChangeNotifier {
  final GitHubService _gitHub = GitHubService();
  
  // Liste des protocoles chargée depuis GitHub
  List<Protocol> _protocols = [];
  List<Protocol> get protocols => List.unmodifiable(_protocols);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- CHARGEMENT ---

  /// Charge tous les protocoles depuis GitHub
  Future<void> loadAllProtocolsFromGitHub() async {
    _setLoading(true);
    try {
      _protocols.clear();
      
      // 1. Récupère la liste des noms de fichiers dans le dossier protocoles
      final fileNames = await _gitHub.listProtocols();
      
      // 2. Récupère et parse le contenu de chaque fichier
      for (final fileName in fileNames) {
        final jsonString = await _gitHub.fetchProtocol(fileName);
        
        if (jsonString != null && jsonString.isNotEmpty) {
          try {
            // Parsing du JSON
            final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
            
            // Conversion en objet Protocol (gère la rétrocompatibilité automatiquement)
            final protocol = Protocol.fromJson(jsonMap, sourceFileName: fileName);
            _protocols.add(protocol);
          } catch (e) {
             debugPrint("❌ Erreur parsing protocole $fileName: $e");
          }
        }
      }
      
      // Tri alphabétique par titre
      _protocols.sort((a, b) => a.titre.compareTo(b.titre));
      notifyListeners();
      
    } catch (e) {
      debugPrint("❌ Erreur globale chargement protocoles: $e");
      // On ne rethrow pas forcément pour ne pas crasher l'UI, mais on garde la liste vide
    } finally {
      _setLoading(false);
    }
  }

  // --- ACTIONS (SAUVEGARDE / SUPPRESSION) ---

  /// Sauvegarde (Publie) un protocole sur GitHub
  Future<bool> saveProtocol(Protocol protocol) async {
    _setLoading(true);
    try {
      // 1. Génération du nom de fichier (si nouveau ou renommé)
      // Note: generateFileName() doit gérer les caractères spéciaux
      final fileName = protocol.generateFileName();
      
      // 2. Mise à jour de la date de modification
      final protocolToSave = protocol.copyWith(
        fileName: fileName,
        dateModification: DateTime.now(),
      );

      // 3. Conversion en JSON formatté
      final jsonContent = const JsonEncoder.withIndent('  ').convert(protocolToSave.toJson());

      // 4. Envoi vers GitHub
      final success = await _gitHub.publishProtocol(
        fileName: fileName,
        jsonContent: jsonContent,
        commitMessage: "Mise à jour protocole: ${protocol.titre}",
      );

      if (success) {
        // 5. Mise à jour de la liste locale pour refléter les changements sans recharger
        final index = _protocols.indexWhere((p) => p.fileName == fileName || (p.fileName == null && p.titre == protocol.titre));
        
        if (index >= 0) {
          _protocols[index] = protocolToSave;
        } else {
          _protocols.add(protocolToSave);
        }
        // Retrier
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

  /// Supprime un protocole de GitHub
  Future<bool> deleteProtocol(Protocol protocol) async {
    if (protocol.fileName == null) return false; // Ne peut pas supprimer s'il n'est pas sur GitHub
    
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

  // --- UTILITAIRES DE GESTION (VENANT DE L'ANCIEN EDITOR SERVICE) ---

  Protocol createNewProtocol() {
    return Protocol(
      titre: 'Nouveau protocole',
      description: '',
      auteur: '',
      version: '1.0',
      dateModification: DateTime.now(),
      blocs: [],
    );
  }

  Protocol duplicateProtocol(Protocol original) {
    // Crée une copie en mémoire. Elle ne sera sauvegardée (et n'aura un fileName) que lors du "Save"
    return Protocol(
      titre: '${original.titre} (copie)',
      description: original.description,
      auteur: original.auteur,
      version: '1.0',
      dateModification: DateTime.now(),
      // On duplique aussi les blocs pour éviter les références partagées
      blocs: original.blocs.map((b) {
        // Astuce: passer par JSON permet une copie profonde (deep copy) facile
        final json = b.toJson();
        json.remove('id'); // On retire l'ID pour en générer un nouveau si besoin
        return ProtocolBlock.fromJson(json);
      }).toList(),
      fileName: null, 
    );
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners(); // Notifie l'UI pour afficher/masquer les spinners
  }
}