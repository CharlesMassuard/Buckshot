import 'package:flutter/material.dart';
import 'package:buckshot/widgets/ChampsTextForm.dart'; // adapte le chemin

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Connectez-vous !',
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
              const SizedBox(height: 16),

              // Champ mot de passe
              ChampsTextForm(
                label: 'Mot de passe',
                controller: _passwordController,
                obscureText: true,
              ),
              const SizedBox(height: 32),

              // Bouton de connexion
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    // (service auth)
                  },
                  child: const Text('Se connecter'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}