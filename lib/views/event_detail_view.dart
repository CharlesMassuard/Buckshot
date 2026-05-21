import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class EventDetailView extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventDetailView({super.key, required this.eventData});

  String _formatFullDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy à HH\'h\'').format(timestamp.toDate());
  }

  String _getRandomMessage(List<Map<String, dynamic>> messagePool, String eventName) {
    int totalWeight = messagePool.fold(0, (sum, item) => sum + (item['weight'] as int));

    int seed = eventName.hashCode.abs() + DateTime.now().day;
    final random = Random(seed);
    int randomValue = random.nextInt(totalWeight);

    int currentSum = 0;
    for (final item in messagePool) {
      currentSum += item['weight'] as int;
      if (randomValue < currentSum) {
        return item['text'] as String;
      }
    }
    return messagePool.first['text'] as String;
  }

  String _getPastMessage(String eventName) {
    final List<Map<String, dynamic>> pool = [
      {'text': "Trop tard l'ancien, c'est fini ! 💀", 'weight': 40},
      {'text': "Le train est déjà parti sans toi... 🚂", 'weight': 40},
      {'text': "Fallait se réveiller avant la fin ! ⏰", 'weight': 35},
      {'text': "Tu as raté le coche, chef. 🎫", 'weight': 35},
      {'text': "Rembobinage impossible, c'est du passé. ⏳", 'weight': 30},
      {'text': "L'événement est déjà dans les livres d'histoire. 📖", 'weight': 25},
      {'text': "Erreur 404 : Soirée introuvable dans le présent. 🌐", 'weight': 20},
      {'text': "C'était le choix cornélien, t'as pris l'option dodo. 🛌", 'weight': 15},
      {'text': "Retour vers le futur ? Non, pas de Doc ici. 🚗💨", 'weight': 10},
      {'text': "Même le BDE a fini de cuver. C'est dire. 🫗", 'weight': 15},
      {'text': "La légende raconte que certains dorment encore sur place. ⛺", 'weight': 10},
      {'text': "Le ménage est fait, les fûts sont vides. Rentre chez toi. 🧹", 'weight': 8},
      {'text': "T'as confondu le calendrier avec ton emploi du temps de l'UV ? 🗓️", 'weight': 5},
    ];
    return _getRandomMessage(pool, eventName);
  }

  String _getFullMessage(String eventName) {
    final int maxPlaces = eventData['capaciteMax'] ?? 0;

    final List<Map<String, dynamic>> pool = [
      {'text': "Pas assez rapide... Skill issue. ⚰️", 'weight': 40},
      {'text': "Plus de places. Victime de son succès ! 📈", 'weight': 40},
      {'text': "Sold out ! Fallait pas bégayer au clic. 🛑", 'weight': 35},
      {'text': "La billetterie a fondu. C'est complet ! 🔥", 'weight': 30},
      {'text': "Reste dehors, c'est blindé de chez blindé. 🚪", 'weight': 30},
      {'text': "T'as cru qu'on t'attendait ? Y'a plus rien ! 🤷‍♂️", 'weight': 25},
      {'text': "Not clear! Quelqu'un a ruiné le serveur. 💥", 'weight': 15},
      {'text': "Sélection naturelle par la fibre optique. 🌐", 'weight': 15},
      {'text': "T'as cru que c'était les restos du cœur ? 💸", 'weight': 10},
      {'text': "T'as cru que tu t'appelais Charles ? 😏", 'weight': 10},
      {'text': "Il ne reste que des miettes et de la sueur. 🧀", 'weight': 8},
      {'text': "Même avec $maxPlaces places, t'as raté le shotgun. Souffle dans le ballon avant de prendre le volant 🚔", 'weight': 25},
      {'text': "Y'avait $maxPlaces places dispo et t'as réussi à finir sur le trottoir. Bravo. 🎪", 'weight': 20},
      {'text': "Y'a plus de places que de moyenne à ton prochain DS, et pourtant t'as raté le coche. 📉", 'weight': 15},
      {'text': "Ton ping est plus élevé que tes chances de valider l'année. 📡", 'weight': 12},
      {'text': "Va falloir corrompre le président du BDE là, parce que c'est mort. 💼", 'weight': 10},
      {'text': "Même en distanciel tu serais arrivé en retard. 💻", 'weight': 8},
      {'text': "Tu n'es pas invité à la fête du pipi caca ! 💩", 'weight': 2},
    ];
    return _getRandomMessage(pool, eventName);
  }

  @override
  Widget build(BuildContext context) {
    final title = eventData['nom'] ?? 'Événement';
    final description = eventData['description'] ?? 'Aucune description.';
    final lieu = eventData['lieu'] ?? 'Lieu non spécifié';
    final capaciteMax = eventData['capaciteMax'] ?? 0;
    final placesRestantes = eventData['placesRestantes'] ?? 0;
    final dateHeure = eventData['dateHeureEvent'] as Timestamp?;

    final now = DateTime.now();
    final bool isPast = dateHeure != null && dateHeure.toDate().isBefore(now);
    final bool noPlacesLeft = placesRestantes <= 0;

    String buttonText = "SHOTGUN";
    bool isButtonEnabled = true;

    if (isPast) {
      buttonText = _getPastMessage(title);
      isButtonEnabled = false;
    } else if (noPlacesLeft) {
      buttonText = _getFullMessage(title);
      isButtonEnabled = false;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                      Text(
                        title,
                        style: GoogleFonts.jura(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[300],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
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
                      Text(
                        'Places disponibles : $placesRestantes / $capaciteMax',
                        style: GoogleFonts.jura(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: noPlacesLeft ? Colors.redAccent : Colors.white,
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: isButtonEnabled
                ? ElevatedButton.icon(
              onPressed: () {
                print("Demande d'inscription enregistrée pour : $title");
              },
              icon: const Icon(Icons.arrow_forward_rounded, size: 28),
              label: Text(
                buttonText,
                style: GoogleFonts.jura(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
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
            )
                : Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Center(
                child: Text(
                  buttonText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.jura(
                    color: Colors.grey[500],
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}