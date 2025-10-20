// import 'dart:async';
// import 'dart:io';
//
// import 'package:connectivity_plus/connectivity_plus.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:provider/provider.dart';
//
// import 'connection_manager_fixed.dart';
// import 'p2p_integration_fixed.dart';
// import 'p2p_manager_fixed.dart';
// import 'sync_manager_complete.dart';
//
//
// /// Configure les permissions réseau nécessaires
// Future<void> _setupNetworkPermissions() async {
//   try {
//     print('[Main] Vérification des permissions réseau...');
//
//     if (Platform.isAndroid) {
//       // Android: demander les permissions à l'exécution
//       final statuses = await [
//         Permission.location, // Remplace accessNetworkState
//         Permission.nearbyWifiDevices,
//       ].request();
//
//       bool allGranted = statuses.values.every((status) => status.isGranted);
//
//       if (!allGranted) {
//         print('[Main] ⚠️ Certaines permissions refusées sur Android');
//       } else {
//         print('[Main] ✅ Permissions Android accordées');
//       }
//     } else if (Platform.isIOS) {
//       // iOS: demander l'accès réseau local
//       final status = await Permission.nearbyWifiDevices.request();
//
//       if (status.isDenied) {
//         print('[Main] ⚠️ Permission réseau local refusée sur iOS');
//       } else if (status.isPermanentlyDenied) {
//         print('[Main] ⚠️ Permission réseau local définitivement refusée');
//         await openAppSettings();
//       } else {
//         print('[Main] ✅ Permissions iOS accordées');
//       }
//     }
//
//     // Vérifier la connectivité
//     final connectivity = await Connectivity().checkConnectivity();
//     if (connectivity == ConnectivityResult.none) {
//       print('[Main] ⚠️ Aucune connexion réseau disponible');
//     } else {
//       print('[Main] ✅ Connectivité réseau OK: $connectivity');
//     }
//   } catch (e) {
//     print('[Main] ❌ Erreur configuration permissions: $e');
//   }
// }
//
// /// Initialise le système P2P complet
// Future<void> _initializeP2P() async {
//   try {
//     print('[Main] =========== Initialisation P2P ===========');
//
//     final p2pIntegration = P2PIntegration();
//
//     // Initialiser P2P avec timeout global
//     await p2pIntegration.initializeP2PSystem().timeout(
//       const Duration(seconds: 30),
//       onTimeout: () {
//         throw TimeoutException('Initialisation P2P timeout après 30 secondes');
//       },
//     );
//
//     print('[Main] ✅ P2P System initialisé avec succès');
//     final stats = p2pIntegration.getNetworkStats();
//     print('[Main] Node ID: ${stats['nodeId']}');
//     print('[Main] Port serveur: ${stats['serverPort']}');
//     print('[Main] ========================================');
//   } catch (e) {
//     print('[Main] ❌ Erreur initialisation P2P: $e');
//     print('[Main] Mode dégradé activé - fonctionnalité réduite');
//   }
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({Key? key}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider<P2PManager>(
//           create: (_) => P2PManager(),
//         ),
//         ChangeNotifierProvider<ConnectionManager>(
//           create: (_) => ConnectionManager(),
//         ),
//         ChangeNotifierProvider<SyncManager>(
//           create: (_) => SyncManager(),
//         ),
//         ChangeNotifierProvider<P2PIntegration>(
//           create: (_) => P2PIntegration(),
//         ),
//       ],
//       child: MaterialApp(
//         title: 'Hôpital P2P',
//         theme: ThemeData(
//           primarySwatch: Colors.blue,
//           useMaterial3: true,
//         ),
//         home: const StartupScreen(
//           child: HomeScreen(),
//         ),
//       ),
//     );
//   }
// }
//
// /// Écran de démarrage avec progression
// class StartupScreen extends StatefulWidget {
//   final Widget child;
//
//   const StartupScreen({
//     Key? key,
//     required this.child,
//   }) : super(key: key);
//
//   @override
//   State<StartupScreen> createState() => _StartupScreenState();
// }
//
// class _StartupScreenState extends State<StartupScreen> {
//   bool _showStartup = true;
//   String _currentStep = 'Initialisation...';
//   double _progress = 0.0;
//
//   @override
//   void initState() {
//     super.initState();
//     _checkP2PStatus();
//   }
//
//   Future<void> _checkP2PStatus() async {
//     for (int i = 0; i < 150; i++) {
//       await Future.delayed(const Duration(milliseconds: 100));
//
//       if (!mounted) return;
//
//       final p2pIntegration = context.read<P2PIntegration>();
//
//       setState(() {
//         _progress = i / 150.0;
//         _currentStep = p2pIntegration.initializationStatus;
//       });
//
//       if (p2pIntegration.isInitialized) {
//         setState(() {
//           _currentStep = 'P2P Opérationnel ✅';
//           _progress = 1.0;
//         });
//
//         await Future.delayed(const Duration(milliseconds: 500));
//         if (mounted) {
//           setState(() => _showStartup = false);
//         }
//         return;
//       }
//     }
//
//     print('[StartupScreen] Timeout init, mode dégradé');
//     if (mounted) {
//       setState(() => _showStartup = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (!_showStartup) {
//       return widget.child;
//     }
//
//     return Scaffold(
//       body: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [
//               Colors.blue[700]!,
//               Colors.blue[900]!,
//             ],
//           ),
//         ),
//         child: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(
//                 Icons.local_hospital,
//                 size: 80,
//                 color: Colors.white,
//               ),
//               const SizedBox(height: 32),
//               Text(
//                 'Hôpital P2P',
//                 style: Theme.of(context).textTheme.headlineMedium?.copyWith(
//                       color: Colors.white,
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 48),
//               Container(
//                 width: 250,
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   children: [
//                     LinearProgressIndicator(
//                       value: _progress,
//                       backgroundColor: Colors.white24,
//                       valueColor: const AlwaysStoppedAnimation(Colors.white),
//                       minHeight: 6,
//                     ),
//                     const SizedBox(height: 16),
//                     Text(
//                       _currentStep,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(
//                         color: Colors.white70,
//                         fontSize: 14,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// /// Écran d'accueil principal
// class HomeScreen extends StatefulWidget {
//   const HomeScreen({Key? key}) : super(key: key);
//
//   @override
//   State<HomeScreen> createState() => _HomeScreenState();
// }
//
// class _HomeScreenState extends State<HomeScreen> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Hôpital P2P'),
//         backgroundColor: Colors.blue[800],
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildStatusCard(context),
//             const SizedBox(height: 24),
//             _buildInfoCard(context),
//             const SizedBox(height: 24),
//             _buildActionsCard(context),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildStatusCard(BuildContext context) {
//     return Consumer<P2PIntegration>(
//       builder: (context, p2p, _) {
//         final stats = p2p.getNetworkStats();
//         final isRunning = stats['isServerRunning'] as bool? ?? false;
//         final neighborCount = stats['connectedNeighbors'] as int? ?? 0;
//
//         return Card(
//           elevation: 4,
//           color: isRunning ? Colors.green[50] : Colors.orange[50],
//           child: Padding(
//             padding: const EdgeInsets.all(16),
//             child: Row(
//               children: [
//                 Icon(
//                   isRunning ? Icons.check_circle : Icons.info,
//                   color: isRunning ? Colors.green : Colors.orange,
//                   size: 32,
//                 ),
//                 const SizedBox(width: 16),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         isRunning ? 'Système Actif' : 'Initialisation',
//                         style: Theme.of(context).textTheme.titleMedium,
//                       ),
//                       Text(
//                         '$neighborCount voisin(s) connecté(s)',
//                         style: Theme.of(context).textTheme.bodySmall,
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   Widget _buildInfoCard(BuildContext context) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Informations P2P',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const Divider(),
//             Consumer<P2PIntegration>(
//               builder: (context, p2p, _) {
//                 final stats = p2p.getNetworkStats();
//                 return Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildInfoRow(
//                       'Status',
//                       p2p.isInitialized ? '✅ Actif' : '⚠️ Init...',
//                     ),
//                     _buildInfoRow(
//                       'Node ID',
//                       '${stats['nodeId']?.toString().substring(0, 20)}...',
//                     ),
//                     _buildInfoRow(
//                       'Serveur',
//                       '${stats['isServerRunning'] == true ? '✅' : '❌'} Port ${stats['serverPort']}',
//                     ),
//                     _buildInfoRow(
//                       'Voisins',
//                       '${stats['connectedNeighbors'] ?? 0}',
//                     ),
//                     _buildInfoRow(
//                       'Découverts',
//                       '${stats['discoveredNodes'] ?? 0}',
//                     ),
//                     _buildInfoRow(
//                       'Syncs réussies',
//                       '${stats['successfulSyncs'] ?? 0}',
//                     ),
//                     _buildInfoRow(
//                       'Syncs échouées',
//                       '${stats['failedSyncs'] ?? 0}',
//                     ),
//                   ],
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildActionsCard(BuildContext context) {
//     return Card(
//       elevation: 4,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Actions',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const Divider(),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton.icon(
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Redémarrer P2P'),
//                 onPressed: () async {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     const SnackBar(content: Text('Redémarrage en cours...')),
//                   );
//                   try {
//                     final p2p = context.read<P2PIntegration>();
//                     await p2p.restart();
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('P2P redémarré avec succès'),
//                           backgroundColor: Colors.green,
//                         ),
//                       );
//                     }
//                   } catch (e) {
//                     if (mounted) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                           content: Text('Erreur: $e'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                     }
//                   }
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontWeight: FontWeight.w500),
//           ),
//           Flexible(
//             child: Text(
//               value,
//               style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
