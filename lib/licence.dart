// j'ai creer une app desktop windows en flutter je veux creer un systeme de multi licence demo a duré determiné et lifetime pour un seul poste impossible a cracké ou a clonner , si l'app est une nouvelle installation ou na jamais été valider par licence qui sera generer par une app android admin en scanant le code qr qui apparait sur la fist screen de l'app windows genere un code pin de 10 chiifres qui sera inseré dans les champs des pins qui est en dessous du code qr et le first screen dois avoir une expliquation detailler sur le choix de la licence et comment valider et demander le code pin et l'app admin dois avoir un choix de licence a générrer apres scanne qr code et le first screen doit avoir un bouton d'envoi du qrcode genre demande de validation par mail parceque le nouvel user va demander cette validation en choisisant le type de la licence
// voila mes dependence utilise les
// dependencies:
// flutter:
// sdk: flutter
// cupertino_icons: ^1.0.8
// cloud_firestore: ^6.0.1
// firebase_messaging: ^16.0.1
// firebase_database: ^12.0.1
// firebase_storage: ^13.0.1
// firebase_in_app_messaging: ^0.9.0+1
// firebase_analytics: any
// google_sign_in: ^7.2.0
// #  firedart: ^0.9.8
// cached_network_image: ^3.4.1
// supabase_flutter: ^2.10.1
// flutter_image_compress: ^2.4.0
// lottie: ^3.3.1
// provider: ^6.1.5+1
// fluttertoast: ^8.2.14
// font_awesome_flutter: ^10.9.0
//
// shared_preferences: ^2.5.3
// avatar_glow: ^3.0.1
// url_launcher: ^6.3.2
// carousel_slider: ^5.1.1
// image_picker: ^1.2.0
// intl_phone_field: ^3.2.0
// intl: ^0.20.2
// mobile_scanner: ^7.0.1
// ticket_widget: ^1.0.2
// readmore: ^3.0.0
// dart_date: ^1.5.3
// flutter_staggered_grid_view: ^0.7.0
// shimmer: ^3.0.0
// rename: ^3.1.0
// marqueer: ^2.1.0
// screenshot: ^3.0.0
// email_validator: ^3.0.0
// flutter_islamic_icons: ^1.0.2
// geocoding: ^4.0.0
// map_launcher: ^4.4.2
// open_location_picker: ^1.1.0
// jiffy: ^6.4.3
// google_fonts: ^6.3.1
// googleapis_auth:
// path: ^1.9.1
// timelines: ^0.1.0
// animated_flip_counter: ^0.3.4
// pretty_qr_code: ^3.5.0
// http: ^1.5.0
// decimal: ^3.2.4
// openfoodfacts: ^3.25.1
// #  video_player: ^2.9.2
// chewie: ^1.12.1
// flutter_easyloading: ^3.0.5
// wakelock_plus: ^1.4.0
// faker: ^2.2.0
// timeago: ^3.7.1
// objectbox: ^4.3.1
// objectbox_flutter_libs: ^4.3.1
// network_info_plus: ^7.0.0
// multicast_dns: ^0.3.3
// percent_indicator: ^4.2.5
// icons_plus: ^5.0.0
// feedback: ^3.2.0
// win32: ^5.14.0
// msix: ^3.16.12
// device_info_plus: ^11.5.0
// pincode_input_fields: ^1.0.3
// syncfusion_flutter_barcodes: ^30.2.6
// linked_scroll_controller: ^0.2.0
// #  excel: ^4.0.6
// country_flags: ^3.3.0
// google_mobile_ads: ^6.0.0
// permission_handler: ^12.0.1
// file_picker: ^10.3.3
// vibration: ^3.1.3
// #  window_manager: ^0.4.2
// string_extensions: ^0.7.4
// #  fluent_ui: ^4.10.0
// firebase_auth: ^6.0.1
// #  calendar_timeline: ^1.1.3
// flutter_slidable: ^4.0.1
// connectivity_plus: ^6.1.5
// #  media_kit: ^1.1.11 # Primary package.
// #  media_kit_video: ^1.2.5 # For video rendering.
// #  media_kit_libs_video: ^1.0.5 # Native video dependencies.
// #  media_kit_libs_audio: ^1.0.5 # Native audio dependencies.
// flutter_avif: ^3.0.0
// youtube_player_flutter: ^9.1.2
// #  webfeed_plus: ^1.1.2
// rename_app: ^1.6.5
// call_log: ^6.0.1
// easy_date_timeline: ^2.0.9
// multi_view_calendar: ^1.0.2
// calendar_planner_view: ^0.3.3
// table_calendar: ^3.2.0
// flutter_hooks: ^0.21.3+1
// #  flutter_bloc: ^9.1.1
// gradient_borders: ^1.0.2
// plugin_platform_interface: ^2.1.8
// smooth_page_indicator: ^1.2.1
// flutter_card_swiper: ^7.0.2
// dynamic_flutter_form: ^1.0.2
// syncfusion_flutter_calendar: ^30.2.7
// #  flutter_native_splash: ^2.4.6
// splash_master: ^0.0.3
// fl_chart: ^0.70.0
// syncfusion_flutter_datagrid: ^30.2.7
//
// import 'dart:convert';
// import 'dart:io';
//
// import 'package:crypto/crypto.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:qr_flutter/qr_flutter.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
//
// class LicenseActivationScreen extends StatefulWidget {
//   const LicenseActivationScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LicenseActivationScreen> createState() =>
//       _LicenseActivationScreenState();
// }
//
// class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
//   String? deviceFingerprint;
//   List<TextEditingController> pinControllers =
//   List.generate(10, (_) => TextEditingController());
//   List<FocusNode> focusNodes = List.generate(10, (_) => FocusNode());
//   bool isLoading = true;
//   bool isValidating = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _generateDeviceFingerprint();
//   }
//
//   @override
//   void dispose() {
//     for (var controller in pinControllers) {
//       controller.dispose();
//     }
//     for (var node in focusNodes) {
//       node.dispose();
//     }
//     super.dispose();
//   }
//
//   Future<void> _generateDeviceFingerprint() async {
//     try {
//       final deviceInfo = DeviceInfoPlugin();
//       String fingerprint = '';
//
//       if (Platform.isWindows) {
//         final windowsInfo = await deviceInfo.windowsInfo;
//
//         // Combinaison d'identifiants uniques du système
//         final components = [
//           windowsInfo.computerName,
//           windowsInfo.numberOfCores.toString(),
//           windowsInfo.systemMemoryInMegabytes.toString(),
//           Platform.operatingSystemVersion,
//         ];
//
//         // Hash SHA-256 pour créer une empreinte unique
//         final bytes = utf8.encode(components.join('|'));
//         final digest = sha256.convert(bytes);
//         fingerprint = digest.toString();
//       }
//
//       setState(() {
//         deviceFingerprint = fingerprint;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       _showError('Erreur lors de la génération de l\'empreinte système');
//     }
//   }
//
//   String _generateQRData() {
//     if (deviceFingerprint == null) return '';
//
//     final timestamp = DateTime
//         .now()
//         .millisecondsSinceEpoch;
//     final data = {
//       'device_id': deviceFingerprint,
//       'timestamp': timestamp,
//       'app_version': '1.0.0',
//     };
//
//     return jsonEncode(data);
//   }
//
//   Future<void> _validateLicense() async {
//     setState(() => isValidating = true);
//
//     try {
//       // Récupérer le code PIN entré
//       final pin = pinControllers.map((c) => c.text).join('');
//
//       if (pin.length != 10) {
//         _showError('Le code PIN doit contenir 10 chiffres');
//         setState(() => isValidating = false);
//         return;
//       }
//
//       // Vérifier le code PIN avec l'algorithme de validation
//       final isValid = await _verifyLicensePin(pin);
//
//       if (isValid) {
//         // Sauvegarder la licence
//         await _saveLicense(pin);
//
//         if (mounted) {
//           Navigator.of(context).pushReplacement(
//             MaterialPageRoute(builder: (_) => const MainAppScreen()),
//           );
//         }
//       } else {
//         _showError('Code PIN invalide');
//       }
//     } catch (e) {
//       _showError('Erreur lors de la validation: $e');
//     } finally {
//       setState(() => isValidating = false);
//     }
//   }
//
//   Future<bool> _verifyLicensePin(String pin) async {
//     try {
//       // Décoder le PIN (format: Type(1) + Durée(2) + DeviceHash(4) + Checksum(3))
//       final licenseType = pin.substring(0, 1);
//       final duration = pin.substring(1, 3);
//       final deviceHash = pin.substring(3, 7);
//       final checksum = pin.substring(7, 10);
//
//       // Vérifier que le hash de l'appareil correspond
//       final expectedHash = _getDeviceHashShort();
//       if (deviceHash != expectedHash) {
//         return false;
//       }
//
//       // Vérifier le checksum
//       final calculatedChecksum = _calculateChecksum(pin.substring(0, 7));
//       if (checksum != calculatedChecksum) {
//         return false;
//       }
//
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
//
//   String _getDeviceHashShort() {
//     if (deviceFingerprint == null) return '0000';
//     final hash = sha256.convert(utf8.encode(deviceFingerprint!));
//     return hash.toString().substring(0, 4);
//   }
//
//   String _calculateChecksum(String data) {
//     final hash = sha256.convert(utf8.encode(data + 'SECRET_SALT_KEY'));
//     return hash.toString().substring(0, 3);
//   }
//
//   Future<void> _saveLicense(String pin) async {
//     final prefs = await SharedPreferences.getInstance();
//
//     final licenseType = pin.substring(0, 1);
//     final duration = int.parse(pin.substring(1, 3));
//
//     DateTime? expiryDate;
//     if (licenseType == '1') {
//       // Demo
//       expiryDate = DateTime.now().add(Duration(days: duration));
//     }
//     // licenseType == '2' = Lifetime, pas de date d'expiration
//
//     final licenseData = {
//       'pin': pin,
//       'device_id': deviceFingerprint,
//       'activated_at': DateTime.now().toIso8601String(),
//       'expiry_date': expiryDate?.toIso8601String(),
//       'type': licenseType == '1' ? 'demo' : 'lifetime',
//     };
//
//     await prefs.setString('license', jsonEncode(licenseData));
//   }
//
//   Future<void> _sendEmailRequest() async {
//     final qrData = _generateQRData();
//     final email = 'support@votreapp.com';
//     final subject = 'Demande d\'activation de licence';
//     final body = '''
// Bonjour,
//
// Je souhaite activer une licence pour votre application.
//
// Données du système:
// $qrData
//
// Merci de me fournir un code PIN d'activation.
//
// Cordialement
// ''';
//
//     final emailUrl = Uri(
//       scheme: 'mailto',
//       path: email,
//       query:
//       'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(
//           body)}',
//     );
//
//     if (await canLaunchUrl(emailUrl)) {
//       await launchUrl(emailUrl);
//     } else {
//       _showError('Impossible d\'ouvrir le client email');
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [Colors.blue.shade700, Colors.purple.shade700],
//           ),
//         ),
//         child: Center(
//           child: Card(
//             margin: const EdgeInsets.all(32),
//             elevation: 8,
//             shape:
//             RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 900),
//               padding: const EdgeInsets.all(40),
//               child: isLoading
//                   ? const Center(child: CircularProgressIndicator())
//                   : SingleChildScrollView(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     _buildHeader(),
//                     const SizedBox(height: 30),
//                     _buildInstructions(),
//                     const SizedBox(height: 30),
//                     _buildQRSection(),
//                     const SizedBox(height: 30),
//                     _buildPinSection(),
//                     const SizedBox(height: 30),
//                     _buildButtons(),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Column(
//       children: [
//         Icon(Icons.security, size: 64, color: Colors.blue.shade700),
//         const SizedBox(height: 16),
//         const Text(
//           'Activation de la Licence',
//           style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 8),
//         Text(
//           'Bienvenue ! Activez votre application',
//           style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildInstructions() {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Colors.blue.shade50,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.blue.shade200),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               Icon(Icons.info_outline, color: Colors.blue.shade700),
//               const SizedBox(width: 8),
//               const Text(
//                 'Comment activer votre licence ?',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           _buildInstructionStep('1', 'Choisissez votre type de licence', [
//             '• Licence DEMO: Durée limitée (7, 15, 30 jours...)',
//             '• Licence LIFETIME: Accès permanent sans expiration',
//           ]),
//           const Divider(height: 24),
//           _buildInstructionStep('2', 'Scannez le QR Code ci-dessous', [
//             '• Utilisez l\'application Admin Android',
//             '• Ou envoyez une demande par email avec le bouton "Demander par Email"',
//           ]),
//           const Divider(height: 24),
//           _buildInstructionStep('3', 'Recevez et entrez votre code PIN', [
//             '• Vous recevrez un code PIN de 10 chiffres',
//             '• Entrez-le dans les champs ci-dessous',
//             '• Cliquez sur "Valider" pour activer',
//           ]),
//           const SizedBox(height: 16),
//           Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               color: Colors.orange.shade50,
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(color: Colors.orange.shade300),
//             ),
//             child: Row(
//               children: [
//                 Icon(Icons.warning_amber, color: Colors.orange.shade700),
//                 const SizedBox(width: 8),
//                 const Expanded(
//                   child: Text(
//                     'Le code PIN est unique pour cet ordinateur et ne peut pas être utilisé sur un autre appareil.',
//                     style: TextStyle(fontSize: 13),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInstructionStep(String number, String title,
//       List<String> points) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Row(
//           children: [
//             CircleAvatar(
//               radius: 16,
//               backgroundColor: Colors.blue.shade700,
//               child: Text(number,
//                   style: const TextStyle(
//                       color: Colors.white, fontWeight: FontWeight.bold)),
//             ),
//             const SizedBox(width: 12),
//             Text(title,
//                 style:
//                 const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//           ],
//         ),
//         const SizedBox(height: 8),
//         Padding(
//           padding: const EdgeInsets.only(left: 44),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: points
//                 .map((p) =>
//                 Padding(
//                   padding: const EdgeInsets.only(bottom: 4),
//                   child: Text(p,
//                       style: TextStyle(color: Colors.grey.shade700)),
//                 ))
//                 .toList(),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQRSection() {
//     return Column(
//       children: [
//         const Text(
//           'Scannez ce QR Code',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(color: Colors.grey.shade300, width: 2),
//           ),
//           child: QrImageView(
//             data: _generateQRData(),
//             version: QrVersions.auto,
//             size: 250,
//             backgroundColor: Colors.white,
//           ),
//         ),
//         const SizedBox(height: 12),
//         Text(
//           'ID Appareil: ${deviceFingerprint?.substring(0, 16)}...',
//           style: TextStyle(
//               fontSize: 12,
//               color: Colors.grey.shade600,
//               fontFamily: 'monospace'),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildPinSection() {
//     return Column(
//       children: [
//         const Text(
//           'Entrez votre code PIN d\'activation',
//           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: List.generate(10, (index) {
//             return Container(
//               width: 50,
//               margin: EdgeInsets.symmetric(horizontal: 4),
//               child: TextField(
//                 controller: pinControllers[index],
//                 focusNode: focusNodes[index],
//                 textAlign: TextAlign.center,
//                 keyboardType: TextInputType.number,
//                 maxLength: 1,
//                 style:
//                 const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 decoration: InputDecoration(
//                   counterText: '',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide:
//                     BorderSide(color: Colors.blue.shade700, width: 2),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                     borderSide:
//                     BorderSide(color: Colors.blue.shade700, width: 3),
//                   ),
//                 ),
//                 inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                 onChanged: (value) {
//                   if (value.isNotEmpty && index < 9) {
//                     focusNodes[index + 1].requestFocus();
//                   }
//                   if (value.isEmpty && index > 0) {
//                     focusNodes[index - 1].requestFocus();
//                   }
//                 },
//               ),
//             );
//           }),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildButtons() {
//     return Column(
//       children: [
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: ElevatedButton.icon(
//             onPressed: isValidating ? null : _validateLicense,
//             icon: isValidating
//                 ? const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                   strokeWidth: 2, color: Colors.white),
//             )
//                 : const Icon(Icons.check_circle),
//             label: Text(
//               isValidating ? 'Validation en cours...' : 'Valider la Licence',
//               style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.green.shade600,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//             ),
//           ),
//         ),
//         const SizedBox(height: 12),
//         SizedBox(
//           width: double.infinity,
//           height: 50,
//           child: OutlinedButton.icon(
//             onPressed: _sendEmailRequest,
//             icon: const Icon(Icons.email),
//             label: const Text(
//               'Demander par Email',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//             ),
//             style: OutlinedButton.styleFrom(
//               side: BorderSide(color: Colors.blue.shade700, width: 2),
//               shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10)),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }
//
// // Écran principal (placeholder)
// class MainAppScreen extends StatelessWidget {
//   const MainAppScreen({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('Application Activée')),
//       body: const Center(
//           child: Text('Bienvenue ! Votre application est activée.')),
//     );
//   }
// }
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:device_info_plus/device_info_plus.dart';
// import 'dart:io';
//
// class LicenseService {
//   static const String _licenseKey = 'license';
//   static const String _secretSalt = 'SECRET_SALT_KEY';
//
//   /// Vérifie si l'application possède une licence valide
//   static Future<LicenseStatus> checkLicense() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final licenseData = prefs.getString(_licenseKey);
//
//       if (licenseData == null) {
//         return LicenseStatus(
//           isValid: false,
//           type: LicenseType.none,
//           message: 'Aucune licence trouvée',
//         );
//       }
//
//       final license = jsonDecode(licenseData);
//
//       // Vérifier l'intégrité de l'appareil
//       final currentDeviceId = await _getDeviceFingerprint();
//       final savedDeviceId = license['device_id'] as String?;
//
//       if (currentDeviceId != savedDeviceId) {
//         return LicenseStatus(
//           isValid: false,
//           type: LicenseType.none,
//           message: 'Cette licence est liée à un autre appareil',
//         );
//       }
//
//       // Vérifier le type de licence
//       final type = license['type'] as String;
//
//       if (type == 'lifetime') {
//         return LicenseStatus(
//           isValid: true,
//           type: LicenseType.lifetime,
//           message: 'Licence LIFETIME active',
//         );
//       }
//
//       if (type == 'demo') {
//         final expiryStr = license['expiry_date'] as String?;
//         if (expiryStr == null) {
//           return LicenseStatus(
//             isValid: false,
//             type: LicenseType.none,
//             message: 'Licence corrompue',
//           );
//         }
//
//         final expiryDate = DateTime.parse(expiryStr);
//         final now = DateTime.now();
//
//         if (now.isAfter(expiryDate)) {
//           return LicenseStatus(
//             isValid: false,
//             type: LicenseType.expired,
//             message: 'Licence DEMO expirée le ${expiryDate.toString().substring(
//                 0, 10)}',
//             expiryDate: expiryDate,
//           );
//         }
//
//         final daysRemaining = expiryDate
//             .difference(now)
//             .inDays;
//
//         return LicenseStatus(
//           isValid: true,
//           type: LicenseType.demo,
//           message: 'Licence DEMO active ($daysRemaining jours restants)',
//           expiryDate: expiryDate,
//           daysRemaining: daysRemaining,
//         );
//       }
//
//       return LicenseStatus(
//         isValid: false,
//         type: LicenseType.none,
//         message: 'Type de licence inconnu',
//       );
//     } catch (e) {
//       return LicenseStatus(
//         isValid: false,
//         type: LicenseType.none,
//         message: 'Erreur lors de la vérification: $e',
//       );
//     }
//   }
//
//   /// Obtient les détails de la licence
//   static Future<Map<String, dynamic>?> getLicenseDetails() async {
//     final prefs = await SharedPreferences.getInstance();
//     final licenseData = prefs.getString(_licenseKey);
//
//     if (licenseData == null) return null;
//
//     return jsonDecode(licenseData);
//   }
//
//   /// Supprime la licence (pour débogage ou réinitialisation)
//   static Future<void> removeLicense() async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.remove(_licenseKey);
//   }
//
//   /// Génère l'empreinte unique de l'appareil
//   static Future<String> _getDeviceFingerprint() async {
//     final deviceInfo = DeviceInfoPlugin();
//     String fingerprint = '';
//
//     if (Platform.isWindows) {
//       final windowsInfo = await deviceInfo.windowsInfo;
//
//       final components = [
//         windowsInfo.computerName,
//         windowsInfo.numberOfCores.toString(),
//         windowsInfo.systemMemoryInMegabytes.toString(),
//         Platform.operatingSystemVersion,
//       ];
//
//       final bytes = utf8.encode(components.join('|'));
//       final digest = sha256.convert(bytes);
//       fingerprint = digest.toString();
//     }
//
//     return fingerprint;
//   }
//
//   /// Vérifie périodiquement la validité de la licence (à appeler régulièrement)
//   static Future<bool> validateLicenseIntegrity() async {
//     final status = await checkLicense();
//     return status.isValid;
//   }
//
//   /// Obtient le hash court de l'appareil (pour validation PIN)
//   static Future<String> getDeviceHashShort() async {
//     final fingerprint = await _getDeviceFingerprint();
//     final hash = sha256.convert(utf8.encode(fingerprint));
//     return hash.toString().substring(0, 4);
//   }
//
//   /// Calcule le checksum pour validation
//   static String calculateChecksum(String data) {
//     final hash = sha256.convert(utf8.encode(data + _secretSalt));
//     return hash.toString().substring(0, 3);
//   }
// }
//
// /// Statut de la licence
// class LicenseStatus {
//   final bool isValid;
//   final LicenseType type;
//   final String message;
//   final DateTime? expiryDate;
//   final int? daysRemaining;
//
//   LicenseStatus({
//     required this.isValid,
//     required this.type,
//     required this.message,
//     this.expiryDate,
//     this.daysRemaining,
//   });
// }
//
// /// Types de licence
// enum LicenseType {
//   none,
//   demo,
//   lifetime,
//   expired,
// }
//
// /// Widget wrapper pour protéger l'application
// class LicenseProtectedApp extends StatefulWidget {
//   final Widget child;
//   final Widget activationScreen;
//
//   const LicenseProtectedApp({
//     Key? key,
//     required this.child,
//     required this.activationScreen,
//   }) : super(key: key);
//
//   @override
//   State<LicenseProtectedApp> createState() => _LicenseProtectedAppState();
// }
//
// class _LicenseProtectedAppState extends State<LicenseProtectedApp> {
//   bool _isChecking = true;
//   bool _isLicenseValid = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkLicense();
//
//     // Vérification périodique toutes les 5 minutes
//     _startPeriodicCheck();
//   }
//
//   Future<void> _checkLicense() async {
//     final status = await LicenseService.checkLicense();
//
//     setState(() {
//       _isLicenseValid = status.isValid;
//       _isChecking = false;
//     });
//
//     if (!status.isValid && status.type == LicenseType.expired) {
//       _showExpiredDialog(status.message);
//     }
//   }
//
//   void _startPeriodicCheck() {
//     Future.delayed(const Duration(minutes: 5), () {
//       if (mounted) {
//         _checkLicense();
//         _startPeriodicCheck();
//       }
//     });
//   }
//
//   void _showExpiredDialog(String message) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) =>
//           AlertDialog(
//             title: const Row(
//               children: [
//                 Icon(Icons.warning, color: Colors.orange),
//                 SizedBox(width: 8),
//                 Text('Licence Expirée'),
//               ],
//             ),
//             content: Text(message),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.of(context).pop();
//                   Navigator.of(context).pushReplacement(
//                     MaterialPageRoute(builder: (_) => widget.activationScreen),
//                   );
//                 },
//                 child: const Text('Renouveler la Licence'),
//               ),
//             ],
//           ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_isChecking) {
//       return const MaterialApp(
//         home: Scaffold(
//           body: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text('Vérification de la licence...'),
//               ],
//             ),
//           ),
//         ),
//       );
//     }
//
//     if (!_isLicenseValid) {
//       return MaterialApp(
//         home: widget.activationScreen,
//       );
//     }
//
//     return widget.child;
//   }
// }
//
// /// Widget pour afficher les infos de licence dans l'app
// class LicenseInfoWidget extends StatefulWidget {
//   const LicenseInfoWidget({Key? key}) : super(key: key);
//
//   @override
//   State<LicenseInfoWidget> createState() => _LicenseInfoWidgetState();
// }
//
// class _LicenseInfoWidgetState extends State<LicenseInfoWidget> {
//   LicenseStatus? _status;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadStatus();
//   }
//
//   Future<void> _loadStatus() async {
//     final status = await LicenseService.checkLicense();
//     setState(() => _status = status);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (_status == null) {
//       return const CircularProgressIndicator();
//     }
//
//     Color statusColor = _status!.isValid ? Colors.green : Colors.red;
//     IconData statusIcon = _status!.isValid ? Icons.check_circle : Icons.error;
//
//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(statusIcon, color: statusColor),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Statut de la Licence',
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: statusColor,
//                   ),
//                 ),
//               ],
//             ),
//             const Divider(height: 24),
//             _buildInfoRow('Type', _getLicenseTypeLabel(_status!.type)),
//             _buildInfoRow('Statut', _status!.message),
//             if (_status!.expiryDate != null)
//               _buildInfoRow(
//                 'Expiration',
//                 _status!.expiryDate!.toString().substring(0, 10),
//               ),
//             if (_status!.daysRemaining != null)
//               _buildInfoRow(
//                 'Jours restants',
//                 _status!.daysRemaining.toString(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '$label:',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           Text(value),
//         ],
//       ),
//     );
//   }
//
//   String _getLicenseTypeLabel(LicenseType type) {
//     switch (type) {
//       case LicenseType.demo:
//         return 'DEMO';
//       case LicenseType.lifetime:
//         return 'LIFETIME';
//       case LicenseType.expired:
//         return 'EXPIRÉE';
//       case LicenseType.none:
//         return 'AUCUNE';
//     }
//   }
// }
//
// import 'package:flutter/material.dart';
// import 'license_activation_screen.dart'; // Le premier fichier
// import 'license_service.dart'; // Le fichier service
//
// void main() {
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Mon Application',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         useMaterial3: true,
//       ),
//       // Le LicenseProtectedApp vérifie automatiquement la licence
//       home: LicenseProtectedApp(
//         activationScreen: const LicenseActivationScreen(),
//         child: const MainApp(),
//       ),
//     );
//   }
// }
//
// // Votre application principale (après activation)
// class MainApp extends StatelessWidget {
//   const MainApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mon Application'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.info),
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const LicenseInfoPage(),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(Icons.check_circle, size: 80, color: Colors.green),
//             const SizedBox(height: 20),
//             const Text(
//               'Application Activée avec Succès !',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             const SizedBox(height: 40),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).push(
//                   MaterialPageRoute(
//                     builder: (_) => const LicenseInfoPage(),
//                   ),
//                 );
//               },
//               child: const Text('Voir les informations de licence'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Page d'information de licence
// class LicenseInfoPage extends StatelessWidget {
//   const LicenseInfoPage({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Informations de Licence'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             const LicenseInfoWidget(),
//             const SizedBox(height: 20),
//             FutureBuilder<Map<String, dynamic>?>(
//               future: LicenseService.getLicenseDetails(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 final details = snapshot.data!;
//                 return Card(
//                   child: Padding(
//                     padding: const EdgeInsets.all(16),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Détails Techniques',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const Divider(height: 24),
//                         _buildDetailRow(
//                           'Code PIN',
//                           details['pin'] ?? 'N/A',
//                         ),
//                         _buildDetailRow(
//                           'Date d\'activation',
//                           _formatDate(details['activated_at']),
//                         ),
//                         _buildDetailRow(
//                           'ID Appareil',
//                           (details['device_id'] as String?)
//                               ?.substring(0, 16) ??
//                               'N/A',
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//             const Spacer(),
//             // Bouton de débogage (à retirer en production)
//             if (const bool.fromEnvironment('DEBUG', defaultValue: false))
//               ElevatedButton(
//                 onPressed: () async {
//                   await LicenseService.removeLicense();
//                   if (context.mounted) {
//                     Navigator.of(context).pushAndRemoveUntil(
//                       MaterialPageRoute(
//                         builder: (_) => const LicenseActivationScreen(),
//                       ),
//                           (route) => false,
//                     );
//                   }
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.red,
//                   foregroundColor: Colors.white,
//                 ),
//                 child: const Text('Supprimer la Licence (DEBUG)'),
//               ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDetailRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '$label:',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           Text(
//             value,
//             style: const TextStyle(fontFamily: 'monospace'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   String _formatDate(String? isoDate) {
//     if (isoDate == null) return 'N/A';
//     try {
//       final date = DateTime.parse(isoDate);
//       return '${date.day}/${date.month}/${date.year} ${date.hour}:${date
//           .minute}';
//     } catch (e) {
//       return 'N/A';
//     }
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
// import 'package:flutter/services.dart';
//
// void main() {
//   runApp(const AdminLicenseApp());
// }
//
// class AdminLicenseApp extends StatelessWidget {
//   const AdminLicenseApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Admin License Generator',
//       theme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         brightness: Brightness.light,
//       ),
//       darkTheme: ThemeData(
//         primarySwatch: Colors.deepPurple,
//         brightness: Brightness.dark,
//       ),
//       home: const AdminLoginScreen(),
//     );
//   }
// }
//
// class AdminLoginScreen extends StatefulWidget {
//   const AdminLoginScreen({Key? key}) : super(key: key);
//
//   @override
//   State<AdminLoginScreen> createState() => _AdminLoginScreenState();
// }
//
// class _AdminLoginScreenState extends State<AdminLoginScreen> {
//   final _passwordController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isPasswordVisible = false;
//   bool _isLoading = false;
//
//   // IMPORTANT: Changez ce mot de passe sécurisé
//   // En production, utilisez un hash SHA-256 du mot de passe
//   static const String _adminPasswordHash =
//       'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f'; // Hash de "Admin@2024"
//
//   @override
//   void dispose() {
//     _passwordController.dispose();
//     super.dispose();
//   }
//
//   String _hashPassword(String password) {
//     final bytes = utf8.encode(password);
//     final digest = sha256.convert(bytes);
//     return digest.toString();
//   }
//
//   void _login() {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     // Simulation d'un délai pour éviter les attaques par force brute
//     Future.delayed(const Duration(milliseconds: 500), () {
//       final enteredPasswordHash = _hashPassword(_passwordController.text);
//
//       if (enteredPasswordHash == _adminPasswordHash) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (_) => const QRScannerScreen()),
//         );
//       } else {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Mot de passe incorrect'),
//             backgroundColor: Colors.red,
//             duration: Duration(seconds: 2),
//           ),
//         );
//         _passwordController.clear();
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.deepPurple.shade700,
//               Colors.deepPurple.shade900,
//             ],
//           ),
//         ),
//         child: SafeArea(
//           child: Center(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(24),
//               child: Card(
//                 elevation: 8,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.all(32),
//                   child: Form(
//                     key: _formKey,
//                     child: Column(
//                       mainAxisSize: MainAxisSize.min,
//                       children: [
//                         // Logo et titre
//                         Container(
//                           padding: const EdgeInsets.all(20),
//                           decoration: BoxDecoration(
//                             color: Colors.deepPurple.shade50,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             Icons.admin_panel_settings,
//                             size: 64,
//                             color: Colors.deepPurple.shade700,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         const Text(
//                           'Admin License',
//                           style: TextStyle(
//                             fontSize: 28,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           'Générateur de Licences',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.grey.shade600,
//                           ),
//                         ),
//                         const SizedBox(height: 40),
//
//                         // Champ mot de passe
//                         TextFormField(
//                           controller: _passwordController,
//                           obscureText: !_isPasswordVisible,
//                           enabled: !_isLoading,
//                           decoration: InputDecoration(
//                             labelText: 'Mot de passe administrateur',
//                             hintText: 'Entrez votre mot de passe',
//                             prefixIcon: const Icon(Icons.lock),
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _isPasswordVisible
//                                     ? Icons.visibility_off
//                                     : Icons.visibility,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   _isPasswordVisible = !_isPasswordVisible;
//                                 });
//                               },
//                             ),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             filled: true,
//                             fillColor: Colors.grey.shade50,
//                           ),
//                           validator: (value) {
//                             if (value == null || value.isEmpty) {
//                               return 'Veuillez entrer le mot de passe';
//                             }
//                             if (value.length < 6) {
//                               return 'Mot de passe trop court';
//                             }
//                             return null;
//                           },
//                           onFieldSubmitted: (_) => _login(),
//                         ),
//                         const SizedBox(height: 32),
//
//                         // Bouton de connexion
//                         SizedBox(
//                           width: double.infinity,
//                           height: 50,
//                           child: ElevatedButton(
//                             onPressed: _isLoading ? null : _login,
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: Colors.deepPurple.shade700,
//                               foregroundColor: Colors.white,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               elevation: 4,
//                             ),
//                             child: _isLoading
//                                 ? const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.white,
//                               ),
//                             )
//                                 : const Text(
//                               'Se connecter',
//                               style: TextStyle(
//                                 fontSize: 16,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//
//                         // Info sécurité
//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.orange.shade50,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.orange.shade200),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.security,
//                                 color: Colors.orange.shade700,
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   'Accès réservé aux administrateurs uniquement',
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.orange.shade900,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class QRScannerScreen extends StatefulWidget {
//   const QRScannerScreen({Key? key}) : super(key: key);
//
//   @override
//   State<QRScannerScreen> createState() => _QRScannerScreenState();
// }
//
// class _QRScannerScreenState extends State<QRScannerScreen> {
//   final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
//   QRViewController? controller;
//   bool hasScanned = false;
//
//   @override
//   void dispose() {
//     controller?.dispose();
//     super.dispose();
//   }
//
//   void _onQRViewCreated(QRViewController controller) {
//     this.controller = controller;
//     controller.scannedDataStream.listen((scanData) {
//       if (!hasScanned && scanData.code != null) {
//         hasScanned = true;
//         controller.pauseCamera();
//         _processQRData(scanData.code!);
//       }
//     });
//   }
//
//   void _processQRData(String qrData) {
//     try {
//       final data = jsonDecode(qrData);
//       final deviceId = data['device_id'] as String?;
//       final timestamp = data['timestamp'] as int?;
//       final appVersion = data['app_version'] as String?;
//
//       if (deviceId == null || timestamp == null) {
//         _showError('QR Code invalide');
//         return;
//       }
//
//       // Vérifier que le timestamp n'est pas trop ancien (max 1 heure)
//       final now = DateTime.now().millisecondsSinceEpoch;
//       if (now - timestamp > 3600000) {
//         _showError('QR Code expiré. Veuillez en générer un nouveau.');
//         return;
//       }
//
//       Navigator.of(context).push(
//         MaterialPageRoute(
//           builder: (_) => LicenseGeneratorScreen(
//             deviceId: deviceId,
//             appVersion: appVersion ?? 'Unknown',
//           ),
//         ),
//       ).then((_) {
//         setState(() => hasScanned = false);
//         controller?.resumeCamera();
//       });
//     } catch (e) {
//       _showError('Erreur lors du scan: $e');
//       setState(() => hasScanned = false);
//       controller?.resumeCamera();
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Scanner QR Code'),
//         centerTitle: true,
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             flex: 5,
//             child: QRView(
//               key: qrKey,
//               onQRViewCreated: _onQRViewCreated,
//               overlay: QrScannerOverlayShape(
//                 borderColor: Colors.deepPurple,
//                 borderRadius: 10,
//                 borderLength: 30,
//                 borderWidth: 10,
//                 cutOutSize: 300,
//               ),
//             ),
//           ),
//           Expanded(
//             flex: 1,
//             child: Container(
//               color: Colors.deepPurple.shade50,
//               child: Center(
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Icon(Icons.qr_code_scanner, size: 48, color: Colors.deepPurple.shade700),
//                     const SizedBox(height: 8),
//                     const Text(
//                       'Scannez le QR Code de l\'application Windows',
//                       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class LicenseGeneratorScreen extends StatefulWidget {
//   final String deviceId;
//   final String appVersion;
//
//   const LicenseGeneratorScreen({
//     Key? key,
//     required this.deviceId,
//     required this.appVersion,
//   }) : super(key: key);
//
//   @override
//   State<LicenseGeneratorScreen> createState() => _LicenseGeneratorScreenState();
// }
//
// class _LicenseGeneratorScreenState extends State<LicenseGeneratorScreen> {
//   String? selectedLicenseType;
//   int? selectedDuration;
//   String? generatedPin;
//
//   final Map<String, String> licenseTypes = {
//     'demo': 'Licence DEMO (Durée limitée)',
//     'lifetime': 'Licence LIFETIME (Permanent)',
//   };
//
//   final List<int> demoDurations = [7, 15, 30, 60, 90];
//
//   void _generatePin() {
//     if (selectedLicenseType == null) {
//       _showError('Veuillez sélectionner un type de licence');
//       return;
//     }
//
//     if (selectedLicenseType == 'demo' && selectedDuration == null) {
//       _showError('Veuillez sélectionner une durée pour la licence DEMO');
//       return;
//     }
//
//     // Format du PIN: Type(1) + Durée(2) + DeviceHash(4) + Checksum(3)
//     final typeCode = selectedLicenseType == 'demo' ? '1' : '2';
//     final durationCode = selectedLicenseType == 'demo'
//         ? selectedDuration.toString().padLeft(2, '0')
//         : '00';
//
//     // Générer un hash court de l'appareil
//     final deviceHash = _getDeviceHashShort(widget.deviceId);
//
//     // Créer le code de base
//     final baseCode = typeCode + durationCode + deviceHash;
//
//     // Calculer le checksum
//     final checksum = _calculateChecksum(baseCode);
//
//     // PIN final
//     final pin = baseCode + checksum;
//
//     setState(() {
//       generatedPin = pin;
//     });
//   }
//
//   String _getDeviceHashShort(String deviceId) {
//     final hash = sha256.convert(utf8.encode(deviceId));
//     return hash.toString().substring(0, 4);
//   }
//
//   String _calculateChecksum(String data) {
//     final hash = sha256.convert(utf8.encode(data + 'SECRET_SALT_KEY'));
//     return hash.toString().substring(0, 3);
//   }
//
//   void _copyToClipboard() {
//     if (generatedPin != null) {
//       Clipboard.setData(ClipboardData(text: generatedPin!));
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Code PIN copié dans le presse-papiers'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }
//
//   void _showError(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message), backgroundColor: Colors.red),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Générer une Licence'),
//         centerTitle: true,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _buildDeviceInfo(),
//             const SizedBox(height: 24),
//             _buildLicenseTypeSelector(),
//             if (selectedLicenseType == 'demo') ...[
//               const SizedBox(height: 24),
//               _buildDurationSelector(),
//             ],
//             const SizedBox(height: 32),
//             _buildGenerateButton(),
//             if (generatedPin != null) ...[
//               const SizedBox(height: 32),
//               _buildGeneratedPin(),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDeviceInfo() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.schedule, color: Colors.deepPurple.shade700),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Durée de la licence',
//                   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Wrap(
//               spacing: 8,
//               runSpacing: 8,
//               children: demoDurations.map((days) {
//                 final isSelected = selectedDuration == days;
//                 return ChoiceChip(
//                   label: Text('$days jours'),
//                   selected: isSelected,
//                   onSelected: (selected) {
//                     setState(() {
//                       selectedDuration = selected ? days : null;
//                       generatedPin = null;
//                     });
//                   },
//                   selectedColor: Colors.deepPurple.shade700,
//                   labelStyle: TextStyle(
//                     color: isSelected ? Colors.white : Colors.black,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 );
//               }).toList(),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildGenerateButton() {
//     return ElevatedButton.icon(
//       onPressed: _generatePin,
//       icon: const Icon(Icons.vpn_key, size: 28),
//       label: const Text(
//         'Générer le Code PIN',
//         style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//       ),
//       style: ElevatedButton.styleFrom(
//         backgroundColor: Colors.deepPurple.shade700,
//         foregroundColor: Colors.white,
//         padding: const EdgeInsets.symmetric(vertical: 16),
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         elevation: 4,
//       ),
//     );
//   }
//
//   Widget _buildGeneratedPin() {
//     return Card(
//       elevation: 8,
//       color: Colors.green.shade50,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(color: Colors.green.shade700, width: 2),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.check_circle, color: Colors.green.shade700, size: 32),
//                 const SizedBox(width: 8),
//                 const Text(
//                   'Code PIN Généré',
//                   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.grey.shade300),
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: generatedPin!.split('').map((digit) {
//                   return Container(
//                     margin: const EdgeInsets.symmetric(horizontal: 4),
//                     padding: const EdgeInsets.all(8),
//                     decoration: BoxDecoration(
//                       color: Colors.deepPurple.shade50,
//                       borderRadius: BorderRadius.circular(8),
//                       border: Border.all(color: Colors.deepPurple.shade300),
//                     ),
//                     child: Text(
//                       digit,
//                       style: TextStyle(
//                         fontSize: 24,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.deepPurple.shade900,
//                         fontFamily: 'monospace',
//                       ),
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton.icon(
//               onPressed: _copyToClipboard,
//               icon: const Icon(Icons.copy),
//               label: const Text('Copier le Code PIN'),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green.shade700,
//                 foregroundColor: Colors.white,
//                 padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                 shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.blue.shade50,
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 children: [
//                   Row(
//                     children: [
//                       Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Détails de la licence',
//                         style: TextStyle(fontWeight: FontWeight.bold),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   _buildLicenseDetail(
//                     'Type',
//                     selectedLicenseType == 'demo' ? 'DEMO' : 'LIFETIME',
//                   ),
//                   if (selectedLicenseType == 'demo')
//                     _buildLicenseDetail('Durée', '$selectedDuration jours'),
//                   _buildLicenseDetail(
//                     'Expiration',
//                     selectedLicenseType == 'demo'
//                         ? DateTime.now()
//                         .add(Duration(days: selectedDuration!))
//                         .toString()
//                         .substring(0, 10)
//                         : 'Jamais',
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildLicenseDetail(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 2),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             '$label:',
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               color: Colors.grey.shade700,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }(Icons.computer, color: Colors.deepPurple.shade700),
// const SizedBox(width: 8),
// const Text(
// 'Informations de l\'appareil',
// style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// ),
// ],
// ),
// const Divider(height: 24),
// _buildInfoRow('ID Appareil', widget.deviceId.substring(0, 16) + '...'),
// _buildInfoRow('Version App', widget.appVersion),
// _buildInfoRow('Date de scan', DateTime.now().toString().substring(0, 19)),
// ],
// ),
// ),
// );
// }
//
// Widget _buildInfoRow(String label, String value) {
// return Padding(
// padding: const EdgeInsets.symmetric(vertical: 4),
// child: Row(
// children: [
// SizedBox(
// width: 120,
// child: Text(
// '$label:',
// style: const TextStyle(fontWeight: FontWeight.w500),
// ),
// ),
// Expanded(
// child: Text(
// value,
// style: TextStyle(color: Colors.grey.shade700, fontFamily: 'monospace'),
// ),
// ),
// ],
// ),
// );
// }
//
// Widget _buildLicenseTypeSelector() {
// return Card(
// elevation: 4,
// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// child: Padding(
// padding: const EdgeInsets.all(16),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// children: [
// Icon(Icons.card_membership, color: Colors.deepPurple.shade700),
// const SizedBox(width: 8),
// const Text(
// 'Type de licence',
// style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
// ),
// ],
// ),
// const SizedBox(height: 16),
// ...licenseTypes.entries.map((entry) {
// return RadioListTile<String>(
// title: Text(entry.value),
// subtitle: Text(
// entry.key == 'demo'
// ? 'Accès temporaire avec date d\'expiration'
//     : 'Accès illimité sans expiration',
// style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
// ),
// value: entry.key,
// groupValue: selectedLicenseType,
// activeColor: Colors.deepPurple.shade700,
// onChanged: (value) {
// setState(() {
// selectedLicenseType = value;
// selectedDuration = null;
// generatedPin = null;
// });
// },
// );
// }).toList(),
// ],
// ),
// ),
// );
// }
//
// Widget _buildDurationSelector() {
// return Card(
// elevation: 4,
// shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
// child: Padding(
// padding: const EdgeInsets.all(16),
// child: Column(
// crossAxisAlignment: CrossAxisAlignment.start,
// children: [
// Row(
// children: [
// Icon
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
//
// /// Utilitaire pour générer le hash du mot de passe administrateur
// ///
// /// UTILISATION:
// /// 1. Exécutez ce script pour générer un nouveau hash
// /// 2. Copiez le hash généré
// /// 3. Remplacez la valeur de _adminPasswordHash dans AdminLoginScreen
// ///
// /// Pour exécuter: dart run password_generator.dart
//
// void main() {
// print('╔════════════════════════════════════════════════════╗');
// print('║  GÉNÉRATEUR DE HASH POUR MOT DE PASSE ADMIN       ║');
// print('╚════════════════════════════════════════════════════╝\n');
//
// // Exemples de mots de passe sécurisés
// final examplePasswords = [
// 'Admin@2024',
// 'SecurePass123!',
// 'MyApp#Admin2024',
// 'StrongPassword!789',
// ];
//
// print('📝 Exemples de hash pour différents mots de passe:\n');
//
// for (var password in examplePasswords) {
// final hash = generatePasswordHash(password);
// print('Mot de passe: "$password"');
// print('Hash SHA-256: $hash');
// print('─' * 70);
// }
//
// print('\n💡 INSTRUCTIONS:');
// print('1. Choisissez un mot de passe fort (min 8 caractères)');
// print('2. Générez son hash avec la fonction generatePasswordHash()');
// print('3. Copiez le hash dans la constante _adminPasswordHash');
// print('4. NE PARTAGEZ JAMAIS le mot de passe en clair!\n');
//
// print('🔐 Recommandations pour un mot de passe fort:');
// print('   • Au moins 8 caractères');
// print('   • Mélange de majuscules et minuscules');
// print('   • Chiffres et caractères spéciaux');
// print('   • Pas de mots du dictionnaire\n');
//
// // Générer un mot de passe personnalisé
// print('═' * 70);
// print('\n✨ GÉNÉRER VOTRE PROPRE HASH:\n');
//
// // Remplacez 'VOTRE_MOT_DE_PASSE' par votre mot de passe réel
// const customPassword = 'VOTRE_MOT_DE_PASSE';
// final customHash = generatePasswordHash(customPassword);
//
// print('Votre mot de passe: "$customPassword"');
// print('Votre hash: $customHash\n');
//
// print('⚠️  IMPORTANT: Après avoir copié le hash, supprimez le mot de');
// print('   passe en clair de ce fichier pour plus de sécurité!\n');
// }
//
// /// Génère un hash SHA-256 d'un mot de passe
// String generatePasswordHash(String password) {
// final bytes = utf8.encode(password);
// final digest = sha256.convert(bytes);
// return digest.toString();
// }
//
// /// Vérifie si un mot de passe correspond à un hash
// bool verifyPassword(String password, String hash) {
// final passwordHash = generatePasswordHash(password);
// return passwordHash == hash;
// }
//
// /// Génère un mot de passe aléatoire sécurisé
// String generateRandomPassword({int length = 12}) {
// const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*';
// final random = DateTime.now().millisecondsSinceEpoch;
//
// String password = '';
// for (int i = 0; i < length; i++) {
// final index = (random + i) % chars.length;
// password += chars[index];
// }
//
// return password;
// }
//
// /// Classe pour gérer les mots de passe admin avec stockage sécurisé
// class AdminPasswordManager {
// static const String _defaultHash =
// 'ef92b778bafe771e89245b89ecbc08a44a4e166c06659911881f383d4473e94f'; // Admin@2024
//
// /// Vérifie un mot de passe contre le hash
// static bool verify(String password, [String? customHash]) {
// final hash = customHash ?? _defaultHash;
// return verifyPassword(password, hash);
// }
//
// /// Génère un nouveau hash pour changer le mot de passe
// static String generateNewHash(String newPassword) {
// if (newPassword.length < 8) {
// throw ArgumentError('Le mot de passe doit contenir au moins 8 caractères');
// }
//
// return generatePasswordHash(newPassword);
// }
//
// /// Valide la force d'un mot de passe
// static PasswordStrength checkPasswordStrength(String password) {
// if (password.length < 8) {
// return PasswordStrength.weak;
// }
//
// bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
// bool hasLowercase = password.contains(RegExp(r'[a-z]'));
// bool hasDigits = password.contains(RegExp(r'[0-9]'));
// bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
//
// int strength = 0;
// if (hasUppercase) strength++;
// if (hasLowercase) strength++;
// if (hasDigits) strength++;
// if (hasSpecialChars) strength++;
//
// if (password.length >= 12) strength++;
//
// if (strength >= 4) return PasswordStrength.strong;
// if (strength >= 3) return PasswordStrength.medium;
// return PasswordStrength.weak;
// }
// }
//
// enum PasswordStrength {
// weak,
// medium,
// strong,
// }
//
// // ═══════════════════════════════════════════════════════════════
// // GUIDE D'UTILISATION POUR PRODUCTION
// // ═══════════════════════════════════════════════════════════════
//
// /*
//
// 📖 ÉTAPES POUR CONFIGURER LE MOT DE PASSE ADMIN:
//
// 1. CHOISIR UN MOT DE PASSE SÉCURISÉ
//    ──────────────────────────────────
//    Exemple: "MySecureApp#2024!"
//
// 2. GÉNÉRER LE HASH
//    ──────────────────────────────────
//    Remplacez 'VOTRE_MOT_DE_PASSE' par votre mot de passe
//    et exécutez ce script:
//
//    dart run password_generator.dart
//
// 3. COPIER LE HASH
//    ──────────────────────────────────
//    Le hash sera affiché dans la console.
//    Exemple: "a1b2c3d4e5f6..."
//
// 4. METTRE À JOUR L'APP ADMIN
//    ──────────────────────────────────
//    Dans admin_android_app.dart, remplacez:
//
//    static const String _adminPasswordHash = 'ANCIEN_HASH';
//
//    par:
//
//    static const String _adminPasswordHash = 'NOUVEAU_HASH';
//
// 5. SUPPRIMER LE MOT DE PASSE EN CLAIR
//    ──────────────────────────────────
//    ⚠️ IMPORTANT: Ne laissez jamais le mot de passe en clair
//    dans votre code source!
//
// 6. DISTRIBUER L'APP
//    ──────────────────────────────────
//    • Compilez l'app avec le nouveau hash
//    • Communiquez le mot de passe de manière sécurisée
//    • Utilisez des canaux chiffrés (Signal, WhatsApp, etc.)
//
// ═══════════════════════════════════════════════════════════════
//
// 🔒 SÉCURITÉ ADDITIONNELLE (Optionnel):
//
// Pour encore plus de sécurité, vous pouvez:
//
// 1. Ajouter un salt unique par installation
// 2. Implémenter un système de double authentification
// 3. Limiter le nombre de tentatives (3 max)
// 4. Ajouter un délai après échec (exponential backoff)
// 5. Logger les tentatives de connexion
//
// ═══════════════════════════════════════════════════════════════
//
// 📝 EXEMPLE DE CONFIGURATION COMPLÈTE:
//
// void main() {
//   // Votre mot de passe choisi
//   const myPassword = 'SuperAdmin@2024!';
//
//   // Générer le hash
//   final hash = AdminPasswordManager.generateNewHash(myPassword);
//   print('Votre hash sécurisé: $hash');
//
//   // Vérifier la force
//   final strength = AdminPasswordManager.checkPasswordStrength(myPassword);
//   print('Force du mot de passe: ${strength.name}');
//
//   // Test de vérification
//   final isValid = AdminPasswordManager.verify(myPassword, hash);
//   print('Vérification: ${isValid ? "✓ OK" : "✗ ÉCHEC"}');
// }
//
// ═══════════════════════════════════════════════════════════════
// */
// # Système de Licence Sécurisé - Documentation
//
// ## 🔐 Vue d'ensemble du système
//
// Ce système de licence offre une protection multi-niveaux contre le piratage et le clonage :
//
// ### Caractéristiques de sécurité
//
// 1. **Empreinte Digitale Unique de l'Appareil**
// - Basée sur : Nom de l'ordinateur, nombre de cœurs CPU, RAM totale, version OS
// - Hachage SHA-256 pour créer une signature unique
// - Impossible à reproduire sur un autre PC
//
// 2. **Code PIN de 10 Chiffres**
// - Format : `[Type][Durée][HashAppareil][Checksum]`
// - Type (1 chiffre) : 1=Demo, 2=Lifetime
// - Durée (2 chiffres) : Nombre de jours pour Demo (00 pour Lifetime)
// - Hash Appareil (4 chiffres) : Partie du hash unique de l'appareil
// - Checksum (3 chiffres) : Validation d'intégrité avec sel secret
//
// 3. **Protection Anti-Clonage**
// - La licence est liée cryptographiquement à l'appareil
// - Vérification périodique (toutes les 5 minutes)
// - Détection immédiate si l'appareil change
//
// 4. **Timestamps et Expiration**
// - QR Code valide pendant 1 heure maximum
// - Vérification automatique d'expiration pour licences Demo
// - Blocage automatique après expiration
//
// 5. **Protection App Admin par Mot de Passe**
// - Accès à l'app Admin protégé par mot de passe sécurisé
// - Hash SHA-256 du mot de passe (jamais stocké en clair)
// - Délai anti-force brute entre les tentatives
//
// ---
//
// ## 📱 Application Windows (Desktop)
//
// ### Installation
//
// 1. Ajoutez les dépendances dans `pubspec.yaml`
// 2. Importez les fichiers fournis
// 3. Configurez votre `main.dart` avec `LicenseProtectedApp`
//
// ### Flux d'utilisation
//
// ```
// Démarrage App
// ↓
// Vérification Licence
// ↓
// Licence Valide? ─── NON ──→ Écran d'Activation
// ↓ OUI                        ↓
// Application Principale      [QR Code + Champs PIN]
// ↓
// Scan ou Email
// ↓
// Saisie PIN (10 chiffres)
// ↓
// Validation
// ↓
// Application Principale
// ```
//
// ### Écran d'Activation
//
// L'utilisateur voit :
// - **QR Code** à scanner avec l'app Admin Android
// - **Instructions détaillées** sur les types de licence
// - **10 champs** pour entrer le code PIN
// - **Bouton "Demander par Email"** pour envoyer une demande
// - **Bouton "Valider"** pour activer la licence
//
// ---
//
// ## 📱 Application Admin Android
//
// ### Configuration du Mot de Passe Admin
//
// **ÉTAPE 1: Générer le hash du mot de passe**
//
// ```bash
// # Exécutez le générateur de hash
// dart run password_generator.dart
// ```
//
// **ÉTAPE 2: Choisir un mot de passe fort**
//
// Critères recommandés:
// - Minimum 8 caractères
// - Majuscules ET minuscules
// - Chiffres
// - Caractères spéciaux (!@#$%^&*)
//
// Exemples:
// - ✅ `AdminApp@2024!`
// - ✅ `SecureKey#789`
// - ❌ `admin123` (trop faible)
// - ❌ `password` (trop simple)
//
// **ÉTAPE 3: Copier le hash**
//
// Le script affichera:
// ```
// Mot de passe: "AdminApp@2024!"
// Hash SHA-256: a1b2c3d4e5f6789...
// ```
//
// **ÉTAPE 4: Mettre à jour le code**
//
// Dans `admin_android_app.dart`, ligne ~25:
// ```dart
// static const String _adminPasswordHash =
// 'COLLEZ_VOTRE_HASH_ICI';
// ```
//
// **⚠️ IMPORTANT**:
// - Ne partagez JAMAIS le mot de passe en clair dans le code
// - Communiquez le mot de passe de manière sécurisée aux admins
// - Changez le mot de passe régulièrement
//
// ### Flux d'utilisation Admin
//
// ```
// Lancement App Admin
// ↓
// Écran de Connexion
// ↓
// Saisie Mot de Passe ─── INCORRECT ──→ Erreur + Nouveau essai
// ↓ CORRECT
// Scanner QR Code
// ↓
// Scan réussi
// ↓
// Choix Type Licence:
// • Demo (avec durée)
// • Lifetime
// ↓
// Génération Code PIN
// ↓
// Copie du PIN
// ↓
// Envoi au client
//
// ```
//
// ### Permissions Android nécessaires
//
// Ajoutez dans `android/app/src/main/AndroidManifest.xml`:
//
// ```xml
// <uses-permission android:name="android.permission.CAMERA" />
// <uses-feature android:name="android.hardware.camera" />
// <uses-feature android:name="android.hardware.camera.autofocus" />
// ```
//
// ---
//
// ## 🔧 Configuration et Personnalisation
//
// ### Changer le sel secret (SECRET_SALT_KEY)
//
// Pour plus de sécurité, changez le sel dans les deux fichiers:
//
// **1. Dans `license_activation_screen.dart` (ligne ~115)**
// ```dart
// String _calculateChecksum(String data) {
// final hash = sha256.convert(utf8.encode(data + 'VOTRE_SEL_UNIQUE'));
// return hash.toString().substring(0, 3);
// }
// ```
//
// **2. Dans `license_service.dart` (ligne ~5)**
// ```dart
// static const String _secretSalt = 'VOTRE_SEL_UNIQUE';
// ```
//
// **3. Dans `admin_android_app.dart` (ligne ~395)**
// ```dart
// String _calculateChecksum(String data) {
// final hash = sha256.convert(utf8.encode(data + 'VOTRE_SEL_UNIQUE'));
// return hash.toString().substring(0, 3);
// }
// ```
//
// ⚠️ **CRITIQUE**: Le même sel doit être utilisé partout!
//
// ### Personnaliser les durées Demo
//
// Dans `admin_android_app.dart`, ligne ~315:
// ```dart
// final List<int> demoDurations = [7, 15, 30, 60, 90, 180, 365];
// ```
//
// ### Changer l'email de support
//
// Dans `license_activation_screen.dart`, ligne ~140:
// ```dart
// final email = 'votre-support@votreapp.com';
// ```
//
// ---
//
// ## 🛡️ Mesures de Sécurité Additionnelles
//
// ### 1. Obfuscation du Code Flutter
//
// ```bash
// flutter build windows --obfuscate --split-debug-info=debug-info/
// flutter build apk --obfuscate --split-debug-info=debug-info/
// ```
//
// ### 2. Limitation des Tentatives de Connexion
//
// Ajoutez dans `AdminLoginScreen`:
// ```dart
// int _failedAttempts = 0;
// static const int maxAttempts = 3;
//
// if (_failedAttempts >= maxAttempts) {
// // Bloquer pendant X minutes
// await Future.delayed(Duration(minutes: 5));
// _failedAttempts = 0;
// }
// ```
//
// ### 3. Logs de Sécurité
//
// ```dart
// void _logSecurityEvent(String event) {
// final timestamp = DateTime.now().toIso8601String();
// print('[$timestamp] SECURITY: $event');
// // Optionnel: envoyer à un serveur de logs
// }
// ```
//
// ### 4. Chiffrement Local
//
// Pour encore plus de sécurité, chiffrez les données avec `flutter_secure_storage`:
// ```dart
// final storage = FlutterSecureStorage();
// await storage.write(key: 'license', value: encryptedData);
// ```
//
// ---
//
// ## 📊 Format du Code PIN
//
// ```
// PIN: [1][30][a7b4][c3f]
// │  │    │    │
// │  │    │    └─ Checksum (3 chiffres)
// │  │    └────── Hash appareil (4 chiffres)
// │  └─────────── Durée en jours (2 chiffres)
// └────────────── Type: 1=Demo, 2=Lifetime
// ```
//
// ### Exemples de PINs:
//
// | Type | Durée | PIN Complet | Description |
// |------|-------|-------------|-------------|
// | Demo | 7 jours | `107a7b4c3f` | Licence test 1 semaine |
// | Demo | 30 jours | `130a7b4c3f` | Licence essai 1 mois |
// | Demo | 90 jours | `190a7b4c3f` | Licence essai 3 mois |
// | Lifetime | ∞ | `200a7b4c3f` | Licence permanente |
//
// ---
//
// ## 🚀 Déploiement en Production
//
// ### Checklist avant déploiement:
//
// - [ ] Mot de passe admin changé et sécurisé
// - [ ] Sel secret (SECRET_SALT_KEY) personnalisé
// - [ ] Email de support configuré
// - [ ] Code obfusqué
// - [ ] Tests sur plusieurs appareils
// - [ ] Documentation admin préparée
// - [ ] Système de support en place
//
// ### Build des applications:
//
// **Windows Desktop:**
// ```bash
// flutter build windows --release --obfuscate
// ```
//
// **Android Admin:**
// ```bash
// flutter build apk --release --obfuscate
// ```
//
// ---
//
// ## 🆘 Support et Dépannage
//
// ### Problème: "Licence invalide"
// - Vérifier que le PIN est correct (10 chiffres)
// - Vérifier que le QR code n'est pas expiré (< 1h)
// - S'assurer que le sel secret est identique partout
//
// ### Problème: "Licence liée à un autre appareil"
// - La licence ne peut pas être transférée
// - Générer une nouvelle licence pour le nouvel appareil
//
// ### Problème: "QR Code expiré"
// - Rafraîchir l'écran d'activation sur Windows
// - Scanner le nouveau QR code généré
//
// ### Problème: Mot de passe admin oublié
// 1. Exécuter `password_generator.dart`
// 2. Générer un nouveau hash
// 3. Recompiler l'app Android avec le nouveau hash
//
// ---
//
// ## 📞 Contact et Support
//
// Pour toute question concernant l'implémentation:
// - Documentation officielle Flutter: https://flutter.dev
// - Crypto package: https://pub.dev/packages/crypto
// - QR Flutter: https://pub.dev/packages/qr_flutter
//
// ---
//
// ## 📄 License et Copyright
//
// © 2024 - Système de Licence Sécurisé
// Tous droits réservés.
//
// Ce système est fourni "tel quel" sans garantie d'aucune sorte.iffres) : Nombre de jours pour Demo (00 pour Lifetime)
// - Hash Appareil (4 chiffres) : Partie du hash unique de l'appareil
// - Checksum (3 chiffres) : Validation d'intégrité avec sel secret
//
// 3. **Protection Anti-Clonage**
// - La licence est liée cryptographiquement à l'appareil
// - Vérification périodique (toutes les 5 minutes)
// - Détection immédiate si l'appareil change
//
// 4. **Timestamps et Expiration**
// - QR Code valide pendant 1 heure maximum
// - Vérification automatique d'expiration pour licences Demo
// - Blocage automatique après expiration
//
// ---
//
// ## 📱 Application Windows (Desktop)
//
// ### Installation
//
// 1. Ajoutez les dépendances dans `pubspec.yaml`
// 2. Importez les fichiers fournis
// 3. Configurez votre `main.dart` avec `LicenseProtectedApp`
//
// ### Flux d'utilisation
//
// ```
// Démarrage App
// ↓
// Vérification Licence
// ↓
// Licence Valide? ─── NON ──→ Écran d'Activation
// ↓ OUI                        ↓
// Application Principale      [QR Code + Champs PIN]
// ↓
// Scan ou Email
// ↓
// Saisie PIN (10 chiffres)
// ↓
// Validation
// ↓
// Application Principale
// ```
//
// ### Écran d'Activation
//
// L'utilisateur voit :
// - **QR Code** à scanner avec l'app Admin Android
// - **Instructions détaillées** sur les types de licence
// - **10 champs** pour entrer le code PIN
// - **Bouton "Demander par Email"** pour envoyer une demande
// - **
// # 🔐 Système de Licence Multi-Plateforme
//
// Système complet de gestion de licences pour applications Flutter Desktop (Windows) avec application Admin Android pour génération de codes PIN.
//
// ## 📋 Table des Matières
//
// 1. [Prérequis](#prérequis)
// 2. [Installation App Windows](#installation-app-windows)
// 3. [Installation App Admin Android](#installation-app-admin-android)
// 4. [Configuration Initiale](#configuration-initiale)
// 5. [Utilisation](#utilisation)
// 6. [Architecture](#architecture)
// 7. [Sécurité](#sécurité)
// 8. [FAQ](#faq)
//
// ---
//
// ## 🎯 Prérequis
//
// ### Pour l'App Windows Desktop:
// - Flutter SDK 3.0.0 ou supérieur
// - Windows 10/11
// - Visual Studio 2022 avec C++ Desktop Development
//
// ### Pour l'App Admin Android:
// - Flutter SDK 3.0.0 ou supérieur
// - Android Studio
// - Android SDK (API 21+)
// - Appareil Android avec caméra
//
// ---
//
// ## 💻 Installation App Windows
//
// ### Étape 1: Créer le projet
//
// ```bash
// flutter create license_app_windows
// cd license_app_windows
// ```
//
// ### Étape 2: Structure des fichiers
//
// Créez cette structure dans `lib/`:
//
// ```
// lib/
// ├── main.dart
// ├── screens/
// │   └── license_activation_screen.dart
// ├── services/
// │   └── license_service.dart
// └── widgets/
// └── license_info_widget.dart
// ```
//
// ### Étape 3: Copier les fichiers
//
// 1. **main.dart** - Copiez le contenu de l'artifact "Exemple d'utilisation - main.dart"
// 2. **license_activation_screen.dart** - Copiez l'artifact "Système de Licence - App Windows (First Screen)"
// 3. **license_service.dart** - Copiez l'artifact "Service de Vérification de Licence"
//
// ### Étape 4: Configuration pubspec.yaml
//
// ```yaml
// name: license_app_windows
// description: Application Windows avec système de licence sécurisé
// version: 1.0.0
//
// environment:
// sdk: '>=3.0.0 <4.0.0'
//
// dependencies:
// flutter:
// sdk: flutter
//
// qr_flutter: ^4.1.0
// crypto: ^3.0.3
// device_info_plus: ^9.1.1
// shared_preferences: ^2.2.2
// url_launcher: ^6.2.2
//
// dev_dependencies:
// flutter_test:
// sdk: flutter
// flutter_lints: ^3.0.1
//
// flutter:
// uses-material-design: true
// ```
//
// ### Étape 5: Installer les dépendances
//
// ```bash
// flutter pub get
// ```
//
// ### Étape 6: Personnaliser
//
// **1. Changez le sel secret** dans 3 fichiers:
// - `license_activation_screen.dart` (ligne ~115)
// - `license_service.dart` (ligne 5)
// - `admin_android_app.dart` (ligne ~395)
//
// Remplacez `'SECRET_SALT_KEY'` par votre propre chaîne unique:
// ```dart
// static const String _secretSalt = 'MonSuperSelUnique2024!';
// ```
//
// **2. Configurez l'email de support** dans `license_activation_screen.dart`:
// ```dart
// final email = 'support@votreapp.com';
// ```
//
// ### Étape 7: Tester
//
// ```bash
// flutter run -d windows
// ```
//
// ### Étape 8: Build pour production
//
// ```bash
// flutter build windows --release --obfuscate --split-debug-info=build/app/outputs/symbols
// ```
//
// L'exécutable se trouve dans: `build\windows\runner\Release\`
//
// ---
//
// ## 📱 Installation App Admin Android
//
// ### Étape 1: Créer le projet
//
// ```bash
// flutter create license_admin_android
// cd license_admin_android
// ```
//
// ### Étape 2: Copier le fichier principal
//
// Remplacez le contenu de `lib/main.dart` par l'artifact "App Admin Android - Générateur de Licences"
//
// ### Étape 3: Configuration pubspec.yaml
//
// ```yaml
// name: license_admin_android
// description: Application Admin pour générer des licences
// version: 1.0.0
//
// environment:
// sdk: '>=3.0.0 <4.0.0'
//
// dependencies:
// flutter:
// sdk: flutter
//
// qr_code_scanner: ^1.0.1
// crypto: ^3.0.3
//
// dev_dependencies:
// flutter_test:
// sdk: flutter
// flutter_lints: ^3.0.1
//
// flutter:
// uses-material-design: true
// ```
//
// ### Étape 4: Configurer les permissions Android
//
// Modifiez `android/app/src/main/AndroidManifest.xml`:
//
// ```xml
// <manifest xmlns:android="http://schemas.android.com/apk/res/android">
//
// <!-- Ajoutez ces permissions -->
// <uses-permission android:name="android.permission.CAMERA" />
// <uses-feature android:name="android.hardware.camera" />
// <uses-feature android:name="android.hardware.camera.autofocus" />
//
// <application
// android:label="License Admin"
// android:icon="@mipmap/ic_launcher">
// <!-- Reste du fichier -->
// </application>
// </manifest>
// ```
//
// ### Étape 5: Installer les dépendances
//
// ```bash
// flutter pub get
// ```
//
// ### Étape 6: Configurer le mot de passe admin
//
// **Option A: Utiliser le générateur de hash**
//
// 1. Créez un fichier `password_generator.dart` avec l'artifact "Générateur de Hash de Mot de Passe Admin"
// 2. Exécutez:
// ```bash
// dart run password_generator.dart
// ```
// 3. Copiez le hash généré
//
// **Option B: Génération manuelle**
//
// ```dart
// import 'dart:convert';
// import 'package:crypto/crypto.dart';
//
// void main() {
// final password = 'VotreMotDePasse2024!';
// final bytes = utf8.encode(password);
// final hash = sha256.convert(bytes);
// print('Hash: $hash');
// }
// ```
//
// **4. Mettez à jour le hash dans main.dart:**
//
// ```dart
// static const String _adminPasswordHash =
// 'COLLEZ_VOTRE_HASH_ICI';
// ```
//
// ### Étape 7: Synchroniser le sel secret
//
// ⚠️ **IMPORTANT**: Le sel secret doit être identique dans l'app Windows ET l'app Android!
//
// Dans `main.dart` de l'app Android (ligne ~395):
// ```dart
// String _calculateChecksum(String data) {
// final hash = sha256.convert(utf8.encode(data + 'MonSuperSelUnique2024!'));
// return hash.toString().substring(0, 3);
// }
// ```
//
// ### Étape 8: Tester
//
// ```bash
// flutter run -d <votre-appareil-android>
// ```
//
// ### Étape 9: Build pour production
//
// ```bash
// flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols
// ```
//
// L'APK se trouve dans: `build/app/outputs/flutter-apk/app-release.apk`
//
// ---
//
// ## ⚙️ Configuration Initiale
//
// ### 1. Tester le système
//
// **Sur Windows:**
// 1. Lancez l'application
// 2. Vous verrez l'écran d'activation avec QR Code
// 3. Notez le QR Code affiché
//
// **Sur Android:**
// 1. Lancez l'app Admin
// 2. Entrez le mot de passe (par défaut: `Admin@2024`)
// 3. Scannez le QR Code de l'app Windows
// 4. Choisissez le type de licence
// 5. Copiez le code PIN généré
//
// **Retour sur Windows:**
// 1. Entrez le code PIN (10 chiffres)
// 2. Cliquez sur "Valider"
// 3. L'application s'active!
//
// ### 2. Vérifier la sécurité
//
// - [ ] Mot de passe admin changé
// - [ ] Sel secret personnalisé et identique partout
// - [ ] Email de support configuré
// - [ ] Tests sur plusieurs appareils
// - [ ] Tentative de clonage sur autre PC (doit échouer)
//
// ---
//
// ## 📖 Utilisation
//
// ### Scénario 1: Nouvelle Installation (Client)
//
// 1. Le client installe votre application Windows
// 2. Au premier lancement, il voit l'écran d'activation
// 3. Il peut:
// - **Option A**: Scanner le QR code avec vous (en personne/vidéo)
// - **Option B**: Cliquer sur "Demander par Email" et vous envoyer une demande
// 4. Vous générez le code PIN avec l'app Admin
// 5. Le client entre le PIN et active l'application
//
// ### Scénario 2: Génération de Licence (Admin)
//
// 1. Ouvrez l'app Admin sur Android
// 2. Entrez votre mot de passe administrateur
// 3. Scannez le QR Code du client
// 4. Choisissez le type de licence:
// - **DEMO**: Pour période d'essai (7, 15, 30, 60, 90 jours)
// - **LIFETIME**: Pour licence définitive
// 5. Appuyez sur "Générer le Code PIN"
// 6. Copiez le PIN (10 chiffres)
// 7. Envoyez-le au client par un canal sécurisé
//
// ### Scénario 3: Renouvellement de Licence Demo
//
// 1. Quand la licence Demo expire, l'app affiche un message
// 2. Le client revient sur l'écran d'activation
// 3. Générez une nouvelle licence (Demo ou Lifetime)
// 4. Le client entre le nouveau PIN
//
// ---
//
// ## 🏗️ Architecture
//
// ### Flux de Sécurité
//
// ```
// ┌─────────────────────┐
// │   App Windows       │
// │  (Client Final)     │
// └──────────┬──────────┘
// │
// │ 1. Génère QR Code
// │    (Device ID + Timestamp)
// ▼
// ┌─────────────────────┐
// │   QR Code           │
// │  Valide 1 heure     │
// └──────────┬──────────┘
// │
// │ 2. Scan avec caméra
// ▼
// ┌─────────────────────┐
// │   App Admin         │
// │  (Android)          │
// │                     │
// │  • Vérifie QR       │
// │  • Choisit licence  │
// │  • Génère PIN       │
// └──────────┬──────────┘
// │
// │ 3. PIN de 10 chiffres
// │    [Type][Durée][Hash][Checksum]
// ▼
// ┌─────────────────────┐
// │   Validation        │
// │                     │
// │  • Hash appareil    │
// │  • Checksum         │
// │  • Date expiration  │
// └──────────┬──────────┘
// │
// │ 4. Si valide
// ▼
// ┌─────────────────────┐
// │   Licence Active    │
// │                     │
// │  • Stockage local   │
// │  • Vérif. continue  │
// │  • Anti-clonage     │
// └─────────────────────┘
// ```
//
// ### Composants de Sécurité
//
// | Composant | Description | Fichier |
// |-----------|-------------|---------|
// | **Device Fingerprint** | Hash SHA-256 unique par PC | `license_service.dart` |
// | **PIN Generator** | Algorithme de génération | `admin_android_app.dart` |
// | **PIN Validator** | Vérification cryptographique | `license_activation_screen.dart` |
// | **License Storage** | SharedPreferences chiffré | `license_service.dart` |
// | **Periodic Check** | Vérification toutes les 5 min | `LicenseProtectedApp` |
// | **Admin Auth** | Hash SHA-256 du mot de passe | `AdminLoginScreen` |
//
// ---
//
// ## 🛡️ Sécurité
//
// ### Ce qui est protégé:
//
// ✅ **Clonage de licence**: Impossible, liée à l'appareil
// ✅ **Transfert de licence**: Bloqué automatiquement
// ✅ **Modification du PIN**: Checksum invalide
// ✅ **Génération de PIN aléatoire**: Hash appareil requis
// ✅ **Accès app Admin**: Protégé par mot de passe
// ✅ **QR Code replay**: Expiration après 1 heure
// ✅ **Licence expirée**: Détection automatique
//
// ### Ce qui N'est PAS protégé:
//
// ❌ **Décompilation totale**: Utilisez l'obfuscation
// ❌ **Analyse de mémoire RAM**: Limitée par Windows
// ❌ **Modification du système**: VM/Containers détectables
//
// ### Améliorer la sécurité:
//
// 1. **Obfuscation obligatoire**:
// ```bash
// flutter build windows --obfuscate --split-debug-info=symbols/
// ```
//
// 2. **Chiffrement additionnel**:
// ```dart
// // Utilisez flutter_secure_storage au lieu de shared_preferences
// final storage = FlutterSecureStorage();
// await storage.write(key: 'license', value: encrypted);
// ```
//
// 3. **Serveur de validation** (optionnel):
// ```dart
// // Vérifier périodiquement avec un serveur
// final response = await http.post('https://api.com/validate',
// body: {'pin': pin, 'device': deviceId});
// ```
//
// 4. **Anti-debugging**:
// ```dart
// // Détection de debugger
// if (Platform.isWindows) {
// bool debuggerPresent = await checkDebugger();
// if (debuggerPresent) exit(0);
// }
// ```
//
// ---
//
// ## ❓ FAQ
//
// ### Q: La licence peut-elle être transférée?
// **R**: Non. Chaque licence est cryptographiquement liée à un appareil spécifique via son empreinte digitale.
//
// ### Q: Que se passe-t-il si je change de PC?
// **R**: Vous devez générer une nouvelle licence pour le nouvel appareil. L'ancienne reste valide sur l'ancien PC.
//
// ### Q: Puis-je modifier le format du PIN?
// **R**: Oui, mais vous devez synchroniser les algorithmes de génération et validation dans les deux apps.
//
// ### Q: Le mot de passe admin est-il sécurisé?
// **R**: Oui, seul le hash SHA-256 est stocké. Le mot de passe en clair n'est jamais sauvegardé.
//
// ### Q: Combien de licences puis-je générer?
// **R**: Illimité. Chaque appareil reçoit une licence unique.
//
// ### Q: Que faire si un client perd sa licence?
// **R**: Régénérez simplement une nouvelle licence avec l'app Admin.
//
// ### Q: L'app fonctionne-t-elle hors ligne?
// **R**: Oui! Aucune connexion internet requise après activation.
//
// ### Q: Puis-je voir toutes les licences actives?
// **R**: Le système actuel ne stocke pas de base de données centrale. Pour cela, ajoutez un serveur backend.
//
// ### Q: La durée Demo peut-elle être modifiée après activation?
// **R**: Non. Pour changer, il faut générer une nouvelle licence.
//
// ### Q: Comment désactiver une licence?
// **R**: Actuellement impossible à distance. Ajoutez un serveur de révocation pour cette fonctionnalité.
//
// ---
//
// ## 🔄 Mises à Jour Futures
//
// Fonctionnalités prévues:
// - [ ] Serveur central de gestion de licences
// - [ ] Dashboard web admin
// - [ ] Révocation de licences à distance
// - [ ] Statistiques d'utilisation
// - [ ] Multi-utilisateurs avec rôles
// - [ ] Export/Import de licences
// - [ ] Notifications d'expiration
// - [ ] Renouvellement automatique
//
// ---
//
// ## 📞 Support
//
// Pour toute question ou problème:
// 1. Consultez la [documentation complète](#)
// 2. Vérifiez les [FAQ](#faq)
// 3. Contactez le support technique
//
// ---
//
// ## 📜 License
//
// © 2024 - Tous droits réservés.
//
// ---
//
// **Bon déploiement! 🚀**
// import 'dart:convert';
// import 'dart:io';
// import 'package:crypto/crypto.dart';
// import 'package:shared_preferences/shared_preferences.dart';
//
// /// Classe pour gérer la sécurité avancée de l'application
// ///
// /// Fonctionnalités:
// /// - Détection de VM/Émulateurs
// /// - Limitation des tentatives de validation
// /// - Détection de modifications système
// /// - Protection anti-tampering
// /// - Logs de sécurité
//
// class AdvancedSecurity {
//
// // ═══════════════════════════════════════════════════════════
// // 1. DÉTECTION DE VM / ÉMULATEURS
// // ═══════════════════════════════════════════════════════════
//
// /// Détecte si l'application tourne dans une VM ou émulateur
// static Future<bool> isRunningInVM() async {
// if (!Platform.isWindows) return false;
//
// try {
// // Vérifier les processus typiques de VM
// final vmProcesses = [
// 'VBoxService.exe',    // VirtualBox
// 'vmtoolsd.exe',       // VMware
// 'vmusrvc.exe',        // VMware
// 'qemu-ga.exe',        // QEMU
// ];
//
// for (var process in vmProcesses) {
// final result = await Process.run('tasklist', []);
// if (result.stdout.toString().contains(process)) {
// _logSecurityEvent('VM_DETECTED', 'Process: $process');
// return true;
// }
// }
//
// // Vérifier les clés de registre Windows typiques de VM
// final registryKeys = [
// r'HKLM\HARDWARE\DESCRIPTION\System\SystemBiosVersion',
// r'HKLM\HARDWARE\DESCRIPTION\System\VideoBiosVersion',
// ];
//
// for (var key in registryKeys) {
// try {
// final result = await Process.run('reg', ['query', key]);
// final output = result.stdout.toString().toLowerCase();
//
// if (output.contains('virtualbox') ||
// output.contains('vmware') ||
// output.contains('qemu') ||
// output.contains('virtual')) {
// _logSecurityEvent('VM_DETECTED', 'Registry: $key');
// return true;
// }
// } catch (e) {
// // Clé n'existe pas, continuer
// }
// }
//
// return false;
// } catch (e) {
// _logSecurityEvent('VM_CHECK_ERROR', e.toString());
// return false;
// }
// }
//
// // ═══════════════════════════════════════════════════════════
// // 2. LIMITATION DES TENTATIVES
// // ═══════════════════════════════════════════════════════════
//
// /// Limite le nombre de tentatives de validation de PIN
// static Future<bool> canAttemptValidation() async {
// final prefs = await SharedPreferences.getInstance();
//
// final attempts = prefs.getInt('validation_attempts') ?? 0;
// final lastAttemptTime = prefs.getInt('last_attempt_timestamp') ?? 0;
// final now = DateTime.now().millisecondsSinceEpoch;
//
// // Réinitialiser après 1 heure
// if (now - lastAttemptTime > 3600000) {
// await prefs.setInt('validation_attempts', 0);
// return true;
// }
//
// // Maximum 5 tentatives par heure
// if (attempts >= 5) {
// _logSecurityEvent('MAX_ATTEMPTS_REACHED', 'Attempts: $attempts');
// return false;
// }
//
// return true;
// }
//
// /// Enregistre une tentative de validation
// static Future<void> recordValidationAttempt({required bool success}) async {
// final prefs = await SharedPreferences.getInstance();
//
// final attempts = prefs.getInt('validation_attempts') ?? 0;
// await prefs.setInt('validation_attempts', attempts + 1);
// await prefs.setInt('last_attempt_timestamp', DateTime.now().millisecondsSinceEpoch);
//
// if (!success) {
// final failedAttempts = prefs.getInt('failed_attempts_total') ?? 0;
// await prefs.setInt('failed_attempts_total', failedAttempts + 1);
// _logSecurityEvent('VALIDATION_FAILED', 'Total failures: ${failedAttempts + 1}');
// } else {
// _logSecurityEvent('VALIDATION_SUCCESS', 'License activated');
// }
// }
//
// /// Obtient le nombre de tentatives restantes
// static Future<int> getRemainingAttempts() async {
// final prefs = await SharedPreferences.getInstance();
// final attempts = prefs.getInt('validation_attempts') ?? 0;
// return 5 - attempts;
// }
//
// // ═══════════════════════════════════════════════════════════
// // 3. DÉTECTION DE MODIFICATIONS SYSTÈME
// // ═══════════════════════════════════════════════════════════
//
// /// Vérifie si l'horloge système a été modifiée (pour contourner expiration)
// static Future<bool> detectTimeManipulation() async {
// final prefs = await SharedPreferences.getInstance();
//
// final lastKnownTime = prefs.getInt('last_known_timestamp') ?? 0;
// final currentTime = DateTime.now().millisecondsSinceEpoch;
//
// // Si l'heure actuelle est antérieure à la dernière heure connue
// if (currentTime < lastKnownTime) {
// _logSecurityEvent('TIME_MANIPULATION',
// 'Last: $lastKnownTime, Current: $currentTime');
// return true;
// }
//
// // Mettre à jour le dernier timestamp connu
// await prefs.setInt('last_known_timestamp', currentTime);
//
// return false;
// }
//
// /// Vérifie l'intégrité des fichiers critiques
// static Future<bool> verifyFileIntegrity() async {
// try {
// // Hash du fichier de licence
// final prefs = await SharedPreferences.getInstance();
// final licenseData = prefs.getString('license');
//
// if (licenseData == null) return true;
//
// final storedHash = prefs.getString('license_hash');
// final currentHash = _hashString(licenseData);
//
// if (storedHash != null && storedHash != currentHash) {
// _logSecurityEvent('FILE_TAMPERING', 'License file modified');
// return false;
// }
//
// // Sauvegarder le hash si pas encore fait
// if (storedHash == null) {
// await prefs.setString('license_hash', currentHash);
// }
//
// return true;
// } catch (e) {
// _logSecurityEvent('INTEGRITY_CHECK_ERROR', e.toString());
// return false;
// }
// }
//
// // ═══════════════════════════════════════════════════════════
// // 4. PROTECTION ANTI-TAMPERING
// // ═══════════════════════════════════════════════════════════
//
// /// Vérifie que l'application n'a pas été modifiée
// static Future<bool> checkAppIntegrity() async {
// try {
// // Vérifier la signature de l'exécutable (Windows)
// if (Platform.isWindows) {
// final exePath = Platform.resolvedExecutable;
//
// // Note: En production, vous devriez signer votre application
// // et vérifier la signature digitale ici
//
// final file = File(exePath);
// if (!await file.exists()) {
// _logSecurityEvent('APP_INTEGRITY_FAIL', 'Executable not found');
// return false;
// }
//
// // Vérifier la taille du fichier (doit être cohérente)
// final size = await file.length();
// final prefs = await SharedPreferences.getInstance();
// final expectedSize = prefs.getInt('expected_exe_size');
//
// if (expectedSize != null && size != expectedSize) {
// _logSecurityEvent('APP_INTEGRITY_FAIL',
// 'Size mismatch: expected $expectedSize, got $size');
// return false;
// }
//
// if (expectedSize == null) {
// await prefs.setInt('expected_exe_size', size);
// }
// }
//
// return true;
// } catch (e) {
// _logSecurityEvent('INTEGRITY_CHECK_ERROR', e.toString());
// return false;
// }
// }
//
// /// Détecte si l'application est debuggée
// static bool isDebugMode() {
// bool isDebug = false;
// assert(() {
// isDebug = true;
// return true;
// }());
// return isDebug;
// }
//
// // ═══════════════════════════════════════════════════════════
// // 5. LOGS DE SÉCURITÉ
// // ═══════════════════════════════════════════════════════════
//
// /// Log un événement de sécurité
// static void _logSecurityEvent(String event, String details) {
// final timestamp = DateTime.now().toIso8601String();
// final logEntry = '[$timestamp] SECURITY_$event: $details';
//
// // En production, envoyez ces logs à un serveur sécurisé
// print(logEntry);
//
// // Sauvegarder localement (optionnel)
// _saveSecurityLog(logEntry);
// }
//
// /// Sauvegarde les logs de sécurité localement
// static Future<void> _saveSecurityLog(String logEntry) async {
// try {
// final prefs = await SharedPreferences.getInstance();
// final logs = prefs.getStringList('security_logs') ?? [];
//
// logs.add(logEntry);
//
// // Garder seulement les 100 derniers logs
// if (logs.length > 100) {
// logs.removeRange(0, logs.length - 100);
// }
//
// await prefs.setStringList('security_logs', logs);
// } catch (e) {
// print('Error saving security log: $e');
// }
// }
//
// /// Récupère tous les logs de sécurité
// static Future<List<String>> getSecurityLogs() async {
// final prefs = await SharedPreferences.getInstance();
// return prefs.getStringList('security_logs') ?? [];
// }
//
// /// Efface les logs de sécurité
// static Future<void> clearSecurityLogs() async {
// final prefs = await SharedPreferences.getInstance();
// await prefs.remove('security_logs');
// }
//
// // ═══════════════════════════════════════════════════════════
// // 6. VÉRIFICATION COMPLÈTE
// // ═══════════════════════════════════════════════════════════
//
// /// Effectue toutes les vérifications de sécurité
// static Future<SecurityCheckResult> performFullSecurityCheck() async {
// final results = <String, bool>{};
// final messages = <String>[];
//
// // 1. Vérifier VM
// final isVM = await isRunningInVM();
// results['vm_check'] = !isVM;
// if (isVM) {
// messages.add('Application détectée dans une machine virtuelle');
// }
//
// // 2. Vérifier manipulation du temps
// final timeManipulated = await detectTimeManipulation();
// results['time_check'] = !timeManipulated;
// if (timeManipulated) {
// messages.add('Manipulation de l\'horloge système détectée');
// }
//
// // 3. Vérifier intégrité des fichiers
// final fileIntegrity = await verifyFileIntegrity();
// results['file_integrity'] = fileIntegrity;
// if (!fileIntegrity) {
// messages.add('Fichiers de licence modifiés');
// }
//
// // 4. Vérifier intégrité de l\'application
// final appIntegrity = await checkAppIntegrity();
// results['app_integrity'] = appIntegrity;
// if (!appIntegrity) {
// messages.add('Application modifiée ou corrompue');
// }
//
// // 5. Vérifier mode debug
// final debugMode = isDebugMode();
// results['debug_check'] = !debugMode;
// if (debugMode) {
// messages.add('Application en mode debug');
// }
//
// // 6. Vérifier tentatives
// final canAttempt = await canAttemptValidation();
// results['attempts_check'] = canAttempt;
// if (!canAttempt) {
// messages.add('Trop de tentatives de validation');
// }
//
// final allPassed = results.values.every((passed) => passed);
//
// if (!allPassed) {
// _logSecurityEvent('SECURITY_CHECK_FAILED', messages.join('; '));
// }
//
// return SecurityCheckResult(
// passed: allPassed,
// checks: results,
// messages: messages,
// );
// }
//
// // ═══════════════════════════════════════════════════════════
// // UTILITAIRES
// // ═══════════════════════════════════════════════════════════
//
// static String _hashString(String input) {
// final bytes = utf8.encode(input);
// final digest = sha256.convert(bytes);
// return digest.toString();
// }
// }
//
// /// Résultat d'une vérification de sécurité complète
// class SecurityCheckResult {
// final bool passed;
// final Map<String, bool> checks;
// final List<String> messages;
//
// SecurityCheckResult({
// required this.passed,
// required this.checks,
// required this.messages,
// });
//
// @override
// String toString() {
// return 'SecurityCheckResult(passed: $passed, checks: $checks, messages: $messages)';
// }
// }
//
// // ═══════════════════════════════════════════════════════════
// // EXEMPLE D'UTILISATION DANS VOTRE APPLICATION
// // ═══════════════════════════════════════════════════════════
//
// /*
//
// INTÉGRATION DANS license_activation_screen.dart:
//
// Future<void> _validateLicense() async {
//   setState(() => isValidating = true);
//
//   try {
//     // 1. Vérifier les tentatives
//     final canAttempt = await AdvancedSecurity.canAttemptValidation();
//     if (!canAttempt) {
//       final remaining = await AdvancedSecurity.getRemainingAttempts();
//       _showError('Trop de tentatives. Réessayez dans 1 heure.');
//       setState(() => isValidating = false);
//       return;
//     }
//
//     // 2. Effectuer les vérifications de sécurité
//     final securityCheck = await AdvancedSecurity.performFullSecurityCheck();
//     if (!securityCheck.passed) {
//       _showError('Vérification de sécurité échouée: ${securityCheck.messages.join(", ")}');
//       await AdvancedSecurity.recordValidationAttempt(success: false);
//       setState(() => isValidating = false);
//       return;
//     }
//
//     // 3. Récupérer le code PIN entré
//     final pin = pinControllers.map((c) => c.text).join('');
//
//     if (pin.length != 10) {
//       _showError('Le code PIN doit contenir 10 chiffres');
//       setState(() => isValidating = false);
//       return;
//     }
//
//     // 4. Vérifier le code PIN
//     final isValid = await _verifyLicensePin(pin);
//
//     if (isValid) {
//       // 5. Sauvegarder la licence
//       await _saveLicense(pin);
//
//       // 6. Enregistrer la tentative réussie
//       await AdvancedSecurity.recordValidationAttempt(success: true);
//
//       if (mounted) {
//         Navigator.of(context).pushReplacement(
//           MaterialPageRoute(builder: (_) => const MainAppScreen()),
//         );
//       }
//     } else {
//       _showError('Code PIN invalide');
//       await AdvancedSecurity.recordValidationAttempt(success: false);
//     }
//   } catch (e) {
//     _showError('Erreur lors de la validation: $e');
//     await AdvancedSecurity.recordValidationAttempt(success: false);
//   } finally {
//     setState(() => isValidating = false);
//   }
// }
//
// ─────────────────────────────────────────────────────────────
//
// INTÉGRATION DANS license_service.dart:
//
// static Future<LicenseStatus> checkLicense() async {
//   try {
//     // 1. Vérifications de sécurité avancées
//     final securityCheck = await AdvancedSecurity.performFullSecurityCheck();
//     if (!securityCheck.passed) {
//       return LicenseStatus(
