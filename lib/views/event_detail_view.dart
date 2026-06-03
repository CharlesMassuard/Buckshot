import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'dart:convert';
import '../services/notification_service.dart';
import 'manage_event_view.dart';

class EventDetailView extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EventDetailView({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<EventDetailView> {
  bool _isProcessing = false;
  String _userRole = 'USER';
  String _useridOrganisateur = '';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  void _fetchUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _userRole = data['role'] ?? 'USER';
            _useridOrganisateur = data['idOrganisateur'] ?? '';
            _isLoadingUser = false;
          });
          return;
        }
      } catch (e) {
        debugPrint("Erreur lors de la récupération du rôle utilisateur: $e");
      }
    }
    if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  String _formatFullDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Date inconnue';
    return DateFormat('dd/MM/yyyy à HH\'h\'mm').format(timestamp.toDate());
  }

  String _formatSimpleDate(Timestamp? timestamp) {
    if (timestamp == null) return 'bientôt';
    return DateFormat('dd/MM/yyyy à HH\'h\'mm').format(timestamp.toDate());
  }

  String _getRandomMessage(List<Map<String, dynamic>> messagePool, String eventName) {
    int totalWeight = messagePool.fold(0, (acc, item) => acc + (item['weight'] as int));
    int seed = eventName.hashCode.abs() + DateTime.now().day;
    final random = Random(seed);
    int randomValue = random.nextInt(totalWeight);

    int currentSum = 0;
    for (final item in messagePool) {
      currentSum += item['weight'] as int;
      if (randomValue < currentSum) {
        return item['text'] as String;
      }
    }
    return messagePool.first['text'] as String;
  }

  String _getPastMessage(String eventName) {
    final List<Map<String, dynamic>> pool = [
      {'text': "Trop tard l'ancien, c'est fini ! 💀", 'weight': 40},
      {'text': "Le train est déjà parti sans toi... 🚂", 'weight': 40},
      {'text': "Fallait se réveiller avant la fin ! ⏰", 'weight': 35},
      {'text': "Tu as raté le coche, chef. 🎫", 'weight': 35},
      {'text': "Rembobinage impossible, c'est du passé. ⏳", 'weight': 30},
      {'text': "L'événement est déjà dans les livres d'histoire. 📖", 'weight': 25},
      {'text': "Erreur 404 : Soirée introuvable dans le présent. 🌐", 'weight': 20},
      {'text': "C'était le choix cornélien, t'as pris l'option d dodo. 🛌", 'weight': 15},
      {'text': "Retour vers le futur ? Non, pas de Doc ici. 🚗💨", 'weight': 10},
      {'text': "Même le BDE a fini de cuver. C'est dire. 🫗", 'weight': 15},
      {'text': "La légende raconte que certains dorment encore sur place. ⛺", 'weight': 10},
      {'text': "Le ménage est fait, les fûts sont vides. Rentre chez toi. 🧹", 'weight': 8},
      {'text': "T'as confondu le calendrier avec ton emploi du temps de l'UV ? 🗓️", 'weight': 5},
    ];
    return _getRandomMessage(pool, eventName);
  }

  String _getFullMessage(String eventName, int maxPlaces) {
    final List<Map<String, dynamic>> pool = [
      {'text': "Pas assez rapide... Skill issue. ⚰️", 'weight': 40},
      {'text': "Plus de places. Victime de son succès ! 📈", 'weight': 40},
      {'text': "Sold out ! Fallait pas bégayer au clic. 🛑", 'weight': 35},
      {'text': "La billetterie a fondu. C'est complet ! 🔥", 'weight': 30},
      {'text': "Reste dehors, c'est blindé de chez blindé. 🚪", 'weight': 30},
      {'text': "T'as cru qu'on t'attendait ? Y'a plus rien ! 🤷‍♂️", 'weight': 25},
      {'text': "Not clear! Quelqu'un a ruiné le serveur. 💥", 'weight': 15},
      {'text': "Sélection naturelle par la fibre optique. 🌐", 'weight': 15},
      {'text': "T'as cru que c'était les restos du cœur ? 💸", 'weight': 10},
      {'text': "T'as cru que tu t'appelais Charles ? 😏", 'weight': 10},
      {'text': "Il ne reste que des miettes et de la sueur. 🧀", 'weight': 8},
      {'text': "Même avec $maxPlaces places, t'as raté le shotgun. Souffle dans le ballon avant de prendre le volant 🚔", 'weight': 25},
      {'text': "Y'avait $maxPlaces places dispo et t'as réussi à finir sur le trottoir. Bravo. 🎪", 'weight': 20},
      {'text': "Y'a plus de places que de moyenne à ton prochain DS, et pourtant t'as raté le coche. 📉", 'weight': 15},
      {'text': "Ton ping est plus élevé que tes chances de valider l'année. 📡", 'weight': 12},
      {'text': "Va falloir corrompre le président du BDE là, parce que c'est mort. 💼", 'weight': 10},
      {'text': "Même en distanciel tu serais arrivé en retard. 💻", 'weight': 8},
      {'text': "Tu n'es pas invité à la fête du pipi caca ! 💩", 'weight': 2},
    ];
    return _getRandomMessage(pool, eventName);
  }

  String _getNotificationMessage(String eventName) {
    final List<Map<String, dynamic>> pool = [
      {'text': "Tu seras notifié chef, t'inquiète même pas ! 🔔🫡", 'weight': 40},
      {'text': "Rappel activé ! Reste à l'affût, ça va partir vite. 🏎️💨", 'weight': 40},
      {'text': "C'est bon boss, ton réveil est branché sur le serveur ! ⏰⚡", 'weight': 35},
      {'text': "Noté ! Ne va pas pleurer si ton téléphone vibre en plein amphi. 🤫📱", 'weight': 30},
      {'text': "Demande reçue. Prépare tes meilleurs réflexes pour le jour J ! 🎯🕹️", 'weight': 30},
      {'text': "Rappel programmé ! Pas d'excuse pour rater le train cette fois. 🚂🎫", 'weight': 25},
      {'text': "Le robot du shotgun a enregistré ton blaze. À la guerre comme à la guerre ! 🤖⚔️", 'weight': 20},
      {'text': "Pas de bégaiement prévu, on te bipe dès que les vannes s'ouvrent ! 🌊🔔", 'weight': 15},
      {'text': "Inscrit aux alertes ! Que la puissance de ton réseau soit avec toi. 📶🙏", 'weight': 15},
    ];
    return _getRandomMessage(pool, eventName);
  }

  String _openBilleterieNotificationMessage(String eventName) {
    final List<String> pool = [
      "C'est ouvert ! Fonce prendre ta place pour $eventName ! 🚀🎉",
      "La billetterie pour $eventName is now open ! C'est le moment de dégainer. 🎯🕹️",
      "Le shotgun pour $eventName est officiellement lancé ! Que la chasse commence ! 🏹🔥",
      "C'est parti pour $eventName ! Ne laisse pas passer ta chance cette fois. 🚂🎫",
      "La billetterie de $eventName vient d'ouvrir ! Prépare tes meilleurs réflexes pour le jour J ! 🎯🕹️",
    ];

    final random = Random();
    return pool[random.nextInt(pool.length)];
  }

  Future<void> _toggleRappel(String eventId, String eventName, Timestamp? dateOuverture, bool currentlyHasReminder) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Vous devez être connecté pour modifier vos favoris ! 🔐");
      return;
    }

    setState(() => _isProcessing = true);
    final reminderDocRef = FirebaseFirestore.instance.collection('reminders').doc("${user.uid}_$eventId");

    try {
      if (currentlyHasReminder) {
        await reminderDocRef.delete();
        _showSnackBar("Événement retiré de tes favoris. 💔", isSuccess: true);
      } else {
        await reminderDocRef.set({
          'userId': user.uid,
          'eventId': eventId,
          'createdAt': FieldValue.serverTimestamp(),
          'notified': false,
        });

        if (dateOuverture != null) {
          final DateTime scheduledDateTime = dateOuverture.toDate();
          if (scheduledDateTime.isAfter(DateTime.now())) {
            await NotificationService().scheduleNotification(
              id: eventId.hashCode.abs(),
              title: '🔥 SHOTGUN OUVERT !',
              body: _openBilleterieNotificationMessage(eventName),
              scheduledDate: scheduledDateTime,
            );
            _showSnackBar("Ajouté aux favoris ! Alerte enregistrée. 🔔🚀", isSuccess: true);
          } else {
            _showSnackBar("Ajouté à ta liste d'intérêts ! ❤️", isSuccess: true);
          }
        } else {
          _showSnackBar("Ajouté à ta liste d'intérêts ! ❤️", isSuccess: true);
        }
      }
    } catch (e) {
      _showSnackBar("Erreur : ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _reserverPlace(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showSnackBar("Vous devez être connecté pour participer ! 🔐");
      return;
    }

    setState(() => _isProcessing = true);

    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final billetsCollection = FirebaseFirestore.instance.collection('billets');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        DocumentSnapshot eventSnapshot = await transaction.get(eventRef);

        if (!eventSnapshot.exists) {
          throw Exception("L'événement n'existe pas ! ❌");
        }

        Map<String, dynamic> data = eventSnapshot.data() as Map<String, dynamic>;

        Timestamp? dateOuverture = data['dateOuvertureBilletterie'] as Timestamp?;
        if (dateOuverture != null && dateOuverture.toDate().isAfter(DateTime.now())) {
          throw Exception("La billetterie n'est pas encore ouverte ! ⏳");
        }

        final existingTicketQuery = await billetsCollection
            .where('userId', isEqualTo: user.uid)
            .where('eventId', isEqualTo: eventId)
            .limit(1)
            .get();

        if (existingTicketQuery.docs.isNotEmpty) {
          throw Exception("Tu as déjà ton billet pour cet événement ! 🎫");
        }

        int currentPlaces = data['placesRestantes'] ?? 0;
        Timestamp? dateHeure = data['dateHeureEvent'] as Timestamp?;

        if (dateHeure != null && dateHeure.toDate().isBefore(DateTime.now())) {
          throw Exception("L'événement est déjà passé ! ⏳");
        }

        if (currentPlaces <= 0) {
          throw Exception("Plus de places disponibles ! 😭");
        }

        transaction.update(eventRef, {
          'placesRestantes': currentPlaces - 1,
        });

        DocumentReference newBilletRef = billetsCollection.doc();
        transaction.set(newBilletRef, {
          'userId': user.uid,
          'eventId': eventId,
          'createdAt': FieldValue.serverTimestamp(),
          'scanAt': null,
        });
      });

      _showSnackBar("SHOTGUN RÉUSSI ! Ton billet est réservé. 🚀🎉", isSuccess: true);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _seDesinscrire(String eventId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isProcessing = true);

    final eventRef = FirebaseFirestore.instance.collection('events').doc(eventId);
    final billetsCollection = FirebaseFirestore.instance.collection('billets');

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final ticketQuery = await billetsCollection
            .where('userId', isEqualTo: user.uid)
            .where('eventId', isEqualTo: eventId)
            .limit(1)
            .get();

        if (ticketQuery.docs.isEmpty) {
          throw Exception("Aucun billet trouvé pour cet événement ! ❌");
        }

        final billetDocRef = billetsCollection.doc(ticketQuery.docs.first.id);

        DocumentSnapshot eventSnapshot = await transaction.get(eventRef);
        if (!eventSnapshot.exists) {
          throw Exception("L'événement n'existe pas ! ❌");
        }

        Map<String, dynamic> data = eventSnapshot.data() as Map<String, dynamic>;
        int currentPlaces = data['placesRestantes'] ?? 0;

        transaction.delete(billetDocRef);
        transaction.update(eventRef, {
          'placesRestantes': currentPlaces + 1,
        });
      });

      _showSnackBar("Désinscription prise en compte. Place libérée ! 🫡👋", isSuccess: true);
    } catch (e) {
      _showSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.jura(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isSuccess ? const Color(0xFF2EC4B6) : const Color(0xFFE63946),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _buildBannerImage(String base64Image) {
    if (base64Image.isNotEmpty) {
      try {
        return Image.memory(
          base64Decode(base64Image),
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
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF0B0914)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.eventData['nom'] ?? 'Événement';
    final description = widget.eventData['description'] ?? 'Aucune description.';
    final lieu = widget.eventData['lieu'] ?? 'Lieu non spécifié';
    final idOrganisateur = widget.eventData['idOrganisateur'] ?? '';
    final capaciteMax = widget.eventData['capaciteMax'] ?? 0;
    final currentUser = FirebaseAuth.instance.currentUser;

    if (_isLoadingUser) {
      return const Scaffold(
        backgroundColor: Color(0xFF0B0914),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD))),
      );
    }

    final bool isMyOwnOrganisedEvent = (_userRole == 'ORGANISATEUR' && _useridOrganisateur == idOrganisateur);

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('events').doc(widget.eventId).snapshots(),
        builder: (context, eventSnapshot) {
          int placesRestantes = widget.eventData['placesRestantes'] ?? 0;
          Timestamp? dateHeure = widget.eventData['dateHeureEvent'] as Timestamp?;
          Timestamp? dateOuvertureBilletterie = widget.eventData['dateOuvertureBilletterie'] as Timestamp?;
          String eventImageBase64 = widget.eventData['image'] ?? '';

          if (eventSnapshot.hasData && eventSnapshot.data!.exists) {
            final freshData = eventSnapshot.data!.data() as Map<String, dynamic>;
            placesRestantes = freshData['placesRestantes'] ?? placesRestantes;
            dateHeure = freshData['dateHeureEvent'] as Timestamp? ?? dateHeure;
            dateOuvertureBilletterie = freshData['dateOuvertureBilletterie'] as Timestamp? ?? dateOuvertureBilletterie;
            eventImageBase64 = freshData['image'] ?? eventImageBase64;
          }

          final now = DateTime.now();
          final bool isPast = dateHeure != null && dateHeure.toDate().isBefore(now);
          final bool noPlacesLeft = placesRestantes <= 0;
          final bool isBilletterieLocked = dateOuvertureBilletterie != null && dateOuvertureBilletterie.toDate().isAfter(now);

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('billets')
                .where('userId', isEqualTo: currentUser?.uid)
                .where('eventId', isEqualTo: widget.eventId)
                .snapshots(),
            builder: (context, billetSnapshot) {
              final bool hasTicket = billetSnapshot.hasData && billetSnapshot.data!.docs.isNotEmpty;

              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('reminders')
                    .doc("${currentUser?.uid}_${widget.eventId}")
                    .snapshots(),
                builder: (context, reminderSnapshot) {
                  final bool hasReminder = reminderSnapshot.hasData && reminderSnapshot.data!.exists;

                  String buttonText = "M'INSCRIRE";
                  bool isButtonEnabled = true;
                  IconData buttonIcon = Icons.local_activity_outlined;

                  if (isMyOwnOrganisedEvent) {
                    buttonText = "GÉRER MON ÉVÉNEMENT";
                    isButtonEnabled = true;
                    buttonIcon = Icons.admin_panel_settings_outlined;
                  } else if (hasTicket) {
                    buttonText = "INSCRIT ! Place réservée 🎫";
                    isButtonEnabled = false;
                  } else if (isPast) {
                    buttonText = _getPastMessage(title);
                    isButtonEnabled = false;
                  } else if (isBilletterieLocked) {
                    if (hasReminder) {
                      buttonText = _getNotificationMessage(title);
                      isButtonEnabled = false;
                    } else {
                      buttonText = "RECEVOIR UNE NOTIFICATION";
                      isButtonEnabled = true;
                      buttonIcon = Icons.notifications_active_outlined;
                    }
                  } else if (noPlacesLeft) {
                    buttonText = _getFullMessage(title, capaciteMax);
                    isButtonEnabled = false;
                  }

                  return Stack(
                    children: [
                      SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 250,
                              width: double.infinity,
                              child: _buildBannerImage(eventImageBase64),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: GoogleFonts.jura(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    description,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[300],
                                      height: 1.4,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance.collection('organizers').doc(idOrganisateur).get(),
                                    builder: (context, orgSnapshot) {
                                      String displayName = 'Chargement...';
                                      if (orgSnapshot.hasData && orgSnapshot.data!.exists) {
                                        final orgData = orgSnapshot.data!.data() as Map<String, dynamic>;
                                        displayName = orgData['nom'] ?? idOrganisateur;
                                      } else if (orgSnapshot.connectionState == ConnectionState.done) {
                                        displayName = idOrganisateur.isNotEmpty ? idOrganisateur : 'Inconnu';
                                      }
                                      return Row(
                                        children: [
                                          const Text(
                                            'organisé par ',
                                            style: TextStyle(color: Colors.grey, fontSize: 16),
                                          ),
                                          Text(
                                            displayName,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Container(width: 120, height: 1, color: Colors.grey[800]),
                                  const SizedBox(height: 24),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Du ${_formatFullDate(dateHeure)}',
                                        style: const TextStyle(color: Colors.white, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Lieu : $lieu',
                                        style: const TextStyle(color: Colors.white, fontSize: 15),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Container(width: 160, height: 1, color: Colors.grey[800]),
                                  const SizedBox(height: 24),
                                  Text(
                                    'Places disponibles : $placesRestantes / $capaciteMax',
                                    style: GoogleFonts.jura(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: noPlacesLeft ? Colors.redAccent : Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 180),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        right: 10,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              hasReminder ? Icons.favorite : Icons.favorite_border_rounded,
                              color: hasReminder ? const Color(0xFF9D4EDD) : Colors.white,
                              size: 26,
                            ),
                            onPressed: _isProcessing
                                ? null
                                : () => _toggleRappel(widget.eventId, title, dateOuvertureBilletterie, hasReminder),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 20,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isBilletterieLocked && !isMyOwnOrganisedEvent) ...[
                              Text(
                                "Ouverture shotgun le\n${_formatSimpleDate(dateOuvertureBilletterie)}",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.jura(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            isButtonEnabled
                                ? ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                if (isMyOwnOrganisedEvent) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ManageEventView(
                                        eventId: widget.eventId,
                                        eventData: widget.eventData,
                                      ),
                                    ),
                                  );
                                } else if (isBilletterieLocked) {
                                  _toggleRappel(widget.eventId, title, dateOuvertureBilletterie, hasReminder);
                                } else {
                                  _reserverPlace(widget.eventId);
                                }
                              },
                              icon: _isProcessing
                                  ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                                  : Icon(
                                buttonIcon,
                                size: 28,
                              ),
                              label: Text(
                                _isProcessing ? "CHARGEMENT..." : buttonText,
                                style: GoogleFonts.jura(
                                  fontSize: (isMyOwnOrganisedEvent) ? 18 : 22,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isMyOwnOrganisedEvent ? const Color(0xFF4EA8DE) : const Color(0xFF9D4EDD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                minimumSize: const Size.fromHeight(56),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 6,
                              ),
                            )
                                : Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                              decoration: BoxDecoration(
                                color: hasTicket
                                    ? const Color(0xFF2EC4B6).withOpacity(0.2)
                                    : (hasReminder ? const Color(0xFF9D4EDD).withOpacity(0.15) : Colors.grey[900]),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                    color: hasTicket
                                        ? const Color(0xFF2EC4B6)
                                        : (hasReminder ? const Color(0xFF9D4EDD) : Colors.transparent),
                                    width: 1.5
                                ),
                              ),
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    buttonText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.jura(
                                      color: hasTicket
                                          ? const Color(0xFF2EC4B6)
                                          : (hasReminder ? const Color(0xFFB776EE) : Colors.grey[500]),
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            if (hasTicket && !isMyOwnOrganisedEvent) ...[
                              const SizedBox(height: 12),
                              TextButton.icon(
                                onPressed: _isProcessing ? null : () => _seDesinscrire(widget.eventId),
                                icon: _isProcessing
                                    ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.redAccent, strokeWidth: 2)
                                )
                                    : const Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 20),
                                label: Text(
                                  _isProcessing ? "TRAITEMENT..." : "Se désinscrire de l'événement",
                                  style: GoogleFonts.jura(
                                    color: Colors.redAccent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}