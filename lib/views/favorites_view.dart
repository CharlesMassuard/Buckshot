import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'event_detail_view.dart';

class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

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

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
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
                      Icons.favorite_border_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 35),
              Text(
                "Tu es intéressé·e",
                style: GoogleFonts.jura(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('reminders')
                      .where('userId', isEqualTo: user?.uid)
                      .snapshots(),
                  builder: (context, remindersSnapshot) {
                    if (remindersSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                    }

                    final reminderDocs = remindersSnapshot.data?.docs ?? [];

                    if (reminderDocs.isEmpty) {
                      return Center(
                        child: Text(
                          "Aucun événement en favori pour le moment 🌟",
                          style: GoogleFonts.jura(color: Colors.grey[500], fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: reminderDocs.length,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemBuilder: (context, index) {
                        final reminder = reminderDocs[index].data() as Map<String, dynamic>;
                        final String eventId = reminder['eventId'] ?? '';

                        return FutureBuilder<DocumentSnapshot>(
                          future: FirebaseFirestore.instance.collection('events').doc(eventId).get(),
                          builder: (context, eventSnapshot) {
                            if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
                              return const SizedBox.shrink();
                            }

                            final event = eventSnapshot.data!.data() as Map<String, dynamic>;
                            final String eventNom = event['nom'] ?? 'Événement';
                            final String eventLieu = event['lieu'] ?? 'Lieu non spécifié';
                            final Timestamp? eventDate = event['dateHeureEvent'] as Timestamp?;
                            final Timestamp? eventDateFin = event['dateFinEvent'] as Timestamp?;
                            final String eventImageBase64 = event['image'] ?? '';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 20),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => EventDetailView(
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
                                    IconButton(
                                      icon: const Icon(Icons.favorite, color: Color(0xFF9D4EDD)),
                                      onPressed: () async {
                                        await reminderDocs[index].reference.delete();
                                      },
                                    )
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