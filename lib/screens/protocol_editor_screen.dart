import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/protocol_model.dart';
import '../services/protocol_provider.dart';
import '../services/medication_provider.dart';
import '../widgets/block_editor_widget.dart';
import '../widgets/editors/block_factory.dart';
import '../widgets/editors/block_type_selector.dart';

// ============================================================================
// ÉCRAN 1 : LISTE DES PROTOCOLES (Inchangé ou presque, inclus pour contexte)
// ============================================================================
class ProtocolListScreen extends StatefulWidget {
  const ProtocolListScreen({super.key});

  @override
  State<ProtocolListScreen> createState() => _ProtocolListScreenState();
}

class _ProtocolListScreenState extends State<ProtocolListScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<ProtocolProvider>(context, listen: false);
      if (provider.protocols.isEmpty) {
        provider.loadAllProtocolsFromGitHub();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ProtocolProvider>(context);
    final allProtocols = provider.protocols;

    final protocols = _searchQuery.isEmpty
        ? allProtocols
        : allProtocols
            .where((p) =>
                p.titre.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocoles (GitHub)'),
        backgroundColor: Colors.teal,
        actions: [
          if (provider.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2)),
            )
          else
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => provider.loadAllProtocolsFromGitHub(),
              tooltip: 'Actualiser depuis GitHub',
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un protocole...',
                prefixIcon: const Icon(Icons.search),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: protocols.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          provider.isLoading
                              ? 'Chargement...'
                              : 'Aucun protocole trouvé',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: protocols.length,
                    itemBuilder: (context, index) {
                      final protocol = protocols[index];
                      return _ProtocolCard(
                        protocol: protocol,
                        onTap: () => _openEditor(context, protocol),
                        onDuplicate: () async {
                          final newProto = provider.duplicateProtocol(protocol);
                          await provider.saveProtocol(newProto);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Protocole dupliqué !')));
                          }
                        },
                        onDelete: () =>
                            _confirmDelete(context, provider, protocol),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final newProto = provider.createNewProtocol();
          _openEditor(context, newProto);
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }

  void _openEditor(BuildContext context, Protocol protocol) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProtocolEditorScreen(protocol: protocol),
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProtocolProvider provider,
      Protocol protocol) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ?'),
        content: Text(
            'Voulez-vous vraiment supprimer "${protocol.titre}" de GitHub ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Supprimer')),
        ],
      ),
    );

    if (confirm == true) {
      final success = await provider.deleteProtocol(protocol);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Protocole supprimé'
                : 'Erreur lors de la suppression'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }
}

class _ProtocolCard extends StatelessWidget {
  final Protocol protocol;
  final VoidCallback onTap;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  const _ProtocolCard({
    required this.protocol,
    required this.onTap,
    required this.onDuplicate,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.description, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (protocol.description != null &&
                        protocol.description!.isNotEmpty)
                      Text(
                        protocol.description!,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'duplicate') onDuplicate();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(children: [
                        Icon(Icons.copy, size: 20),
                        SizedBox(width: 8),
                        Text('Dupliquer')
                      ])),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Row(children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Supprimer', style: TextStyle(color: Colors.red))
                      ])),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ÉCRAN 2 : ÉDITEUR DE PROTOCOLE - ARCHITECTURE SLIVER OPTIMISÉE
// ============================================================================

class ProtocolEditorScreen extends StatefulWidget {
  final Protocol protocol;

  const ProtocolEditorScreen({super.key, required this.protocol});

  @override
  State<ProtocolEditorScreen> createState() => _ProtocolEditorScreenState();
}

class _ProtocolEditorScreenState extends State<ProtocolEditorScreen> {
  late Protocol _protocol;
  bool _hasChanges = false;

  // Controllers pour les métadonnées
  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late TextEditingController _auteurController;
  late TextEditingController _versionController;

