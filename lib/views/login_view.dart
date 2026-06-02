import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/buckshot_input_field.dart'; 
import 'forgot_password_view.dart';
import 'register_view.dart';
import 'home_view.dart';

class LoginView extends StatefulWidget {
  final String? prefilledEmail;

  const LoginView({super.key,this.prefilledEmail});

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
        text: 'En vous connectant, vous acceptez nos ',
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