import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import 'package:buckshot/buckshot_theme.dart';

class EditEventView extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const EditEventView({
    super.key,
    required this.eventId,
    required this.eventData,
  });

  @override
  State<EditEventView> createState() => _EditEventViewState();
}

class _EditEventViewState extends State<EditEventView> {
  DateTime? selectedStartDate;
  TimeOfDay? selectedStartTime;
  DateTime? selectedEndDate;
  TimeOfDay? selectedEndTime;
  DateTime? selectedOpenDate;
  TimeOfDay? selectedOpenTime;
  DateTime? selectedCloseDate;
  TimeOfDay? selectedCloseTime;

  File? _imageFile;
  String _currentBase64Image = '';
  bool _isLoading = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _seatsController;

  final Color neonPink = const Color(0xFFE5097F);
  final Color neonPurple = const Color(0xFF9146FF);
  final Color darkInputBg = const Color(0xFF1D1B26);
  final Color neonGlowColor = const Color(0xFF5D1F9B);

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.eventData['nom'] ?? '');
    _descriptionController = TextEditingController(text: widget.eventData['description'] ?? '');
    _locationController = TextEditingController(text: widget.eventData['lieu'] ?? '');
    _seatsController = TextEditingController(text: (widget.eventData['capaciteMax'] ?? 0).toString());

    _currentBase64Image = widget.eventData['image'] ?? '';

    _parseFirestoreDates();
  }

  void _parseFirestoreDates() {
    if (widget.eventData['dateHeureEvent'] is Timestamp) {
      final dt = (widget.eventData['dateHeureEvent'] as Timestamp).toDate();
      selectedStartDate = dt;
      selectedStartTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (widget.eventData['dateFinEvent'] is Timestamp) {
      final dt = (widget.eventData['dateFinEvent'] as Timestamp).toDate();
      selectedEndDate = dt;
      selectedEndTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (widget.eventData['dateOuvertureBilletterie'] is Timestamp) {
      final dt = (widget.eventData['dateOuvertureBilletterie'] as Timestamp).toDate();
      selectedOpenDate = dt;
      selectedOpenTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
    if (widget.eventData['dateFermetureBilletterie'] is Timestamp) {
      final dt = (widget.eventData['dateFermetureBilletterie'] as Timestamp).toDate();
      selectedCloseDate = dt;
      selectedCloseTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
    }
  }

  void _showImageSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF12101A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Modifier l'affiche",
                  style: GoogleFonts.jura(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined, color: neonPink),
                  title: Text(
                    "Choisir depuis la galerie",
                    style: GoogleFonts.jura(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const Divider(color: Colors.white10),
                ListTile(
                  leading: Icon(Icons.camera_alt_outlined, color: neonPurple),
                  title: Text(
                    "Prendre une photo",
                    style: GoogleFonts.jura(color: Colors.white, fontSize: 16),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<File> resizeImage(File imageFile, {int maxWidth = 1080}) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) return imageFile;

    if (image.width > maxWidth) {
      final resized = img.copyResize(image, width: maxWidth);
      final resizedBytes = img.encodeJpg(resized, quality: 85);
      return File(imageFile.path)..writeAsBytesSync(resizedBytes);
    }
    return imageFile;
  }

  Future<String?> imageToBase64(File? imageFile) async {
    if (imageFile == null) return _currentBase64Image;

    final resizedFile = await resizeImage(imageFile, maxWidth: 400);
    final bytes = await resizedFile.readAsBytes();
    final base64 = base64Encode(bytes);

    if (base64.length > 1048576) {
      _showSnackBar("L'image est trop lourde, veuillez en choisir une autre. 📂");
      return null;
    }
    return base64;
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.jura(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: isSuccess ? const Color(0xFF2EC4B6) : const Color(0xFFE63946),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _selectDateTime({
    required bool isStart,
    required bool isOpen,
    required bool isClose,
  }) async {
    final pickerTheme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.dark(
        primary: neonPurple,
        onPrimary: Colors.white,
        surface: const Color(0xFF161420),
        onSurface: Colors.white,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: GoogleFonts.jura(fontWeight: FontWeight.bold),
          foregroundColor: neonPink,
        ),
      ),
    );

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(data: pickerTheme, child: child!),
    );

    if (pickedDate != null) {
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        initialEntryMode: TimePickerEntryMode.input,
        builder: (context, child) => Theme(data: pickerTheme, child: child!),
      );

      if (pickedTime != null) {
        setState(() {
          if (isStart) {
            selectedStartDate = pickedDate;
            selectedStartTime = pickedTime;
          } else if (isOpen) {
            selectedOpenDate = pickedDate;
            selectedOpenTime = pickedTime;
          } else if (isClose) {
            selectedCloseDate = pickedDate;
            selectedCloseTime = pickedTime;
          } else {
            selectedEndDate = pickedDate;
            selectedEndTime = pickedTime;
          }
        });
      }
    }
  }

  String _getFormattedDateTime(DateTime? date, TimeOfDay? time, String defaultHint) {
    if (date == null || time == null) return defaultHint;
    final String formattedDate = DateFormat('dd/MM/yyyy').format(date);
    final String formattedTime = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return "$formattedDate à $formattedTime";
  }

  void _validateAndSave() async {
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar("Le titre de l'événement est obligatoire ! 🏷️");
      return;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showSnackBar("La description est obligatoire ! 📝");
      return;
    }
    if (selectedStartDate == null || selectedStartTime == null) {
      _showSnackBar("La date et l'heure de début sont obligatoires ! 🗓️");
      return;
    }
    if (selectedEndDate == null || selectedEndTime == null) {
      _showSnackBar("La date et l'heure de fin sont obligatoires ! 🏁");
      return;
    }
    if (selectedOpenDate == null || selectedOpenTime == null) {
      _showSnackBar("L'ouverture de la billetterie est obligatoire ! 🚀");
      return;
    }
    if (selectedCloseDate == null || selectedCloseTime == null) {
      _showSnackBar("La fermeture de la billetterie est obligatoire ! 🔒");
      return;
    }
    if (_locationController.text.trim().isEmpty) {
      _showSnackBar("Le lieu est obligatoire ! 📍");
      return;
    }
    if (_seatsController.text.isEmpty || int.tryParse(_seatsController.text) == null) {
      _showSnackBar("Le nombre de places doit être un nombre valide ! 🎟️");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? base64ResultImage = await imageToBase64(_imageFile);
      if (base64ResultImage == null) {
        setState(() => _isLoading = false);
        return;
      }

      final int newCapaciteMax = int.parse(_seatsController.text.trim());
      final int oldCapaciteMax = widget.eventData['capaciteMax'] ?? 0;
      final int oldPlacesRestantes = widget.eventData['placesRestantes'] ?? 0;

      final int placesVendues = oldCapaciteMax - oldPlacesRestantes;
      final int newPlacesRestantes = (newCapaciteMax - placesVendues).clamp(0, newCapaciteMax);

      final DateTime finalStartDate = DateTime(selectedStartDate!.year, selectedStartDate!.month, selectedStartDate!.day, selectedStartTime!.hour, selectedStartTime!.minute);
      final DateTime finalEndDate = DateTime(selectedEndDate!.year, selectedEndDate!.month, selectedEndDate!.day, selectedEndTime!.hour, selectedEndTime!.minute);
      final DateTime finalOpenDate = DateTime(selectedOpenDate!.year, selectedOpenDate!.month, selectedOpenDate!.day, selectedOpenTime!.hour, selectedOpenTime!.minute);
      final DateTime finalCloseDate = DateTime(selectedCloseDate!.year, selectedCloseDate!.month, selectedCloseDate!.day, selectedCloseTime!.hour, selectedCloseTime!.minute);

      await FirebaseFirestore.instance.collection('events').doc(widget.eventId).update({
        'nom': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'lieu': _locationController.text.trim(),
        'capaciteMax': newCapaciteMax,
        'placesRestantes': newPlacesRestantes,
        'dateHeureEvent': Timestamp.fromDate(finalStartDate),
        'dateFinEvent': Timestamp.fromDate(finalEndDate),
        'dateOuvertureBilletterie': Timestamp.fromDate(finalOpenDate),
        'dateFermetureBilletterie': Timestamp.fromDate(finalCloseDate),
        'image': base64ResultImage,
      });

      _showSnackBar("Événement modifié avec succès ! 🛠️✨", isSuccess: true);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Erreur lors de la modification de l'événement : $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildMaquetteInputField({
    required String hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    IconData? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: GoogleFonts.jura(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.jura(color: Colors.grey[500], fontSize: 15),
          filled: true,
          fillColor: darkInputBg,
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey[600], size: 22) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10, width: 1)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10, width: 1)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: neonPink, width: 1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildMaquetteDatePickerField({
    required String currentText,
    required VoidCallback onTap,
    bool hasValue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: darkInputBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  currentText,
                  style: GoogleFonts.jura(
                      color: hasValue ? Colors.white : Colors.grey[500],
                      fontSize: 15
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.calendar_month_outlined, color: Colors.grey[600], size: 22),
            ],
          ),
        ),
      ),
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0D0B14),
        appBar: AppBar(
          title: Text(
            'Modifier l’évènement',
            style: GoogleFonts.jura(color: neonPink, fontWeight: FontWeight.bold, fontSize: 24),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF12101A),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: neonGlowColor.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: neonGlowColor.withOpacity(0.4),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),

                _buildMaquetteInputField(
                  hint: "Titre",
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                ),

                _buildMaquetteInputField(
                  hint: "Description",
                  controller: _descriptionController,
                  maxLines: 4,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                ),

                _buildMaquetteDatePickerField(
                  currentText: _getFormattedDateTime(selectedStartDate, selectedStartTime, "Date et heure de début"),
                  hasValue: selectedStartDate != null,
                  onTap: () => _selectDateTime(isStart: true, isOpen: false, isClose: false),
                ),

                _buildMaquetteDatePickerField(
                  currentText: _getFormattedDateTime(selectedEndDate, selectedEndTime, "Date et heure de fin"),
                  hasValue: selectedEndDate != null,
                  onTap: () => _selectDateTime(isStart: false, isOpen: false, isClose: false),
                ),

                _buildMaquetteDatePickerField(
                  currentText: _getFormattedDateTime(selectedOpenDate, selectedOpenTime, "Date et heure ouverture billetterie"),
                  hasValue: selectedOpenDate != null,
                  onTap: () => _selectDateTime(isStart: false, isOpen: true, isClose: false),
                ),

                _buildMaquetteDatePickerField(
                  currentText: _getFormattedDateTime(selectedCloseDate, selectedCloseTime, "Date et heure fermeture billetterie"),
                  hasValue: selectedCloseDate != null,
                  onTap: () => _selectDateTime(isStart: false, isOpen: false, isClose: true),
                ),

                _buildMaquetteInputField(
                  hint: "Lieu",
                  controller: _locationController,
                  suffixIcon: Icons.location_on_outlined,
                  textInputAction: TextInputAction.next,
                ),

                _buildMaquetteInputField(
                  hint: "Nombre de places",
                  controller: _seatsController,
                  keyboardType: TextInputType.number,
                  suffixIcon: Icons.people_outline,
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 10),

                OutlinedButton.icon(
                  onPressed: _showImageSourcePicker,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: neonPink, width: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: Icon(Icons.add_a_photo_outlined, color: neonPink, size: 22),
                  label: Text(
                    (_imageFile != null || _currentBase64Image.isNotEmpty) ? "Modifier la photo" : "Ajouter une photo",
                    style: GoogleFonts.jura(color: neonPink, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),

                const SizedBox(height: 20),

                if (_imageFile != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                    ),
                  )
                else if (_currentBase64Image.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10, width: 1),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.memory(base64Decode(_currentBase64Image), fit: BoxFit.cover),
                    ),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: neonPurple,
                      disabledBackgroundColor: neonPurple.withOpacity(0.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: _isLoading ? null : _validateAndSave,
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.save_outlined, color: Colors.white, size: 26),
                        const SizedBox(width: 12),
                        Text(
                          "Sauvegarder",
                          style: GoogleFonts.jura(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}