import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objectBox/Entity.dart';
import 'DailyPlanningFormPage.dart';
import 'Providers.dart';

class DailyPlanningListPage extends StatelessWidget {
  // Copy of month names from MonthlyPlanning class
  final List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  Widget build(BuildContext context) {
    final dailyPlanningProvider = Provider.of<DailyPlanningProvider>(context);
    final dailyPlannings = dailyPlanningProvider.getAllDailyPlannings();

    return Scaffold(
      appBar: AppBar(
        title: Text('Liste des Plannings Quotidiens'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DailyPlanningFormPage()),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: dailyPlannings.length,
        itemBuilder: (context, index) {
          final dailyPlanning = dailyPlannings[index];
          return Card(
            child: ListTile(
              title: Text(
                  '${dailyPlanning.dayOfMonth} ${_monthNames[dailyPlanning.dayDate.month - 1]} ${dailyPlanning.dayDate.year}'),
              subtitle: Text(
                  'Activité: ${ActivityType.values[dailyPlanning.activityType].displayName}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(Icons.edit),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DailyPlanningFormPage(
                            dailyPlanning: dailyPlanning, index: index),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () => dailyPlanningProvider
                        .deleteDailyPlanning(dailyPlanning.id),
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
