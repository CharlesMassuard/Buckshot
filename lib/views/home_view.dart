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

        List<Widget> activePages = [
          _allPages[0],
          _allPages[1],
        ];

        if (showScanner) {
          activePages.add(_allPages[2]); 
        }

        activePages.addAll([
          _allPages[3], 
          _allPages[4], 
        ]);

        if (_currentIndex >= activePages.length) {
          _currentIndex = activePages.length - 1;
        }

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

            // --- Filtre global Inscriptions : Événements dont la date de fin n'est pas passée ---
            final liveOrUpcomingEvents = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateFin = data['dateFinEvent'] as Timestamp?;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              final DateTime targetDate = dateFin?.toDate() ?? dateHeure?.toDate() ?? now;
              return targetDate.isAfter(now);
            }).toList();

            // --- Filtre strict (Toutes autres sections) : Événements dont la date d'événement n'est pas passée ---
            final strictlyUpcomingEvents = liveOrUpcomingEvents.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              return dateHeure != null && dateHeure.toDate().isAfter(now);
            }).toList();


            // --- 1. "Dernier shotgun en cours" : dateOuvertureBilletterie le plus proche de maintenant ---
            List<QueryDocumentSnapshot> sortedByBilleterieProche = List.from(strictlyUpcomingEvents);
            sortedByBilleterieProche.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final dateA = dataA['dateOuvertureBilletterie'] as Timestamp?;
              final dateB = dataB['dateOuvertureBilletterie'] as Timestamp?;

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;

              final diffA = (dateA.toDate().difference(now)).abs().inMilliseconds;
              final diffB = (dateB.toDate().difference(now)).abs().inMilliseconds;
              return diffA.compareTo(diffB);
            });

            final mainEventDoc = sortedByBilleterieProche.isNotEmpty ? sortedByBilleterieProche.first : allDocs.first;
            final mainEvent = mainEventDoc.data() as Map<String, dynamic>;


            // --- 2. "En tête d'affiche" : Billetterie ouverte, trié par taux de remplissage élevé ---
            final headlinerDocs = strictlyUpcomingEvents.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateOuverture = data['dateOuvertureBilletterie'] as Timestamp?;
              return dateOuverture != null && dateOuverture.toDate().isBefore(now);
            }).toList();

            headlinerDocs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;

              final int placesRestantesA = dataA['placesRestantes'] ?? 0;
              final int capaciteMaxA = dataA['capaciteMax'] ?? 1;
              final int placesRestantesB = dataB['placesRestantes'] ?? 0;
              final int capaciteMaxB = dataB['capaciteMax'] ?? 1;

              final double rempliA = (capaciteMaxA - placesRestantesA) / (capaciteMaxA <= 0 ? 1 : capaciteMaxA);
              final double rempliB = (capaciteMaxB - placesRestantesB) / (capaciteMaxB <= 0 ? 1 : capaciteMaxB);

              return rempliB.compareTo(rempliA);
            });


            // --- 3. "Vos Inscriptions" ---
            final myInscriptionsDocs = liveOrUpcomingEvents.where((doc) => myRegisteredIds.contains(doc.id)).toList();


            // --- 4. "Nouveautés" : Trié par date de création ---
            List<QueryDocumentSnapshot> noveltyDocs = List.from(strictlyUpcomingEvents);
            noveltyDocs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final dateA = dataA['createdAt'] as Timestamp?;
              final dateB = dataB['createdAt'] as Timestamp?;

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;

              return dateB.compareTo(dateA);
            });


            // --- 5. "Les prochains shotgun" : Pas encore ouverts, ordre chronologique d'ouverture ---
            final upcomingShotgunDocs = strictlyUpcomingEvents.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateOuverture = data['dateOuvertureBilletterie'] as Timestamp?;
              return dateOuverture != null && dateOuverture.toDate().isAfter(now);
            }).toList();

            upcomingShotgunDocs.sort((a, b) {
              final dataA = a.data() as Map<String, dynamic>;
              final dataB = b.data() as Map<String, dynamic>;
              final dateA = dataA['dateOuvertureBilletterie'] as Timestamp?;
              final dateB = dataB['dateOuvertureBilletterie'] as Timestamp?;

              if (dateA == null && dateB == null) return 0;
              if (dateA == null) return 1;
              if (dateB == null) return -1;

              return dateA.compareTo(dateB);
            });


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
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection('reminders')
                                .where('userId', isEqualTo: user?.uid)
                                .snapshots(),
                            builder: (context, remindersSnapshot) {
                              final bool hasFavorites = remindersSnapshot.hasData &&
                                  remindersSnapshot.data!.docs.isNotEmpty;

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

                    // --- 1. Bannière principale ---
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

                    // --- 2. En tête d'affiche ---
                    _buildSectionTitle(context, 'En tête d’affiche'),
                    headlinerDocs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Text(
                              "Aucun événement ouvert aux inscriptions pour le moment 🛑",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : _buildHorizontalEventList(headlinerDocs),

                    // --- 3. Vos Inscriptions ---
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

                    // --- 4. Nouveautés ---
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

                    // --- 5. Les prochains shotgun ---
                    _buildSectionTitle(context, 'Les prochains shotgun'),
                    upcomingShotgunDocs.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            child: Text(
                              "Aucune ouverture planifiée à venir ⏰",
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          )
                        : _buildHorizontalEventList(upcomingShotgunDocs),

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