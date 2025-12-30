import 'package:flutter/material.dart';
import '../models/protocol_model.dart';
import '../services/protocol_editor_service.dart';
import '../widgets/block_editor_widgets.dart';

/// Écran de liste des protocoles
class ProtocolListScreen extends StatefulWidget {
  const ProtocolListScreen({super.key});

  @override
  State<ProtocolListScreen> createState() => _ProtocolListScreenState();
}

class _ProtocolListScreenState extends State<ProtocolListScreen> {
  final _service = ProtocolEditorService();
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProtocols();
  }

  Future<void> _loadProtocols() async {
    setState(() => _isLoading = true);
    await _service.loadProtocols();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final protocols = _searchQuery.isEmpty 
        ? _service.protocols 
        : _service.search(_searchQuery);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Protocoles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProtocols,
            tooltip: 'Actualiser',
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : protocols.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_outlined, 
                                size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Aucun protocole'
                                  : 'Aucun résultat',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
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
                            onTap: () => _openEditor(protocol),
                            onDuplicate: () => _duplicateProtocol(protocol),
                            onDelete: () => _deleteProtocol(protocol),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewProtocol,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau'),
      ),
    );
  }

  void _openEditor(Protocol protocol) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProtocolEditorScreen(protocol: protocol),
      ),
    );
    if (result == true) {
      _loadProtocols();
    }
  }

  void _createNewProtocol() {
    final newProtocol = _service.createNewProtocol();
    _openEditor(newProtocol);
  }

  void _duplicateProtocol(Protocol protocol) async {
    final duplicate = _service.duplicateProtocol(protocol);
    final success = await _service.saveProtocol(duplicate);
    if (success) {
      _loadProtocols();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Protocole dupliqué')),
        );
      }
    }
  }

  void _deleteProtocol(Protocol protocol) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le protocole ?'),
        content: Text('Voulez-vous vraiment supprimer "${protocol.titre}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _service.deleteProtocol(protocol);
      if (success) {
        _loadProtocols();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Protocole supprimé')),
          );
        }
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
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.description,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protocol.titre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (protocol.description != null && 
                        protocol.description!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          protocol.description!,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (protocol.version != null)
                          Chip(
                            label: Text('v${protocol.version}'),
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        Chip(
                          label: Text('${protocol.blocs.length} blocs'),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'duplicate':
                      onDuplicate();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'duplicate',
                    child: Row(
                      children: [
                        Icon(Icons.copy),
                        SizedBox(width: 12),
                        Text('Dupliquer'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Supprimer', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Écran d'édition d'un protocole
class ProtocolEditorScreen extends StatefulWidget {
  final Protocol protocol;

  const ProtocolEditorScreen({super.key, required this.protocol});

  @override
  State<ProtocolEditorScreen> createState() => _ProtocolEditorScreenState();
}

class _ProtocolEditorScreenState extends State<ProtocolEditorScreen> {
  final _service = ProtocolEditorService();
  late Protocol _protocol;
  bool _hasChanges = false;
  bool _isSaving = false;

  // Liste des noms de médicaments pour l'autocomplétion
  List<String> _medicamentNames = [];

  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late TextEditingController _auteurController;
  late TextEditingController _versionController;

  @override
  void initState() {
    super.initState();
    _protocol = widget.protocol;
    _titreController = TextEditingController(text: _protocol.titre);
    _descriptionController = TextEditingController(text: _protocol.description ?? '');
    _auteurController = TextEditingController(text: _protocol.auteur ?? '');
    _versionController = TextEditingController(text: _protocol.version ?? '1.0');
    _loadMedicamentNames();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _auteurController.dispose();
    _versionController.dispose();
    super.dispose();
  }

  Future<void> _loadMedicamentNames() async {
    // TODO: Charger depuis le service de médicaments
    // Pour l'instant, liste vide - sera connecté au service existant
    setState(() {
      _medicamentNames = [];
    });
  }

  void _updateProtocol() {
    setState(() {
      _protocol = _protocol.copyWith(
        titre: _titreController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        auteur: _auteurController.text.isEmpty ? null : _auteurController.text,
        version: _versionController.text.isEmpty ? null : _versionController.text,
      );
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_protocol.fileName == null ? 'Nouveau protocole' : 'Modifier'),
          actions: [
            if (_hasChanges)
              TextButton.icon(
                onPressed: _isSaving ? null : _saveProtocol,
                icon: _isSaving 
                    ? const SizedBox(
                        width: 16, 
                        height: 16, 
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Enregistrer'),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Métadonnées du protocole
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Informations générales',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titreController,
                        decoration: const InputDecoration(
                          labelText: 'Titre *',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => _updateProtocol(),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        onChanged: (_) => _updateProtocol(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _auteurController,
                              decoration: const InputDecoration(
                                labelText: 'Auteur',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _updateProtocol(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _versionController,
                              decoration: const InputDecoration(
                                labelText: 'Version',
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (_) => _updateProtocol(),
                            ),
                          ),
                        ],
                      ),
                      if (_protocol.fileName != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Fichier: ${_protocol.fileName}',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Blocs du protocole
              Row(
                children: [
                  const Text(
                    'Contenu du protocole',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _addBlock,
                    icon: const Icon(Icons.add),
                    label: const Text('Ajouter un bloc'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_protocol.blocs.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.add_box_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun bloc',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ajoutez des blocs pour construire votre protocole',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _protocol.blocs.length,
                  onReorder: _reorderBlocks,
                  itemBuilder: (context, index) {
                    final block = _protocol.blocs[index];
                    return BlockEditorWidget(
                      key: ValueKey('block_$index'),
                      block: block,
                      medicamentNames: _medicamentNames,
                      onChanged: (updated) => _updateBlock(index, updated),
                      onDelete: () => _deleteBlock(index),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addBlock() async {
    final type = await showDialog<BlockType>(
      context: context,
      builder: (_) => const BlockTypeSelectorDialog(),
    );

    if (type == null) return;

    final newBlock = createBlockOfType(type, _protocol.blocs.length);
    setState(() {
      _protocol = _protocol.copyWith(
        blocs: [..._protocol.blocs, newBlock],
      );
      _hasChanges = true;
    });
  }

  void _updateBlock(int index, ProtocolBlock updated) {
    final updatedBlocs = List<ProtocolBlock>.from(_protocol.blocs);
    updatedBlocs[index] = updated;
    setState(() {
      _protocol = _protocol.copyWith(blocs: updatedBlocs);
      _hasChanges = true;
    });
  }

  void _deleteBlock(int index) {
    final updatedBlocs = List<ProtocolBlock>.from(_protocol.blocs)..removeAt(index);
    // Mettre à jour les ordres
    for (int i = 0; i < updatedBlocs.length; i++) {
      updatedBlocs[i] = updatedBlocs[i].copyWithOrdre(i);
    }
    setState(() {
      _protocol = _protocol.copyWith(blocs: updatedBlocs);
      _hasChanges = true;
    });
  }

  void _reorderBlocks(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final updatedBlocs = List<ProtocolBlock>.from(_protocol.blocs);
    final item = updatedBlocs.removeAt(oldIndex);
    updatedBlocs.insert(newIndex, item);
    // Mettre à jour les ordres
    for (int i = 0; i < updatedBlocs.length; i++) {
      updatedBlocs[i] = updatedBlocs[i].copyWithOrdre(i);
    }
    setState(() {
      _protocol = _protocol.copyWith(blocs: updatedBlocs);
      _hasChanges = true;
    });
  }

  Future<void> _saveProtocol() async {
    if (_titreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await _service.saveProtocol(_protocol);

    setState(() => _isSaving = false);

    if (success) {
      setState(() => _hasChanges = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Protocole enregistré')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifications non enregistrées'),
        content: const Text('Voulez-vous enregistrer vos modifications ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop('discard'),
            child: const Text('Abandonner'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop('cancel'),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop('save'),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    switch (result) {
      case 'save':
        await _saveProtocol();
        return true;
      case 'discard':
        return true;
      default:
        return false;
    }
  }
}