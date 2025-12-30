import 'package:flutter/material.dart';
import 'screens/protocol_editor_screen.dart';

void main() {
  runApp(const MedicationEditorApp());
}

class MedicationEditorApp extends StatelessWidget {
  const MedicationEditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medication Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const _MedicamentsPlaceholder(), // À remplacer par l'écran existant
    const ProtocolListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Médicaments',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Protocoles',
          ),
        ],
      ),
    );
  }
}

/// Placeholder pour l'écran des médicaments existant
class _MedicamentsPlaceholder extends StatelessWidget {
  const _MedicamentsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Médicaments'),
      ),
      body: const Center(
        child: Text(
          'Écran des médicaments existant\n(À intégrer)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}