// CorrectionGroupsButton.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'StaffProvider.dart';

class CorrectionGroupsButton extends StatelessWidget {
  const CorrectionGroupsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🔧 Correction des Groupes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 12),
            Text('Corrections à appliquer:'),
            SizedBox(height: 8),
            Text('• 🏥 Paramédical: "Garde 12H" → "Garde 24H"'),
            Text('• 🧹 Agents d\'hygiène: "08h-12h" → "12h"'),
            SizedBox(height: 16),
            _CorrectionButton(),
          ],
        ),
      ),
    );
  }
}

class _CorrectionButton extends StatefulWidget {
  @override
  __CorrectionButtonState createState() => __CorrectionButtonState();
}

class __CorrectionButtonState extends State<_CorrectionButton> {
  bool _isLoading = false;
  Map<String, dynamic>? _currentStats;
  Map<String, int>? _lastResults;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    final provider = Provider.of<StaffProvider>(context, listen: false);
    setState(() {
      _currentStats = provider.getGroupCorrectionStats();
    });
  }

  Future<void> _correctGroups() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final provider = Provider.of<StaffProvider>(context, listen: false);
      final results = await provider.correctStaffGroups();

      setState(() {
        _lastResults = results;
        _currentStats = provider.getGroupCorrectionStats();
      });

      _showResultsDialog(results);
    } catch (e) {
      _showErrorDialog('Erreur lors de la correction: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showResultsDialog(Map<String, int> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('✅ Correction Terminée'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('La correction a été effectuée avec succès!'),
            SizedBox(height: 16),
            Text('📊 Résultats:'),
            SizedBox(height: 8),
            Text('• 🏥 Paramédical modifié: ${results['paramedicalModified']}'),
            Text('• 🧹 Hygiène modifié: ${results['hygieneModified']}'),
            Text('• 📝 Total modifications: ${results['totalModified']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Statistiques actuelles
        if (_currentStats != null) ...[
          Card(
            color: Colors.grey[100],
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📈 Situation actuelle:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                      '🏥 Paramédical "Garde 12H": ${_currentStats!['paramedical12H']}/${_currentStats!['totalParamadical']}'),
                  Text(
                      '🧹 Hygiène "08h-12h": ${_currentStats!['hygiene8H12H']}/${_currentStats!['totalHygiene']}'),
                ],
              ),
            ),
          ),
          SizedBox(height: 12),
        ],

        // Bouton de correction
        _isLoading
            ? CircularProgressIndicator()
            : ElevatedButton.icon(
                onPressed: _correctGroups,
                icon: Icon(Icons.auto_fix_high),
                label: Text(
                  'CORRIGER LES GROUPES',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),

        // Résultats précédents
        if (_lastResults != null) ...[
          SizedBox(height: 16),
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '📋 Dernière correction:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Modifications: ${_lastResults!['totalModified']}'),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
