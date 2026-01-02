import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DoseInputWidget extends StatelessWidget {
  final String unite;
  final bool useDoseRange;
  
  // Controllers
  final TextEditingController? doseController;
  final TextEditingController? minController;
  final TextEditingController? maxController;

  const DoseInputWidget({
    super.key,
    required this.unite,
    required this.useDoseRange,
    this.doseController,
    this.minController,
    this.maxController,
  });

  @override
  Widget build(BuildContext context) {
    if (useDoseRange) {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: minController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Dose Min ($unite)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) =>
                  useDoseRange && (value == null || value.trim().isEmpty)
                      ? 'Requis'
                      : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: maxController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Dose Max ($unite)',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              validator: (value) =>
                  useDoseRange && (value == null || value.trim().isEmpty)
                      ? 'Requis'
                      : null,
            ),
          ),
        ],
      );
    } else {
      return TextFormField(
        controller: doseController,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: 'Dose ($unite)',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        validator: (value) =>
            !useDoseRange && (value == null || value.trim().isEmpty)
                ? 'Requis'
                : null,
      );
    }
  }
}