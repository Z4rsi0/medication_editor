import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../services/protocol_provider.dart';
import 'medication_list_screen.dart';
import 'general_info_screen.dart';
import 'protocol_home_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicationsFromGitHub();
  }

  Future<void> _loadMedicationsFromGitHub() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<MedicationProvider>(context, listen: false)
          .loadFromGitHub();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Médicaments chargés depuis GitHub'),
            backgroundColor: Colors.green,
          ),
        );
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Éditeur Médical'),
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des médicaments depuis GitHub...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditeur Médical'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMedicationsFromGitHub,
            tooltip: 'Recharger depuis GitHub',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // En-tête
              Icon(
                Icons.medical_services,
                size: 100,
                color: Colors.teal.shade300,
              ),
              const SizedBox(height: 32),
              const Text(
                'Éditeur Médical',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gestion des médicaments et protocoles',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Section Médicaments
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.medication,
                            size: 40,
                            color: Colors.teal.shade400,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Médicaments',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Créer et gérer les fiches médicaments',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<MedicationProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            '${provider.medications.length} médicament(s) chargé(s)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Provider.of<MedicationProvider>(context,
                                        listen: false)
                                    .startNewMedication();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const GeneralInfoScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Nouveau'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const MedicationListScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.list),
                              label: const Text('Liste'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.teal,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: const BorderSide(
                                    color: Colors.teal, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Section Protocoles
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.description,
                            size: 40,
                            color: Colors.blue.shade400,
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Protocoles',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Créer et gérer les protocoles cliniques',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProtocolProvider>(
                        builder: (context, provider, child) {
                          return Text(
                            '${provider.protocols.length} protocole(s) chargé(s)',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ProtocolHomeScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          label: const Text('Gérer les protocoles'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}