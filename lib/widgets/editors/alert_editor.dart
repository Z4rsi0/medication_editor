import 'package:flutter/material.dart';
import '../../models/protocol_model.dart';

class AlerteBlockEditor extends StatefulWidget {
  final AlerteBlock block;
  final Function(ProtocolBlock) onChanged;

  const AlerteBlockEditor(
      {super.key, required this.block, required this.onChanged});

  @override
  State<AlerteBlockEditor> createState() => _AlerteBlockEditorState();
}

class _AlerteBlockEditorState extends State<AlerteBlockEditor> {
  late TextEditingController _contenuController;

  @override
  void initState() {
    super.initState();
    _contenuController = TextEditingController(text: widget.block.contenu);
  }

  @override
  void dispose() {
    _contenuController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<AlerteNiveau>(
          value: widget.block.niveau,
          decoration: const InputDecoration(
              labelText: 'Niveau d\'alerte', border: OutlineInputBorder()),
          items: AlerteNiveau.values
              .map((n) => DropdownMenuItem(
                    value: n,
                    child: Row(
                      children: [
                        Icon(_getAlertIcon(n),
                            color: _getAlertColor(n), size: 20),
                        const SizedBox(width: 8),
                        Text(_getAlertLabel(n)),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) widget.onChanged(widget.block.copyWith(niveau: v));
          },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contenuController,
          decoration: const InputDecoration(
              labelText: 'Contenu de l\'alerte',
              border: OutlineInputBorder(),
              alignLabelWithHint: true),
          maxLines: 3,
          onChanged: (_) => widget.onChanged(
              widget.block.copyWith(contenu: _contenuController.text)),
        ),
      ],
    );
  }

  IconData _getAlertIcon(AlerteNiveau niveau) {
    switch (niveau) {
      case AlerteNiveau.info:
        return Icons.info;
      case AlerteNiveau.attention:
        return Icons.warning_amber;
      case AlerteNiveau.danger:
        return Icons.error;
      case AlerteNiveau.critique:
        return Icons.dangerous;
    }
  }

  Color _getAlertColor(AlerteNiveau niveau) {
    switch (niveau) {
      case AlerteNiveau.info:
        return Colors.blue;
      case AlerteNiveau.attention:
        return Colors.orange;
      case AlerteNiveau.danger:
        return Colors.deepOrange;
      case AlerteNiveau.critique:
        return Colors.red;
    }
  }

  String _getAlertLabel(AlerteNiveau niveau) {
    switch (niveau) {
      case AlerteNiveau.info:
        return 'Information';
      case AlerteNiveau.attention:
        return 'Attention';
      case AlerteNiveau.danger:
        return 'Danger';
      case AlerteNiveau.critique:
        return 'Critique';
    }
  }
}