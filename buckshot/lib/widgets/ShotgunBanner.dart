import 'package:flutter/material.dart';

class ShotgunBanner extends StatelessWidget {
  final String title;
  final String description;
  final String date;
  final String hours;
  final String imageUrl;
  
  // Nouveaux paramètres pour contrôler la taille
  final double height;
  final double? width; // Null par défaut pour qu'elle prenne toute la largeur disponible (double.infinity)

  const ShotgunBanner({
    super.key,
    this.title = 'Événement à venir',
    this.description = 'Aucune description disponible pour le moment.',
    this.date = '--/--',
    this.hours = '--h--h',
    this.imageUrl = 'https://images.unsplash.com/photo-1492684223066-81342ee5ff30',
    this.height = 160.0, // Hauteur par défaut de ta maquette
    this.width,          // Optionnel, prend tout l'espace si non précisé
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      height: height, // Applique la hauteur paramétrable
      width: width,   // Applique la largeur paramétrable
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(15),
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.darken,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15), // Mêmes coins arrondis
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0.5, 1.0], // Le dégradé commence au milieu
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8), // Noir semi-transparent en bas
            ],
          ),
        ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 11, color: Colors.grey[300]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(date, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text(hours, style: TextStyle(fontSize: 12, color: Colors.grey[300])),
                ],
              ),
            ],
          ),
        ),
      )
    );
  }
}