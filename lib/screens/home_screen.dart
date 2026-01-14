import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/medication_provider.dart';
import '../services/protocol_provider.dart';
import 'medication_list_screen.dart';
import 'general_info_screen.dart'; 
import 'protocol_editor_screen.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDataFromGitHub();
    });
  }

  Future<void> _loadDataFromGitHub() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      if (mounted) {
        await Provider.of<MedicationProvider>(context, listen: false).loadFromGitHub();
      }
      
      if (mounted) {
        // Charge TOUS les protocoles (Standards + Pocus)
        await Provider.of<ProtocolProvider>(context, listen: false).loadAllProtocolsFromGitHub();
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Données chargées depuis GitHub'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Note: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditeur Médical'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadDataFromGitHub,
            tooltip: 'Recharger depuis GitHub',
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // --- 1. MÉDICAMENTS ---
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.medication, size: 40, color: Colors.teal.shade400),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Médicaments', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Doses et posologies pédiatriques', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<MedicationProvider>(
                        builder: (context, provider, child) {
                          return Text('${provider.medications.length} médicament(s)', style: const TextStyle(color: Colors.grey));
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Provider.of<MedicationProvider>(context, listen: false).startNewMedication();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneralInfoScreen()));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Nouveau'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationListScreen())),
                              icon: const Icon(Icons.list),
                              label: const Text('Liste'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: const BorderSide(color: Colors.teal)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 2. PROTOCOLES (STANDARDS) ---
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.description, size: 40, color: Colors.blue),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Protocoles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Soins et procédures standards', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProtocolProvider>(
                        builder: (context, provider, child) {
                          // Compteur filtré
                          return Text('${provider.standardProtocols.length} protocole(s)', style: const TextStyle(color: Colors.grey));
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final provider = Provider.of<ProtocolProvider>(context, listen: false);
                                final newProtocol = provider.createNewProtocol();
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolEditorScreen(protocol: newProtocol)));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Nouveau'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context, 
                                // Mode Standard
                                MaterialPageRoute(builder: (_) => const ProtocolListScreen(isPocusMode: false))
                              ),
                              icon: const Icon(Icons.list),
                              label: const Text('Liste'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.blue, side: const BorderSide(color: Colors.blue)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // --- 3. POCUS (NOUVEAU) ---
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.waves, size: 40, color: Colors.teal), // Icône Pocus
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('POCUS', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                Text('Échographie clinique', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Consumer<ProtocolProvider>(
                        builder: (context, provider, child) {
                          // Compteur filtré
                          return Text('${provider.pocusProtocols.length} fiche(s) écho', style: const TextStyle(color: Colors.grey));
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                final provider = Provider.of<ProtocolProvider>(context, listen: false);
                                // Création avec pré-remplissage POCUS
                                var newProtocol = provider.createNewProtocol();
                                newProtocol = newProtocol.copyWith(categorie: 'POCUS');
                                
                                Navigator.push(context, MaterialPageRoute(builder: (_) => ProtocolEditorScreen(protocol: newProtocol)));
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Nouveau'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                context, 
                                // Mode Pocus
                                MaterialPageRoute(builder: (_) => const ProtocolListScreen(isPocusMode: true))
                              ),
                              icon: const Icon(Icons.list),
                              label: const Text('Liste'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.teal, side: const BorderSide(color: Colors.teal)),
                            ),
                          ),
                        ],
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