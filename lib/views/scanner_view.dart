import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/scanner_service.dart';

class ScannerView extends StatefulWidget {
  final String eventId;
  final Map<String, dynamic> eventData;

  const ScannerView({
    super.key, 
    required this.eventId, 
    required this.eventData
  });

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  final MobileScannerController cameraController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  late ScannerService _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScannerService(eventId: widget.eventId);
    _controller.addListener(_onControllerContextUpdate);
  }

  void _onControllerContextUpdate() {
    if (mounted) setState(() {});
  }

  String _formatEventDate(Timestamp? timestampStart, Timestamp? timestampEnd) {
    if (timestampStart == null) return 'Date inconnue';
    final DateTime start = timestampStart.toDate();
    final DateFormat formatter = DateFormat('E dd MMM yyyy', 'fr_FR');
    
    String formatTime(DateTime dt) {
      return dt.minute > 0 
          ? DateFormat('HH\'h\'mm').format(dt) 
          : DateFormat('HH\'h\'').format(dt);
    }

    if (timestampEnd != null) {
      final DateTime end = timestampEnd.toDate();
      if (start.day != end.day) {
        return "${formatter.format(start)} ${formatTime(start)} - ${formatter.format(end)} ${formatTime(end)}";
      }
      final String timeRange = "${formatTime(start)} - ${formatTime(end)}";
      return "${formatter.format(start)} | $timeRange";
    }
    
    return "${formatter.format(start)} | ${formatTime(start)}";
  }

  @override
  void dispose() {
    cameraController.dispose();
    _controller.removeListener(_onControllerContextUpdate);
    _controller.disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String title = widget.eventData['nom'] ?? 'Événement';
    final Timestamp? eventDate = widget.eventData['dateHeureEvent'] as Timestamp?;
    final Timestamp? eventDateFin = widget.eventData['dateFinEvent'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0914),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                title,
                style: GoogleFonts.jura(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                _formatEventDate(eventDate, eventDateFin),
                style: GoogleFonts.jura(
                  fontSize: 16,
                  color: Colors.grey[300],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: Center(
                child: _controller.resultState == ScanResultState.none
                    ? SizedBox(
                        width: 310,
                        height: 310,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: MobileScanner(
                                  controller: cameraController,
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    if (barcodes.isNotEmpty && !_controller.isProcessing) {
                                      final String code = barcodes.first.rawValue ?? '';
                                      if (code.isNotEmpty) {
                                        _controller.processQRScan(code);
                                      }
                                    }
                                  },
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 280,
                              height: 280,
                              child: CustomPaint(
                                painter: ScannerBorderPainter(),
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildResultCard(),
              ),
            ),
            if (_controller.resultState != ScanResultState.none)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: OutlinedButton(
                  onPressed: _controller.resetScanner,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFF007F), width: 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: const Size(double.infinity, 54),
                    backgroundColor: const Color(0xFF161224),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Color(0xFFFF007F), size: 24),
                      const SizedBox(width: 12),
                      Text(
                        "Scanner un nouveau billet",
                        style: GoogleFonts.jura(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const SizedBox(height: 94),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    Color glowColor = (_controller.resultState == ScanResultState.success) 
        ? const Color(0xFF39FF14) 
        : const Color(0xFFE63946);

    return Container(
      width: 310,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: const Color(0xFF161224),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glowColor.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: glowColor.withValues(alpha: 0.25),
            blurRadius: 25,
            spreadRadius: 5,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_controller.resultState == ScanResultState.success) ...[
            _buildInfoRow(_controller.studentName),
            const SizedBox(height: 16),
            _buildInfoRow(_controller.ticketIdDisplay),
            const SizedBox(height: 16),
            _buildStatusRow("Accès autorisé", const Color(0xFF39FF14)),
          ] else if (_controller.resultState == ScanResultState.invalid) ...[
            const SizedBox(height: 20),
            _buildStatusRow("Billet invalide", const Color(0xFFE63946)),
            const SizedBox(height: 20),
          ] else if (_controller.resultState == ScanResultState.alreadyScanned) ...[
            _buildInfoRow(_controller.studentName),
            const SizedBox(height: 16),
            _buildInfoRow(_controller.ticketIdDisplay),
            const SizedBox(height: 16),
            _buildStatusRowWithSub("Billet déjà scanné", _controller.scanTimeDisplay, const Color(0xFFE63946)),
          ] else if (_controller.resultState == ScanResultState.wrongEvent) ...[
            _buildInfoRow(_controller.studentName),
            const SizedBox(height: 16),
            _buildInfoRow(_controller.ticketIdDisplay),
            const SizedBox(height: 16),
            _buildStatusRow("Billet pour un autre événement", const Color(0xFFE63946)),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0914).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.jura(color: Colors.white70, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildStatusRow(String mainText, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0914).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          mainText,
          style: GoogleFonts.jura(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildStatusRowWithSub(String mainText, String subText, Color textColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B0914).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            mainText,
            style: GoogleFonts.jura(color: textColor, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 3),
          Text(
            subText,
            style: GoogleFonts.jura(color: textColor.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class ScannerBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 40.0;
    final double radius = 12.0; 

    final pathTopLeft = Path()
      ..moveTo(0, cornerLength)
      ..lineTo(0, radius)
      ..arcToPoint(Offset(radius, 0), radius: Radius.circular(radius))
      ..lineTo(cornerLength, 0);
    canvas.drawPath(pathTopLeft, paint);

    final pathTopRight = Path()
      ..moveTo(size.width - cornerLength, 0)
      ..lineTo(size.width - radius, 0)
      ..arcToPoint(Offset(size.width, radius), radius: Radius.circular(radius))
      ..lineTo(size.width, cornerLength);
    canvas.drawPath(pathTopRight, paint);

    final pathBottomRight = Path()
      ..moveTo(size.width, size.height - cornerLength)
      ..lineTo(size.width, size.height - radius)
      ..arcToPoint(Offset(size.width - radius, size.height), radius: Radius.circular(radius))
      ..lineTo(size.width - cornerLength, size.height);
    canvas.drawPath(pathBottomRight, paint);

    final pathBottomLeft = Path()
      ..moveTo(cornerLength, size.height)
      ..lineTo(radius, size.height)
      ..arcToPoint(Offset(0, size.height - radius), radius: Radius.circular(radius))
      ..lineTo(0, size.height - cornerLength);
    canvas.drawPath(pathBottomLeft, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}