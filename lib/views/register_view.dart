import 'package:flutter/material.dart';
import 'package:buckshot/widgets/ChampsTextForm.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}
//TODO ajouter les onChanged
class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmedPasswordController =TextEditingController();
  //pour les sécurités pour item sécurisation utiliser onChanged sur les widgets Text form field 

  final _lastnameController = TextEditingController();
  final _firstnameController = TextEditingController();
  

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmedPasswordController.dispose();
    _lastnameController.dispose();
    _firstnameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Creer votre compte !',
                style: TextStyle(
                  color: colors.onBackground,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),

              // Champ email
              ChampsTextForm(
                label: 'Email',
                controller: _emailController,
              ),
              const SizedBox(height: 32),

              // Champ mot de passe
              ChampsTextForm(
                label: 'Mot de passe',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              //Confirmation de mot de passse 
              ChampsTextForm(
                label: 'Confirmer votre mot de passe',
                controller: _confirmedPasswordController,
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Bouton d'inscription
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // (...,verification de l'email, puis service inscription)
                  },
                  child: const Text('Créer mon compte'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}