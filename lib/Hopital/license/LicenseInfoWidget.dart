import 'package:flutter/material.dart';

import 'LicenseService.dart';

class LicenseInfoWidget extends StatefulWidget {
  const LicenseInfoWidget({Key? key}) : super(key: key);

  @override
  State<LicenseInfoWidget> createState() => _LicenseInfoWidgetState();
}

class _LicenseInfoWidgetState extends State<LicenseInfoWidget> {
  LicenseStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await LicenseService.checkLicense();
    setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    if (_status == null) {
      return const CircularProgressIndicator();
    }

    Color statusColor = _status!.isValid ? Colors.green : Colors.red;
    IconData statusIcon = _status!.isValid ? Icons.check_circle : Icons.error;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor),
                const SizedBox(width: 8),
                Text(
                  'Statut de la Licence',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Type', _getLicenseTypeLabel(_status!.type)),
            _buildInfoRow('Statut', _status!.message),
            if (_status!.expiryDate != null)
              _buildInfoRow(
                'Expiration',
                _status!.expiryDate!.toString().substring(0, 10),
              ),
            if (_status!.daysRemaining != null)
              _buildInfoRow(
                'Jours restants',
                _status!.daysRemaining.toString(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(value),
        ],
      ),
    );
  }

  String _getLicenseTypeLabel(LicenseType type) {
    switch (type) {
      case LicenseType.demo:
        return 'DEMO';
      case LicenseType.lifetime:
        return 'LIFETIME';
      case LicenseType.expired:
        return 'EXPIRÉE';
      case LicenseType.none:
        return 'AUCUNE';
    }
  }
}
