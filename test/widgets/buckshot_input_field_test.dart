import 'package:buckshot/widgets/buckshot_input_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BuckshotInputField affiche les erreurs de validation', (tester) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(
            key: formKey,
            child: BuckshotInputField(
              controller: controller,
              hintText: 'Adresse mail',
              validator: (value) => value == null || value.isEmpty ? 'Champ obligatoire' : null,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Adresse mail'), findsOneWidget);

    formKey.currentState!.validate();
    await tester.pump();

    expect(find.text('Champ obligatoire'), findsOneWidget);
  });

  testWidgets('BuckshotInputField permet de basculer la visibilite du mot de passe', (tester) async {
    final controller = TextEditingController(text: 'Secret123!');
    var isObscured = true;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            return Scaffold(
              body: BuckshotInputField(
                controller: controller,
                hintText: 'Mot de passe',
                isPassword: true,
                isObscured: isObscured,
                onToggleObscure: () => setState(() => isObscured = !isObscured),
              ),
            );
          },
        ),
      ),
    );

    TextFormField field() => tester.widget<TextFormField>(find.byType(TextFormField));

    expect(field().obscureText, isTrue);
    expect(find.byIcon(Icons.visibility_off), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_off));
    await tester.pump();

    expect(field().obscureText, isFalse);
    expect(find.byIcon(Icons.visibility), findsOneWidget);
  });
}
