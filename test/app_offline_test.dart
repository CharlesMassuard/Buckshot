import 'package:buckshot/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp affiche le mode hors-ligne quand Firebase est indisponible', (tester) async {
    await tester.pumpWidget(const MyApp(isFirebaseReady: false));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.textContaining('Mode hors-ligne'), findsOneWidget);
    expect(find.byType(StreamBuilder), findsNothing);
  });
}
