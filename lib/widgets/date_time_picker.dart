import 'package:flutter/material.dart';

class DateTimePicker extends StatefulWidget {
  final ValueChanged<DateTime?> onDateChanged;
  final ValueChanged<TimeOfDay?> onTimeChanged;

  const DateTimePicker({
    super.key,
    required this.onDateChanged,
    required this.onTimeChanged,
  });

  @override
  State<DateTimePicker> createState() => _DateTimePickerState();
}

class _DateTimePickerState extends State<DateTimePicker> {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  @override
  void dispose() {
    super.dispose();
  }

  void resetData(){
    selectedDate = null;
    selectedTime = null;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell( // Date et heure de début
      onTap: _pickDateTime, // Déclenche l'ouverture au clic
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xff0d0c12),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              "${selectedDate != null
                  ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                  : 'Date'} ${selectedTime != null
                  ? '${selectedTime!.hour}:${selectedTime!.minute}'
                  : 'et heure'}",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w300,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );

  }

  // Fonction pour ouvrir les sélecteurs de date puis d'heure
  Future<void> _pickDateTime() async {
    // D'abord sélection de la date
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: selectedDate ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030)
    );

    if (pickedDate == null) return; // L'utilisateur a annulé

    // Puis sélection de l'heure
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(selectedDate ?? DateTime.now()),
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return; // L'utilisateur a annulé

    setState(() {
      selectedDate = pickedDate;
      selectedTime = pickedTime;
    });

    widget.onDateChanged(pickedDate);
    widget.onTimeChanged(pickedTime);
  }
}