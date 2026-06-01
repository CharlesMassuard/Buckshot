import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_view.dart';
import '../widgets/PrivacyCheckbox.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _authService = AuthService();
  
  bool _isLoading = false;
  bool _isObscured = true;
  bool _isConfirmObscured = true;
  bool _hasAcceptedPrivacy = false; 

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _signUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirm = _confirmController.text.trim();

    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showError("Remplis tout, on n'est pas aux devinettes ici ! 📝");
      return;
    }
    if (password != confirm) {
      _showError("Tes mots de passe ne sont pas jumeaux... 👯‍♂️");
      return;
    }
    if (!_hasAcceptedPrivacy) {
      _showError("Tu dois accepter la politique de confidentialité pour continuer ! 🕵️‍♂️");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _authService.createUserWithEmailAndPassword(email, password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
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
                              color: colors.primary.withOpacity(0.4),
                              blurRadius: 25,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            BuckshotInputField(controller: _usernameController, hintText: 'Nom d\'utilisateur'),
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
                            const SizedBox(height: 16),
                            
                            
                            PrivacyCheckbox(
                              isChecked: _hasAcceptedPrivacy,
                              onChanged: (value) {
                                setState(() {
                                  _hasAcceptedPrivacy = value ?? false;
                                });
                              },
                            ),
                            
                            const SizedBox(height: 24),
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
            ? const CircularProgressIndicator(color: Colors.white)
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
}