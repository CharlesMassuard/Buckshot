import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';

class PrivacyCheckbox extends StatelessWidget {
  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  const PrivacyCheckbox({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: isChecked,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(
              text: 'J\'accepte les ',
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[400], height: 1.4),
              children: [
                TextSpan(
                  text: 'mentions légales', 
                  style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => _showLegalMentions(context),
                ),
                const TextSpan(text: ' et la '),
                TextSpan(
                  text: 'politique de confidentialité', 
                  style: const TextStyle(color: Colors.white, decoration: TextDecoration.underline),
                  recognizer: TapGestureRecognizer()..onTap = () => _showPrivacyPolicy(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}