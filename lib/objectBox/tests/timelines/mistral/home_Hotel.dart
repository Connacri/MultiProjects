import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Entity.dart';
import 'provider_hotel.dart';

class ReservationPage extends StatelessWidget {
  const ReservationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Réservations"),
        actions: [
          IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EmployeesPage())),
              icon: Icon(Icons.person_2)),
          IconButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (context) => RoomsPage())),
              icon: Icon(Icons.meeting_room_outlined)),
          SizedBox(
            width: 50,
          )
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, hotelProvider, child) {
          final reservations = hotelProvider.reservations;

          if (reservations.isEmpty) {
            return const Center(child: Text("Aucune réservation trouvée."));
          }

          return ListView.builder(
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              final room = reservation.room.target;
              final guests =
                  reservation.guests.map((g) => g.fullName).join(", ");
              final employee = reservation.receptionist.target;

              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("Chambre: ${room?.code ?? 'N/A'}"),
                  subtitle: Text(
                    "Du ${reservation.from.toLocal()} au ${reservation.to.toLocal()}\n"
                    "Clients: $guests\n"
                    "Receptionniste: ${employee?.fullName ?? 'N/A'}\n"
                    "Prix/Nuit: ${reservation.pricePerNight} DA",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      hotelProvider.deleteReservation(reservation.id);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openReservationForm(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openReservationForm(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReservationFormPage()),
    );
  }
}

class ReservationFormPage extends StatefulWidget {
  const ReservationFormPage({super.key});

  @override
  State<ReservationFormPage> createState() => _ReservationFormPageState();
}

class _ReservationFormPageState extends State<ReservationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _guestController = TextEditingController();
  Room? _selectedRoom;
  Employee? _selectedEmployee;
  List<Guest> _selectedGuests = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  double _pricePerNight = 0;

  @override
  Widget build(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle Réservation")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Sélection Chambre - Using IDs to avoid duplicate object issues
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Chambre"),
                value: _selectedRoom?.id,
                items: hotelProvider.hotels.first.rooms.map((room) {
                  return DropdownMenuItem<int>(
                    value: room.id,
                    child: Text("${room.code} - ${room.type}"),
                  );
                }).toList(),
                onChanged: (roomId) {
                  setState(() {
                    _selectedRoom = roomId != null
                        ? hotelProvider.rooms.firstWhere((r) => r.id == roomId)
                        : null;
                  });
                },
                validator: (value) =>
                    value == null ? "Choisissez une chambre" : null,
              ),

              // Sélection Réceptionniste - Using IDs to avoid duplicate object issues
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(labelText: "Réceptionniste"),
                value: _selectedEmployee?.id,
                items: hotelProvider.employees.map((emp) {
                  return DropdownMenuItem<int>(
                    value: emp.id,
                    child: Text(emp.fullName),
                  );
                }).toList(),
                onChanged: (empId) {
                  setState(() {
                    _selectedEmployee = empId != null
                        ? hotelProvider.employees
                            .firstWhere((e) => e.id == empId)
                        : null;
                  });
                },
                validator: (value) =>
                    value == null ? "Choisissez un réceptionniste" : null,
              ),

              // Sélection Clients
              TextFormField(
                controller: _guestController,
                decoration: const InputDecoration(
                  labelText: "Ajouter un client",
                  hintText: "Tapez le nom et appuyez sur Entrée",
                ),
                onFieldSubmitted: (value) => _addGuest(value),
              ),
              if (_selectedGuests.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedGuests.map((g) {
                    return Chip(
                      label: Text(g.fullName),
                      onDeleted: () {
                        setState(() => _selectedGuests.remove(g));
                      },
                    );
                  }).toList(),
                ),
              ],

              // Dates
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _fromDate = picked);
                        }
                      },
                      child: Text(_fromDate == null
                          ? "Date début"
                          : "Du: ${_fromDate!.toLocal()}"),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _fromDate ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => _toDate = picked);
                        }
                      },
                      child: Text(_toDate == null
                          ? "Date fin"
                          : "Au: ${_toDate!.toLocal()}"),
                    ),
                  ),
                ],
              ),

              // Prix
              TextFormField(
                decoration: const InputDecoration(labelText: "Prix par nuit"),
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                    setState(() => _pricePerNight = double.tryParse(val) ?? 0),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Vérifier s'il y a du texte non ajouté dans le TextFormField
                  if (_guestController.text.trim().isNotEmpty) {
                    _addGuest(_guestController.text.trim());
                  }

                  if (_formKey.currentState!.validate() &&
                      _selectedRoom != null &&
                      _selectedEmployee != null &&
                      _fromDate != null &&
                      _toDate != null &&
                      _selectedGuests.isNotEmpty) {
                    final newReservation = Reservation(
                      from: _fromDate!,
                      to: _toDate!,
                      pricePerNight: _pricePerNight,
                    );

                    hotelProvider.addReservation(
                        room: _selectedRoom!,
                        receptionist: _selectedEmployee!,
                        guests: _selectedGuests,
                        from: _fromDate!,
                        to: _toDate!,
                        pricePerNight: _pricePerNight);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Enregistrer"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addGuest(String guestName) {
    if (guestName.trim().isEmpty) return;

    final trimmedName = guestName.trim();

    // Vérifier si le client existe déjà dans la liste
    final existingGuest = _selectedGuests.firstWhere(
      (guest) => guest.fullName.toLowerCase() == trimmedName.toLowerCase(),
      orElse: () => Guest(
          fullName: '',
          phoneNumber: '',
          email: '',
          idCardNumber: '',
          nationality: ''),
    );

    if (existingGuest.fullName.isEmpty) {
      // Créer un nouveau client
      final newGuest = Guest(
        fullName: trimmedName,
        phoneNumber: '',
        // Valeurs par défaut
        email: '',
        idCardNumber: '',
        nationality: '',
      );

      setState(() {
        _selectedGuests.add(newGuest);
        _guestController.clear();
      });
    } else {
      // Client déjà ajouté, juste vider le champ
      _guestController.clear();
    }
  }

  @override
  void dispose() {
    _guestController.dispose();
    super.dispose();
  }
}

