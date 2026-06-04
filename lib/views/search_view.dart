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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('events').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Erreur réseau...'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
            }

            final allDocs = snapshot.data?.docs ?? [];
            final now = DateTime.now();

            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['nom'] ?? '').toString().toLowerCase();
              return name.contains(_searchQuery);
            }).toList();

            final upcomingItems = filteredDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? start = data['dateHeureEvent'] as Timestamp?;
              return start != null && start.toDate().isAfter(now);
            }).toList();

            final ongoingItems = filteredDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? start = data['dateHeureEvent'] as Timestamp?;
              final Timestamp? end = data['dateFinEvent'] as Timestamp?;
              if (start == null) return false;
              final startDate = start.toDate();
              final endDate = end?.toDate() ?? startDate.add(const Duration(hours: 4));
              return startDate.isBefore(now) && endDate.isAfter(now);
            }).toList();

            final pastItems = filteredDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final Timestamp? start = data['dateHeureEvent'] as Timestamp?;
              final Timestamp? end = data['dateFinEvent'] as Timestamp?;
              if (start == null) return true;
              final endDate = end?.toDate() ?? start.toDate().add(const Duration(hours: 4));
              return endDate.isBefore(now);
            }).toList();

            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 20.0, bottom: 17.0),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                  indicatorWeight: 3,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey[500],
                  labelStyle: GoogleFonts.jura(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: GoogleFonts.jura(
                    fontSize: 16,
                  ),
                  tabs: [
                    Tab(text: 'A Venir (${upcomingItems.length})'),
                    Tab(text: 'En Cours (${ongoingItems.length})'),
                    Tab(text: 'Passés (${pastItems.length})'),
                  ],
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildEventList(upcomingItems),
                        _buildEventList(ongoingItems),
                        _buildEventList(pastItems),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventList(List<QueryDocumentSnapshot> tabDocs) {
    if (tabDocs.isEmpty) {
      return Center(
        child: Text(
          'Aucun événement trouvé',
          style: GoogleFonts.jura(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: tabDocs.length,
      padding: const EdgeInsets.only(bottom: 20),
      itemBuilder: (context, index) {
        final doc = tabDocs[index];
        final event = doc.data() as Map<String, dynamic>;
        final eventId = doc.id;

        final title = event['nom'] ?? 'Événement';
        final lieu = event['lieu'] ?? 'Lieu non spécifié';
        final Timestamp? dateHeure = event['dateHeureEvent'] as Timestamp?;
        final Timestamp? dateFinEvent = event['dateFinEvent'] as Timestamp?;
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
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
                        title,
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
                        _formatEventDate(dateHeure, dateFinEvent),
                        style: GoogleFonts.jura(
                          fontSize: 13,
                          color: Colors.grey[400],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lieu,
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