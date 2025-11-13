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

  // Singleton
  static final GitHubService _instance = GitHubService._internal();
  factory GitHubService() => _instance;
  GitHubService._internal();

  /// Initialise le service avec les credentials depuis .env
  Future<void> initialize() async {
    _token = dotenv.env['GITHUB_TOKEN'];
    _repoOwner = dotenv.env['GITHUB_REPO_OWNER'];
    _repoName = dotenv.env['GITHUB_REPO_NAME'];
    _branch = dotenv.env['GITHUB_BRANCH'] ?? 'main';
    _filePath = dotenv.env['GITHUB_FILE_PATH'] ?? 'assets/medicaments_pediatrie.json';
  }

  /// Vérifie si les credentials sont configurées
  bool get isConfigured =>
      _token != null &&
      _repoOwner != null &&
      _repoName != null &&
      _branch != null &&
      _filePath != null;

  /// Récupère les credentials actuelles
  Map<String, String?> get credentials => {
        'token': _token != null ? '${_token!.substring(0, 10)}...' : null, // Masqué pour sécurité
        'repoOwner': _repoOwner,
        'repoName': _repoName,
        'branch': _branch,
        'filePath': _filePath,
      };

  /// Teste la connexion à GitHub
  Future<bool> testConnection() async {
    if (!isConfigured) return false;

    try {
      final response = await http.get(
        Uri.parse('https://api.github.com/repos/$_repoOwner/$_repoName'),
        headers: {
          'Authorization': 'token $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Erreur test connexion GitHub: $e');
      return false;
    }
  }

  /// Récupère le SHA du fichier medications.json sur GitHub
  Future<String?> _getFileSha(String path) async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$_repoOwner/$_repoName/contents/$path?ref=$_branch'),
        headers: {
          'Authorization': 'token $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['sha'] as String?;
      }
      return null;
    } catch (e) {
      print('Erreur récupération SHA: $e');
      return null;
    }
  }

  /// Publie le fichier medications.json sur GitHub
  Future<bool> publishMedications({
    required String jsonContent,
    required String commitMessage,
  }) async {
    if (!isConfigured) {
      throw Exception('GitHub non configuré - vérifiez votre fichier .env');
    }

    try {
      // Récupère le SHA si le fichier existe déjà
      final sha = await _getFileSha(_filePath!);

      // Encode le contenu en base64
      final contentBase64 = base64Encode(utf8.encode(jsonContent));

      // Prépare le body de la requête
      final body = {
        'message': commitMessage,
        'content': contentBase64,
        'branch': _branch,
      };

      // Ajoute le SHA si le fichier existe (pour update)
      if (sha != null) {
        body['sha'] = sha;
      }

      // Envoie la requête à GitHub
      final response = await http.put(
        Uri.parse(
            'https://api.github.com/repos/$_repoOwner/$_repoName/contents/$_filePath'),
        headers: {
          'Authorization': 'token $_token',
          'Accept': 'application/vnd.github.v3+json',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Fichier publié avec succès sur GitHub');
        return true;
      } else {
        print('❌ Erreur publication: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Exception lors de la publication: $e');
      return false;
    }
  }

  /// Récupère le contenu du fichier medications.json depuis GitHub
  Future<String?> fetchMedications() async {
    if (!isConfigured) return null;

    try {
      final response = await http.get(
        Uri.parse(
            'https://api.github.com/repos/$_repoOwner/$_repoName/contents/$_filePath?ref=$_branch'),
        headers: {
          'Authorization': 'token $_token',
          'Accept': 'application/vnd.github.v3+json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final contentBase64 = data['content'] as String;
        // Supprime les retours à la ligne du base64
        final cleanBase64 = contentBase64.replaceAll('\n', '');
        final decodedBytes = base64Decode(cleanBase64);
        return utf8.decode(decodedBytes);
      }
      return null;
    } catch (e) {
      print('Erreur récupération medications: $e');
      return null;
    }
  }
}