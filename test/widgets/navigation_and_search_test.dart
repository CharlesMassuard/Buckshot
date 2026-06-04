import 'package:buckshot/widgets/barre_de_navigation.dart';
import 'package:buckshot/widgets/barre_de_recherche.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BarreDeNavigation signale l index selectionne', (tester) async {
    var selectedIndex = -1;
    var tappedLabel = '';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: BarreDeNavigation(
            currentIndex: 0,
            onItemSelected: (index) => selectedIndex = index,
            items: [
              NavItem(icon: Icons.home, label: 'Accueil', onTap: () => tappedLabel = 'Accueil'),
              NavItem(icon: Icons.search, label: 'Recherche', onTap: () => tappedLabel = 'Recherche'),
              NavItem(icon: Icons.person, label: 'Profil', onTap: () => tappedLabel = 'Profil'),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.search));
    await tester.pump();

    expect(selectedIndex, 1);
    expect(tappedLabel, 'Recherche');
  });

  testWidgets('BarreDeRecherche emet les saisies puis une valeur vide au clear', (tester) async {
    final controller = TextEditingController();
    final emittedValues = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: BarreDeRecherche(
              controller: controller,
              onChanged: emittedValues.add,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(SearchBar), 'gala');
    await tester.pump();

    expect(controller.text, 'gala');
    expect(emittedValues, contains('gala'));

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(emittedValues.last, isEmpty);
  });
}
