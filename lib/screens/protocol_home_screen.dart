import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/protocol_provider.dart';
import 'protocol_general_info_screen.dart';
import 'protocol_list_screen.dart';

class ProtocolHomeScreen extends StatefulWidget {
  const ProtocolHomeScreen({super.key});

  @override
  State<ProtocolHomeScreen> createState() => _ProtocolHomeScreenState();
}

class _ProtocolHomeScreenState extends State<ProtocolHomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProtocolsFromGitHub();
  }

  Future<void> _loadProtocolsFromGitHub() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await Provider.of<ProtocolProvider>(context, listen: false)
          .loadAllProtocolsFromGitHub();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Protocoles chargés depuis GitHub'),
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
          title: const Text('Éditeur de Protocoles'),
          backgroundColor: Colors.blue,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement des protocoles depuis GitHub...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditeur de Protocoles'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProtocolsFromGitHub,
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
              Icon(
                Icons.description,
                size: 100,
                color: Colors.blue.shade300,
              ),
              const SizedBox(height: 32),
              const Text(
                'Éditeur de Protocoles',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Consumer<ProtocolProvider>(
                builder: (context, provider, child) {
                  return Text(
                    '${provider.protocols.length} protocole(s) chargé(s)',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 300,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Provider.of<ProtocolProvider>(context, listen: false)
                        .startNewProtocol();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProtocolGeneralInfoScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Nouveau protocole'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 300,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ProtocolListScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.list),
                  label: const Text('Voir les protocoles'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                    side: const BorderSide(color: Colors.blue, width: 2),
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