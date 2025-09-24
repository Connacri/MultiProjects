import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'MonthlyPlanningFormPage.dart';
import 'Providers.dart';

class MonthlyPlanningListPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final monthlyPlanningProvider =
        Provider.of<MonthlyPlanningProvider>(context);
    final monthlyPlannings = monthlyPlanningProvider.monthlyPlannings;

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Plannings Mensuels'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => MonthlyPlanningFormPage())),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: monthlyPlannings.length,
        itemBuilder: (context, index) {
          final monthlyPlanning = monthlyPlannings[index];
          return Card(
            child: ListTile(
              title:
                  Text('${monthlyPlanning.monthName} ${monthlyPlanning.year}'),
              subtitle: Text('Service: ${monthlyPlanning.service}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MonthlyPlanningFormPage(
                            monthlyPlanning: monthlyPlanning, index: index),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () =>
                        monthlyPlanningProvider.removeMonthlyPlanning(index),
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
