import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ticket_detail_view.dart';

class MyTicketsView extends StatefulWidget {
  const MyTicketsView({super.key});

  @override
  State<MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<MyTicketsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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

  Stream<List<Map<String, dynamic>>> _getUserTicketsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('billets')
        .where('userId', isEqualTo: user.uid)
        .snapshots()
        .asyncMap((billetSnapshot) async {
          List<Map<String, dynamic>> combinedTickets = [];

          for (var billetDoc in billetSnapshot.docs) {
            final billetData = billetDoc.data();
            final String eventId = billetData['eventId'] ?? '';

            if (eventId.isNotEmpty) {
              final eventDoc = await FirebaseFirestore.instance.collection('events').doc(eventId).get();
              
              if (eventDoc.exists) {
                final eventData = eventDoc.data()!;
                combinedTickets.add({
                  'billetId': billetDoc.id,
                  'userId': billetData['userId'] ?? user.uid,
                  'scanAt': billetData['scanAt'],
                  'createdAt': billetData['createdAt'],
                  'eventId': eventId,
                  'eventNom': eventData['nom'] ?? 'Événement',
                  'eventLieu': eventData['lieu'] ?? 'Lieu non spécifié',
                  'eventDate': eventData['dateHeureEvent'],
                  'eventDateFin': eventData['dateFinEvent'],
                  'eventImage': eventData['imageUrl'] ?? 'assets/soiree.png',
                });
              }
            }
          }

          combinedTickets.sort((a, b) {
            final Timestamp? dateA = a['eventDate'];
            final Timestamp? dateB = b['eventDate'];
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateA.compareTo(dateB);
          });

          return combinedTickets;
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'Mes Billets',
                style: GoogleFonts.jura(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 25),
              TabBar(
                controller: _tabController,
                indicatorColor: const Color(0xFFE63946),
                indicatorWeight: 2,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[400],
                labelStyle: GoogleFonts.jura(fontSize: 18, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.jura(fontSize: 18),
                tabs: const [
                  Tab(text: 'A Venir'),
                  Tab(text: 'En Cours'),
                  Tab(text: 'Passés'),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _getUserTicketsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                    }

                    final tickets = snapshot.data ?? [];
                    final now = DateTime.now();

                    final upcomingTickets = tickets.where((t) {
                      final Timestamp? start = t['eventDate'];
                      return start != null && start.toDate().isAfter(now);
                    }).toList();

                    final ongoingTickets = tickets.where((t) {
                      final Timestamp? start = t['eventDate'];
                      final Timestamp? end = t['eventDateFin'];
                      if (start == null) return false;
                      final startDate = start.toDate();
                      final endDate = end?.toDate() ?? startDate.add(const Duration(hours: 4));
                      return startDate.isBefore(now) && endDate.isAfter(now);
                    }).toList();

                    final pastTickets = tickets.where((t) {
                      final Timestamp? start = t['eventDate'];
                      final Timestamp? end = t['eventDateFin'];
                      if (start == null) return true;
                      final endDate = end?.toDate() ?? start.toDate().add(const Duration(hours: 4));
                      return endDate.isBefore(now);
                    }).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTicketList(upcomingTickets),
                        _buildTicketList(ongoingTickets),
                        _buildTicketList(pastTickets),
                      ],
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

  Widget _buildTicketList(List<Map<String, dynamic>> tickets) {
    if (tickets.isEmpty) {
      return Center(
        child: Text(
          "Aucun billet ici pour le moment 😢",
          style: GoogleFonts.jura(color: Colors.grey[500], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      itemCount: tickets.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final ticket = tickets[index];

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => TicketDetailView(ticketData: ticket),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // Commence tout en bas de l'écran
                  const end = Offset.zero; // Finit à sa position normale
                  const curve = Curves.easeInOutCubic; // Animation fluide et naturelle

                  var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 400), // Vitesse de l'effet
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    ticket['eventImage'],
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
                        ticket['eventNom'],
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
                        _formatEventDate(ticket['eventDate'], ticket['eventDateFin']),
                        style: GoogleFonts.jura(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        ticket['eventLieu'],
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
  }
}