  @override
  void initState() {
    super.initState();
    _protocol = widget.protocol;
    _titreController = TextEditingController(text: _protocol.titre);
    _descriptionController =
        TextEditingController(text: _protocol.description ?? '');
    _auteurController = TextEditingController(text: _protocol.auteur ?? '');
    _versionController =
        TextEditingController(text: _protocol.version ?? '1.0');
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _auteurController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  void _updateMeta() {
    setState(() {
      _protocol = _protocol.copyWith(
        titre: _titreController.text,
        description: _descriptionController.text,
        auteur: _auteurController.text,
        version: _versionController.text,
      );
      _hasChanges = true;
    });
  }

  Future<void> _save(BuildContext context) async {
    if (_titreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Le titre est obligatoire')));
      return;
    }

    final provider = Provider.of<ProtocolProvider>(context, listen: false);
    final success = await provider.saveProtocol(_protocol);

    if (success) {
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Sauvegardé sur GitHub !'),
            backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur de sauvegarde'),
            backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le MedicationProvider pour l'autocomplétion
    final medicationProvider = Provider.of<MedicationProvider>(context);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        if (!_hasChanges) return true;
        final ret = await showDialog<String>(
            context: context,
            builder: (ctx) => AlertDialog(
                  title: const Text('Modifications non enregistrées'),
                  content:
                      const Text('Voulez-vous enregistrer avant de quitter ?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, 'cancel'),
                        child: const Text('Annuler')),
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, 'discard'),
                        child: const Text('Ne pas enregistrer',
                            style: TextStyle(color: Colors.red))),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, 'save'),
                        child: const Text('Enregistrer')),
                  ],
                ));
        if (ret == 'save') {
          await _save(context);
          return true;
        }
        return ret == 'discard';
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100, // Fond légèrement grisé
        body: CustomScrollView(
          // Utilisation de Slivers pour la performance
          slivers: [
            // 1. App Bar Sliver
            SliverAppBar(
              title: Text(_protocol.fileName == null ? 'Nouveau' : 'Modifier'),
              floating: true,
              pinned: true,
              actions: [
                Consumer<ProtocolProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Padding(
                          padding: EdgeInsets.only(right: 16),
                          child: Center(
                              child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))));
                    }
                    return TextButton.icon(
                      onPressed: _hasChanges ? () => _save(context) : null,
                      icon: const Icon(Icons.save),
                      label: const Text('Enregistrer'),
                      style: TextButton.styleFrom(
                        foregroundColor: _hasChanges
                            ? Colors.white
                            : Colors.white.withOpacity(0.5),
                      ),
                    );
                  },
                ),
              ],
            ),

            // 2. Métadonnées (Box Adapter)
            SliverToBoxAdapter(
              child: Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Infos Générales',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      TextField(
                          controller: _titreController,
                          decoration: const InputDecoration(labelText: 'Titre *'),
                          onChanged: (_) => _updateMeta()),
                      const SizedBox(height: 8),
                      TextField(
                          controller: _descriptionController,
                          decoration:
                              const InputDecoration(labelText: 'Description'),
                          maxLines: 2,
                          onChanged: (_) => _updateMeta()),
                      const SizedBox(height: 8),
                      Row(children: [
                        Expanded(
                            child: TextField(
                                controller: _auteurController,
                                decoration:
                                    const InputDecoration(labelText: 'Auteur'),
                                onChanged: (_) => _updateMeta())),
                        const SizedBox(width: 8),
                        Expanded(
                            child: TextField(
                                controller: _versionController,
                                decoration:
                                    const InputDecoration(labelText: 'Version'),
                                onChanged: (_) => _updateMeta())),
                      ]),
                    ],
                  ),
                ),
              ),
            ),

            // 3. Header "Contenu"
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text('Contenu du protocole',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: _addBlock,
                      icon: const Icon(Icons.add),
                      label: const Text('Ajouter un bloc'),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Liste des blocs (SliverReorderableList)
            if (_protocol.blocs.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                    child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                            'Aucun bloc. Ajoutez-en un pour commencer !',
                            style: TextStyle(color: Colors.grey)))),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverReorderableList(
                  itemCount: _protocol.blocs.length,
                  onReorder: _reorderBlocks,
                  itemBuilder: (context, index) {
                    final block = _protocol.blocs[index];
                    // IMPORTANT : ReorderableDragStartListener est nécessaire ici
                    return ReorderableDragStartListener(
                      key: ValueKey('block_${block.hashCode}'),
                      index: index,
                      child: BlockEditorWidget(
                        block: block,
                        medicationProvider: medicationProvider,
                        onChanged: (updated) => _updateBlock(index, updated),
                        onDelete: () => _deleteBlock(index),
                      ),
                    );
                  },
                ),
              ),
              
            // 5. Marge de fin pour éviter que le FAB ou le bas de l'écran ne cache le dernier élément
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // --- LOGIQUE D'EDITION DES BLOCS ---

  Future<void> _addBlock() async {
    final type = await showDialog<BlockType>(
        context: context, builder: (_) => const BlockTypeSelectorDialog());
    if (type == null) return;

    setState(() {
      _protocol = _protocol.copyWith(
          blocs: [..._protocol.blocs, createBlockOfType(type, _protocol.blocs.length)]);
      _hasChanges = true;
    });
  }

  void _updateBlock(int index, ProtocolBlock updated) {
    final newBlocs = List<ProtocolBlock>.from(_protocol.blocs);
    newBlocs[index] = updated;
    setState(() {
      _protocol = _protocol.copyWith(blocs: newBlocs);
      _hasChanges = true;
    });
  }

  void _deleteBlock(int index) {
    final newBlocs = List<ProtocolBlock>.from(_protocol.blocs)..removeAt(index);
    // Réindexer
    for (int i = 0; i < newBlocs.length; i++) {
      newBlocs[i] = newBlocs[i].copyWithOrdre(i);
    }
    setState(() {
      _protocol = _protocol.copyWith(blocs: newBlocs);
      _hasChanges = true;
    });
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final newBlocs = List<ProtocolBlock>.from(_protocol.blocs);
    final item = newBlocs.removeAt(oldIndex);
    newBlocs.insert(newIndex, item);
    // Réindexer
    for (int i = 0; i < newBlocs.length; i++) {
      newBlocs[i] = newBlocs[i].copyWithOrdre(i);
    }
    setState(() {
      _protocol = _protocol.copyWith(blocs: newBlocs);
      _hasChanges = true;
    });
  }
}