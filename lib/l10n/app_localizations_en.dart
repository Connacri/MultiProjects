// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'AuthApp';

  @override
  String get login => 'Login';

  @override
  String get signup => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get name => 'Full Name';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get hasAccount => 'Already have an account?';

  @override
  String get signupNow => 'Sign up';

  @override
  String get loginNow => 'Log in';

  @override
  String get selectRole => 'Select your role';

  @override
  String get parent => 'Parent';

  @override
  String get school => 'School';

  @override
  String get coach => 'Coach';

  @override
  String get resetPassword => 'Reset Password';

  @override
  String get sendResetLink => 'Send Reset Link';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get profile => 'Profile';

  @override
  String get signout => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deactivateAccount => 'Deactivate Account';

  @override
  String get reactivateAccount => 'Reactivate Account';

  @override
  String get accountDeactivated => 'Account Deactivated';

  @override
  String get daysUntilDeletion => 'days until permanent deletion';

  @override
  String get confirmDelete => 'Confirm Deletion';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get deleteWarning => 'Your account will be deactivated for 60 days before permanent deletion. You can reactivate it during this period.';

  @override
  String get reactivateSuccess => 'Account reactivated successfully';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get nameRequired => 'Name is required';

  @override
  String get roleRequired => 'Role is required';

  @override
  String get passwordMismatch => 'Passwords do not match';

  @override
  String get invalidEmail => 'Invalid email';

  @override
  String get weakPassword => 'Password must be at least 6 characters';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get signupSuccess => 'Sign up successful';

  @override
  String get resetEmailSent => 'Reset email sent';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get accountDeleted => 'Account deleted successfully';

  @override
  String get emailAlreadyInUse => 'This email is already in use';

  @override
  String get userNotFound => 'User not found';

  @override
  String get wrongPassword => 'Wrong password';

  @override
  String get userDisabled => 'This account has been disabled';

  @override
  String get tooManyRequests => 'Too many attempts. Please try again later';

  @override
  String get networkError => 'Network connection error';

  @override
  String get authError => 'Authentication error';

  @override
  String get accountDeactivatedCanReactivate => 'Your account is deactivated. Log in to reactivate it';

  @override
  String get accountDeletedPermanently => 'This account has been permanently deleted';

  @override
  String get reactivationPeriodExpired => 'Reactivation period has expired';

  @override
  String get signoutError => 'Error signing out';

  @override
  String get deactivateAccountError => 'Error deactivating account';

  @override
  String get fetchUserError => 'Error fetching user data';

  @override
  String get signupError => 'Error during signup';

  @override
  String get resetPasswordError => 'Error resetting password';

  @override
  String get deleteAccountError => 'Error deleting account';
}
