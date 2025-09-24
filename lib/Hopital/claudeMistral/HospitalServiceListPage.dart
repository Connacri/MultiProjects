import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'HospitalServiceFormPage.dart';
import 'Providers.dart';

class HospitalServiceListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final hospitalServiceProvider =
        Provider.of<HospitalServiceProvider>(context);
    final hospitalServices = hospitalServiceProvider.hospitalServices;

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Services Hospitaliers'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => HospitalServiceFormPage())),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: hospitalServices.length,
        itemBuilder: (context, index) {
          final hospitalService = hospitalServices[index];
          return Card(
            child: ListTile(
              title: Text(hospitalService.name),
              subtitle: Text('Code: ${hospitalService.serviceCode}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HospitalServiceFormPage(
                            hospitalService: hospitalService, index: index),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        hospitalServiceProvider.removeHospitalService(index),
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
