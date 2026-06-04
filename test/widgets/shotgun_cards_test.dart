import 'package:buckshot/widgets/shotgun_banner.dart';
import 'package:buckshot/widgets/shotgun_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ShotgunBanner affiche les informations et reagit au tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShotgunBanner(
            title: 'Gala INSA',
            description: 'Grand gala annuel',
            date: '05/06',
            hours: '20h',
            imageUrl: '',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Gala INSA'), findsOneWidget);
    expect(find.text('Grand gala annuel'), findsOneWidget);
    expect(find.text('05/06'), findsOneWidget);
    expect(find.text('20h'), findsOneWidget);

    await tester.tap(find.byType(ShotgunBanner));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('ShotgunItem separe les horaires debut et fin', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ShotgunItem(
            title: 'Soiree test',
            date: '15/07',
            hours: '18h - 02h',
            imageUrl: '',
          ),
        ),
      ),
    );

    expect(find.text('Soiree test'), findsOneWidget);
    expect(find.text('15/07'), findsOneWidget);
    expect(find.text('18h'), findsOneWidget);
    expect(find.text('02h'), findsOneWidget);
  });
}
