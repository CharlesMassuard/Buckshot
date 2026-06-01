import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/ShotgunBanner.dart';
import '../widgets/ShotgunItem.dart';
import '../widgets/BarreDeRecherche.dart';
import '../widgets/BarreDeNavigation.dart';
import 'event_detail_view.dart';
import 'search_view.dart';
import 'profile_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _allPages = [
    const _HomeContent(),
    const SearchView(),
    const Center(child: Text('Scanner QR', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Billets (Bientôt dispo)', style: TextStyle(color: Colors.white))),
    const ProfileView(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        String role = 'USER';
        if (snapshot.hasData && snapshot.data!.exists) {
          final userData = snapshot.data!.data() as Map<String, dynamic>?;
          role = userData?['role'] ?? 'USER';
        }

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
          backgroundColor: Theme.of(context).colorScheme.background,
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
    final now = DateTime.now();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('billets')
          .where('userId', isEqualTo: user?.uid)
          .snapshots(),
      builder: (context, billetSnapshot) {
        final Set<String> myRegisteredIds = billetSnapshot.hasData
            ? billetSnapshot.data!.docs
            .map((doc) => (doc.data() as Map<String, dynamic>)['eventId'] as String? ?? '')
            .toSet()
            : {};

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, eventSnapshot) {
            if (eventSnapshot.hasError) return const Center(child: Text('Erreur...'));
            if (eventSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
            }

            final allDocs = eventSnapshot.data?.docs ?? [];
            if (allDocs.isEmpty) return const Center(child: Text('Aucun événement disponible'));

            final myInscriptionsDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              return myRegisteredIds.contains(doc.id) &&
                  dateHeure != null &&
                  dateHeure.toDate().isAfter(now);
            }).toList();

            final headlinerDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              return dateHeure != null && dateHeure.toDate().isAfter(now);
            }).toList();

            final activeNoveltyDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              return dateHeure != null && dateHeure.toDate().isAfter(now);
            }).toList();

            List<QueryDocumentSnapshot> noveltyDocs = List.from(activeNoveltyDocs);
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

            final upcomingEvents = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final dateHeure = data['dateHeureEvent'] as Timestamp?;
              return dateHeure != null && dateHeure.toDate().isAfter(now);
            }).toList();

            upcomingEvents.sort((a, b) {
              final dateA = (a.data() as Map<String, dynamic>)['dateHeureEvent'] as Timestamp;
              final dateB = (b.data() as Map<String, dynamic>)['dateHeureEvent'] as Timestamp;
              return dateA.compareTo(dateB);
            });

            final mainEventDoc = upcomingEvents.isNotEmpty ? upcomingEvents.first : allDocs.first;
            final mainEvent = mainEventDoc.data() as Map<String, dynamic>;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'Dernier shotgun en cours'),
                  ShotgunBanner(
                    title: mainEvent['nom'] ?? 'Événement',
                    description: mainEvent['description'] ?? '',
                    date: _formatDate(mainEvent['dateHeureEvent'] as Timestamp?),
                    hours: _formatHours(mainEvent['dateHeureEvent'] as Timestamp?),
                    imageUrl: 'assets/soiree.png',
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

                  _buildSectionTitle(context, 'Vos inscriptions'),
                  myInscriptionsDocs.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text("Vous n'avez pas encore de réservations 🎫",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  )
                      : _buildHorizontalEventList(myInscriptionsDocs),

                  _buildSectionTitle(context, 'En tête d’affiche'),
                  headlinerDocs.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text("Plus aucun événement disponible pour le moment 🛑",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  )
                      : _buildHorizontalEventList(headlinerDocs),

                  _buildSectionTitle(context, 'Nouveautés'),
                  noveltyDocs.isEmpty
                      ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                    child: Text("Aucune nouveauté récente.",
                        style: TextStyle(color: Colors.grey, fontSize: 14)),
                  )
                      : _buildHorizontalEventList(noveltyDocs),

                  const SizedBox(height: 24),
                ],
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
            imageUrl: 'assets/soiree.png',
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