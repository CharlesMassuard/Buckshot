import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'ticket_detail_view.dart';
import 'create_event_view.dart';
import 'event_detail_view.dart';

class MyTicketsView extends StatefulWidget {
  const MyTicketsView({super.key});

  @override
  State<MyTicketsView> createState() => _MyTicketsViewState();
}

class _MyTicketsViewState extends State<MyTicketsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isShowingTickets = true;
  String _userRole = 'USER';
  String _useridOrganisateur = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && mounted) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _userRole = data['role'] ?? 'USER';
          _useridOrganisateur = data['idOrganisateur'] ?? '';
        });
      }
    }
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
              'eventImage': eventData['image'] ?? '',
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

  Stream<List<Map<String, dynamic>>> _getOrganiserEventsStream() {
    if (_useridOrganisateur.isEmpty) return Stream.value([]);

    return FirebaseFirestore.instance
        .collection('events')
        .where('idOrganisateur', isEqualTo: _useridOrganisateur)
        .snapshots()
        .map((eventSnapshot) {
      List<Map<String, dynamic>> events = [];

      for (var eventDoc in eventSnapshot.docs) {
        final eventData = eventDoc.data();
        events.add({
          'eventId': eventDoc.id,
          'eventNom': eventData['nom'] ?? 'Événement',
          'eventLieu': eventData['lieu'] ?? 'Lieu non spécifié',
          'eventDate': eventData['dateHeureEvent'],
          'eventDateFin': eventData['dateFinEvent'],
          'eventImage': eventData['image'] ?? '',
          'rawEventData': eventData,
        });
      }

      events.sort((a, b) {
        final Timestamp? dateA = a['eventDate'];
        final Timestamp? dateB = b['eventDate'];
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateA.compareTo(dateB);
      });

      return events;
    });
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
    final theme = Theme.of(context);
    final bool isOrganizer = (_userRole == 'ORGANISATEUR');

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      floatingActionButton: (isOrganizer && !_isShowingTickets)
          ? FloatingActionButton(
        backgroundColor: const Color(0xFF9D4EDD),
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventView()),
          );
        },
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      )
          : null,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: isOrganizer
                  ? Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _isShowingTickets = true),
                    child: Text(
                      'Mes Billets',
                      style: GoogleFonts.jura(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: _isShowingTickets ? Colors.white : Colors.grey[600],
                        decoration: _isShowingTickets ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: theme.colorScheme.secondary,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _isShowingTickets = false),
                    child: Text(
                      'Mes Events',
                      style: GoogleFonts.jura(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: !_isShowingTickets ? Colors.white : Colors.grey[600],
                        decoration: !_isShowingTickets ? TextDecoration.underline : TextDecoration.none,
                        decorationColor: theme.colorScheme.secondary,
                        decorationThickness: 2,
                      ),
                    ),
                  ),
                ],
              )
                  : Text(
                'Mes Billets',
                style: GoogleFonts.jura(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 25),
            Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: theme.colorScheme.secondary,
                indicatorWeight: 3,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey[500],
                labelStyle: GoogleFonts.jura(fontSize: 16, fontWeight: FontWeight.bold),
                unselectedLabelStyle: GoogleFonts.jura(fontSize: 16),
                tabs: const [
                  Tab(text: 'A Venir'),
                  Tab(text: 'En Cours'),
                  Tab(text: 'Passés'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: _isShowingTickets ? _getUserTicketsStream() : _getOrganiserEventsStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                    }

                    final items = snapshot.data ?? [];
                    final now = DateTime.now();

                    final upcomingItems = items.where((item) {
                      final Timestamp? start = item['eventDate'];
                      return start != null && start.toDate().isAfter(now);
                    }).toList();

                    final ongoingItems = items.where((item) {
                      final Timestamp? start = item['eventDate'];
                      final Timestamp? end = item['eventDateFin'];
                      if (start == null) return false;
                      final startDate = start.toDate();
                      final endDate = end?.toDate() ?? startDate.add(const Duration(hours: 4));
                      return startDate.isBefore(now) && endDate.isAfter(now);
                    }).toList();

                    final pastItems = items.where((item) {
                      final Timestamp? start = item['eventDate'];
                      final Timestamp? end = item['eventDateFin'];
                      if (start == null) return true;
                      final endDate = end?.toDate() ?? start.toDate().add(const Duration(hours: 4));
                      return endDate.isBefore(now);
                    }).toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(upcomingItems),
                        _buildList(ongoingItems),
                        _buildList(pastItems),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isShowingTickets ? Icons.confirmation_number_outlined : Icons.celebration_outlined,
                size: 60,
                color: Colors.grey[700],
              ),
              const SizedBox(height: 16),
              Text(
                _isShowingTickets
                    ? "Aucun billet pour le moment !\nTrouve ton prochain shotgun sur l'accueil 🎫"
                    : "Rien de prévu ici !\nAppuie sur le bouton + pour lancer les festivités 🚀",
                textAlign: TextAlign.center,
                style: GoogleFonts.jura(
                  color: Colors.grey[500],
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final item = items[index];

        return InkWell(
          onTap: () {
            if (_isShowingTickets) {
              Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => TicketDetailView(ticketData: item),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(0.0, 1.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOutCubic;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return SlideTransition(position: animation.drive(tween), child: child);
                  },
                  transitionDuration: const Duration(milliseconds: 400),
                ),
              );
            } else {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailView(
                    eventId: item['eventId'],
                    eventData: item['rawEventData'],
                  ),
                ),
              );
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildEventImage(item['eventImage']),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['eventNom'],
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
                        _formatEventDate(item['eventDate'], item['eventDateFin']),
                        style: GoogleFonts.jura(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['eventLieu'],
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