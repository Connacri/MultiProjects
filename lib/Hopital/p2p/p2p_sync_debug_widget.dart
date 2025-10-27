import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objectBox/classeObjectBox.dart';
import '../StaffProvider.dart';

/// Widget de debug pour diagnostiquer les problèmes de synchronisation
class P2PSyncDebugWidget extends StatefulWidget {
  @override
  State<P2PSyncDebugWidget> createState() => _P2PSyncDebugWidgetState();
}

class _P2PSyncDebugWidgetState extends State<P2PSyncDebugWidget> {
  int _localRebuildCount = 0;

  @override
  Widget build(BuildContext context) {
    _localRebuildCount++;

    return Consumer<StaffProvider>(
      builder: (context, provider, _) {
        print(
            '[Debug] 🔍 Widget rebuild #$_localRebuildCount - ${provider.staffs.length} staffs');

        return Container(
          padding: EdgeInsets.all(8),
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade700),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.bug_report,
                      size: 16, color: Colors.amber.shade900),
                  SizedBox(width: 8),
                  Text(
                    'DEBUG P2P SYNC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              _buildDebugRow('Widget Rebuilds:', _localRebuildCount.toString()),
              _buildDebugRow(
                  'Provider Staffs:', provider.staffs.length.toString()),
              _buildDebugRow(
                  'Remote Changes:', provider.remoteChangesReceived.toString()),
              _buildDebugRow('Last Update:',
                  _formatTimestamp(provider.lastUpdateTimestamp)),
              _buildDebugRow('Is Loading:', provider.isLoading.toString()),
              SizedBox(height: 8),
              Row(
                children: [
                  ElevatedButton.icon(
                    icon: Icon(Icons.refresh, size: 14),
                    label: Text('Force Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () async {
                      print('[Debug] 🔄 Force refresh déclenché manuellement');
                      await provider.forceRefresh();
                      setState(() {});
                    },
                  ),
                  SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(Icons.data_object, size: 14),
                    label: Text('Check ObjectBox'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: () {
                      _checkObjectBoxDirectly(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDebugRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label ',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp == 0) return 'Never';
    final now = DateTime.now().millisecondsSinceEpoch;
    final diff = now - timestamp;
    if (diff < 1000) return 'Now';
    if (diff < 60000) return '${(diff / 1000).round()}s ago';
    return '${(diff / 60000).round()}m ago';
  }

  void _checkObjectBoxDirectly(BuildContext context) {
    final objectBox = ObjectBox();
    final directCount = objectBox.staffBox.count();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.data_object, color: Colors.blue),
            SizedBox(width: 8),
            Text('ObjectBox Direct Check'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Direct ObjectBox count: $directCount'),
            SizedBox(height: 8),
            Text(
                'Provider staffs count: ${Provider.of<StaffProvider>(context, listen: false).staffs.length}'),
            SizedBox(height: 8),
            Text(
              directCount ==
                      Provider.of<StaffProvider>(context, listen: false)
                          .staffs
                          .length
                  ? '✅ Counts match'
                  : '❌ MISMATCH DETECTED!',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: directCount ==
                        Provider.of<StaffProvider>(context, listen: false)
                            .staffs
                            .length
                    ? Colors.green
                    : Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () async {
              await Provider.of<StaffProvider>(context, listen: false)
                  .forceRefresh();
              Navigator.of(ctx).pop();
            },
            child: Text('Force Sync'),
          ),
        ],
      ),
    );
  }
}
