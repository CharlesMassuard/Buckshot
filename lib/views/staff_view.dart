import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'scanner_view.dart';

class StaffView extends StatelessWidget {
  const StaffView({super.key});

  String _formatEventDate(Timestamp? timestampStart, Timestamp? timestampEnd) {
    if (timestampStart == null) return 'Date inconnue';
    final DateTime start = timestampStart.toDate();
    final DateFormat formatter = DateFormat('E dd MMM', 'fr_FR');
    
    String formatTime(DateTime dt) {
      return dt.minute > 0 
          ? DateFormat('HH\'h\'mm').format(dt) 
          : DateFormat('HH\'h\'').format(dt);
    }

    if (timestampEnd != null) {
      final DateTime end = timestampEnd.toDate();
      if (start.day != end.day) {
        return "${formatter.format(start)} - ${formatter.format(end)} ${start.year}";
      }
      
      final String timeRange = "${formatTime(start)}-${formatTime(end)}";
      return "${formatter.format(start)} ${start.year} | $timeRange";
    }
    
    return "${formatter.format(start)} ${start.year} | ${formatTime(start)}";
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white30, width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.badge_outlined,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              Text(
                "Tu es staff",
                style: GoogleFonts.jura(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                    }

                    if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                      return Center(
                        child: Text(
                          "Erreur lors de la récupération du profil 😢",
                          style: GoogleFonts.jura(color: Colors.grey[500], fontSize: 16),
                        ),
                      );
                    }

                    final userData = userSnapshot.data!.data() as Map<String, dynamic>?;
                    final String userIdOrganisateur = userData?['idOrganisateur'] ?? '';

                    if (userIdOrganisateur.isEmpty) {
                      return Center(
                        child: Text(
                          "Tu n'es rattaché à aucune organisation 😢",
                          style: GoogleFonts.jura(color: Colors.grey[500], fontSize: 16),
                        ),
                      );
                    }

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('events')
                          .where('idOrganisateur', isEqualTo: userIdOrganisateur)
                          .snapshots(),
                      builder: (context, eventSnapshot) {
                        if (eventSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                        }

                        final eventDocs = eventSnapshot.data?.docs ?? [];

                        if (eventDocs.isEmpty) {
                          return Center(
                            child: Text(
                              "Aucun événement à gérer pour le moment 😢",
                              style: GoogleFonts.jura(color: Colors.grey[500], fontSize: 16),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: eventDocs.length,
                          padding: const EdgeInsets.only(bottom: 20),
                          itemBuilder: (context, index) {
                            final doc = eventDocs[index];
                            final event = doc.data() as Map<String, dynamic>;
                            final eventId = doc.id;

                            final String eventNom = event['nom'] ?? 'Événement';
                            final String eventLieu = event['lieu'] ?? 'Lieu non spécifié';
                            final String eventImage = event['imageUrl'] ?? 'assets/soiree.png';
                            final Timestamp? eventDate = event['dateHeureEvent'] as Timestamp?;
                            final Timestamp? eventDateFin = event['dateFinEvent'] as Timestamp?;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ScannerView(
                                        eventId: eventId, 
                                        eventData: event,
                                      ),
                                    ),
                                  );
                                },
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        eventImage,
                                        width: 90,
                                        height: 90,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            width: 90,
                                            height: 90,
                                            color: Colors.grey[800],
                                            child: const Icon(Icons.image, color: Colors.white54),
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            eventNom,
                                            style: GoogleFonts.jura(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatEventDate(eventDate, eventDateFin),
                                            style: GoogleFonts.jura(
                                              fontSize: 13,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            eventLieu,
                                            style: GoogleFonts.jura(
                                              fontSize: 13,
                                              color: Colors.grey[400],
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}