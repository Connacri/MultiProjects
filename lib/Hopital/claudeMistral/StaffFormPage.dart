import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objectBox/Entity.dart';
import 'Providers.dart';

class StaffFormPage extends StatefulWidget {
  final Staff? staff;
  final int? index;

  StaffFormPage({this.staff, this.index});

  @override
  _StaffFormPageState createState() => _StaffFormPageState();
}

class _StaffFormPageState extends State<StaffFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _firstName;
  late String _lastName;
  late String _staffNumber;
  late int _function;
  late String _grade;

  @override
  void initState() {
    super.initState();
    if (widget.staff != null) {
      _firstName = widget.staff!.firstName;
      _lastName = widget.staff!.lastName;
      _staffNumber = widget.staff!.staffNumber;
      _function = widget.staff!.function;
      _grade = widget.staff!.grade;
    } else {
      _firstName = '';
      _lastName = '';
      _staffNumber = '';
      _function = 0;
      _grade = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.staff == null
            ? 'Ajouter un Employé'
            : 'Modifier un Employé'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Prénom'),
                initialValue: _firstName,
                onSaved: (value) => _firstName = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un prénom' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nom'),
                initialValue: _lastName,
                onSaved: (value) => _lastName = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Numéro d\'employé'),
                initialValue: _staffNumber,
                onSaved: (value) => _staffNumber = value!,
                validator: (value) => value!.isEmpty
                    ? 'Veuillez entrer un numéro d\'employé'
                    : null,
              ),
              DropdownButtonFormField<int>(
                value: _function,
                items: HospitalFunction.values.map((function) {
                  return DropdownMenuItem<int>(
                    value: function.index,
                    child: Text(function.displayName),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _function = value!),
                decoration: InputDecoration(labelText: 'Fonction'),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Grade'),
                initialValue: _grade,
                onSaved: (value) => _grade = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un grade' : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final staff = Staff(
                      firstName: _firstName,
                      lastName: _lastName,
                      staffNumber: _staffNumber,
                      function: _function,
                      grade: _grade,
                    );
                    final staffProvider =
                        Provider.of<StaffProvider>(context, listen: false);
                    if (widget.staff == null) {
                      staffProvider.addStaff(staff);
                    } else {
                      staffProvider.updateStaff(widget.index!, staff);
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
