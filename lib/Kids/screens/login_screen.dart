// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import '../../l10n/app_localizations.dart';
// import '../providers/auth_provider_dart.dart';
// import '../providers/locale_provider.dart';
// import '../widgets/custom_text_field_widget.dart';
// import '../widgets/loading_overlay_widget.dart';
// import 'forgot_password_screen.dart';
// import 'signup_screen.dart';
//
// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});
//
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   void _showSnackBar(String message, {bool isError = true}) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             Icon(
//               isError ? Icons.error_outline : Icons.check_circle_outline,
//               color: Colors.white,
//             ),
//             const SizedBox(width: 12),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//         margin: const EdgeInsets.all(16),
//       ),
//     );
//   }
//
//   String _getErrorMessage(String error, AppLocalizations l10n) {
//     if (error.contains('invalid_email')) return l10n.invalidEmail;
//     if (error.contains('user_not_found')) return l10n.userNotFound;
//     if (error.contains('wrong_password')) return l10n.wrongPassword;
//     if (error.contains('user_disabled')) return l10n.userDisabled;
//     if (error.contains('too_many_requests')) return l10n.tooManyRequests;
//     if (error.contains('network_error')) return l10n.networkError;
//     if (error.contains('account_deactivated_can_reactivate')) {
//       return l10n.accountDeactivatedCanReactivate;
//     }
//     if (error.contains('account_deleted_permanently')) {
//       return l10n.accountDeletedPermanently;
//     }
//     return l10n.authError;
//   }
//
//   Future<void> _handleLogin() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     final authProvider = Provider.of<AuthProvider>(context, listen: false);
//     final l10n = AppLocalizations.of(context)!;
//
//     final success = await authProvider.signIn(
//       email: _emailController.text.trim(),
//       password: _passwordController.text,
//     );
//
//     if (!mounted) return;
//
//     if (success) {
//       _showSnackBar(l10n.loginSuccess, isError: false);
//     } else if (authProvider.error != null) {
//       _showSnackBar(_getErrorMessage(authProvider.error!, l10n));
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final l10n = AppLocalizations.of(context)!;
//     final authProvider = Provider.of<AuthProvider>(context);
//     final localeProvider = Provider.of<LocaleProvider>(context);
//
//     return LoadingOverlay(
//       isLoading: authProvider.isLoading,
//       child: Scaffold(
//         backgroundColor: Colors.grey.shade50,
//         appBar: AppBar(
//           backgroundColor: Colors.transparent,
//           elevation: 0,
//           actions: [
//             PopupMenuButton<Locale>(
//               icon: const Icon(Icons.language, color: Colors.blue),
//               onSelected: (locale) => localeProvider.setLocale(locale),
//               itemBuilder: (context) => [
//                 const PopupMenuItem(
//                   value: Locale('fr'),
//                   child: Text('Français'),
//                 ),
//                 const PopupMenuItem(
//                   value: Locale('en'),
//                   child: Text('English'),
//                 ),
//                 const PopupMenuItem(
//                   value: Locale('ar'),
//                   child: Text('العربية'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         body: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.blue,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const Icon(
//                         Icons.lock_outline,
//                         size: 40,
//                         color: Colors.white,
//                       ),
//                     ),
//                     const SizedBox(height: 24),
//                     Text(
//                       l10n.appTitle,
//                       style: const TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       l10n.login,
//                       style: TextStyle(
//                         fontSize: 16,
//                         color: Colors.grey.shade600,
//                       ),
//                     ),
//                     const SizedBox(height: 40),
//                     Container(
//                       constraints: const BoxConstraints(maxWidth: 400),
//                       padding: const EdgeInsets.all(24),
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(16),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.black.withOpacity(0.05),
//                             blurRadius: 10,
//                             offset: const Offset(0, 4),
//                           ),
//                         ],
//                       ),
//                       child: Column(
//                         children: [
//                           CustomTextField(
//                             controller: _emailController,
//                             label: l10n.email,
//                             prefixIcon: Icons.email_outlined,
//                             keyboardType: TextInputType.emailAddress,
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return l10n.emailRequired;
//                               }
//                               if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
//                                   .hasMatch(value)) {
//                                 return l10n.invalidEmail;
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 16),
//                           CustomTextField(
//                             controller: _passwordController,
//                             label: l10n.password,
//                             prefixIcon: Icons.lock_outline,
//                             obscureText: _obscurePassword,
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _obscurePassword
//                                     ? Icons.visibility_outlined
//                                     : Icons.visibility_off_outlined,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   _obscurePassword = !_obscurePassword;
//                                 });
//                               },
//                             ),
//                             validator: (value) {
//                               if (value == null || value.isEmpty) {
//                                 return l10n.passwordRequired;
//                               }
//                               if (value.length < 6) {
//                                 return l10n.weakPassword;
//                               }
//                               return null;
//                             },
//                           ),
//                           const SizedBox(height: 8),
//                           Align(
//                             alignment: Alignment.centerRight,
//                             child: TextButton(
//                               onPressed: () {
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(
//                                     builder: (context) =>
//                                         const ForgotPasswordScreen(),
//                                   ),
//                                 );
//                               },
//                               child: Text(l10n.forgotPassword),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           SizedBox(
//                             width: double.infinity,
//                             height: 50,
//                             child: ElevatedButton(
//                               onPressed: _handleLogin,
//                               child: Text(
//                                 l10n.login,
//                                 style: const TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 16),
//                           Row(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text(
//                                 l10n.noAccount,
//                                 style: TextStyle(color: Colors.grey.shade600),
//                               ),
//                               TextButton(
//                                 onPressed: () {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (context) =>
//                                           const SignupScreen(),
//                                     ),
//                                   );
//                                 },
//                                 child: Text(
//                                   l10n.signupNow,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
