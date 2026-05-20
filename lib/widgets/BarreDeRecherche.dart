import 'package:flutter/material.dart';

class BarreDeRecherche extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const BarreDeRecherche({
    super.key,
    this.controller,
    this.onChanged,
  });

  @override
  State<BarreDeRecherche> createState() => _BarreDeRechercheState();
}

class _BarreDeRechercheState extends State<BarreDeRecherche> {
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _internalController,
      constraints: const BoxConstraints(
        maxWidth: 400.0,
        minHeight: 45.0,
        maxHeight: 45.0,
      ),
      hintText: 'Rechercher un élément...',
      hintStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.grey),
      ),
      trailing: [
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.grey),
          onPressed: () {
            _internalController.clear();
            if (widget.onChanged != null) widget.onChanged!('');
          },
        ),
      ],
      onChanged: (value) {
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
        if (value.length > 1) {
          debugPrint('Texte recherché : $value');
        }
      },
      elevation: WidgetStateProperty.all(2.0),
      backgroundColor: WidgetStateProperty.all(const Color(0xFF161224)),
      textStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white),
      ),
    );
  }
}