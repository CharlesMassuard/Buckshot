import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/ShotgunBanner.dart';
import '../widgets/ShotgunItem.dart';
import '../widgets/BarreDeRecherche.dart';
import '../widgets/BarreDeNavigation.dart';
import 'event_detail_view.dart';
import 'search_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _HomeContent(),
    const SearchView(),
    const Center(child: Text('Billets (Bientôt dispo)', style: TextStyle(color: Colors.white))),
    const Center(child: Text('Profil (Bientôt dispo)', style: TextStyle(color: Colors.white))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,

      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),

      bottomNavigationBar: Barredenavigation(
        currentIndex: _currentIndex,
        onItemSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          NavItem(icon: Icons.home_outlined, label: 'Accueil', onTap: () {}),
          NavItem(icon: Icons.search, label: 'Recherche', onTap: () {}),
          NavItem(icon: Icons.confirmation_number_outlined, label: 'Billets', onTap: () {}),
          NavItem(icon: Icons.account_circle_outlined, label: 'Profil', onTap: () {}),
        ],
      ),
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

    return SafeArea(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Erreur...'));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) return const Center(child: Text('Aucun événement'));

          final mainEvent = docs.first.data() as Map<String, dynamic>;

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
                      MaterialPageRoute(builder: (context) => EventDetailView(eventData: mainEvent)),
                    );
                  },
                ),

                _buildSectionTitle(context, 'Vos inscriptions'),
                _buildHorizontalEventList(docs),

                _buildSectionTitle(context, 'En tête d’affiche'),
                _buildHorizontalEventList(docs),

                _buildSectionTitle(context, 'Nouveautés'),
                _buildHorizontalEventList(docs),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
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
          final event = docs[index].data() as Map<String, dynamic>;

          return ShotgunItem(
            title: event['nom'] ?? 'Événement',
            date: _formatDate(event['dateHeureEvent'] as Timestamp?),
            hours: _formatHours(event['dateHeureEvent'] as Timestamp?),
            imageUrl: 'assets/soiree.png',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventDetailView(eventData: event)),
              );
            },
          );
        },
      ),
    );
  }
}