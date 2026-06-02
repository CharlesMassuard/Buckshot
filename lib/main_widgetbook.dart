import 'package:buckshot/widgets/BarreDeNavigation.dart';
import 'package:buckshot/widgets/ShotGunBanner.dart';
import 'package:buckshot/widgets/ShotGunItem.dart';
import 'package:flutter/material.dart';
import 'package:buckshot/widgets/BarreDeRecherche.dart';

void main() {
  runApp(const MonCatalogueApp());
}


class MonCatalogueApp extends StatefulWidget {
  const MonCatalogueApp({super.key});

  @override
  State<MonCatalogueApp> createState() => _MonCatalogueAppState();
}

class _MonCatalogueAppState extends State<MonCatalogueApp> {

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
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
                const BarreDeRecherche(),
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
                  description:
                      'Rejoignez-nous pour une soirée de musique et de danse !',
                  date: '21/06',
                  hours: '18h - Minuit',
                  imageUrl: 'assets/soiree.png',
                  height: 120.0,
                  width: 300,
                ),
              ),

              _wrapCentred(
                const ShotgunItem(
                  title: "Soirée fin d'année",
                  description:
                      'Libérez votre créativité avec nos ateliers de peinture pour tous les âges.',
                  date: '15/07',
                  hours: '10h - 16h',
                  imageUrl: 'assets/soiree.png',
                  height: 160.0,
                  width: 120.0,
                ),
              ),

              const Divider(height: 40),

              _sectionTitle("Barre de navigation"),

              _wrapCentred(
                BarreDeNavigation(
                  currentIndex: currentIndex,

                  onItemSelected: (index) {
                    setState(() {
                      currentIndex = index;
                    });
                  },

                  items: [
                    NavItem(
                      icon: Icons.home,
                      label: "Accueil",
                      onTap: () {
                        debugPrint("Aller sur la page Accueil");
                      },
                    ),

                    NavItem(
                      icon: Icons.mood,
                      label: "Joyeux",
                      onTap: () {
                        debugPrint("Aller sur la page Joyeux");
                      },
                    ),

                    NavItem(
                      icon: Icons.sentiment_dissatisfied,
                      label: "",
                      onTap: () {
                        debugPrint("Aller sur la page Triste");
                      },
                    ),
                  ],
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
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
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
  