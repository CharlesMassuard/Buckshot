import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import '../widgets/barre_de_recherche.dart';
import 'event_detail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatFullDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('EEE dd MMM yyyy', 'fr_FR').format(timestamp.toDate());
  }

  Widget _buildEventImage(String base64Image) {
    if (base64Image.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Image),
          width: 90,
          height: 75,
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
      height: 75,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: 90,
        height: 75,
        color: Colors.grey[900],
        child: const Icon(Icons.image, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: BarreDeRecherche(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
            ),
            TabBar(
              controller: _tabController,
              indicatorColor: theme.colorScheme.secondary,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[500],
              labelStyle: GoogleFonts.jura(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              unselectedLabelStyle: GoogleFonts.jura(
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'A Venir'),
                Tab(text: 'En Cours'),
                Tab(text: 'Passés'),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('events').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Erreur réseau...'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: theme.colorScheme.primary));
                  }

                  final allDocs = snapshot.data?.docs ?? [];

                  final filteredDocs = allDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final name = (data['nom'] ?? '').toString().toLowerCase();
                    return name.contains(_searchQuery);
                  }).toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEventList(filteredDocs, 'avenir'),
                      _buildEventList(filteredDocs, 'encours'),
                      _buildEventList(filteredDocs, 'passes'),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventList(List<QueryDocumentSnapshot> docs, String tabType) {
    final now = DateTime.now();

    final tabDocs = docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp = data['dateHeureEvent'] as Timestamp?;
      if (timestamp == null) return tabType == 'avenir';

      final eventDate = timestamp.toDate();
      if (tabType == 'avenir') return eventDate.isAfter(now);
      if (tabType == 'passes') return eventDate.isBefore(now.subtract(const Duration(hours: 5)));
      return eventDate.isBefore(now) && eventDate.isAfter(now.subtract(const Duration(hours: 5)));
    }).toList();

    if (tabDocs.isEmpty) {
      return Center(
        child: Text(
          'Aucun événement trouvé',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: tabDocs.length,
      itemBuilder: (context, index) {
        final doc = tabDocs[index];
        final event = doc.data() as Map<String, dynamic>;
        final eventId = doc.id;

        final title = event['nom'] ?? 'Événement';
        final lieu = event['lieu'] ?? 'Lieu non spécifié';
        final dateHeure = event['dateHeureEvent'] as Timestamp?;
        final eventImageBase64 = event['image'] ?? '';

        return InkWell(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildEventImage(eventImageBase64),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatFullDate(dateHeure),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lieu,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 13,
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