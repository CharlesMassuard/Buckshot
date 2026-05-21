import 'package:flutter/material.dart';

class BarreDeRecherche extends StatefulWidget {
  const BarreDeRecherche({super.key});

  @override
  State<BarreDeRecherche> createState() => _BarreDeRechercheState();
}

class _BarreDeRechercheState extends State<BarreDeRecherche> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SearchBar(
      controller: _searchController,
      // On définit ici la taille de la barre
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
          icon: const Icon(Icons.clear),
          onPressed: () => _searchController.clear(),
        ),
      ],
      onChanged: (value) {
        if (value.length > 1) {
          debugPrint('Texte recherché : $value');
        }
      },
      elevation: WidgetStateProperty.all(2.0),
      backgroundColor: WidgetStateProperty.all(Colors.grey[800]),
      textStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white),
      ),
    );
  }
}