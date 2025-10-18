import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'p2p_integration_fixed.dart';

/// Écran de démarrage affichant la progression P2P
class StartupScreen extends StatefulWidget {
  final Widget child;

  const StartupScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _showStartup = true;
  String _currentStep = 'Initialisation...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _checkP2PStatus();
  }

  Future<void> _checkP2PStatus() async {
    // Attendre max 30 secondes pour l'initialisation
    for (int i = 0; i < 300; i++) {
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      final p2pIntegration = context.read<P2PIntegration>();

      setState(() {
        _progress = i / 300.0;
        _currentStep = p2pIntegration.initializationStatus;
      });

      // Vérifier si P2P est prêt
      if (p2pIntegration.isInitialized) {
        setState(() {
          _currentStep = 'P2P Opérationnel ✅';
          _progress = 1.0;
        });

        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          setState(() => _showStartup = false);
        }
        return;
      }
    }

    // Timeout : afficher quand même l'app en mode dégradé
    print('[StartupScreen] Timeout init - mode dégradé');
    if (mounted) {
      setState(() => _showStartup = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showStartup) {
      return widget.child;
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[700]!,
              Colors.blue[900]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.local_hospital,
                size: 80,
                color: Colors.white,
              ),
              const SizedBox(height: 32),
              Text(
                'Hôpital P2P',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 48),
              Container(
                width: 250,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white24,
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentStep,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
