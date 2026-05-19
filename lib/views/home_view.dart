import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../models/event_model.dart';
import 'scanner_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final DatabaseService _dbService = DatabaseService();
  String _scanResult = "Aucun scan effectué";
  Color _resultColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚡ Buckshot App ⚡', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Section Résultats du scan Staff
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text('Statut du dernier scan :', style: TextStyle(color: Color(0xFFE0AAFF))),
                  const SizedBox(height: 8),
                  Text(_scanResult, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _resultColor)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Liste dynamique des événements branchée sur Firebase
            Expanded(
              child: StreamBuilder<List<EventModel>>(
                stream: _dbService.getEvents(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return const Center(child: Text('Erreur de chargement'));
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final events = snapshot.data!;
                  if (events.isEmpty) return const Center(child: Text('Aucun événement disponible'));

                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Card(
                        color: Theme.of(context).colorScheme.surface,
                        margin: const EdgeInsets.only(bottom: 16),
                        child: ListTile(
                          title: Text(event.nom, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${event.lieu} • ${event.placesRestantes} places'),
                          trailing: Icon(Icons.local_activity_rounded, color: Theme.of(context).colorScheme.secondary),
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Bouton Flottant pour ouvrir la caméra
            ElevatedButton.icon(
              onPressed: () async {
                final String? code = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const ScannerView()),
                );
                if (code != null && mounted) {
                  bool dejavalide = await _dbService.validerBillet(code);
                  setState(() {
                    if (dejavalide) {
                      _scanResult = "✅ ACCÈS AUTORISÉ";
                      _resultColor = const Color(0xFF39FF14); // Vert Néon
                    } else {
                      _scanResult = "❌ BILLET INVALIDE OU DÉJÀ SCANNÉ";
                      _resultColor = Theme.of(context).colorScheme.error;
                    }
                  });
                }
              },
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Scanner un billet'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}