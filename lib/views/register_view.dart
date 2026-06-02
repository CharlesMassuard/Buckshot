import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'login_view.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController(); // Utilisé pour le Prénom
  final _lastNameController = TextEditingController();  // Utilisé pour le Nom
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isObscured = true;
  bool _isConfirmObscured = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _signUp() async {
    final username = _usernameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    // Vérification que TOUS les champs sont remplis
    if (username.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError("Remplis tout, on n'est pas aux devinettes ici ! 📝");
      return;
    }
    if (password != confirm) {
      _showError("Tes mots de passe ne sont pas jumeaux... 👯‍♂️");
      return;
    }

    setState(() => _isLoading = true);
    try {
      // 1. Création du compte dans l'authentification Firebase
      await _authService.createUserWithEmailAndPassword(email, password);

      // 2. Récupération de l'UID généré pour l'utilisateur actuellement connecté
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        // 3. Insertion dans Firestore avec les vraies données
        await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).set({
          'uid': currentUser.uid,
          'prenom': username,
          'nom': lastName,
          'email': email,
          'organisation': '',
          'role': 'USER',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 4. Redirection vers la page de connexion
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginView()),
          );
        }
      } else {
        _showError("Une erreur est survenue lors de la récupération de l'utilisateur. ❌");
      }

    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: theme.colorScheme.error,
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Image.asset('assets/BuckshotLogoLong.png', height: 50, fit: BoxFit.contain),
                      const SizedBox(height: 40),
                      Text(
                        'Rejoignez-nous !',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: colors.secondary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withValues(alpha: 0.4),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            BuckshotInputField(controller: _usernameController, hintText: 'Prénom'),
                            const SizedBox(height: 16),
                            BuckshotInputField(controller: _lastNameController, hintText: 'Nom'),
                            const SizedBox(height: 16),
                            BuckshotInputField(controller: _emailController, hintText: 'Adresse mail'),
                            const SizedBox(height: 16),
                            BuckshotInputField(
                              controller: _passwordController,
                              hintText: 'Mot de passe',
                              isPassword: true,
                              isObscured: _isObscured,
                              onToggleObscure: () => setState(() => _isObscured = !_isObscured),
                            ),
                            const SizedBox(height: 16),
                            BuckshotInputField(
                              controller: _confirmController,
                              hintText: 'Confirmer le mot de passe',
                              isPassword: true,
                              isObscured: _isConfirmObscured,
                              onToggleObscure: () => setState(() => _isConfirmObscured = !_isConfirmObscured),
                            ),
                            const SizedBox(height: 32),
                            _buildButton(
                              context: context,
                              label: 'Créer mon compte',
                              icon: Icons.rocket_launch_outlined,
                              onPressed: _isLoading ? null : _signUp,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 20),
                            _buildDivider(theme),
                            const SizedBox(height: 20),
                            _buildOutlinedButton(
                              context: context,
                              label: 'Déjà inscrit ? Connexion',
                              icon: Icons.login_outlined,
                              onPressed: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (context) => const LoginView()),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      _buildFooter(theme),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildButton({required BuildContext context, required String label, required IconData icon, required VoidCallback? onPressed, bool isLoading = false}) {
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        style: theme.elevatedButtonTheme.style,
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 14),
            Text(label, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({required BuildContext context, required String label, required IconData icon, required VoidCallback onPressed}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colors.secondary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.secondary, size: 28),
            const SizedBox(width: 14),
            Text(label, style: theme.textTheme.bodyLarge?.copyWith(color: colors.secondary, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[800])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('OU', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700], fontWeight: FontWeight.bold)),
        ),
        Expanded(child: Divider(color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Text.rich(
      TextSpan(
        text: 'En créant un compte, vous acceptez nos ',
        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400]),
        children: const [
          TextSpan(text: 'mentions légales', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
          TextSpan(text: ' et notre '),
          TextSpan(text: 'politique de confidentialité', style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}