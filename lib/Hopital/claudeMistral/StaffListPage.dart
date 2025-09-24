import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'Providers.dart';
import 'StaffFormPage.dart';

class StaffListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final staffProvider = Provider.of<StaffProvider>(context);
    final staffs = staffProvider.staffs;

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Staffs'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => StaffFormPage())),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: staffs.length,
        itemBuilder: (context, index) {
          final staff = staffs[index];
          return Card(
            child: ListTile(
              title: Text('${staff.firstName} ${staff.lastName}'),
              subtitle: Text('${staff.function}: ${staff.grade}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            StaffFormPage(staff: staff, index: index),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => staffProvider.removeStaff(index),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
