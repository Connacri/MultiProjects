import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objectBox/Entity.dart';
import 'Providers.dart';

class MonthlyPlanningFormPage extends StatefulWidget {
  final MonthlyPlanning? monthlyPlanning;
  final int? index;

  MonthlyPlanningFormPage({this.monthlyPlanning, this.index});

  @override
  _MonthlyPlanningFormPageState createState() =>
      _MonthlyPlanningFormPageState();
}

class _MonthlyPlanningFormPageState extends State<MonthlyPlanningFormPage> {
  final _formKey = GlobalKey<FormState>();
  late int _month;
  late int _year;
  late String _service;
  late String _department;

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
  void initState() {
    super.initState();
    if (widget.monthlyPlanning != null) {
      _month = widget.monthlyPlanning!.month;
      _year = widget.monthlyPlanning!.year;
      _service = widget.monthlyPlanning!.service;
      _department = widget.monthlyPlanning!.department;
    } else {
      _month = DateTime.now().month;
      _year = DateTime.now().year;
      _service = '';
      _department = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.monthlyPlanning == null
            ? 'Ajouter un Planning Mensuel'
            : 'Modifier un Planning Mensuel'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<int>(
                value: _month,
                items: List.generate(12, (index) => index + 1).map((month) {
                  return DropdownMenuItem<int>(
                    value: month,
                    child: Text(_monthNames[month - 1]),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _month = value!),
                decoration: InputDecoration(labelText: 'Mois'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Année'),
                initialValue: _year.toString(),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _year = int.tryParse(value) ?? _year;
                  }
                },
                validator: (value) {
                  if (value!.isEmpty) return 'Veuillez entrer une année';
                  if (int.tryParse(value) == null)
                    return 'Veuillez entrer un nombre valide';
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Service'),
                initialValue: _service,
                onSaved: (value) => _service = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un service' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Département'),
                initialValue: _department,
                onSaved: (value) => _department = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un département' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final monthlyPlanningProvider =
                        Provider.of<MonthlyPlanningProvider>(context,
                            listen: false);

                    // Create or update the monthly planning
                    final monthlyPlanning = MonthlyPlanning()
                      ..month = _month
                      ..year = _year
                      ..service = _service
                      ..department = _department
                      // Set other required fields with default values
                      ..planningType = widget.monthlyPlanning?.planningType ?? 0
                      ..status = widget.monthlyPlanning?.status ?? 0;

                    if (widget.monthlyPlanning == null) {
                      monthlyPlanningProvider
                          .addMonthlyPlanning(monthlyPlanning);
                    } else {
                      monthlyPlanning.id = widget.monthlyPlanning!.id;
                      monthlyPlanningProvider.updateMonthlyPlanning(
                          widget.index!, monthlyPlanning);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text('Enregistrer'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
