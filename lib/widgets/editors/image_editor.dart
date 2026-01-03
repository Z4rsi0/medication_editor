import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/protocol_model.dart';

class ImageBlockEditor extends StatefulWidget {
  final ImageBlock block;
  final Function(ProtocolBlock) onChanged;

  const ImageBlockEditor(
      {super.key, required this.block, required this.onChanged});

  @override
  State<ImageBlockEditor> createState() => _ImageBlockEditorState();
}

class _ImageBlockEditorState extends State<ImageBlockEditor> {
  late TextEditingController _legendeController;
  late TextEditingController _urlController;
  late int _largeur;
  bool _isBase64 = false;
  String _base64Data = '';

  @override
  void initState() {
    super.initState();
    _initValues();
  }

  void _initValues() {
    _legendeController = TextEditingController(text: widget.block.legende ?? '');
    _urlController = TextEditingController(
        text: widget.block.estBase64 ? '' : widget.block.source);
    _largeur = widget.block.largeurPourcent ?? 100;
    _isBase64 = widget.block.estBase64;
    if (_isBase64) _base64Data = widget.block.source;
  }

  @override
  void didUpdateWidget(ImageBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block != oldWidget.block) {
      if ((widget.block.legende ?? '') != _legendeController.text) {
        _legendeController.text = widget.block.legende ?? '';
      }
      if (!widget.block.estBase64 && widget.block.source != _urlController.text) {
        _urlController.text = widget.block.source;
      }
      if (widget.block.largeurPourcent != _largeur) {
        _largeur = widget.block.largeurPourcent ?? 100;
      }
    }
  }

  @override
  void dispose() {
    _legendeController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      source: _isBase64 ? _base64Data : _urlController.text,
      estBase64: _isBase64,
      legende: _legendeController.text.isEmpty ? null : _legendeController.text,
      largeurPourcent: _largeur,
    ));
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      setState(() {
        _base64Data = base64Encode(bytes);
        _isBase64 = true;
      });
      _updateBlock();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
                value: false, label: Text('URL'), icon: Icon(Icons.link)),
            ButtonSegment(
                value: true,
                label: Text('Fichier'),
                icon: Icon(Icons.file_upload)),
          ],
          selected: {_isBase64},
          onSelectionChanged: (set) {
            setState(() {
              _isBase64 = set.first;
              _updateBlock();
            });
          },
        ),
        const SizedBox(height: 12),
        if (_isBase64) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.image),
            label: Text(_base64Data.isEmpty
                ? 'Sélectionner une image'
                : 'Image chargée ✓'),
            onPressed: _pickImage,
          ),
          if (_base64Data.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              height: 100,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(base64Decode(_base64Data),
                      fit: BoxFit.contain)),
            ),
          ],
        ] else
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
                labelText: 'URL de l\'image',
                hintText: 'https://...',
                border: OutlineInputBorder()),
            onChanged: (_) => _updateBlock(),
          ),
        const SizedBox(height: 12),
        TextField(
          controller: _legendeController,
          decoration: const InputDecoration(
              labelText: 'Légende (optionnel)', border: OutlineInputBorder()),
          onChanged: (_) => _updateBlock(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Text('Largeur: '),
            Expanded(
              child: Slider(
                  value: _largeur.toDouble(),
                  min: 20,
                  max: 100,
                  divisions: 8,
                  label: '$_largeur%',
                  onChanged: (v) {
                    setState(() => _largeur = v.round());
                    _updateBlock();
                  }),
            ),
            Text('$_largeur%'),
          ],
        ),
      ],
    );
  }
}