class RoomsPage extends StatelessWidget {
  const RoomsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Chambres"),
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final rooms = provider.rooms;
          if (rooms.isEmpty) {
            return const Center(child: Text("Aucune chambre enregistrée"));
          }
          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text("${room.code} - ${room.type}"),
                  subtitle: Text(
                      "Capacité: ${room.capacity}, Prix: ${room.basePrice} DA, Statut: ${room.status}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => provider.deleteRoom(room.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddRoomDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddRoomDialog(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AddRoomDialog(hotelProvider: hotelProvider),
    );
  }
}

class AddRoomDialog extends StatefulWidget {
  final HotelProvider hotelProvider;

  const AddRoomDialog({super.key, required this.hotelProvider});

  @override
  State<AddRoomDialog> createState() => _AddRoomDialogState();
}

class _AddRoomDialogState extends State<AddRoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final codeCtrl = TextEditingController();
  final typeCtrl = TextEditingController();
  final capacityCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouvelle Chambre"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: codeCtrl,
              decoration: const InputDecoration(labelText: "Code chambre"),
              validator: (val) => val!.isEmpty ? "Champ requis" : null,
            ),
            TextFormField(
              controller: typeCtrl,
              decoration: const InputDecoration(
                  labelText: "Type (Single/Double/Suite)"),
            ),
            TextFormField(
              controller: capacityCtrl,
              decoration: const InputDecoration(labelText: "Capacité"),
              keyboardType: TextInputType.number,
            ),
            TextFormField(
              controller: priceCtrl,
              decoration: const InputDecoration(labelText: "Prix de base"),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final room = Room(
                code: codeCtrl.text,
                type: typeCtrl.text.isEmpty ? "Single" : typeCtrl.text,
                capacity: int.tryParse(capacityCtrl.text) ?? 1,
                basePrice: double.tryParse(priceCtrl.text) ?? 0,
              );
              widget.hotelProvider.addRoom(room);
              Navigator.pop(context);
            }
          },
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    codeCtrl.dispose();
    typeCtrl.dispose();
    capacityCtrl.dispose();
    priceCtrl.dispose();
    super.dispose();
  }
}

class EmployeesPage extends StatelessWidget {
  const EmployeesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des Employés")),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          final employees = provider.employees;
          if (employees.isEmpty) {
            return const Center(child: Text("Aucun employé enregistré"));
          }
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final emp = employees[index];
              return Card(
                margin: const EdgeInsets.all(8),
                child: ListTile(
                  title: Text(emp.fullName),
                  subtitle:
                      Text("Tel: ${emp.phoneNumber}\nEmail: ${emp.email}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => provider.deleteEmployee(emp.id),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddEmployeeDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openAddEmployeeDialog(BuildContext context) {
    final hotelProvider = Provider.of<HotelProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddEmployeeDialog(hotelProvider: hotelProvider);
      },
    );
  }
}

class AddEmployeeDialog extends StatefulWidget {
  final HotelProvider hotelProvider;

  const AddEmployeeDialog({super.key, required this.hotelProvider});

  @override
  State<AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends State<AddEmployeeDialog> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Nouvel Employé"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: "Nom complet"),
              validator: (val) => val!.isEmpty ? "Champ requis" : null,
            ),
            TextFormField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: "Téléphone"),
            ),
            TextFormField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Annuler"),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final emp = Employee(
                fullName: nameCtrl.text,
                phoneNumber: phoneCtrl.text,
                email: emailCtrl.text,
              );

              widget.hotelProvider.addEmployee(emp);

              Navigator.pop(context);
            }
          },
          child: const Text("Enregistrer"),
        ),
      ],
    );
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    super.dispose();
  }
}

