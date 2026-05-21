import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EventDetailView extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailView({super.key, required this.eventData});

  String _formatFullDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy à HH\'h\'').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    final title = eventData['nom'] ?? 'Événement';
    final description = eventData['description'] ?? 'Aucune description.';
    final lieu = eventData['lieu'] ?? 'Lieu non spécifié';
    final capaciteMax = eventData['capaciteMax'] ?? 0;
    final placesRestantes = eventData['placesRestantes'] ?? 0;
    final dateHeure = eventData['dateHeureEvent'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: Stack(
        children: [
          // 1. CONTENU DÉROULANT
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image d'en-tête
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/soiree.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titre
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Description
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[300],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Organisateur
                      Row(
                        children: const [
                          Text(
                            'organisé par ',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                          Text(
                            'BDE INSA HDF',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(width: 120, height: 1, color: Colors.grey[800]),
                      const SizedBox(height: 24),

                      // Détails techniques (Date, lieu)
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Du ${_formatFullDate(dateHeure)}',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, color: Colors.white, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Lieu : $lieu',
                            style: const TextStyle(color: Colors.white, fontSize: 15),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(width: 160, height: 1, color: Colors.grey[800]),
                      const SizedBox(height: 24),

                      // Places
                      Text(
                        'Places disponibles : $placesRestantes / $capaciteMax',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 100), // Marge pour le bouton
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. RETOUR ARRIÈRE
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // 3. BOUTON DE SHOTGUN FIXE
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: ElevatedButton.icon(
              onPressed: () {
                print("Demande d'inscription enregistrée pour : $title");
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 28),
              label: const Text(
                'SHOTGUN',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9D4EDD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}