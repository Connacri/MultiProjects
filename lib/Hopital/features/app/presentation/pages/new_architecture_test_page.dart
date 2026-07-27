import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../planning/presentation/providers/planning_provider.dart';
import '../../../planning/presentation/providers/rotation_configuration_provider.dart';
import '../../../planning/presentation/widgets/planning_workspace.dart';

/// Explicit entry point used to validate the new Planning architecture before
/// replacing the legacy application shell.
class NewArchitectureTestPage extends StatelessWidget {
  const NewArchitectureTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    final planningProvider = context.read<PlanningProvider>();
    final rotationProvider = context.read<RotationConfigurationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle architecture'),
      ),
      body: PlanningWorkspace(
        planningProvider: planningProvider,
        rotationProvider: rotationProvider,
      ),
    );
  }
}
