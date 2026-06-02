import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:buckshot/models/event_model.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buckshot/widgets/date_time_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  DateTime? selectedStartDate; //Début évent
  TimeOfDay? selectedStartTime;
  DateTime? selectedEndDate; //Fin évent
  TimeOfDay? selectedEndTime;
  DateTime? selectedOpenDate; //Ouverture billeterie
  TimeOfDay? selectedOpenTime;
  DateTime? selectedCloseDate; // Fermeture billeterie
  TimeOfDay? selectedCloseTime;
  File? _image;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _seatsController = TextEditingController();

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<File> resizeImage(File imageFile, {int maxWidth = 1080}) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes)!;
    if (image.width > maxWidth) {
      final resized = img.copyResize(image, width: maxWidth);
      final resizedBytes = img.encodeJpg(resized, quality: 85);
      return File(imageFile.path)
        ..writeAsBytesSync(resizedBytes);
    }
    return imageFile;
  }


    Future<String?> imageToBase64(File? imageFile) async {
      if (imageFile == null){
        return "";
      }

      final resizedFile = await resizeImage(imageFile, maxWidth: 200);
      final bytes = await resizedFile.readAsBytes();
      final base64 = base64Encode(bytes);

      // Vérifier que la taille Base64 < 1 Mo (1 048 576 octets)
      if (base64.length > 1048576) {
        print("Erreur: L'image en Base64 dépasse 1 Mo !");
        return null;
      }
      return base64;
    }

  void _validate() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le titre est obligatoire !')),
      );
      return;
    }
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La description est obligatoire !')),
      );
      return;
    }
    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le lieu est obligatoire !')),
      );
      return;
    }
    if (_seatsController.text.isEmpty || int.tryParse(_seatsController.text) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nombre de places doit être un nombre valide !')),
      );
      return;
    }
    if (selectedStartDate == null || selectedStartTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date et l\'heure de début sont obligatoires !')),
      );
      return;
    }
    if (selectedEndDate == null || selectedEndTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date et l\'heure de fin sont obligatoires !')),
      );
      return;
    }
    if (selectedOpenDate == null || selectedOpenTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date et l\'heure d\'ouverture sont obligatoires !')),
      );
      return;
    }
    if (selectedCloseDate == null || selectedCloseDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La date et l\'heure de fermeture sont obligatoires !')),
      );
      return;
    }
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('L\'image est obligatoire !')),
      );
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        //if (data['organisation'] == null) return;

        final organizerDoc = await FirebaseFirestore.instance
            .collection('organizers')
            .doc(data['idOrganisateur'])
            .get();

        if (!organizerDoc.exists) return;

        final String key = "event_${_titleController.text}_${selectedStartDate.toString()}";

        final resizedImage = await imageToBase64(_image);

        if (resizedImage == null) return;

        final EventModel eventModel = EventModel(
          id : key,
          nom: _titleController.text,
          description: _descriptionController.text,
          idOrganisateur: data['idOrganisateur'],
          capaciteMax: int.parse(_seatsController.text),
          placesRestantes : int.parse(_seatsController.text),
          lieu: _locationController.text,
          dateHeureEvent: DateTime(selectedStartDate?.year ?? DateTime.now().year,
              selectedStartDate?.month ?? DateTime.now().month,
              selectedStartDate?.day ?? DateTime.now().day,
              selectedStartTime?.hour ?? DateTime.now().hour,
              selectedStartTime?.minute ?? DateTime.now().minute),

          dateFinEvent: DateTime(selectedEndDate?.year ?? DateTime.now().year,
              selectedEndDate?.month ?? DateTime.now().month,
              selectedEndDate?.day ?? DateTime.now().day,
              selectedEndTime?.hour ?? DateTime.now().hour,
              selectedEndTime?.minute ?? DateTime.now().minute),

          dateOuvertureBilletterie: DateTime(selectedOpenDate?.year ?? DateTime.now().year,
              selectedOpenDate?.month ?? DateTime.now().month,
              selectedOpenDate?.day ?? DateTime.now().day,
              selectedOpenTime?.hour ?? DateTime.now().hour,
              selectedOpenTime?.minute ?? DateTime.now().minute),

          dateFermetureBilletterie: DateTime(selectedCloseDate?.year ?? DateTime.now().year,
              selectedCloseDate?.month ?? DateTime.now().month,
              selectedCloseDate?.day ?? DateTime.now().day,
              selectedCloseTime?.hour ?? DateTime.now().hour,
              selectedCloseTime?.minute ?? DateTime.now().minute),
          image: resizedImage,
        );

        await FirebaseFirestore.instance.collection('events').add(eventModel.toFirestore());

        _titleController.text = "";
        _descriptionController.text = "";
        _seatsController.text = "";
        _locationController.text = "";
        selectedStartDate = null;
        selectedStartTime = null;
        selectedEndDate = null;
        selectedEndTime = null;
        selectedOpenDate = null;
        selectedOpenTime = null;
        selectedCloseDate = null;
        selectedCloseTime = null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evènement créé avec succès ! !')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors la création de l\'évènement !')),
      );
    }

    // Si tout est valide
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Événement créé avec succès !')),
    );


  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _seatsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un événement', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withAlpha(77),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // --- Titre ---
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Titre de l'événement",
                      labelStyle: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // --- Description ---
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // --- Date et heure de début ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Date et heure de début",
                      style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DateTimePicker(
                    onDateChanged: (date) => selectedStartDate = date,
                    onTimeChanged: (time) => selectedStartTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Date et heure de fin ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Date et heure de fin",
                      style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DateTimePicker(
                    onDateChanged: (date) => selectedEndDate = date,
                    onTimeChanged: (time) => selectedEndTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Date et heure d'ouverture du shotgun ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Date et heure d'ouverture du shotgun",
                      style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DateTimePicker(
                    onDateChanged: (date) => selectedOpenDate = date,
                    onTimeChanged: (time) => selectedOpenTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Date et heure de fermeture du shotgun ---
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Date et heure de fermeture du shotgun",
                      style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14)
                    ),
                  ),
                  const SizedBox(height: 8),
                  DateTimePicker(
                    onDateChanged: (date) => selectedCloseDate = date,
                    onTimeChanged: (time) => selectedCloseTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Lieu ---
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: "Lieu de l'événement",
                      labelStyle: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // --- Nombre de places ---
                  TextFormField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nombre de places",
                      labelStyle: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Theme.of(context).colorScheme.surface, width: 1)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    style: GoogleFonts.jura(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                  ),
                  const SizedBox(height: 16),

                  // --- Image ---
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Image de l'événement",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          style: BorderStyle.solid,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[900],
                      ),
                      child: _image != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      )
                          : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 40,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyez pour choisir une image',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Bouton Créer ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _validate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text("Créer l'événement"),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}