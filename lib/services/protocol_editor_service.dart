// ignore_for_file: avoid_redundant_argument_values

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../models/protocol_model.dart';

/// Service de gestion des protocoles pour l'éditeur
class ProtocolEditorService {
  static final ProtocolEditorService _instance = ProtocolEditorService._internal();
  factory ProtocolEditorService() => _instance;
  ProtocolEditorService._internal();

  List<Protocol> _protocols = [];
  String? _protocolsDirectory;

  List<Protocol> get protocols => List.unmodifiable(_protocols);

  /// Initialise le répertoire des protocoles
  Future<String> get protocolsDirectory async {
    if (_protocolsDirectory != null) return _protocolsDirectory!;
    
    final appDir = await getApplicationDocumentsDirectory();
    _protocolsDirectory = '${appDir.path}/protocoles';
    
    // Créer le répertoire s'il n'existe pas
    final dir = Directory(_protocolsDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    
    return _protocolsDirectory!;
  }

  /// Charge tous les protocoles depuis le répertoire
  Future<void> loadProtocols() async {
    try {
      final dirPath = await protocolsDirectory;
      final dir = Directory(dirPath);
      
      if (!await dir.exists()) {
        _protocols = [];
        return;
      }

      final files = await dir
          .list()
          .where((f) => f is File && f.path.endsWith('.json'))
          .toList();

      _protocols = [];
      
      for (var file in files) {
        try {
          final content = await File(file.path).readAsString();
          final json = jsonDecode(content) as Map<String, dynamic>;
          final fileName = file.path.split('/').last;
          _protocols.add(Protocol.fromJson(json, sourceFileName: fileName));
        } catch (e) {
          debugPrint('Erreur chargement protocole ${file.path}: $e');
        }
      }

      // Trier par titre
      _protocols.sort((a, b) => a.titre.compareTo(b.titre));
      
      debugPrint('✅ ${_protocols.length} protocoles chargés');
    } catch (e) {
      debugPrint('❌ Erreur chargement protocoles: $e');
      _protocols = [];
    }
  }

  /// Sauvegarde un protocole
  Future<bool> saveProtocol(Protocol protocol) async {
    try {
      final dirPath = await protocolsDirectory;
      final fileName = protocol.generateFileName();
      final filePath = '$dirPath/$fileName';
      
      // Mettre à jour avec le nouveau nom de fichier si c'est un nouveau protocole
      final protocolToSave = protocol.copyWith(
        fileName: fileName,
        dateModification: DateTime.now(),
      );
      
      final jsonContent = const JsonEncoder.withIndent('  ')
          .convert(protocolToSave.toJson());
      
      await File(filePath).writeAsString(jsonContent);
      
      // Mettre à jour la liste locale
      final existingIndex = _protocols.indexWhere(
        (p) => p.fileName == fileName || p.titre == protocol.titre
      );
      
      if (existingIndex >= 0) {
        _protocols[existingIndex] = protocolToSave;
      } else {
        _protocols.add(protocolToSave);
        _protocols.sort((a, b) => a.titre.compareTo(b.titre));
      }
      
      debugPrint('✅ Protocole sauvegardé: $fileName');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur sauvegarde protocole: $e');
      return false;
    }
  }

  /// Supprime un protocole
  Future<bool> deleteProtocol(Protocol protocol) async {
    try {
      if (protocol.fileName == null) return false;
      
      final dirPath = await protocolsDirectory;
      final filePath = '$dirPath/${protocol.fileName}';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }
      
      _protocols.removeWhere((p) => p.fileName == protocol.fileName);
      
      debugPrint('✅ Protocole supprimé: ${protocol.fileName}');
      return true;
    } catch (e) {
      debugPrint('❌ Erreur suppression protocole: $e');
      return false;
    }
  }

  /// Exporte un protocole vers un fichier
  Future<String?> exportProtocol(Protocol protocol, String exportPath) async {
    try {
      final fileName = protocol.generateFileName();
      final filePath = '$exportPath/$fileName';
      
      final jsonContent = const JsonEncoder.withIndent('  ')
          .convert(protocol.toJson());
      
      await File(filePath).writeAsString(jsonContent);
      
      debugPrint('✅ Protocole exporté: $filePath');
      return filePath;
    } catch (e) {
      debugPrint('❌ Erreur export protocole: $e');
      return null;
    }
  }

  /// Importe un protocole depuis un fichier
  Future<Protocol?> importProtocol(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ Fichier non trouvé: $filePath');
        return null;
      }
      
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final fileName = filePath.split('/').last;
      
      return Protocol.fromJson(json, sourceFileName: fileName);
    } catch (e) {
      debugPrint('❌ Erreur import protocole: $e');
      return null;
    }
  }

  /// Vérifie si un nom de fichier existe déjà
  Future<bool> fileNameExists(String fileName) async {
    final dirPath = await protocolsDirectory;
    final file = File('$dirPath/$fileName');
    return await file.exists();
  }

  /// Crée un nouveau protocole vide
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

  /// Duplique un protocole existant
  Protocol duplicateProtocol(Protocol original) {
    return Protocol(
      titre: '${original.titre} (copie)',
      description: original.description,
      auteur: original.auteur,
      version: '1.0',
      dateModification: DateTime.now(),
      blocs: original.blocs.map((b) => _duplicateBlock(b)).toList(),
      fileName: null, // Nouveau fichier sera généré
    );
  }

  ProtocolBlock _duplicateBlock(ProtocolBlock block) {
    // Recréer le bloc avec un nouvel ID
    final json = block.toJson();
    json.remove('id'); // Supprimer l'ID pour en générer un nouveau
    return ProtocolBlock.fromJson(json);
  }

  /// Recherche dans les protocoles
  List<Protocol> search(String query) {
    if (query.isEmpty) return _protocols;
    
    final lowerQuery = query.toLowerCase();
    return _protocols.where((p) {
      return p.titre.toLowerCase().contains(lowerQuery) ||
          (p.description?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  /// Récupère un protocole par son titre
  Protocol? findByTitre(String titre) {
    try {
      return _protocols.firstWhere(
        (p) => p.titre.toLowerCase() == titre.toLowerCase()
      );
    } catch (_) {
      return null;
    }
  }

  /// Récupère un protocole par son nom de fichier
  Protocol? findByFileName(String fileName) {
    try {
      return _protocols.firstWhere((p) => p.fileName == fileName);
    } catch (_) {
      return null;
    }
  }
}