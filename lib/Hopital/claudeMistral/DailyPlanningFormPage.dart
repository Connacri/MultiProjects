import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objectBox/Entity.dart';
import 'Providers.dart';

class DailyPlanningFormPage extends StatefulWidget {
  final DailyPlanning? dailyPlanning;
  final int? index;

  DailyPlanningFormPage({this.dailyPlanning, this.index});

  @override
  _DailyPlanningFormPageState createState() => _DailyPlanningFormPageState();
}

class _DailyPlanningFormPageState extends State<DailyPlanningFormPage> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _dayDate;
  late int _activityType;
  late int _staffId;
  List<Staff> _staffs = [];

  @override
  void initState() {
    super.initState();
    // Initialize staff list (you might want to get this from a provider)
    // This is just a placeholder - replace with actual staff data
    _staffs = []; // You should populate this with actual staff data

    if (widget.dailyPlanning != null) {
      _dayDate = widget.dailyPlanning!.dayDate;
      _activityType = widget.dailyPlanning!.activityType;
      _staffId = widget.dailyPlanning!.staff.target?.id ?? 0;
    } else {
      _dayDate = DateTime.now();
      _activityType = 0;
      _staffId = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.dailyPlanning == null
            ? 'Ajouter un Planning Quotidien'
            : 'Modifier un Planning Quotidien'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Date'),
                initialValue:
                    '${_dayDate.day}/${_dayDate.month}/${_dayDate.year}',
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dayDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) {
                    setState(() => _dayDate = date);
                  }
                },
                readOnly: true,
              ),
              DropdownButtonFormField<int>(
                value: _staffId,
                items: _staffs.map((staff) {
                  return DropdownMenuItem<int>(
                    value: staff.id,
                    child: Text('${staff.lastName} ${staff.firstName}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _staffId = value!),
                decoration: InputDecoration(labelText: 'Staff'),
              ),
              DropdownButtonFormField<int>(
                value: _activityType,
                items: ActivityType.values.map((activityType) {
                  return DropdownMenuItem<int>(
                    value: activityType.index,
                    child: Text(activityType.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _activityType = value!),
                decoration: InputDecoration(labelText: 'Type d\'activité'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final dailyPlanningProvider =
                        Provider.of<DailyPlanningProvider>(context,
                            listen: false);

                    final dailyPlanning = DailyPlanning()
                      ..dayDate = _dayDate
                      ..dayOfMonth = _dayDate.day
                      ..activityType = _activityType
                      ..status = widget.dailyPlanning?.status ?? 0;

                    // Set the staff relationship
                    final selectedStaff = _staffs.firstWhere(
                      (staff) => staff.id == _staffId,
                      orElse: () => Staff()..id = _staffId,
                    );
                    dailyPlanning.staff.target = selectedStaff;

                    if (widget.dailyPlanning == null) {
                      dailyPlanningProvider.addDailyPlanning(dailyPlanning);
                    } else {
                      dailyPlanning.id = widget.dailyPlanning!.id;
                      dailyPlanningProvider.updateDailyPlanning(dailyPlanning);
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
