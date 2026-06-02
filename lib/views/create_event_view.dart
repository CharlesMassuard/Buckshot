import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:buckshot/widgets/date_time_picker.dart';

class CreateEventView extends StatefulWidget {
  const CreateEventView({super.key});

  @override
  State<CreateEventView> createState() => _CreateEventViewState();
}

class _CreateEventViewState extends State<CreateEventView> {
  DateTime? selectedStartDate;
  TimeOfDay? selectedStartTime;
  DateTime? selectedEndDate;
  TimeOfDay? selectedEndTime;
  DateTime? selectedOpenDate;
  TimeOfDay? selectedOpenTime;
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

  void _validate() {
    if (_titleController.text.isEmpty) {
      _showSnackBar('Le titre est obligatoire !');
      return;
    }
    if (_descriptionController.text.isEmpty) {
      _showSnackBar('La description est obligatoire !');
      return;
    }
    if (_locationController.text.isEmpty) {
      _showSnackBar('Le lieu est obligatoire !');
      return;
    }
    if (_seatsController.text.isEmpty || int.tryParse(_seatsController.text) == null) {
      _showSnackBar('Le nombre de places doit être un nombre valide !');
      return;
    }
    if (selectedStartDate == null || selectedStartTime == null) {
      _showSnackBar('La date et l\'heure de début sont obligatoires !');
      return;
    }
    if (selectedEndDate == null || selectedEndTime == null) {
      _showSnackBar('La date et l\'heure de fin sont obligatoires !');
      return;
    }
    if (selectedOpenDate == null || selectedOpenTime == null) {
      _showSnackBar('La date et l\'heure d\'ouverture sont obligatoires !');
      return;
    }

    // Si tout est valide
    _showSnackBar('Événement créé avec succès !');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
    final theme = Theme.of(context);

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
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              border: Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.primary.withAlpha(77),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
              color: theme.colorScheme.surface,
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
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      fillColor: theme.colorScheme.surface,
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // --- Description ---
                  TextFormField(
                    controller: _descriptionController,
                    keyboardType: TextInputType.multiline,
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      fillColor: theme.colorScheme.surface,
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // --- Date de début ---
                  _buildDateLabel("Date et heure de début"),
                  DateTimePicker(
                    onDateChanged: (date) => selectedStartDate = date,
                    onTimeChanged: (time) => selectedStartTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Date de fin ---
                  _buildDateLabel("Date et heure de fin"),
                  DateTimePicker(
                    onDateChanged: (date) => selectedEndDate = date,
                    onTimeChanged: (time) => selectedEndTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Shotgun ---
                  _buildDateLabel("Date et heure d'ouverture du shotgun"),
                  DateTimePicker(
                    onDateChanged: (date) => selectedOpenDate = date,
                    onTimeChanged: (time) => selectedOpenTime = time,
                  ),
                  const SizedBox(height: 16),

                  // --- Lieu ---
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      labelText: "Lieu de l'événement",
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      fillColor: theme.colorScheme.surface,
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // --- Places ---
                  TextFormField(
                    controller: _seatsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Nombre de places",
                      labelStyle: TextStyle(color: theme.colorScheme.primary),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                      ),
                      fillColor: theme.colorScheme.surface,
                      filled: true,
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // --- Zone Image ---
                  _buildDateLabel("Image de l'événement"),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.colorScheme.primary),
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.grey[900],
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, color: theme.colorScheme.primary, size: 40),
                                  const SizedBox(height: 8),
                                  Text('Appuyez pour choisir une image', style: TextStyle(color: theme.colorScheme.primary)),
                                ],
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Bouton Sauvegarder ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _validate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.save),
                      label: const Text("Créer l'événement"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateLabel(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}