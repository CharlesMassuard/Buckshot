import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/buckshot_input_field.dart'; 
import 'forgot_password_view.dart';
import 'register_view.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  final String? prefilledEmail;

  const LoginView({super.key, this.prefilledEmail});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>(); 
  late TextEditingController _emailController;
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isPasswordObscured = true;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.prefilledEmail ?? '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMarkdownDialog(BuildContext context, String title, String assetPath) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
          title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: FutureBuilder<String>(
              future: rootBundle.loadString(assetPath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF9D4EDD)));
                }
                if (snapshot.hasError) {
                  return const Text('Erreur lors du chargement du fichier', style: TextStyle(color: Colors.white));
                }
                
                return SingleChildScrollView(
                  child: MarkdownBody(
                    data: snapshot.data ?? 'Fichier vide',
                    styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                      p: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                      h1: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 20),
                      h2: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      listBullet: const TextStyle(color: Color(0xFF9D4EDD)),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer', style: TextStyle(color: Color(0xFF9D4EDD), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    _showMarkdownDialog(context, 'Politique de confidentialité', 'assets/markdown/privacy_politique.md');
  }

  void _showLegalMentions(BuildContext context) {
    _showMarkdownDialog(context, 'Mentions légales', 'assets/markdown/mentions_legales.md');
  }

  void _signIn() async {
    if (!_formKey.currentState!.validate()) return; 

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final theme = Theme.of(context);

    setState(() => _isLoading = true);
    try {
      await _authService.signInWithEmailAndPassword(email, password);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeView()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                        'Connectez-vous !',
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
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              BuckshotInputField(
                                controller: _emailController,
                                hintText: 'Adresse mail',
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Renseigne un email, t'as cru que j'allais deviner ? 🧐";
                                  }
                                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                                  if (!emailRegex.hasMatch(value)) {
                                    return "Cet email n'a pas un format valide.";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              BuckshotInputField(
                                controller: _passwordController,
                                hintText: 'Mot de passe',
                                isPassword: true,
                                isObscured: _isPasswordObscured,
                                onToggleObscure: () => setState(() => _isPasswordObscured = !_isPasswordObscured),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return "Le mot de passe est obligatoire.";
                                  }
                                  if (value.length < 8) {
                                    return "Le mot de passe doit faire au moins 8 caractères.";
                                  }
                                  return null;
                                },
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ForgotPasswordView()),
                                    );
                                  },
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[500],
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              _buildButton(
                                context: context,
                                label: 'Se connecter',
                                icon: Icons.person_outline,
                                onPressed: _isLoading ? null : _signIn,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 20),
                              _buildDivider(theme),
                              const SizedBox(height: 20),
                              _buildOutlinedButton(
                                context: context,
                                label: 'Créer mon compte',
                                icon: Icons.person_add_outlined,
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                                  );
                                },
                              ),
                            ],
                          ),
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
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
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
        style: OutlinedButton.styleFrom(side: BorderSide(color: colors.secondary, width: 2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
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
        text: 'En vous connectant, vous acceptez nos \n',
        style: GoogleFonts.jura(color: Colors.grey[400], fontSize: 14, height: 1.4),
        children: [
          TextSpan(
            text: 'mentions légales', 
            style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => _showLegalMentions(context),
          ),
          const TextSpan(text: ' et notre '),
          TextSpan(
            text: 'politique de confidentialité', 
            style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()..onTap = () => _showPrivacyPolicy(context),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}