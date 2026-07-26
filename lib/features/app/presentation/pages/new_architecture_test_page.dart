import 'package:flutter/material.dart';

import '../../../planning/presentation/widgets/planning_workspace.dart';

/// Explicit entry point used to validate the new Planning architecture before
/// replacing the legacy application shell.
class NewArchitectureTestPage extends StatelessWidget {
  const NewArchitectureTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle architecture'),
      ),
      body: const PlanningWorkspace(),
    );
  }
}
