import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/home_screen.dart';
import 'services/medication_provider.dart';
import 'services/protocol_provider.dart';
import 'services/github_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
    await GitHubService().initialize();
  } catch (e) {
    debugPrint("⚠️ Erreur d'initialisation (.env ou GitHub): $e");
  }

  runApp(const MedicationEditorApp());
}

class MedicationEditorApp extends StatelessWidget {
  const MedicationEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MedicationProvider()),
        ChangeNotifierProvider(create: (_) => ProtocolProvider()),
      ],
      child: MaterialApp(
        title: 'Éditeur Médical',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // J'ai retiré cardTheme pour corriger ton erreur de compilation spécifique.
          // Le style par défaut s'appliquera.
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}