import 'package:flutter/material.dart';

import '../../objectBox/classeObjectBox.dart';

class SimpleP2PTest extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final objectBox = ObjectBox();
    final staffList = objectBox.staffBox.getAll();
    final branchList = objectBox.branchBox.getAll();

    return Scaffold(
      appBar: AppBar(title: Text('Test P2P Simple')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📊 STATS:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Staff: ${staffList.length}'),
              Text('Branches: ${branchList.length}'),
              SizedBox(height: 20),
              Text('👥 STAFF (premiers 10):',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...staffList.take(10).map((staff) => ListTile(
                    title: Text(staff.nom),
                    subtitle: Text(
                        'ID: ${staff.id} - Branch: ${staff.branch.targetId}'),
                  )),
              SizedBox(height: 20),
              Text('🏢 BRANCHES:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ...branchList.map((branch) => ListTile(
                    title: Text(branch.branchNom),
                    subtitle: Text('ID: ${branch.id}'),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
