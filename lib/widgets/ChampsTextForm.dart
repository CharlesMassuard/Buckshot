import 'package:flutter/material.dart';

class ChampsTextForm extends StatefulWidget {
  const ChampsTextForm({super.key});

  @override
  State<ChampsTextForm> createState() => _ChampsTextFormState();
}

class _ChampsTextFormState extends State<ChampsTextForm> {

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextFormField(
      style: TextStyle(color: colors.onSurface ),
      decoration: InputDecoration(
        labelStyle: TextStyle( color:colors.onSurfaceVariant),
        filled: true,
        fillColor: colors.surface,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.surfaceVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.onPrimary)
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error)
        ),
      ),
    );

  }

}