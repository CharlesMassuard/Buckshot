import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
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

  Widget _buildEventImage(String base64Image) {
    if (base64Image.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Image),
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildAssetPlaceholder(),
        );
      } catch (e) {
        return _buildAssetPlaceholder();
      }
    }
    return _buildAssetPlaceholder();
  }

  Widget _buildAssetPlaceholder() {
    return Image.asset(
      'assets/soiree.png',
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 90,
        height: 90,
        color: Colors.grey[800],
        child: const Icon(Icons.image, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

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

                        final allDocs = eventSnapshot.data?.docs ?? [];

                        final filteredDocs = allDocs.where((doc) {
                          final event = doc.data() as Map<String, dynamic>;
                          final Timestamp? eventDateFin = event['dateFinEvent'] as Timestamp?;
                          if (eventDateFin == null) return true;
                          return eventDateFin.toDate().isAfter(now);
                        }).toList();

                        filteredDocs.sort((a, b) {
                          final eventA = a.data() as Map<String, dynamic>;
                          final eventB = b.data() as Map<String, dynamic>;

                          final Timestamp? dateStartA = eventA['dateHeureEvent'] as Timestamp?;
                          final Timestamp? dateStartB = eventB['dateHeureEvent'] as Timestamp?;

                          final bool startedA = dateStartA == null || dateStartA.toDate().subtract(const Duration(minutes: 30)).isBefore(now);
                          final bool startedB = dateStartB == null || dateStartB.toDate().subtract(const Duration(minutes: 30)).isBefore(now);

                          if (startedA && !startedB) return -1;
                          if (!startedA && startedB) return 1;

                          if (dateStartA != null && dateStartB != null) {
                            return dateStartA.compareTo(dateStartB);
                          }
                          return 0;
                        });

                        if (filteredDocs.isEmpty) {
                          return Center(
                            child: Text(
                              "Aucun événement actif à gérer 😢",
                              style: GoogleFonts.jura(color: Colors.grey[500], fontSize: 16),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: filteredDocs.length,
                          padding: const EdgeInsets.only(bottom: 20),
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final event = doc.data() as Map<String, dynamic>;
                            final eventId = doc.id;

                            final String eventNom = event['nom'] ?? 'Événement';
                            final String eventLieu = event['lieu'] ?? 'Lieu non spécifié';
                            final Timestamp? eventDate = event['dateHeureEvent'] as Timestamp?;
                            final Timestamp? eventDateFin = event['dateFinEvent'] as Timestamp?;
                            final String eventImageBase64 = event['image'] ?? '';

                            final bool hasStarted = eventDate == null || eventDate.toDate().subtract(const Duration(minutes: 30)).isBefore(now);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: Opacity(
                                opacity: hasStarted ? 1.0 : 0.5,
                                child: AbsorbPointer(
                                  absorbing: !hasStarted,
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
                                          child: _buildEventImage(eventImageBase64),
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
                                        if (!hasStarted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.white12,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: Colors.white30, width: 0.8),
                                            ),
                                            child: Text(
                                              "Fermé",
                                              style: GoogleFonts.jura(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
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