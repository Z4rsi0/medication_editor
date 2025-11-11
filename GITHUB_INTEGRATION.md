# 🚀 Guide d'intégration GitHub (Future)

Ce document décrit comment ajouter l'intégration GitHub automatique pour pousser directement les médicaments vers le repository ped_app.

## 📋 Fonctionnalités à ajouter

### 1. Configuration GitHub
- Token d'authentification GitHub
- URL du repository
- Branche cible
- Chemin vers medications.json

### 2. Interface utilisateur
- Écran de configuration dans les paramètres
- Bouton "Push vers GitHub" dans l'écran d'export
- Indicateur de statut de connexion

### 3. Gestion des conflits
- Pull avant push
- Merge automatique ou manuel
- Historique des versions

---

## 🔧 Implémentation technique

### Dépendances à ajouter dans pubspec.yaml

```yaml
dependencies:
  # Existantes...
  http: ^1.1.0
  github: ^9.19.0
  shared_preferences: ^2.2.2
```

### Structure de fichiers à créer

```
lib/
├── services/
│   ├── github_service.dart          # Service d'interaction GitHub
│   └── github_config.dart           # Configuration GitHub
├── screens/
│   └── settings_screen.dart         # Écran paramètres GitHub
└── models/
    └── github_credentials.dart      # Modèle pour credentials
```

---

## 💻 Code de base pour github_service.dart

```dart
import 'package:github/github.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GitHubService {
  GitHub? _github;
  String? _repositorySlug;
  String? _branch;
  String? _filePath;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('github_token');
    _repositorySlug = prefs.getString('github_repo'); // Format: "username/repo"
    _branch = prefs.getString('github_branch') ?? 'main';
    _filePath = prefs.getString('github_file_path') ?? 'assets/data/medications.json';

    if (token != null) {
      _github = GitHub(auth: Authentication.withToken(token));
    }
  }

  Future<void> saveCredentials({
    required String token,
    required String repositorySlug,
    String? branch,
    String? filePath,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('github_token', token);
    await prefs.setString('github_repo', repositorySlug);
    await prefs.setString('github_branch', branch ?? 'main');
    await prefs.setString('github_file_path', filePath ?? 'assets/data/medications.json');
    await initialize();
  }

  Future<bool> isConfigured() async {
    await initialize();
    return _github != null && _repositorySlug != null;
  }

  Future<String> getCurrentFileContent() async {
    if (_github == null || _repositorySlug == null) {
      throw Exception('GitHub not configured');
    }

    try {
      final slug = RepositorySlug.full(_repositorySlug!);
      final contents = await _github!.repositories.getContents(
        slug,
        _filePath!,
        ref: _branch,
      );

      if (contents.file == null) {
        throw Exception('File not found');
      }

      return utf8.decode(base64.decode(contents.file!.content!));
    } catch (e) {
      throw Exception('Failed to fetch file: $e');
    }
  }

  Future<void> pushMedications(String jsonContent, String commitMessage) async {
    if (_github == null || _repositorySlug == null) {
      throw Exception('GitHub not configured');
    }

    try {
      final slug = RepositorySlug.full(_repositorySlug!);
      
      // Get current file SHA
      final contents = await _github!.repositories.getContents(
        slug,
        _filePath!,
        ref: _branch,
      );

      if (contents.file == null) {
        throw Exception('File not found');
      }

      // Update file
      await _github!.repositories.updateFile(
        slug,
        _filePath!,
        commitMessage,
        jsonContent,
        contents.file!.sha!,
        branch: _branch,
      );
    } catch (e) {
      throw Exception('Failed to push: $e');
    }
  }

  Future<List<Map<String, dynamic>>> mergeMedications(
    String existingJson,
    String newJson,
  ) async {
    try {
      final existing = jsonDecode(existingJson) as List<dynamic>;
      final newMeds = jsonDecode(newJson) as List<dynamic>;
      
      final existingList = existing.cast<Map<String, dynamic>>();
      final newList = newMeds.cast<Map<String, dynamic>>();
      
      // Merge logic: add new medications
      final merged = List<Map<String, dynamic>>.from(existingList);
      
      for (final newMed in newList) {
        final exists = merged.any((m) => m['nom'] == newMed['nom']);
        if (!exists) {
          merged.add(newMed);
        }
      }
      
      return merged;
    } catch (e) {
      throw Exception('Failed to merge: $e');
    }
  }
}
```

---

## 🎨 Interface de configuration (settings_screen.dart)

