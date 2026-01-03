import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';

class TexteBlockEditor extends StatefulWidget {
  final TexteBlock block;
  final Function(ProtocolBlock) onChanged;

  const TexteBlockEditor({
    super.key, 
    required this.block, 
    required this.onChanged
  });

  @override
  State<TexteBlockEditor> createState() => _TexteBlockEditorState();
}

class _TexteBlockEditorState extends State<TexteBlockEditor> {
  late TextEditingController _contenuController;
  late TexteFormat _format;

  @override
  void initState() {
    super.initState();
    _contenuController = TextEditingController(text: widget.block.contenu);
    _format = widget.block.format ?? TexteFormat();
  }

  @override
  void didUpdateWidget(TexteBlockEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.block.contenu != oldWidget.block.contenu &&
        widget.block.contenu != _contenuController.text) {
      _contenuController.text = widget.block.contenu;
      // Garder le curseur à la fin si possible
      _contenuController.selection = TextSelection.fromPosition(
          TextPosition(offset: _contenuController.text.length));
    }
    if (widget.block.format != oldWidget.block.format) {
      _format = widget.block.format ?? TexteFormat();
    }
  }

  @override
  void dispose() {
    _contenuController.dispose();
    super.dispose();
  }

  void _updateBlock() {
    widget.onChanged(widget.block.copyWith(
      contenu: _contenuController.text, 
      format: _format
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 4,
          children: [
            _FormatToggle(
                icon: Icons.format_bold,
                isActive: _format.gras,
                activeColor: colorScheme.primary,
                onToggle: () {
                  setState(() => _format = _format.copyWith(gras: !_format.gras));
                  _updateBlock();
                }),
            _FormatToggle(
                icon: Icons.format_italic,
                isActive: _format.italique,
                activeColor: colorScheme.primary,
                onToggle: () {
                  setState(() => _format = _format.copyWith(italique: !_format.italique));
                  _updateBlock();
                }),
            _FormatToggle(
                icon: Icons.format_underline,
                isActive: _format.souligne,
                activeColor: colorScheme.primary,
                onToggle: () {
                  setState(() => _format = _format.copyWith(souligne: !_format.souligne));
                  _updateBlock();
                }),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _contenuController,
          decoration: const InputDecoration(
              labelText: 'Contenu',
              border: OutlineInputBorder(),
              alignLabelWithHint: true),
          maxLines: 5,
          onChanged: (_) => _updateBlock(),
        ),
      ],
    );
  }
}

class _FormatToggle extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onToggle;
  final Color activeColor;

  const _FormatToggle({
    required this.icon,
    required this.isActive,
    required this.onToggle,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon),
      onPressed: onToggle,
      color: isActive ? activeColor : Colors.grey,
      style: IconButton.styleFrom(
          backgroundColor: isActive ? activeColor.withOpacity(0.1) : null),
    );
  }
}