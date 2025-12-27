import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../claude/auth_provider_v2.dart';

/// 🎯 Écran de réinitialisation de mot de passe - Design moderne
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer,
              colorScheme.secondaryContainer,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildContent(context, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context, colorScheme),
              const SizedBox(height: 32),
              if (_emailSent)
                _buildSuccessView(context)
              else
                _buildFormView(context),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête avec icône et titre
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Bouton retour
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Icône principale
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            _emailSent ? Icons.mark_email_read : Icons.lock_reset,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),

        // Titre
        Text(
          _emailSent ? 'Email envoyé !' : 'Mot de passe oublié',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Sous-titre
        Text(
          _emailSent
              ? 'Consultez votre boîte de réception'
              : 'Entrez votre email pour recevoir un lien de réinitialisation',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Vue du formulaire
  Widget _buildFormView(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Champ email
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'exemple@email.com',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Bouton envoyer
          FilledButton(
            onPressed: _isLoading ? null : _handleSendReset,
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Envoyer le lien',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Vue de succès
  Widget _buildSuccessView(BuildContext context) {
    return Column(
      children: [
        // Instructions
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceVariant,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochaines étapes :',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildInstructionItem(
                  '1',
                  'Consultez votre boîte de réception',
                ),
                _buildInstructionItem(
                  '2',
                  'Cliquez sur le lien de réinitialisation',
                ),
                _buildInstructionItem(
                  '3',
                  'Créez un nouveau mot de passe',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() => _emailSent = false);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Renvoyer'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Connexion'),
              ),
            ),
          ],
        ),

        // Note sur le spam
        const SizedBox(height: 16),
        Text(
          'Vérifiez également votre dossier spam/courrier indésirable',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Item d'instruction numéroté
  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  Future<void> _handleSendReset() async {
    // 1. Valider le formulaire
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // 2. Mettre à jour l'état de chargement
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Récupérer le provider
      final authProvider = context.read<AuthProviderV2>();

      // 4. Appeler la méthode de réinitialisation
      final result = await authProvider.sendPasswordReset(
        _emailController.text.trim(),
      );

      // 5. Vérifier si le widget est toujours monté
      if (!mounted) return;

      // 6. Gestion du résultat
      if (result.success) {
        setState(() {
          _emailSent = true;
        });
        _showSnackBar(
          'Email de réinitialisation envoyé !',
          isError: false,
        );
      } else {
        // Afficher le message d'erreur retourné par le provider
        final errorMessage = result.message ?? 'Erreur inconnue';
        _showSnackBar(errorMessage, isError: true);
      }
    } catch (e) {
      // En cas d'exception inattendue
      if (mounted) {
        _showSnackBar(
          'Erreur inattendue : $e',
          isError: true,
        );
      }
    } finally {
      // Toujours arrêter le loading, même en cas d'erreur
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Colors.red[700] : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
