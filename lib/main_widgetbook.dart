import 'package:buckshot/widgets/ShotGunBanner.dart';
import 'package:flutter/material.dart';
// Ajuste le chemin de l'import selon ton projet :
import 'package:buckshot/widgets/BarreDeRecherche.dart';

void main() {
  runApp(const MonCatalogueApp());
}

class MonCatalogueApp extends StatelessWidget {
  const MonCatalogueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(), // Style un peu "Buckshot" 
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Catalogue des Composants - Buckshot'),
          backgroundColor: Colors.green,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [


              
              _sectionTitle('Barre de Recherche'),
              _wrapCentred(
                const MaBarreDeRecherche(),
              ),


              const Divider(height: 40),


              _sectionTitle('Boutons'),
              _wrapCentred(
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Bouton Principal'),
                ),
              ),
              

              const Divider(height: 40),
              

              _sectionTitle('Cartes / Layouts'),
              _wrapCentred(
                const ShotgunBanner(
                  title: 'Fête de la Musique',
                  description: 'Rejoignez-nous pour une soirée de musique et de danse !',
                  date: '21/06',
                  hours: '18h - Minuit',
                  imageUrl: 'assets/soiree.png', //L'image ne fonctionne pas encore a tous les coups
                  height: 120.0,
                  width: 300,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      key: ValueKey(title),
      child: Text(
        title,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  Widget _wrapCentred(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: child),
    );
  }
}