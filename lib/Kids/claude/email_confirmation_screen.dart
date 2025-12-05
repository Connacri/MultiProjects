import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider_v2.dart';

/// 📧 Écran de confirmation email - Design moderne
class EmailConfirmationScreen extends StatefulWidget {
  const EmailConfirmationScreen({super.key});

  @override
  State<EmailConfirmationScreen> createState() =>
      _EmailConfirmationScreenState();
}

class _EmailConfirmationScreenState extends State<EmailConfirmationScreen> {
  bool _isResending = false;
  bool _emailResent = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProviderV2>();
    final userEmail = authProvider.currentUser?.email ?? 'votre email';
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.primaryContainer.withOpacity(0.3),
              colorScheme.secondaryContainer.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: _buildContent(context, colorScheme, userEmail),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ColorScheme colorScheme, String email) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 500),
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
              _buildEmailInfo(context, email),
              const SizedBox(height: 24),
              _buildInstructions(context),
              const SizedBox(height: 32),
              _buildActions(context, email),
              const SizedBox(height: 24),
              _buildFooter(context),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête avec icône animée
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
    return Column(
      children: [
        // Icône email animée
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 800),
          builder: (context, value, child) {
            return Transform.scale(
              scale: 0.8 + (value * 0.2),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mark_email_unread,
                  size: 64,
                  color: colorScheme.primary,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),

        // Titre
        Text(
          'Confirmez votre email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Sous-titre
        Text(
          'Nous avons envoyé un lien de confirmation',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Info sur l'email envoyé
  Widget _buildEmailInfo(BuildContext context, String email) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.email,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email envoyé à',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Instructions
  Widget _buildInstructions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Prochaines étapes :',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        _buildInstructionItem(
          context,
          '1',
          'Ouvrez votre boîte email',
          Icons.mail_outline,
        ),
        const SizedBox(height: 12),
        _buildInstructionItem(
          context,
          '2',
          'Cliquez sur le lien de confirmation',
          Icons.link,
        ),
        const SizedBox(height: 12),
        _buildInstructionItem(
          context,
          '3',
          'Revenez compléter votre profil',
          Icons.person_outline,
        ),
        const SizedBox(height: 16),

        // Note spam
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.orange.shade200,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.orange.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Vérifiez également votre dossier spam/courrier indésirable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Item d'instruction
  Widget _buildInstructionItem(
    BuildContext context,
    String number,
    String text,
    IconData icon,
  ) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  /// Boutons d'action
  Widget _buildActions(BuildContext context, String email) {
    return Column(
      children: [
        // Bouton Renvoyer l'email
        if (_emailResent)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.shade200,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.green.shade700,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Email renvoyé avec succès !',
                  style: TextStyle(
                    color: Colors.green.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          )
        else
          OutlinedButton.icon(
            onPressed:
                _isResending ? null : () => _handleResendEmail(context, email),
            icon: _isResending
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            label: Text(_isResending ? 'Envoi...' : 'Renvoyer l\'email'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

        const SizedBox(height: 12),

        // Bouton Se déconnecter
        TextButton.icon(
          onPressed: () => _handleLogout(context),
          icon: const Icon(Icons.logout),
          label: const Text('Se déconnecter'),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),

        const SizedBox(height: 8),

        // Bouton Supprimer le compte
        TextButton.icon(
          onPressed: () => _showDeleteAccountDialog(context),
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          label: const Text(
            'Supprimer ce compte',
            style: TextStyle(color: Colors.red),
          ),
          style: TextButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
      ],
    );
  }

  /// Footer
  Widget _buildFooter(BuildContext context) {
    return Text(
      'Besoin d\'aide ? Contactez le support',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      textAlign: TextAlign.center,
    );
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  Future<void> _handleResendEmail(BuildContext context, String email) async {
    setState(() {
      _isResending = true;
      _emailResent = false;
    });

    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.resendConfirmationEmail(email);

    setState(() => _isResending = false);

    if (!mounted) return;

    if (result.success) {
      setState(() => _emailResent = true);

      // Réinitialiser après 5 secondes
      Future.delayed(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _emailResent = false);
        }
      });
    } else {
      _showErrorSnackBar(result.message ?? 'Erreur lors du renvoi');
    }
  }

  void _handleLogout(BuildContext context) {
    final authProvider = context.read<AuthProviderV2>();
    authProvider.logout();
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le compte'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer ce compte ?\n\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(context);
              await _handleDeleteAccount(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.deleteUnconfirmedAccount();

    if (!mounted) return;

    if (result.success) {
      _showSuccessSnackBar('Compte supprimé avec succès');
    } else {
      _showErrorSnackBar(result.message ?? 'Erreur lors de la suppression');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