class HotelListPage extends StatelessWidget {
  const HotelListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste des Hôtels")),
      body: Consumer<HotelProvider>(
        builder: (context, provider, _) {
          final hotels = provider.hotels;

          if (hotels.isEmpty) {
            return const Center(
              child: Text("Aucun hôtel trouvé"),
            );
          }

          return ListView.builder(
            itemCount: hotels.length,
            itemBuilder: (context, index) {
              final hotel = hotels[index];
              return Card(
                margin: const EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text(hotel.id.toString()),
                  ),
                  title: Text(hotel.name),
                  subtitle: Text(
                      "${hotel.floors} Etages(s) • ${hotel.roomsPerFloor} chambre(s)/Etage • ${hotel.rooms.length} chambre(s) - Evite ${hotel.avoidedNumbers}"),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      provider.deleteHotel(hotel.id);
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => HotelDetail(currentHotel: hotel)));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 👉 bouton pour ajouter un hôtel
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class HotelDetail extends StatelessWidget {
  final Hotel currentHotel;

  const HotelDetail({
    super.key,
    required this.currentHotel,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          RoomsChipsWidget(hotel: currentHotel),
          DetailedRoomsChipsWidget(hotel: currentHotel)
        ],
      ),
    );
  }
}

class RoomsChipsWidget extends StatelessWidget {
  final Hotel hotel;

  const RoomsChipsWidget({
    Key? key,
    required this.hotel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (context, provider, child) {
        final rooms = provider.getRoomsForHotel(hotel);

        if (rooms.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aucune chambre créée pour cet hôtel',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chambres créées',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Chip(
                      label: Text('${rooms.length} chambres'),
                      backgroundColor: Colors.blue.shade100,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: rooms.map((room) {
                    return _buildRoomChip(room);
                  }).toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomChip(Room room) {
    Color chipColor;
    Color textColor;
    IconData statusIcon;

    // Définir la couleur et l'icône selon le statut
    switch (room.status.toLowerCase()) {
      case 'available':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusIcon = Icons.check_circle;
        break;
      case 'occupied':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusIcon = Icons.person;
        break;
      case 'maintenance':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusIcon = Icons.build;
        break;
      case 'cleaning':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusIcon = Icons.cleaning_services;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusIcon = Icons.hotel;
    }

    return Chip(
      avatar: Icon(
        statusIcon,
        size: 16,
        color: textColor,
      ),
      label: Text(
        room.code,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: chipColor,
      side: BorderSide(
        color: textColor.withOpacity(0.3),
        width: 1,
      ),
    );
  }
}

// Widget alternatif avec plus d'informations
class DetailedRoomsChipsWidget extends StatelessWidget {
  final Hotel hotel;

  const DetailedRoomsChipsWidget({
    Key? key,
    required this.hotel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (context, provider, child) {
        final rooms = provider.getRoomsForHotel(hotel);

        if (rooms.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Aucune chambre créée pour cet hôtel',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }

        // Grouper les chambres par étage
        final roomsByFloor = <int, List<Room>>{};

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chambres par étage',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Chip(
                      label: Text('${rooms.length} chambres'),
                      backgroundColor: Colors.blue.shade100,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...roomsByFloor.entries.map((entry) {
                  final floor = entry.key;
                  final floorRooms = entry.value;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Étage $floor',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 4.0,
                          children: floorRooms.map((room) {
                            return _buildDetailedRoomChip(room);
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailedRoomChip(Room room) {
    Color chipColor;
    Color textColor;
    IconData statusIcon;

    switch (room.status.toLowerCase()) {
      case 'available':
        chipColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        statusIcon = Icons.check_circle;
        break;
      case 'occupied':
        chipColor = Colors.red.shade100;
        textColor = Colors.red.shade800;
        statusIcon = Icons.person;
        break;
      case 'maintenance':
        chipColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        statusIcon = Icons.build;
        break;
      case 'cleaning':
        chipColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        statusIcon = Icons.cleaning_services;
        break;
      default:
        chipColor = Colors.grey.shade100;
        textColor = Colors.grey.shade800;
        statusIcon = Icons.hotel;
    }

    return Tooltip(
      message:
          'Chambre ${room.code}\nPrix: ${room.basePrice!.toStringAsFixed(0)}€\nStatut: ${room.status}',
      child: Chip(
        avatar: Icon(
          statusIcon,
          size: 14,
          color: textColor,
        ),
        label: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              room.code,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            Text(
              '${room.basePrice!.toStringAsFixed(0)}€',
              style: TextStyle(
                color: textColor.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
        backgroundColor: chipColor,
        side: BorderSide(
          color: textColor.withOpacity(0.3),
          width: 1,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

// Utilisation dans votre page :
/*
// Widget simple
RoomsChipsWidget(hotel: currentHotel)

// Widget détaillé avec prix et groupement par étage
DetailedRoomsChipsWidget(hotel: currentHotel)
*/
