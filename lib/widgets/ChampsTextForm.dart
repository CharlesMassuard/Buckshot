import 'package:flutter/material.dart';

class ChampsTextForm extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscureText;

  const ChampsTextForm({
    super.key,
    required this.label,
    required this.controller,
    this.obscureText = false,
  });

  @override
  State<ChampsTextForm> createState() => _ChampsTextFormState();
}

class _ChampsTextFormState extends State<ChampsTextForm> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surface,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error, width: 2),
        ),
      ),
    );
  }
}