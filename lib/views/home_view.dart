import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

// Services
import '../services/user_service.dart';
import '../services/event_service.dart';

// Widgets
import '../widgets/shotgun_banner.dart';
import '../widgets/shotgun_item.dart';
import '../widgets/barre_de_navigation.dart';

// Vues
import 'event_detail_view.dart';
import 'search_view.dart';
import 'profile_view.dart';
import 'my_tickets_view.dart';
import 'staff_view.dart';
import 'favorites_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;
  final UserService _userService = UserService();

  final List<Widget> _allPages = [
    const _HomeContent(),
    const SearchView(),
    const StaffView(),
    const MyTicketsView(),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<String>(
      stream: _userService.getUserRole(user?.uid),
      builder: (context, roleSnapshot) {
        final role = roleSnapshot.data ?? 'USER';
        final bool showScanner = (role == 'ORGANISATEUR' || role == 'STAFF');

        // Reconstruction dynamique des pages selon les droits
        List<Widget> activePages = [
          _allPages[0],
          _allPages[1],
        ];

        if (showScanner) {
          activePages.add(_allPages[2]); // StaffView 
        }

        activePages.addAll([
          _allPages[3], // MyTicketsView
          _allPages[4], // ProfileView
        ]);

        if (_currentIndex >= activePages.length) {
          _currentIndex = activePages.length - 1;
        }

        // Reconstruction dynamique des items de la barre de navigation
        List<NavItem> navItems = [
          NavItem(icon: Icons.home_outlined, label: 'Accueil', onTap: () {}),
          NavItem(icon: Icons.search, label: 'Recherche', onTap: () {}),
        ];

        if (showScanner) {
          navItems.add(
            NavItem(icon: Icons.qr_code_scanner, label: 'Scanner', onTap: () {}),
          );
        }

        navItems.addAll([
          NavItem(icon: Icons.confirmation_number_outlined, label: 'Billets', onTap: () {}),
          NavItem(icon: Icons.account_circle_outlined, label: 'Profil', onTap: () {}),
        ]);

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: IndexedStack(
            index: _currentIndex,
            children: activePages,
          ),
          bottomNavigationBar: BarreDeNavigation(
            currentIndex: _currentIndex,
            onItemSelected: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: navItems,
          ),
        );
      },
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '--/--';
    return DateFormat('dd/MM').format(timestamp.toDate());
  }

  String _formatHours(Timestamp? timestamp) {
    if (timestamp == null) return '--h';
    return '${DateFormat('HH').format(timestamp.toDate())}h';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = FirebaseAuth.instance.currentUser;
    final eventService = EventService();
    final now = DateTime.now();

    return StreamBuilder<Set<String>>(
      stream: eventService.getMyRegisteredEventIds(user?.uid),
      builder: (context, billetSnapshot) {
        final myRegisteredIds = billetSnapshot.data ?? {};

        return StreamBuilder<List<QueryDocumentSnapshot>>(
          stream: eventService.getAllEvents(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.hasError) return const Center(child: Text('Erreur...'));
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }

            final allDocs = eventSnapshot.data ?? [];
            if (allDocs.isEmpty) return const Center(child: Text('Aucun événement disponible'));

            // --- Filtrage : Uniquement les événements futurs ---
            final upcomingEvents = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              return dateHeure != null && dateHeure.toDate().isAfter(now);
            }).toList();

            // --- 1. Vos Inscriptions ---
            final myInscriptionsDocs = upcomingEvents.where((doc) => myRegisteredIds.contains(doc.id)).toList();

            // --- 2. En tête d'affiche ---
            final headlinerDocs = List<QueryDocumentSnapshot>.from(upcomingEvents);

            // --- 3. Nouveautés ---
            List<QueryDocumentSnapshot> noveltyDocs = List.from(upcomingEvents);
            noveltyDocs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final dateA = dataA['dateOuvertureBilletterie'] as Timestamp?;
              final dateB = dataB['dateOuvertureBilletterie'] as Timestamp?;
              if (dateA == null || dateB == null) return 0;
              return dateB.compareTo(dateA);
            });
            if (noveltyDocs.length > 10) {
              noveltyDocs = noveltyDocs.sublist(0, 10);
            }

            // --- 4. Bannière principale ---
            List<QueryDocumentSnapshot> sortedUpcoming = List.from(upcomingEvents);
            sortedUpcoming.sort((a, b) {
              final dateA = (a.data() as Map<String, dynamic>)['dateHeureEvent'] as Timestamp;
              final dateB = (b.data() as Map<String, dynamic>)['dateHeureEvent'] as Timestamp;
              return dateA.compareTo(dateB);
            });

            final mainEventDoc = sortedUpcoming.isNotEmpty ? sortedUpcoming.first : allDocs.first;
            final mainEvent = mainEventDoc.data() as Map<String, dynamic>;

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header (Logo + Bouton Favoris) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Image.asset(
                            'assets/BuckshotLogoLong.png',
                            height: 40,
                            fit: BoxFit.contain,
                          ),
                          StreamBuilder<bool>(
                            stream: eventService.hasFavorites(user?.uid),
                            builder: (context, remindersSnapshot) {
                              final bool hasFavorites = remindersSnapshot.data ?? false;

                              return IconButton(
                                icon: Icon(
                                  hasFavorites ? Icons.favorite : Icons.favorite_border_rounded,
                                  color: hasFavorites ? const Color(0xFF9D4EDD) : Colors.white,
                                  size: 28,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const FavoritesView(),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    // --- Bannière principale ---
                    _buildSectionTitle(context, 'Dernier shotgun en cours'),
                    ShotgunBanner(
                      title: mainEvent['nom'] ?? 'Événement',
                      description: mainEvent['description'] ?? '',
                      date: _formatDate(mainEvent['dateHeureEvent'] as Timestamp?),
                      hours: _formatHours(mainEvent['dateHeureEvent'] as Timestamp?),
                      imageUrl: mainEvent['image'] ?? 'assets/soiree.png',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailView(
                              eventId: mainEventDoc.id,
                              eventData: mainEvent,
                            ),
                          ),
                        );
                      },
                    ),

                    // --- Vos Inscriptions ---
                    _buildSectionTitle(context, 'Vos inscriptions'),
                    myInscriptionsDocs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Text(
                              "Vous n'avez pas encore de réservations 🎫",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : _buildHorizontalEventList(myInscriptionsDocs),

                    // --- En tête d'affiche ---
                    _buildSectionTitle(context, 'En tête d’affiche'),
                    headlinerDocs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Text(
                              "Plus aucun événement disponible pour le moment 🛑",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : _buildHorizontalEventList(headlinerDocs),

                    // --- Nouveautés ---
                    _buildSectionTitle(context, 'Nouveautés'),
                    noveltyDocs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Text(
                              "Aucune nouveauté récente.",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : _buildHorizontalEventList(noveltyDocs),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildHorizontalEventList(List<QueryDocumentSnapshot> docs) {
    return SizedBox(
      height: 230,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        itemCount: docs.length,
        itemBuilder: (context, index) {
          final doc = docs[index];
          final event = doc.data() as Map<String, dynamic>;

          return ShotgunItem(
            title: event['nom'] ?? 'Événement',
            date: _formatDate(event['dateHeureEvent'] as Timestamp?),
            hours: _formatHours(event['dateHeureEvent'] as Timestamp?),
            imageUrl: event['image'] ?? 'assets/soiree.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailView(
                    eventId: doc.id,
                    eventData: event,
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