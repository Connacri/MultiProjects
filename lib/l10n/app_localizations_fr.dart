// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'AuthApp';

  @override
  String get login => 'Connexion';

  @override
  String get signup => 'Inscription';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get name => 'Nom complet';

  @override
  String get forgotPassword => 'Mot de passe oublié?';

  @override
  String get noAccount => 'Pas de compte?';

  @override
  String get hasAccount => 'Déjà un compte?';

  @override
  String get signupNow => 'S\'inscrire';

  @override
  String get loginNow => 'Se connecter';

  @override
  String get selectRole => 'Sélectionnez votre rôle';

  @override
  String get parent => 'Parent';

  @override
  String get school => 'École';

  @override
  String get coach => 'Coach';

  @override
  String get resetPassword => 'Réinitialiser le mot de passe';

  @override
  String get sendResetLink => 'Envoyer le lien';

  @override
  String get backToLogin => 'Retour à la connexion';

  @override
  String get profile => 'Profil';

  @override
  String get signout => 'Déconnexion';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deactivateAccount => 'Désactiver le compte';

  @override
  String get reactivateAccount => 'Réactiver le compte';

  @override
  String get accountDeactivated => 'Compte désactivé';

  @override
  String get daysUntilDeletion => 'jours avant suppression définitive';

  @override
  String get confirmDelete => 'Confirmer la suppression';

  @override
  String get cancel => 'Annuler';

  @override
  String get confirm => 'Confirmer';

  @override
  String get deleteWarning => 'Votre compte sera désactivé pendant 60 jours avant suppression définitive. Vous pourrez le réactiver pendant cette période.';

  @override
  String get reactivateSuccess => 'Compte réactivé avec succès';

  @override
  String get emailRequired => 'L\'email est requis';

  @override
  String get passwordRequired => 'Le mot de passe est requis';

  @override
  String get nameRequired => 'Le nom est requis';

  @override
  String get roleRequired => 'Le rôle est requis';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get invalidEmail => 'Email invalide';

  @override
  String get weakPassword => 'Le mot de passe doit contenir au moins 6 caractères';

  @override
  String get loginSuccess => 'Connexion réussie';

  @override
  String get signupSuccess => 'Inscription réussie';

  @override
  String get resetEmailSent => 'Email de réinitialisation envoyé';

  @override
  String get errorOccurred => 'Une erreur s\'est produite';

  @override
  String get accountDeleted => 'Compte supprimé avec succès';

  @override
  String get emailAlreadyInUse => 'Cet email est déjà utilisé';

  @override
  String get userNotFound => 'Utilisateur non trouvé';

  @override
  String get wrongPassword => 'Mot de passe incorrect';

  @override
  String get userDisabled => 'Ce compte a été désactivé';

  @override
  String get tooManyRequests => 'Trop de tentatives. Veuillez réessayer plus tard';

  @override
  String get networkError => 'Erreur de connexion réseau';

  @override
  String get authError => 'Erreur d\'authentification';

  @override
  String get accountDeactivatedCanReactivate => 'Votre compte est désactivé. Connectez-vous pour le réactiver';

  @override
  String get accountDeletedPermanently => 'Ce compte a été supprimé définitivement';

  @override
  String get reactivationPeriodExpired => 'La période de réactivation a expiré';

  @override
  String get signoutError => 'Erreur lors de la déconnexion';

  @override
  String get deactivateAccountError => 'Erreur lors de la désactivation';

  @override
  String get fetchUserError => 'Erreur lors de la récupération des données';

  @override
  String get signupError => 'Erreur lors de l\'inscription';

  @override
  String get resetPasswordError => 'Erreur lors de la réinitialisation';

  @override
  String get deleteAccountError => 'Erreur lors de la suppression';
}