```dart
import 'package:flutter/material.dart';
import '../services/github_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _repoController = TextEditingController();
  final _branchController = TextEditingController(text: 'main');
  final _filePathController = TextEditingController(
    text: 'assets/data/medications.json',
  );
  
  final _githubService = GitHubService();
  bool _isConfigured = false;

  @override
  void initState() {
    super.initState();
    _checkConfiguration();
  }

  Future<void> _checkConfiguration() async {
    final configured = await _githubService.isConfigured();
    setState(() {
      _isConfigured = configured;
    });
  }

  Future<void> _saveConfiguration() async {
    if (_formKey.currentState!.validate()) {
      try {
        await _githubService.saveCredentials(
          token: _tokenController.text.trim(),
          repositorySlug: _repoController.text.trim(),
          branch: _branchController.text.trim(),
          filePath: _filePathController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Configuration GitHub enregistrée'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration GitHub'),
        backgroundColor: Colors.teal,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_isConfigured)
              Card(
                color: Colors.green.shade50,
                child: const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('GitHub configuré'),
                ),
              ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _tokenController,
              decoration: const InputDecoration(
                labelText: 'Token GitHub',
                hintText: 'ghp_...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
              ),
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Token obligatoire';
                }
                return null;
              },
            ),
            const SizedBox(height: 8),
            const Text(
              'Créez un Personal Access Token sur GitHub avec les permissions "repo"',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _repoController,
              decoration: const InputDecoration(
                labelText: 'Repository',
                hintText: 'username/ped_app',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.folder),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Repository obligatoire';
                }
                if (!value.contains('/')) {
                  return 'Format: username/repository';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _branchController,
              decoration: const InputDecoration(
                labelText: 'Branche',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.source),
              ),
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _filePathController,
              decoration: const InputDecoration(
                labelText: 'Chemin du fichier',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.insert_drive_file),
              ),
            ),
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _saveConfiguration,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Enregistrer la configuration'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _repoController.dispose();
    _branchController.dispose();
    _filePathController.dispose();
    super.dispose();
  }
}
```

---

## 🔄 Modification de medication_list_screen.dart

Ajouter un bouton "Push vers GitHub" dans l'écran de liste :

```dart
// Dans la section actions de l'AppBar
IconButton(
  icon: const Icon(Icons.cloud_upload),
  onPressed: () => _pushToGitHub(context, provider),
),

// Nouvelle méthode
Future<void> _pushToGitHub(
  BuildContext context,
  MedicationProvider provider,
) async {
  final githubService = GitHubService();
  
  final isConfigured = await githubService.isConfigured();
  if (!isConfigured) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configuration requise'),
        content: const Text(
          'Veuillez d\'abord configurer GitHub dans les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    // Récupérer le contenu actuel
    final existingContent = await githubService.getCurrentFileContent();
    
    // Merger avec les nouveaux médicaments
    final newJson = provider.exportToJson();
    final merged = await githubService.mergeMedications(
      existingContent,
      newJson,
    );
    
    // Push vers GitHub
    final mergedJson = const JsonEncoder.withIndent('  ').convert(merged);
    await githubService.pushMedications(
      mergedJson,
      'Add ${provider.medications.length} medication(s) via Medication Editor',
    );
    
    Navigator.pop(context); // Fermer le loading
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Médicaments poussés vers GitHub avec succès'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    Navigator.pop(context); // Fermer le loading
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## 🎯 Workflow avec GitHub

### 1. Configuration initiale
1. Créer un Personal Access Token sur GitHub
2. Aller dans Paramètres de l'app
3. Renseigner les informations GitHub
4. Sauvegarder

### 2. Ajout de médicaments
1. Créer plusieurs médicaments
2. Aller dans "Voir les médicaments"
3. Cliquer sur "Push vers GitHub"
4. L'app va :
   - Récupérer le fichier actuel
   - Merger les nouveaux médicaments
   - Faire un commit automatique

### 3. Gestion des conflits
- L'app merge automatiquement les nouveaux médicaments
- Les médicaments existants ne sont pas modifiés
- Commit message automatique avec le nombre de médicaments

---

## 🔒 Sécurité

### Token GitHub
- Stocké dans SharedPreferences (encrypted sur iOS)
- Jamais affiché en clair
- Permissions minimales requises : `repo`

### Bonnes pratiques
- Ne jamais commiter le token dans le code
- Utiliser des tokens avec expiration
- Révoquer les tokens non utilisés

---

## 📝 Notes d'implémentation

1. **Installer les dépendances** :
   ```bash
   flutter pub add github http shared_preferences
   ```

2. **Créer les fichiers mentionnés** ci-dessus

3. **Ajouter le lien vers Settings** dans HomeScreen :
   ```dart
   IconButton(
     icon: const Icon(Icons.settings),
     onPressed: () {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (context) => const SettingsScreen(),
         ),
       );
     },
   )
   ```

4. **Tester en local** d'abord avec un repository de test

---

## ✅ Checklist d'implémentation

- [ ] Ajouter les dépendances
- [ ] Créer GitHubService
- [ ] Créer SettingsScreen
- [ ] Modifier MedicationListScreen
- [ ] Ajouter le bouton Settings dans HomeScreen
- [ ] Tester avec un repository test
- [ ] Gérer les erreurs de connexion
- [ ] Ajouter un indicateur de chargement
- [ ] Implémenter le retry en cas d'échec
- [ ] Documenter pour les utilisateurs

---

Cette fonctionnalité transformera l'application en un outil complet de gestion des médicaments avec synchronisation automatique !
