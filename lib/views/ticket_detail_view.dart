import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';
import 'event_detail_view.dart';

class TicketDetailView extends StatelessWidget {
  final Map<String, dynamic> ticketData;

  const TicketDetailView({
    super.key,
    required this.ticketData,
  });

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('E dd MMM yyyy', 'fr_FR').format(timestamp.toDate());
  }

  String _formatHours(Timestamp? timestamp) {
    if (timestamp == null) return '--h--';
    return DateFormat('HH\'h\'mm').format(timestamp.toDate()).replaceAll('00', '');
  }

  Widget _buildTicketImage(String base64Image) {
    if (base64Image.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Image),
          height: 180,
          width: double.infinity,
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
      height: 180,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 180,
        color: Colors.grey[300],
        child: const Icon(Icons.image, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String billetId = ticketData['billetId'] ?? '';
    final String userId = ticketData['userId'] ?? '';
    final String eventId = ticketData['eventId'] ?? '';
    final String eventNom = ticketData['eventNom'] ?? 'Événement';
    final String eventImageBase64 = ticketData['eventImage'] ?? '';
    final Timestamp? eventDate = ticketData['eventDate'] as Timestamp?;
    final Timestamp? eventDateFin = ticketData['eventDateFin'] as Timestamp?;

    final bool hasDifferentEndDay = eventDate != null && 
        eventDateFin != null && 
        eventDate.toDate().day != eventDateFin.toDate().day;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0, top: 10.0),
                child: IconButton(
                  icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 36),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                      child: _buildTicketImage(eventImageBase64),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      eventNom,
                      style: GoogleFonts.jura(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    QrImageView(
                      data: billetId,
                      version: QrVersions.auto,
                      size: 200.0,
                      gapless: false,
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      billetId.toUpperCase(),
                      style: GoogleFonts.jura(
                        fontSize: 12,
                        color: Colors.grey[600],
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    userId.isEmpty
                        ? Text("Étudiant", style: GoogleFonts.jura(fontSize: 15, color: Colors.grey[700]))
                        : FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
                            builder: (context, snapshot) {
                              String userName = "Chargement...";
                              if (snapshot.hasData && snapshot.data!.exists) {
                                final data = snapshot.data!.data() as Map<String, dynamic>?;
                                final String prenom = data?['prenom'] ?? '';
                                final String nom = data?['nom'] ?? '';
                                userName = "$prenom $nom".trim();
                                if (userName.isEmpty) userName = "Étudiant";
                              }
                              return Text(
                                userName,
                                style: GoogleFonts.jura(
                                  fontSize: 15,
                                  color: Colors.grey[700],
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
                      child: hasDifferentEndDay
                          ? Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Du",
                                      style: GoogleFonts.jura(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_formatDate(eventDate)} à ${_formatHours(eventDate)}",
                                      style: GoogleFonts.jura(fontSize: 14, color: Colors.grey[900], fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "au",
                                      style: GoogleFonts.jura(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      "${_formatDate(eventDateFin)} à ${_formatHours(eventDateFin)}",
                                      style: GoogleFonts.jura(fontSize: 14, color: Colors.grey[900], fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDate(eventDate),
                                  style: GoogleFonts.jura(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  eventDateFin != null
                                      ? "${_formatHours(eventDate)} - ${_formatHours(eventDateFin)}"
                                      : _formatHours(eventDate),
                                  style: GoogleFonts.jura(
                                    fontSize: 14,
                                    color: Colors.grey[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            InkWell(
              onTap: () async {
                final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
                if (eventDoc.exists && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EventDetailView(
                        eventId: eventId,
                        eventData: eventDoc.data()!,
                      ),
                    ),
                  );
                }
              },
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.visibility_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Voir l’évènement",
                    style: GoogleFonts.jura(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}