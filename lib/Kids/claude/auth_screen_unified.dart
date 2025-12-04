import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'auth_provider_v2.dart';

/// 🎨 Écran d'authentification unifié - Design Material 3 Facebook-like
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late TabController _tabController;
  bool _obscurePassword = true;
  String? _selectedRole;
  bool _isCheckingEmail = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Écouter les changements d'email pour vérification automatique
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Vérification automatique si l'email existe (debounce 500ms)
  void _onEmailChanged() {
    // Annuler la vérification précédente
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_emailController.text.contains('@') &&
          _emailController.text.length > 5) {
        _checkEmailExists();
      }
    });
  }

  Future<void> _checkEmailExists() async {
    if (_isCheckingEmail) return;

    setState(() => _isCheckingEmail = true);

    final authProvider = context.read<AuthProviderV2>();
    final exists =
        await authProvider.checkEmailExists(_emailController.text.trim());

    setState(() => _isCheckingEmail = false);

    // Si l'email existe et qu'on est sur l'onglet Signup, suggérer de se connecter
    if (exists && _tabController.index == 1) {
      _showSnackBar(
        'Cet email existe déjà. Passez à la connexion.',
        isError: false,
        action: SnackBarAction(
          label: 'Connexion',
          textColor: Colors.white,
          onPressed: () => _tabController.animateTo(0),
        ),
      );
    }
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
              child: _buildAuthCard(context, colorScheme),
            ),
          ),
        ),
      ),
    );
  }

  /// Carte d'authentification principale
  Widget _buildAuthCard(BuildContext context, ColorScheme colorScheme) {
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
              _buildHeader(colorScheme),
              const SizedBox(height: 32),
              _buildTabBar(colorScheme),
              const SizedBox(height: 24),
              _buildTabBarView(),
              const SizedBox(height: 16),
              _buildForgotPasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  /// En-tête avec logo et titre
  Widget _buildHeader(ColorScheme colorScheme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.sports_soccer,
            size: 48,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Kids Sports Academy',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Gérez vos cours et inscriptions',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Barre d'onglets Login/Signup
  Widget _buildTabBar(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Connexion'),
          Tab(text: 'Inscription'),
        ],
      ),
    );
  }

  /// Contenu des onglets
  Widget _buildTabBarView() {
    return SizedBox(
      height: _tabController.index == 1 ? 450 : 250,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildLoginForm(),
          _buildSignupForm(),
        ],
      ),
    );
  }

  /// Formulaire de connexion
  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 16),
          _buildPasswordField(),
          const SizedBox(height: 24),
          _buildLoginButton(),
        ],
      ),
    );
  }

  /// Formulaire d'inscription
  Widget _buildSignupForm() {
    return Form(
      child: Column(
        children: [
          _buildEmailField(),
          const SizedBox(height: 8),
          _buildPasswordField(),
          const SizedBox(height: 8),
          _buildRoleSelector(),
          const SizedBox(height: 8),
          _buildSignupButton(),
        ],
      ),
    );
  }

  /// Champ Email avec validation
  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email',
        hintText: 'exemple@email.com',
        prefixIcon: const Icon(Icons.email_outlined),
        suffixIcon: _isCheckingEmail
            ? const SizedBox(
                width: 20,
                height: 20,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
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
    );
  }

  /// Champ Mot de passe avec indicateur de force
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'Mot de passe',
            hintText: 'Minimum 6 caractères',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez entrer un mot de passe';
            }
            if (value.length < 6) {
              return 'Le mot de passe doit contenir au moins 6 caractères';
            }
            return null;
          },
        ),
        if (_tabController.index == 1 && _passwordController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: _buildPasswordStrengthIndicator(),
          ),
      ],
    );
  }

  /// Indicateur de force du mot de passe
  Widget _buildPasswordStrengthIndicator() {
    final password = _passwordController.text;
    final strength = _calculatePasswordStrength(password);

    Color color;
    String label;

    if (strength < 0.33) {
      color = Colors.red;
      label = 'Faible';
    } else if (strength < 0.66) {
      color = Colors.orange;
      label = 'Moyen';
    } else {
      color = Colors.green;
      label = 'Fort';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: strength,
          backgroundColor: Colors.grey[300],
          color: color,
          minHeight: 4,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double _calculatePasswordStrength(String password) {
    double strength = 0;

    if (password.length >= 6) strength += 0.25;
    if (password.length >= 10) strength += 0.25;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.25;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.25;

    return strength;
  }

  /// Sélecteur de rôle (Parent, Coach, Club)
  Widget _buildRoleSelector() {
    final roles = [
      {'value': 'parent', 'label': 'Parent', 'icon': Icons.family_restroom},
      {'value': 'coach', 'label': 'Coach', 'icon': Icons.sports},
      {'value': 'school', 'label': 'Club', 'icon': Icons.school},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Je suis un(e)',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: roles.map((role) {
            final isSelected = _selectedRole == role['value'];

            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    role['icon'] as IconData,
                    size: 20,
                    color: isSelected ? Colors.white : null,
                  ),
                  const SizedBox(width: 8),
                  Text(role['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() =>
                    _selectedRole = selected ? role['value'] as String : null);
              },
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Bouton de connexion
  Widget _buildLoginButton() {
    return Consumer<AuthProviderV2>(
      builder: (context, authProvider, _) {
        final isLoading = authProvider.isLoading;

        return FilledButton(
          onPressed: isLoading ? null : _handleLogin,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Se connecter',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }

  /// Bouton d'inscription
  Widget _buildSignupButton() {
    return Consumer<AuthProviderV2>(
      builder: (context, authProvider, _) {
        final isLoading = authProvider.isLoading;

        return FilledButton(
          onPressed: isLoading || _selectedRole == null ? null : _handleSignup,
          style: FilledButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Créer un compte',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        );
      },
    );
  }

  /// Bouton Mot de passe oublié
  Widget _buildForgotPasswordButton() {
    return TextButton(
      onPressed: _showForgotPasswordDialog,
      child: const Text('Mot de passe oublié ?'),
    );
  }

  // ==========================================================================
  // ACTIONS
  // ==========================================================================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (result.success) {
      _showSnackBar('Connexion réussie !', isError: false);

      // Navigation gérée par AuthWrapper
    } else {
      _showSnackBar(result.message ?? 'Erreur de connexion', isError: true);
    }
  }

  Future<void> _handleSignup() async {
    if (_selectedRole == null) {
      _showSnackBar('Veuillez sélectionner votre rôle', isError: true);
      return;
    }

    final authProvider = context.read<AuthProviderV2>();
    final result = await authProvider.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      role: _selectedRole!,
    );

    if (!mounted) return;

    if (result.success) {
      _showSnackBar('Compte créé avec succès !', isError: false);

      // Navigation vers ProfileCompletionScreen gérée par AuthWrapper
    } else {
      // Gérer le cas "email existe déjà"
      if (result.errorCode == 'email_exists') {
        _showSnackBar(
          result.message!,
          isError: false,
          action: SnackBarAction(
            label: 'Connexion',
            textColor: Colors.white,
            onPressed: () => _tabController.animateTo(0),
          ),
        );
      } else {
        _showSnackBar(result.message ?? 'Erreur d\'inscription', isError: true);
      }
    }
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Entrez votre email pour recevoir un lien de réinitialisation.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              final email = emailController.text.trim();

              if (email.isEmpty || !email.contains('@')) {
                _showSnackBar('Email invalide', isError: true);
                return;
              }

              Navigator.pop(context);

              final authProvider = context.read<AuthProviderV2>();
              final result = await authProvider.sendPasswordReset(email);

              if (result.success) {
                _showSnackBar(
                  'Email de réinitialisation envoyé !',
                  isError: false,
                );
              } else {
                _showSnackBar(result.message!, isError: true);
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message,
      {required bool isError, SnackBarAction? action}) {
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
        action: action,
      ),
    );
  }
}
