// ignore_for_file: avoid_print

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GitHubService {
  String? _token;
  String? _repoOwner;
  String? _repoName;
  String? _branch;
  String? _filePath;

  static final GitHubService _instance = GitHubService._internal();
  factory GitHubService() => _instance;
  GitHubService._internal();

  Future<void> initialize() async {
    _token = dotenv.env['GITHUB_TOKEN'];
    _repoOwner = dotenv.env['GITHUB_REPO_OWNER'];
    _repoName = dotenv.env['GITHUB_REPO_NAME'];
    _branch = dotenv.env['GITHUB_BRANCH'] ?? 'main';
    _filePath = dotenv.env['GITHUB_FILE_PATH'] ?? 'assets/medicaments_pediatrie.json';
  }

  bool get isConfigured =>
      _token != null &&
      _repoOwner != null &&
      _repoName != null &&
      _branch != null &&
      _filePath != null;

  Map<String, String?> get credentials => {
        'token': _token != null ? '${_token!.substring(0, 10)}...' : null,
        'repoOwner': _repoOwner,
        'repoName': _repoName,
        'branch': _branch,
        'filePath': _filePath,
      };

  // --- HEADERS HELPER ---
  Map<String, String> get _headers => {
        'Authorization': 'token $_token',
        'Accept': 'application/vnd.github.v3+json',
      };

  String get _baseUrl => 'https://api.github.com/repos/$_repoOwner/$_repoName';

  /// Teste la connexion
  Future<bool> testConnection() async {
    if (!isConfigured) return false;
    try {
      final response = await http.get(Uri.parse(_baseUrl), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (e) {
      print('Erreur test connexion GitHub: $e');
      return false;
    }
  }

  /// Récupère le SHA d'un fichier (privé)
  Future<String?> _getFileSha(String path) async {
    if (!isConfigured) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/contents/$path?ref=$_branch'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sha'] as String?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Récupère le contenu brut (String JSON) d'un fichier depuis GitHub
  /// Gère le décodage Base64 -> UTF8
  Future<String?> fetchFileContent(String path) async {
    if (!isConfigured) return null;
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/contents/$path?ref=$_branch'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contentBase64 = data['content'] as String;
        // Nettoyage des sauts de ligne du base64
        final cleanBase64 = contentBase64.replaceAll(RegExp(r'\s'), '');
        final decodedBytes = base64Decode(cleanBase64);
        return utf8.decode(decodedBytes);
      }
      return null;
    } catch (e) {
      print('Erreur fetchFileContent ($path): $e');
      return null;
    }
  }

  /// Publie un contenu (String) sur GitHub
  Future<bool> publishFile({
    required String path,
    required String content, // Contenu déjà sérialisé (JSON string)
    required String commitMessage,
  }) async {
    if (!isConfigured) throw Exception('GitHub non configuré');

    try {
      final sha = await _getFileSha(path);
      final contentBase64 = base64Encode(utf8.encode(content));

      final body = {
        'message': commitMessage,
        'content': contentBase64,
        'branch': _branch,
        if (sha != null) 'sha': sha,
      };

      final response = await http.put(
        Uri.parse('$_baseUrl/contents/$path'),
        headers: {
          ..._headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print('Erreur publishFile ($path): $e');
      return false;
    }
  }

  /// Supprime un fichier
  Future<bool> deleteFile({
    required String path,
    required String commitMessage,
  }) async {
    if (!isConfigured) throw Exception('GitHub non configuré');

    try {
      final sha = await _getFileSha(path);
      if (sha == null) return false;

      final body = {
        'message': commitMessage,
        'sha': sha,
        'branch': _branch,
      };

      final response = await http.delete(
        Uri.parse('$_baseUrl/contents/$path'),
        headers: {
          ..._headers,
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur deleteFile ($path): $e');
      return false;
    }
  }

  // --- WRAPPERS AVEC SUPPORT DU DOSSIER CIBLE ---

  Future<String?> fetchMedications() => fetchFileContent(_filePath!);

  Future<bool> publishMedications({
    required String jsonContent,
    required String commitMessage,
  }) => publishFile(path: _filePath!, content: jsonContent, commitMessage: commitMessage);

  /// Liste les fichiers d'un dossier (par défaut assets/protocoles)
  Future<List<String>> listProtocols({String folder = 'assets/protocoles'}) async {
    if (!isConfigured) return [];
    try {
      // On utilise le paramètre folder ici
      final response = await http.get(
        Uri.parse('$_baseUrl/contents/$folder?ref=$_branch'),
        headers: _headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> contents = json.decode(response.body);
        return contents
            .where((item) =>
                item['type'] == 'file' && item['name'].toString().endsWith('.json'))
            .map((item) => item['name'] as String)
            .toList();
      }
      return [];
    } catch (e) {
      print('Erreur listProtocols ($folder): $e');
      return [];
    }
  }

  /// Récupère un protocole dans le dossier spécifié
  Future<String?> fetchProtocol(String fileName, {String folder = 'assets/protocoles'}) => 
      fetchFileContent('$folder/$fileName');

  /// Publie (sauvegarde) un protocole dans le dossier spécifié
  Future<bool> publishProtocol({
    required String fileName,
    required String jsonContent,
    required String commitMessage,
    String folder = 'assets/protocoles',
  }) => publishFile(path: '$folder/$fileName', content: jsonContent, commitMessage: commitMessage);

  /// Supprime un protocole dans le dossier spécifié
  Future<bool> deleteProtocol({
    required String fileName,
    required String commitMessage,
    String folder = 'assets/protocoles',
  }) => deleteFile(path: '$folder/$fileName', commitMessage: commitMessage);
}