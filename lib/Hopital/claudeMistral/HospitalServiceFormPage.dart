import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../objectBox/Entity.dart';
import 'Providers.dart';

class HospitalServiceFormPage extends StatefulWidget {
  final HospitalService? hospitalService;
  final int? index;

  HospitalServiceFormPage({this.hospitalService, this.index});

  @override
  _HospitalServiceFormPageState createState() =>
      _HospitalServiceFormPageState();
}

class _HospitalServiceFormPageState extends State<HospitalServiceFormPage> {
  final _formKey = GlobalKey<FormState>();
  late String _serviceCode;
  late String _name;
  late String _description;

  @override
  void initState() {
    super.initState();
    if (widget.hospitalService != null) {
      _serviceCode = widget.hospitalService!.serviceCode;
      _name = widget.hospitalService!.name;
      _description = widget.hospitalService!.description ?? '';
    } else {
      _serviceCode = '';
      _name = '';
      _description = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.hospitalService == null
            ? 'Ajouter un Service Hospitalier'
            : 'Modifier un Service Hospitalier'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Code de Service'),
                initialValue: _serviceCode,
                onSaved: (value) => _serviceCode = value!,
                validator: (value) => value!.isEmpty
                    ? 'Veuillez entrer un code de service'
                    : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Nom'),
                initialValue: _name,
                onSaved: (value) => _name = value!,
                validator: (value) =>
                    value!.isEmpty ? 'Veuillez entrer un nom' : null,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Description'),
                initialValue: _description,
                onSaved: (value) => _description = value!,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final hospitalService = HospitalService()
                      ..serviceCode = _serviceCode
                      ..name = _name
                      ..description = _description;
                    final hospitalServiceProvider =
                        Provider.of<HospitalServiceProvider>(context,
                            listen: false);
                    if (widget.hospitalService == null) {
                      hospitalServiceProvider
                          .addHospitalService(hospitalService);
                    } else {
                      hospitalServiceProvider.updateHospitalService(
                          widget.index!, hospitalService);
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
