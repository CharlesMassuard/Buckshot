import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum ScanResultState { none, success, invalid, alreadyScanned, wrongEvent }

class ScannerService extends ChangeNotifier {
  final String eventId;
  
  bool _isProcessing = false;
  ScanResultState _resultState = ScanResultState.none;
  String _studentName = '';
  String _ticketIdDisplay = '';
  String _scanTimeDisplay = '';
  bool _isMounted = true;

  ScannerService({required this.eventId});

  bool get isProcessing => _isProcessing;
  ScanResultState get resultState => _resultState;
  String get studentName => _studentName;
  String get ticketIdDisplay => _ticketIdDisplay;
  String get scanTimeDisplay => _scanTimeDisplay;

  Future<void> processQRScan(String ticketId) async {
    if (_isProcessing || _resultState != ScanResultState.none) return;
    
    _isProcessing = true;
    _ticketIdDisplay = ticketId;
    _notify();

    try {
      final billetDoc = await FirebaseFirestore.instance.collection('billets').doc(ticketId).get();

      if (!billetDoc.exists) {
        _resultState = ScanResultState.invalid;
        _startAutoResetTimer();
        return;
      }

      final billetData = billetDoc.data()!;
      final String ticketEventId = billetData['eventId'] ?? '';
      final String userId = billetData['userId'] ?? '';
      final Timestamp? existingScan = billetData['scanAt'] as Timestamp?;

      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        final String prenom = userData['prenom'] ?? '';
        final String nom = userData['nom'] ?? '';
        _studentName = "$prenom $nom".trim();
      } else {
        _studentName = "Étudiant inconnu";
      }

      if (ticketEventId != eventId) {
        _resultState = ScanResultState.wrongEvent;
        _startAutoResetTimer();
        return;
      }

      if (existingScan != null) {
        _scanTimeDisplay = DateFormat('le dd MMM yyyy à HH\'h\'mm', 'fr_FR').format(existingScan.toDate());
        _resultState = ScanResultState.alreadyScanned;
        _startAutoResetTimer();
        return;
      }

      await FirebaseFirestore.instance.collection('billets').doc(ticketId).update({
        'scanAt': FieldValue.serverTimestamp(),
        'scannedBy': userId,
      });

      _resultState = ScanResultState.success;
      _startAutoResetTimer();

    } catch (e) {
      _resultState = ScanResultState.invalid;
      _startAutoResetTimer();
    } finally {
      _isProcessing = false;
      _notify();
    }
  }

  void _startAutoResetTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (_resultState != ScanResultState.none) {
        resetScanner();
      }
    });
  }

  void resetScanner() {
    _resultState = ScanResultState.none;
    _studentName = '';
    _ticketIdDisplay = '';
    _scanTimeDisplay = '';
    _notify();
  }

  void _notify() {
    if (_isMounted) notifyListeners();
  }

  void disposeController() {
    _isMounted = false;
  }
}