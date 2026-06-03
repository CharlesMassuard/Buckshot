import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'scanner_view.dart';
import 'edit_event_view.dart';

class ManageEventView extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const ManageEventView({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<ManageEventView> createState() => _ManageEventViewState();
}

class _ManageEventViewState extends State<ManageEventView> {
  final Color neonPink = const Color(0xFFE5097F);
  final Color neonPurple = const Color(0xFF9146FF);
  final Color darkCardBg = const Color(0xFF12101A);
  final Color darkInputBg = const Color(0xFF1D1B26);
  final Color neonGlowColor = const Color(0xFF5D1F9B);

  bool _isDeleting = false;

  String _formatFullDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date non spécifiée';
    return DateFormat('dd/MM/yyyy à HH\'h\'mm').format(timestamp.toDate());
  }

  void _openQRScanner(Map<String, dynamic> currentEventData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScannerView(
          eventId: widget.eventId,
          eventData: currentEventData,
        ),
      ),
    );
  }

  void _editEventInfo(Map<String, dynamic> currentEventData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEventView(
          eventId: widget.eventId,
          eventData: currentEventData,
        ),
      ),
    );
  }

  Future<void> _confirmCancelEvent() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF161420),
        title: Text("Annuler l'événement ?",
            style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text("Cette action est irréversible. Tous les billets associés seront supprimés.",
            style: GoogleFonts.jura(color: Colors.grey[400])),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Annuler", style: GoogleFonts.jura(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE63946)),
            onPressed: () => Navigator.pop(context, true),
            child: Text("Confirmer", style: GoogleFonts.jura(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isDeleting = true);
      try {
        await FirebaseFirestore.instance.collection('events').doc(widget.eventId).delete();

        final billetsQuery = await FirebaseFirestore.instance
            .collection('billets')
            .where('eventId', isEqualTo: widget.eventId)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (var doc in billetsQuery.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Événement annulé et supprimé avec succès. 💥",
                  style: GoogleFonts.jura(fontWeight: FontWeight.bold, color: Colors.white)),
              backgroundColor: const Color(0xFFE63946),
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Erreur lors de la suppression : $e")),
          );
        }
      } finally {
        if (mounted) setState(() => _isDeleting = false);
      }
    }
  }

  Widget _buildStatCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: darkInputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.jura(color: Colors.grey[400], fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.jura(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        title: Text(
          'Tableau de bord',
          style: GoogleFonts.jura(color: neonPink, fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> currentData = Map<String, dynamic>.from(widget.eventData);

          int capaciteMax = currentData['capaciteMax'] ?? 0;
          int placesRestantes = currentData['placesRestantes'] ?? 0;
          Timestamp? dateHeure = currentData['dateHeureEvent'] as Timestamp?;
          String nomEvent = currentData['nom'] ?? 'Mon Événement';
          String imageBase64 = currentData['image'] ?? '';

          if (snapshot.hasData && snapshot.data!.exists) {
            currentData = snapshot.data!.data() as Map<String, dynamic>;
            capaciteMax = currentData['capaciteMax'] ?? capaciteMax;
            placesRestantes = currentData['placesRestantes'] ?? placesRestantes;
            dateHeure = currentData['dateHeureEvent'] as Timestamp? ?? dateHeure;
            nomEvent = currentData['nom'] ?? nomEvent;
            imageBase64 = currentData['image'] ?? imageBase64;
          }

          int placesReservees = capaciteMax - placesRestantes;
          double remplissagePourcentage = capaciteMax > 0 ? (placesReservees / capaciteMax) * 100 : 0.0;

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('billets')
                .where('eventId', isEqualTo: widget.eventId)
                .snapshots(),
            builder: (context, billetsSnapshot) {
              int totalBilletsDoc = billetsSnapshot.hasData ? billetsSnapshot.data!.docs.length : placesReservees;

              int totalScannes = 0;
              if (billetsSnapshot.hasData) {
                totalScannes = billetsSnapshot.data!.docs.where((doc) {
                  final d = doc.data() as Map<String, dynamic>;
                  return d['scanAt'] != null;
                }).length;
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: darkCardBg,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: neonGlowColor.withOpacity(0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: neonGlowColor.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (imageBase64.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                base64Decode(imageBase64),
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Container(color: darkInputBg, width: 60, height: 60),
                              ),
                            )
                          else
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(color: darkInputBg, borderRadius: BorderRadius.circular(12)),
                              child: Icon(Icons.celebration, color: neonPink),
                            ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nomEvent,
                                  style: GoogleFonts.jura(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatFullDate(dateHeure),
                                  style: GoogleFonts.jura(color: Colors.grey[400], fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text("STATISTIQUES DE VENTE", style: GoogleFonts.jura(color: neonPink, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                      const SizedBox(height: 12),

                      _buildStatCard(
                        title: "Places Réservées (Shotguns)",
                        value: "$totalBilletsDoc / $capaciteMax",
                        icon: Icons.confirmation_number_outlined,
                        color: neonPurple,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        title: "Taux de remplissage",
                        value: "${remplissagePourcentage.toStringAsFixed(1)} %",
                        icon: Icons.pie_chart_outline,
                        color: Colors.tealAccent,
                      ),
                      const SizedBox(height: 12),
                      _buildStatCard(
                        title: "Entrées validées (Scannées)",
                        value: "$totalScannes scannés",
                        icon: Icons.check_circle_outline,
                        color: neonPink,
                      ),

                      const SizedBox(height: 28),
                      Text("ACTIONS DE GESTION", style: GoogleFonts.jura(color: neonPink, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1.2)),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: neonPurple,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _openQRScanner(currentData),
                          icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                          label: Text("Scanner les billets (QR)", style: GoogleFonts.jura(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _editEventInfo(currentData),
                          icon: const Icon(Icons.edit_note, color: Colors.white),
                          label: Text("Modifier les informations", style: GoogleFonts.jura(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white10),
                      const SizedBox(height: 12),

                      _isDeleting
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE63946)))
                          : SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1C1318),
                            side: const BorderSide(color: Color(0xFFE63946), width: 1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          onPressed: _confirmCancelEvent,
                          icon: const Icon(Icons.delete_forever_outlined, color: Color(0xFFE63946)),
                          label: Text("Annuler définitivement l'évènement", style: GoogleFonts.jura(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFE63946))),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}