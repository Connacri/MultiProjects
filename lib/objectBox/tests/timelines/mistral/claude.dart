import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/provider_hotel.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/widgets.dart';
import 'package:provider/provider.dart';
import 'package:string_extensions/string_extensions.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../Entity.dart';
import 'HotelDataInitializer.dart';
import 'claude_crud.dart';
import 'home_Hotel.dart';

class HotelReservationDataSource extends CalendarDataSource {
  HotelReservationDataSource(List<Reservation> reservations, List<Room> rooms) {
    // Vérification des données d'entrée
    if (reservations.isEmpty) {
      debugPrint('ATTENTION: Aucune réservation fournie au DataSource');
    }
    if (rooms.isEmpty) {
      debugPrint('ERREUR: Aucune chambre fournie au DataSource');
      appointments = <Reservation>[];
      resources = <CalendarResource>[];
      return;
    }

    // Filtrer les réservations valides
    final validReservations = reservations.where((res) {
      // Vérifier que la réservation a une chambre liée
      final room = res.room.target;
      if (room == null) {
        debugPrint('ATTENTION: Réservation sans chambre liée ignorée');
        return false;
      }

      // Vérifier que la chambre est dans la liste des rooms
      final roomExists = rooms.any((r) => r.id == room.id);
      if (!roomExists) {
        debugPrint(
            'ATTENTION: Réservation pour chambre ${room.code} non trouvée dans la liste');
        return false;
      }

      return true;
    }).toList();

    // debugPrint(
    //     'DataSource: ${validReservations.length} réservations valides sur ${reservations.length}');

    appointments = validReservations;

    resources = rooms
        .map((room) => CalendarResource(
              id: room.id,
              displayName: room.code,
              color: Colors.black45,
            ))
        .toList();

    // debugPrint('DataSource: ${resources!.length} ressources (chambres) créées');
  }

  @override
  DateTime getStartTime(int index) {
    if (index >= appointments!.length) {
      debugPrint('ERREUR: Index $index hors limites pour appointments');
      return DateTime.now();
    }
    return (appointments![index] as Reservation).from;
  }

  @override
  DateTime getEndTime(int index) {
    if (index >= appointments!.length) {
      debugPrint('ERREUR: Index $index hors limites pour appointments');
      return DateTime.now().add(const Duration(days: 1));
    }
    return (appointments![index] as Reservation).to;
  }

  @override
  String getSubject(int index) {
    if (index >= appointments!.length) {
      return 'Erreur de données';
    }

    final reservation = appointments![index] as Reservation;
    final guestName = reservation.guests.isNotEmpty
        ? reservation.guests.first.fullName
        : 'Aucun client';
    final totalPrice = reservation.pricePerNight *
        reservation.to.difference(reservation.from).inDays;

    return '$guestName\nNuitée : ${reservation.pricePerNight.toStringAsFixed(2)} DA\nTotal : ${totalPrice.toStringAsFixed(2)} DA\nStatus : ${reservation.status}';
  }

  @override
  List<Object> getResourceIds(int index) {
    if (index >= appointments!.length) {
      debugPrint('ERREUR: Index $index hors limites pour getResourceIds');
      return [];
    }

    final reservation = appointments![index] as Reservation;
    final room = reservation.room.target;

    if (room == null) {
      debugPrint('ERREUR: Réservation sans chambre liée dans getResourceIds');
      return [];
    }

    return [room.id];
  }

  @override
  Color getColor(int index) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.brown,
      Colors.grey,
      Colors.blueGrey,
    ];

    return colors[index % colors.length];
  }

  @override
  bool isAllDay(int index) {
    return false;
  }
}

// ========================= ÉCRAN PRINCIPAL =========================

class Hotel_Management extends StatefulWidget {
  @override
  HotelManagementState createState() => HotelManagementState();
}

class HotelManagementState extends State<Hotel_Management> {
  Hotel? _currentHotel;
  List<Reservation> _reservations = [];
  late HotelReservationDataSource _dataSource;
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.timelineMonth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: AppDrawer(
        currentHotel: _currentHotel,
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, _) {
          // Si c'est le premier lancement, afficher le formulaire de création
          if (provider.isFirstLaunch) {
            return buildFirstLaunchScreen(provider);
          }

          final hotels = provider.hotels;

          if (hotels.isEmpty) {
            return const Center(
              child: Text("Aucun hôtel trouvé"),
            );
          }
          _currentHotel = hotels.first;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Center(
              //   child: Padding(
              //     padding: const EdgeInsets.all(28.0),
              //     child: Text(hotels.first.name),
              //   ),
              // ),
              // _buildHotelInfo(),
              // Wrap(
              //   spacing: 16,
              //   runSpacing: 8,
              //   children: [
              //     // _buildRoomStatusLegend(),
              //     IconButton(
              //       onPressed: _showEditOptions,
              //       icon: const Icon(
              //         Icons.list,
              //         // Icône "outlined" pour un look plus épuré
              //
              //         color: Colors.white,
              //       ),
              //       style: FilledButton.styleFrom(
              //         foregroundColor: Colors.white,
              //         backgroundColor: Colors.deepPurple.shade400,
              //         // Couleur principale du thème
              //         padding: const EdgeInsets.symmetric(
              //             horizontal: 16, vertical: 12),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(
              //               12), // Coins arrondis pour un style moderne
              //         ),
              //         elevation: 3,
              //         // Ombre légère pour le relief
              //         shadowColor: Colors.deepPurple.shade200,
              //         // Ombre colorée subtile
              //         textStyle: const TextStyle(
              //           fontWeight: FontWeight.w600,
              //         ),
              //         visualDensity: VisualDensity.standard,
              //         // Taille minimale pour un bouton confortable
              //       ),
              //     ),
              //     IconButton(
              //       onPressed: () async {
              //         final hotelProvider = context.read<HotelProvider>();
              //         final initializer = HotelDataInitializer(hotelProvider);
              //
              //         await initializer.initializeAllDefaultData();
              //       },
              //       icon: Icon(Icons.star),
              //     ),
              //
              //     IconButton(
              //       onPressed: () async {
              //         final hotelProvider = context.read<HotelProvider>();
              //         await hotelProvider.clearAllTestData();
              //       },
              //       icon: Icon(
              //         Icons.clear_all,
              //         color: Colors.red,
              //       ),
              //     ),
              //   ],
              // ),
              // SizedBox(
              //   height: 16,
              // ),
              Expanded(child: _buildCalendar(provider)),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildCalendar(HotelProvider provider) {
    final reservations =
        _currentHotel!.rooms.expand((room) => room.reservations).toList();
    _dataSource = HotelReservationDataSource(
        _currentHotel!.rooms.expand((room) => room.reservations).toList(),
        _currentHotel!.rooms.toList());

    return SfCalendar(
      controller: _calendarController,
      view: _currentView,
      dataSource: _dataSource,
      allowViewNavigation: false,
      allowDragAndDrop: false,
      allowAppointmentResize: false,
      showDatePickerButton: true,
      showTodayButton: true,
      // todayHighlightColor: //Colors.transparent,
      //     Colors.deepPurple,

      todayTextStyle: TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.bold,
      ),

      firstDayOfWeek: 1,
      timeSlotViewSettings: TimeSlotViewSettings(
        timeInterval: Duration(days: 1),
        startHour: 0,
        endHour: 24,
        timeIntervalWidth: 42,
        timeIntervalHeight: 10,
        timelineAppointmentHeight: 30,
        timeTextStyle: TextStyle(fontSize: 14),
      ),
      resourceViewSettings: ResourceViewSettings(
        visibleResourceCount: 15, //_calculateVisibleRooms(),
        size: 60,
        displayNameTextStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 18,
        ),
        showAvatar: false,
      ),

      onTap: _onCalendarTap,
      onLongPress: _onCalendarLongPress,
      headerStyle: CalendarHeaderStyle(
        backgroundColor: Colors.deepPurple,
        textStyle: TextStyle(color: Colors.white, fontSize: 20),
      ),

      appointmentBuilder: _appointmentBuilder,
      // monthViewSettings: MonthViewSettings(
      //   dayFormat: 'dd',
      //   showAgenda: true,
      //   appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
      // ),
      // monthCellBuilder: (BuildContext context, MonthCellDetails details) {
      //   final isToday = DateUtils.isSameDay(details.date, today);
      //   final isFriday = details.date.weekday == DateTime.friday;
      //   final isWeekend = details.date.weekday == DateTime.saturday ||
      //       details.date.weekday == DateTime.sunday;
      //
      //   if (isToday) {
      //     return Container(
      //       decoration: BoxDecoration(
      //         color: Colors.green.shade100,
      //         border: Border.all(color: Colors.grey.shade300),
      //       ),
      //       child: Column(
      //         children: [
      //           Text(
      //             _formatShortDayName(details.date),
      //             style: TextStyle(fontSize: 10),
      //           ),
      //           Text(
      //             _formatDayNumber(details.date),
      //             style: TextStyle(fontWeight: FontWeight.bold),
      //           ),
      //         ],
      //       ),
      //     );
      //   } else if (isFriday || isWeekend) {
      //     return Container(
      //       decoration: BoxDecoration(
      //         color: isFriday ? Colors.orange.shade50 : Colors.blue.shade50,
      //         border: Border.all(color: Colors.grey.shade300),
      //       ),
      //       child: Column(
      //         children: [
      //           Text(
      //             _formatShortDayName(details.date),
      //             style: TextStyle(fontSize: 10),
      //           ),
      //           Text(
      //             _formatDayNumber(details.date),
      //             style: TextStyle(fontWeight: FontWeight.bold),
      //           ),
      //         ],
      //       ),
      //     );
      //   } else {
      //     return Container(
      //       decoration: BoxDecoration(
      //         border: Border.all(color: Colors.grey.shade300),
      //       ),
      //       child: Column(
      //         children: [
      //           Text(
      //             _formatShortDayName(details.date),
      //             style: TextStyle(fontSize: 10),
      //           ),
      //           Text(
      //             _formatDayNumber(details.date),
      //             style: TextStyle(fontWeight: FontWeight.bold),
      //           ),
      //         ],
      //       ),
      //     );
      //   }
      // },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      titleSpacing: 0,
      elevation: 8,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepPurple.shade700, Colors.purpleAccent.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      title: LayoutBuilder(
        builder: (context, constraints) {
          double w = constraints.maxWidth;

          if (w < 600) {
            return _buildAppBarSmall2();
          } else {
            return _buildAppBarSmall();
          }
        },
      ),

      // style: TextStyle(
      //     fontWeight: FontWeight.bold,
      //     fontSize: 22,
      //     color: Colors.white,
      //     letterSpacing: 1.2,
      //   ),
      //),
      actions: [
        // IconButton(
        //   onPressed: () {
        //     Navigator.of(context)
        //         .push(MaterialPageRoute(builder: (ctx) => HotelListPage()));
        //   },
        //   icon: Icon(Icons.ac_unit_outlined),
        // ),
        // IconButton(
        //     onPressed: () => Navigator.push(context,
        //         MaterialPageRoute(builder: (context) => ReservationPage())),
        //     icon: Icon(Icons.hotel)),
        // // Bouton "Aujourd'hui"
        // // Tooltip(
        // //   message: "Aller à aujourd'hui",
        // //   child: IconButton(
        // //     icon: Icon(Icons.today_rounded),
        // //     onPressed: () => _calendarController.displayDate = DateTime.now(),
        // //   ),
        // // ),
        // const SizedBox(width: 8),
        // // Bouton ajouter/modifier hôtel
        // Tooltip(
        //   message: "Créer / Modifier un hôtel",
        //   child: IconButton(
        //     icon: Icon(Icons.add_business_rounded),
        //     onPressed: _showHotelCreationDialog,
        //   ),
        // ),
        // const SizedBox(width: 8),
        // // Menu vue calendrier

        IconButton(
          icon: const Icon(Icons.auto_awesome),
          tooltip: "Sélectionner la saison actuelle",
          onPressed: () async {
            final provider = Provider.of<HotelProvider>(context, listen: false);
            final seasonal =
                await provider.selectSeasonalPricing(_currentHotel!);

            if (seasonal != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Saison appliquée : ${seasonal.name}")),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text("Aucune saison applicable trouvée")),
              );
            }
          },
        ),

        PopupMenuButton<VoidCallback>(
          tooltip: "Actions rapides",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: () => _showEditOptions(),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Options'),
                ],
              ),
            ),
            PopupMenuItem(
              value: () async {
                final hotelProvider = context.read<HotelProvider>();
                final initializer = HotelDataInitializer(hotelProvider);
                await initializer.initializeAllDefaultData();
              },
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  SizedBox(width: 8),
                  Text('Données par défaut'),
                ],
              ),
            ),
            PopupMenuItem(
              value: () async {
                final hotelProvider = context.read<HotelProvider>();
                await hotelProvider.clearAllTestData();
              },
              child: Row(
                children: [
                  Icon(Icons.clear_all, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Vider les données'),
                ],
              ),
            ),
          ],
        ),
        PopupMenuButton<String>(
          tooltip: "Navigation rapide",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.deepPurple.shade400,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.more_vert, color: Colors.white),
          ),
          onSelected: (value) {
            switch (value) {
              case 'hotels':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => HotelListPage()),
                );
                break;
              case 'reservations':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ReservationPage()),
                );
                break;
              case 'create':
                _showHotelCreationDialog();
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'hotels',
              child: Row(
                children: const [
                  Icon(Icons.ac_unit_outlined, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Liste des hôtels'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'reservations',
              child: Row(
                children: const [
                  Icon(Icons.hotel, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Réservations'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'create',
              child: Row(
                children: const [
                  Icon(Icons.add_business_rounded, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Créer un hôtel'),
                ],
              ),
            ),
          ],
        )
      ],
    );
  }

  void showHotelEditDialog(HotelProvider provider, Hotel hotel) {
    final nameController = TextEditingController(text: hotel.name);
    final floorsController =
        TextEditingController(text: hotel.floors.toString());
    final roomsPerFloorController =
        TextEditingController(text: hotel.roomsPerFloor.toString());
    final avoidedController =
        TextEditingController(text: hotel.avoidedNumbers ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Modifier l\'hôtel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'hôtel*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: floorsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'étages*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomsPerFloorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chambres par étage*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: avoidedController,
                decoration: const InputDecoration(
                  labelText: 'Numéros à éviter (optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.block),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir un nom pour l\'hôtel'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Modifier l'hôtel
              hotel.name = nameController.text.trim();
              hotel.floors =
                  int.tryParse(floorsController.text) ?? hotel.floors;
              hotel.roomsPerFloor =
                  int.tryParse(roomsPerFloorController.text) ??
                      hotel.roomsPerFloor;
              hotel.avoidedNumbers = avoidedController.text.trim();

              provider.updateHotel(hotel);

              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Hôtel modifié avec succès'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void confirmDeleteHotel(HotelProvider provider, Hotel hotel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'hôtel'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer l\'hôtel "${hotel.name}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              provider.deleteHotel(hotel.id);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hôtel "${hotel.name}" supprimé'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  Widget buildFirstLaunchScreen(HotelProvider provider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hotel,
              size: 120,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
            const SizedBox(height: 32),
            Text(
              'Bienvenue !',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Créez votre premier hôtel pour commencer à gérer vos réservations',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: ElevatedButton.icon(
                onPressed: () => showHotelCreationDialog(provider),
                icon: const Icon(Icons.add_business),
                label: const Text('Créer mon hôtel'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showHotelCreationDialog(HotelProvider provider) {
    final nameController = TextEditingController();
    final floorsController = TextEditingController(text: '3');
    final roomsPerFloorController = TextEditingController(text: '10');
    final avoidedController = TextEditingController(text: '13');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Création de l\'hôtel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom de l\'hôtel*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: floorsController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nombre d\'étages*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.layers),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: roomsPerFloorController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Chambres par étage*',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.meeting_room),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: avoidedController,
                decoration: const InputDecoration(
                  labelText: 'Numéros à éviter (optionnel)',
                  hintText: 'Ex: 13,113,213',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.block),
                  helperText: 'Séparez les numéros par des virgules',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez saisir un nom pour l\'hôtel'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              createHotel(
                provider,
                nameController.text.trim(),
                int.tryParse(floorsController.text) ?? 3,
                int.tryParse(roomsPerFloorController.text) ?? 10,
                avoidedController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
                context,
              );
              Navigator.pop(context);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> createHotel(
    HotelProvider provider,
    String name,
    int floors,
    int roomsPerFloor,
    List<String> avoidedNumbers,
    BuildContext context,
  ) async {
    try {
      // 1. Créer et enregistrer l’hôtel
      final hotel = Hotel(
        name: name.isNotEmpty ? name : 'Mon Hôtel',
        floors: floors,
        roomsPerFloor: roomsPerFloor,
        avoidedNumbers: avoidedNumbers.join(','),
      );
      final hotelId = await provider.addHotel(hotel);

      // 2. S’assurer qu’au moins une catégorie existe
      var categories = await provider.getRoomCategories();
      RoomCategory defaultCategory;
      if (categories.isEmpty) {
        defaultCategory = RoomCategory(
          name: 'Standard',
          code: 'STD',
          description: 'Chambre standard',
          bedType: 'Double',
          capacity: 2,
          standing: 'Standard',
          basePrice: 120.0,
        );
        final categoryId = await provider.addRoomCategory(defaultCategory);
        defaultCategory.id = categoryId;
      } else {
        defaultCategory = categories.firstWhere((c) => c.capacity == 2);
      }

      // 3. Générer les chambres et les lier via leurs IDs
      int createdRooms = 0;
      for (int floor = 1; floor <= floors; floor++) {
        for (int roomNum = 1; roomNum <= roomsPerFloor; roomNum++) {
          final roomCode = '$floor${roomNum.toString().padLeft(2, '0')}';

          // ignorer les numéros interdits
          final shouldAvoid = avoidedNumbers.any(
            (a) => a.isNotEmpty && roomCode.contains(a),
          );
          if (shouldAvoid) continue;

          final room = Room(code: roomCode, status: 'Libre');
          room.hotel.targetId = hotelId;
          room.category.targetId = defaultCategory.id;

          await provider.addRoom(room);
          createdRooms++;
        }
      }

      // 4. Feedback utilisateur
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hôtel "$name" créé avec $createdRooms chambres.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la création : $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHotelInfo() {
    if (_currentHotel == null) return SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade50, Colors.purple.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icône hôtel stylisée
            CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.1),
              radius: 24,
              child:
                  Icon(Icons.hotel_rounded, color: Colors.deepPurple, size: 28),
            ),

            const SizedBox(width: 16),

            // Infos texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _currentHotel!.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.meeting_room_rounded,
                          size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 4),
                      Text(
                        "${_currentHotel!.rooms.length} chambres",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.layers_rounded,
                          size: 18, color: Colors.deepPurple),
                      const SizedBox(width: 4),
                      Text(
                        "${_currentHotel!.floors} étages",
                        style: TextStyle(
                            fontSize: 14, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bouton d’édition rapide
            IconButton(
              icon: Icon(Icons.edit_rounded, color: Colors.deepPurple),
              tooltip: "Modifier l'hôtel",
              onPressed: _showHotelCreationDialog,
            ),
          ],
        ),
      ),
    );
  }

  Widget _appointmentBuilder(
      BuildContext context, CalendarAppointmentDetails details) {
    if (details.appointments.isEmpty) return Container();
    final reservation = details.appointments.first as Reservation;
    final nights = reservation.to.difference(reservation.from).inDays;
    final totalPrice = reservation.pricePerNight * nights;

    return Container(
      width: details.bounds.width,
      height: details.bounds.height,
      decoration: BoxDecoration(
        color: _getRandomColorForReservation(reservation.guests.hashCode)
            .withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          // Partie gauche: noms des invités
          Expanded(
            child: Text(
              reservation.guests.map((g) => g.fullName).join(", "),
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 8),
          // Partie droite: prix et statut
          Flexible(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    '${totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    reservation.status,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    //   Container(
    //   width: details.bounds.width,
    //   height: details.bounds.height,
    //   // Utilisez toute la hauteur disponible
    //
    //   // decoration: BoxDecoration(
    //   //   color: _getRandomColorForReservation(reservation.clientName.hashCode),
    //   //   borderRadius: BorderRadius.circular(14),
    //   //   border: Border.all(color: Colors.white, width: 1),
    //   //   boxShadow: [
    //   //     BoxShadow(
    //   //       color: Colors.black.withOpacity(0.1),
    //   //       blurRadius: 2,
    //   //       offset: Offset(0, 1),
    //   //     ),
    //   //   ],
    //   // ),
    //   decoration: BoxDecoration(
    //     color: _getRandomColorForReservation(reservation.guests.hashCode)
    //         .withOpacity(0.9),
    //     borderRadius: BorderRadius.circular(12),
    //     boxShadow: [
    //       BoxShadow(
    //         color: Colors.black.withOpacity(0.1),
    //         blurRadius: 4,
    //         offset: Offset(0, 2),
    //       ),
    //     ],
    //   ),
    //   padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //   // child: Text(
    //   //   reservation.guests.map((g) => g.fullName).join(", "),
    //   //   style: TextStyle(
    //   //     color: Colors.white,
    //   //     fontWeight: FontWeight.bold,
    //   //     fontSize: 13,
    //   //   ),
    //   //   maxLines: 1,
    //   //   overflow: TextOverflow.ellipsis,
    //   // ),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     children: [
    //       Text(
    //         reservation.guests.map((g) => g.fullName).join(", "),
    //         style: TextStyle(
    //           color: Colors.white,
    //           fontWeight: FontWeight.bold,
    //           fontSize: 13,
    //         ),
    //         maxLines: 1,
    //         overflow: TextOverflow.ellipsis,
    //       ),
    //       Row(
    //         children: [
    //           Text(
    //             '${totalPrice.toStringAsFixed(2)}',
    //             style: TextStyle(
    //               color: Colors.white,
    //               fontSize: 12,
    //               fontWeight: FontWeight.w600,
    //             ),
    //           ),
    //           Text(
    //             reservation.status,
    //             style: TextStyle(
    //               color: Colors.white70,
    //               fontSize: 11,
    //               fontWeight: FontWeight.w500,
    //             ),
    //             maxLines: 1,
    //             overflow: TextOverflow.ellipsis,
    //           ),
    //         ],
    //       ),
    //     ],
    //   ),
    // );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  Widget _buildFloatingActionButtons() {
    return FloatingActionButton(
      heroTag: "add",
      onPressed: _showAddReservationDialog,
      backgroundColor: Colors.green,
      child: Icon(Icons.add, color: Colors.white),
    );
  }

  // ========================= DIALOGUES =========================

  void _showHotelCreationDialog() {
    final nameController = TextEditingController();
    final floorsController = TextEditingController(text: '3');
    final roomsPerFloorController = TextEditingController(text: '10');
    final avoidedController = TextEditingController(text: '13');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Création de l\'hôtel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nom de l\'hôtel',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: floorsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nombre d\'étages',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: roomsPerFloorController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Chambres par étage',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: avoidedController,
                decoration: InputDecoration(
                  labelText: 'Numéros à éviter (séparés par virgule)',
                  hintText: 'Ex: 13,113,213',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (_currentHotel != null)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
          ElevatedButton(
            onPressed: () {
              createHotel(
                Provider.of<HotelProvider>(
                  context,
                  listen: false,
                ),
                nameController.text,
                int.tryParse(floorsController.text) ?? 3,
                int.tryParse(roomsPerFloorController.text) ?? 10,
                avoidedController.text.split(',').map((e) => e.trim()).toList(),
                context,
              );
              Navigator.pop(context);
            },
            child: Text('Créer'),
          ),
        ],
      ),
    );
  }

  void _showAddReservationDialog(
      [Room? preselectedRoom, DateTime? preselectedDate]) {
    final provider = Provider.of<HotelProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: context.read<HotelProvider>(),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width < 600
                ? MediaQuery.of(context).size.width
                : MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: ReservationDialogContent(
              preselectedRoom: preselectedRoom,
              preselectedDate: preselectedDate,
              currentHotel: _currentHotel!,
              provider: provider,
              parentContext: context,
              // Passer le contexte parent pour SnackBar
              onReservationAdded: () {
                // Rafraîchir le calendrier
                setState(() {
                  _dataSource = HotelReservationDataSource(
                      _currentHotel!.rooms
                          .expand((room) => room.reservations)
                          .toList(),
                      _currentHotel!.rooms.toList());
                });
              },
              seasonalPricings: provider.getSeasonalPricings(),
              seasonSaved: provider.selectedSeasonalPricing!,
            ),
          ),
        ),
      ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit),
              title: Text('Modifier une réservation'),
              onTap: () {
                Navigator.pop(context);
                showReservationList(isEdit: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Supprimer une réservation'),
              onTap: () {
                Navigator.pop(context);
                showReservationList(isDelete: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void showReservationList({bool isEdit = false, bool isDelete = false}) {
    final provider = Provider.of<HotelProvider>(context, listen: false);
    final reservations = isEdit
        ? provider.reservations
        : provider.reservations.where((r) => r.status != 'Annulée').toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDelete
            ? 'Supprimer une réservation'
            : 'Modifier une réservation'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: reservations.isEmpty
              ? const Center(
                  child: Text(
                    'Aucune réservation disponible',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = reservations[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(reservation.status),
                        child: Text(
                          reservation.room.target?.code ?? 'N/A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        // Utilisation de la méthode du provider pour obtenir le nom du client principal
                        reservation.guests.map((g) => g.fullName).join(", "),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            // Utilisation de la méthode du provider pour obtenir le nom de la chambre
                            '${provider.getRoomNameForReservation(reservation)} - ${_formatDate(reservation.from)} → ${_formatDate(reservation.to)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text(
                            'Statut: ${reservation.status}',
                            style: TextStyle(
                              fontSize: 11,
                              color: _getStatusColor(reservation.status),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      trailing: Icon(
                        isDelete ? Icons.delete : Icons.edit,
                        color: isDelete ? Colors.red : Colors.blue,
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        if (isDelete) {
                          confirmDeleteReservation(reservation);
                        } else {
                          showEditReservationDialog(reservation);
                        }
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

// Méthode helper pour obtenir la couleur selon le statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Confirmée':
        return Colors.green;
      case 'En cours':
        return Colors.blue;
      case 'Terminée':
        return Colors.grey;
      case 'Annulée':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

// Méthode de confirmation de suppression corrigée
  void confirmDeleteReservation(Reservation reservation) {
    // Obtenir le provider une fois avant d'ouvrir le dialog
    final provider = Provider.of<HotelProvider>(context, listen: false);
    final clientName = provider.getPrimaryGuestName(reservation);
    final roomName = provider.getRoomNameForReservation(reservation);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                'Êtes-vous sûr de vouloir supprimer cette réservation ?'),
            const SizedBox(height: 16),
            Text(
              'Client: $clientName',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Chambre: $roomName',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            Text(
              'Période: ${_formatDate(reservation.from)} → ${_formatDate(reservation.to)}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await provider.deleteReservation(reservation.id);

              if (success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Réservation supprimée avec succès'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Erreur lors de la suppression'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

// 1. Méthode pour afficher le dialogue d'édition (version corrigée)
  void showEditReservationDialog(Reservation reservation) {
    final provider = Provider.of<HotelProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ChangeNotifierProvider.value(
        value: context.read<HotelProvider>(),
        child: Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: ReservationDialogContent(
              preselectedRoom: reservation.room.target,
              preselectedDate: reservation.from,
              currentHotel: _currentHotel!,
              provider: provider,
              parentContext: context,
              isEditing: true,
              // Nouveau paramètre
              existingReservation: reservation,
              // Nouveau paramètre
              onReservationAdded: () {
                // Rafraîchir le calendrier après modification
                setState(() {
                  _dataSource = HotelReservationDataSource(
                      _currentHotel!.rooms
                          .expand((room) => room.reservations)
                          .toList(),
                      _currentHotel!.rooms.toList());
                });
              },
              seasonalPricings: provider.getSeasonalPricings(),
              seasonSaved: provider.selectedSeasonalPricing!,
            ),
          ),
        ),
      ),
    );
  }

  // ========================= GESTIONNAIRES D'ÉVÉNEMENTS =========================

  void _onCalendarTap(CalendarTapDetails details) {
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final reservation = details.appointments!.first as Reservation;
      _showReservationDetails(reservation);
    } else if (details.targetElement == CalendarElement.calendarCell) {
      String? roomNumber = details.resource?.displayName;
      // ✅ Handle the case where no room is found
      Room? room;
      try {
        room = _currentHotel?.rooms.firstWhere((r) => r.code == roomNumber);
      } catch (e) {
        room = null;
      }
      _showAddReservationDialog(room, details.date);
    }
  }

  void _onCalendarLongPress(CalendarLongPressDetails details) {
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final reservation = details.appointments!.first as Reservation;
      _showQuickActions(reservation);
    }
  }

  final dateFormatter =
      DateFormat('EEEE dd/MM/yyyy', 'fr_FR'); // jour + date FR
  void _showReservationDetails(Reservation reservation) {
    final nights = reservation.to.difference(reservation.from).inDays;
    final totalPrice = reservation.pricePerNight * nights;

    // 🔹 Récupération de la chambre liée
    final roomCode = reservation.room.target?.code ?? "N/A";

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==== HEADER ====
                Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
                  child: Text(
                    'Réservation Détail',
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColorDark,
                    ),
                  ),
                ),

                // ==== CONTENU ====
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // En-tête avec le nom du client et de la chambre
                      _buildHeaderSection(
                        reservation,
                        reservation.guests.map((g) => g.fullName).join(", "),
                        roomCode, // ✅ Correction : on passe le code de la chambre
                      ),

                      const SizedBox(height: 16),
                      ReservationCard(
                        reservation: reservation,
                      ),
                      const SizedBox(height: 8),
                      reservation.extras.isEmpty
                          ? SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Extras :",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  // coins arrondis
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10, sigmaY: 10), // flou
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        // fond semi-transparent
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                            color:
                                                Colors.white.withOpacity(0.3)),
                                      ),
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: reservation.extras.length,
                                        itemBuilder: (context, index) {
                                          final extra =
                                              reservation.extras[index];
                                          return Tooltip(
                                            message:
                                                extra.extraService.target!.name,
                                            child: ListTile(
                                              onTap: () => Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) =>
                                                      ExtraServiceDetailPage(
                                                    reservationExtra: extra,
                                                  ),
                                                ),
                                              ),
                                              leading: const Icon(Icons.check,
                                                  color: Colors.green),
                                              title: Text(
                                                extra.extraService.target!.name,
                                                overflow: TextOverflow.ellipsis,
                                                // texte visible
                                              ),
                                              trailing: Text(
                                                  "${extra.extraService.target!.price.toStringAsFixed(2)} DA"),
                                              dense: true,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28.0, vertical: 18),
                        child: _buildReservationTimeline(
                          reservation.from,
                          reservation.to,
                          nights,
                        ),
                      ),

                      // Détails tarifaires
                      _buildPricingSection(
                        nights,
                        reservation.pricePerNight,
                        totalPrice,
                      ),
                      const SizedBox(height: 16),
                      // 🔹 Saison appliquée
                      BentoCard(season: reservation.seasonalPricing.target!),
                      const SizedBox(height: 16),
                      // Statut de la réservation
                      _buildStatusSection(reservation.status),
                    ],
                  ),
                ),

                //==== FOOTER style coupon vert ====
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "🎉 Félicitations ${reservation.guests.map((g) => g.fullName).join(", ")} 🎉",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Vous avez réservé",
                        style: TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "ROOM-$roomCode",
                          // ✅ Correction : affichage code chambre
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

// Section pour l'en-tête (client et chambre)
  Widget _buildHeaderSection(
      Reservation reservation, String clientName, String roomName) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                'Réception', reservation.receptionist.target!.fullName,
                isHeader: true),
            // Row(
            //   crossAxisAlignment: CrossAxisAlignment.center,
            //   children: [
            //     const Text(
            //       'Client:',
            //       style: TextStyle(
            //         fontWeight: FontWeight.bold,
            //         fontSize: 16,
            //       ),
            //     ),
            //     Expanded(
            //       // ✅ Pour que les chips prennent l’espace restant
            //       child: Wrap(
            //         spacing: -12,
            //         runSpacing: 0,
            //         children: List.generate(reservation.guests.length, (index) {
            //           final guest = reservation.guests[index];
            //
            //           return Transform.scale(
            //             scale: 0.8, // 70% de la taille -> réduction de ~30%
            //             child: InputChip(
            //               avatar: CircleAvatar(
            //                 radius: 10, // réduit aussi l’avatar
            //                 backgroundColor: Colors.blue.shade100,
            //                 child: Text(
            //                   guest.fullName.substring(0, 1).toUpperCase(),
            //                   style: const TextStyle(
            //                     color: Colors.black,
            //                     fontSize: 12, // police réduite
            //                   ),
            //                 ),
            //               ),
            //               label: Text(
            //                 guest.fullName.capitalize,
            //                 style:
            //                     const TextStyle(fontSize: 13), // police réduite
            //               ),
            //               backgroundColor: Colors.deepPurpleAccent,
            //               labelStyle: const TextStyle(color: Colors.white),
            //               shape: RoundedRectangleBorder(
            //                 borderRadius: BorderRadius.circular(20),
            //               ),
            //               onPressed: () {
            //                 Navigator.push(
            //                   context,
            //                   MaterialPageRoute(
            //                     builder: (_) => ClientDetailPage(guest: guest),
            //                   ),
            //                 );
            //               },
            //             ),
            //           );
            //           ;
            //         }),
            //       ),
            //     ),
            //   ],
            // ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Client:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final List<Widget> chips = [];
                      double usedWidth = 0;
                      const double spacing = 6;
                      const double chipScale = 0.8;

                      // On réserve la largeur pour le chip "+X"
                      const double plusChipMinWidth = 50;

                      for (int i = 0; i < reservation.guests.length; i++) {
                        final guest = reservation.guests[i];

                        // Mesure du texte (largeur du label)
                        final painter = TextPainter(
                          text: TextSpan(
                            text: guest.fullName.capitalize,
                            style: const TextStyle(fontSize: 13),
                          ),
                          maxLines: 1,
                          textDirection: ui.TextDirection.ltr,
                        )..layout();

                        // Largeur estimée du chip (avatar + texte + padding)
                        double chipWidth = painter.width + 40;
                        chipWidth *= chipScale;

                        // Vérifie si on peut placer ce chip + au moins le chip "+X"
                        if (usedWidth + chipWidth + spacing + plusChipMinWidth >
                            constraints.maxWidth) {
                          final remaining = reservation.guests.length - i;

                          // Ajout du chip "+X"
                          chips.add(
                            GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Tous les clients"),
                                    content: SizedBox(
                                      width: double.maxFinite,
                                      child: ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: reservation.guests.length,
                                        itemBuilder: (context, index) {
                                          final g = reservation.guests[index];
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor:
                                                  Colors.blue.shade100,
                                              child: Text(
                                                g.fullName
                                                    .substring(0, 1)
                                                    .toUpperCase(),
                                              ),
                                            ),
                                            title: Text(g.fullName.capitalize),
                                            onTap: () {
                                              Navigator.pop(context);
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      ClientDetailPage(
                                                          guest: g),
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              child: Transform.scale(
                                scale: 0.8,
                                child: Chip(
                                  backgroundColor: Colors.grey.shade300,
                                  label: Text(
                                    "+$remaining",
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          );
                          break; // stop → on a placé "+X"
                        } else {
                          // Ajout du chip normal
                          chips.add(
                            InputChip(
                              avatar: CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  guest.fullName.substring(0, 1).toUpperCase(),
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 10),
                                ),
                              ),
                              label: Text(
                                guest.fullName.capitalize,
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: Colors.deepPurpleAccent,
                              labelStyle: const TextStyle(color: Colors.white),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ClientDetailPage(guest: guest),
                                  ),
                                );
                              },
                            ),
                          );
                          usedWidth += chipWidth + spacing;
                        }
                      }

                      return Row(
                        children: chips,
                      );
                    },
                  ),
                ),
              ],
            ),
            _buildDetailRow('Chambre', roomName, isHeader: true),
          ],
        ),
      ),
    );
  }

// Section pour les détails tarifaires
  Widget _buildPricingSection(
      int nights, double pricePerNight, double totalPrice) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Nuitées', '$nights nuit(s)',
                icon: Icons.bedtime_outlined),
            _buildDetailRow(
              'Prix/nuitée',
              '${pricePerNight.toStringAsFixed(2)}',
              icon: Icons.attach_money_rounded,
            ),
            Divider(),
            _buildDetailRow(
              'Prix total',
              '${totalPrice.toStringAsFixed(2)}',
              isHighlighted: true,
              icon: Icons.money_rounded,
            ),
          ],
        ),
      ),
    );
  }

// Section pour le statut
  Widget _buildStatusSection(String status) {
    Color statusColor;
    IconData statusIcon;

    switch (status.toLowerCase()) {
      case 'confirmée':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'annulé':
        statusColor = Colors.red;
        statusIcon = Icons.cancel_rounded;
        break;
      case 'en attente':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline_rounded;
    }

    return Center(
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor),
          SizedBox(width: 8),
          Text(
            'Statut: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Chip(
            backgroundColor: statusColor,
            label: Text(
              status,
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Ligne de détail générique
  Widget _buildDetailRow(String label, String value,
      {bool isHeader = false, bool isHighlighted = false, IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(icon, size: 20, color: Colors.grey.shade600),
            ),
          SizedBox(
            width: isHeader ? 82 : 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                fontSize: isHeader ? 16 : 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                fontSize: isHighlighted ? 16 : 14,
                color: isHighlighted ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

// Timeline du séjour (inchangée mais intégrée dans le nouveau design)
  Widget _buildReservationTimeline(DateTime start, DateTime end, int nights) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: CircleAvatar(
            backgroundColor: Colors.black87,
            child: Text(
              '$nights',
              style: TextStyle(color: Colors.white60, fontSize: 20),
            ),
          ),
        ),
        Center(
          child: Text(
            "Durée du séjour $nights Nuitées",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            // Check-in
            Column(
              children: [
                Icon(FontAwesomeIcons.planeArrival,
                    color: Colors.green.shade700, size: 28),
                SizedBox(height: 6),
                Text(
                  _formatDate(start),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "Arrivée",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            // Ligne de progression
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 8),
                height: 2,
                color: Colors.grey.shade400,
              ),
            ),
            // Check-out
            Column(
              children: [
                Icon(FontAwesomeIcons.planeDeparture,
                    color: Colors.red.shade700, size: 28),
                SizedBox(height: 6),
                Text(
                  _formatDate(end),
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  "Départ",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  void _showQuickActions(Reservation reservation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              reservation.guests.map((g) => g.fullName).join(", "),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.info),
              title: Text('Voir les détails'),
              onTap: () {
                Navigator.pop(context);
                _showReservationDetails(reservation);
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, color: Colors.blue),
              title: Text('Modifier'),
              onTap: () {
                Navigator.pop(context);
                showEditReservationDialog(reservation);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                confirmDeleteReservation(reservation);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========================= UTILITAIRES =========================

  int _calculateVisibleRooms() {
    final screenWidth = MediaQuery.of(context).size.width;
    return ((screenWidth - 100) / 120).floor().clamp(3, 15);
  }

  MaterialColor _getRandomColorForReservation(int seed) {
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.lime,
      Colors.deepOrange,
      Colors.lightBlue,
      Colors.lightGreen,
      Colors.brown,
      Colors.blueGrey,
      Colors.deepPurple,
    ];
    return colors[seed.abs() % colors.length];
  }

  _buildAppBarSmall() {
    return Consumer<HotelProvider>(
      builder: (_, provider, __) {
        final list = provider.seasonalPricing;
        SeasonalPricing? selected = provider.selectedSeasonalPricing;

        // ✅ Auto-select saison selon la date courante
        if (selected == null && list.isNotEmpty) {
          final now = DateTime.now();
          try {
            final found = list.firstWhere(
              (sp) =>
                  sp.startDate.isBefore(now) &&
                  sp.endDate.isAfter(now), // saison active
            );

            // 🚀 Appel repoussé après la fin du build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_currentHotel != null) {
                provider.setSelectedSeasonalPricing(_currentHotel!, found);
              } else {
                debugPrint(
                    "⚠️ Pas d'hôtel courant disponible au moment du callback");
              }
            });

            selected = found;
          } catch (e) {
            // aucune saison ne correspond à la date actuelle
            selected = null;
          }
        }
        final dateFormatter = DateFormat("EEE d MMMM yyyy", "fr_FR");
        return InkWell(
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (_) {
                  return ListView(
                    children: list.map((sp) {
                      return ListTile(
                        leading: const Icon(Icons.calendar_today),
                        title: Text(sp.name),
                        subtitle: Text(
                            "Multiplicateur: ${sp.multiplier}x\n${sp.startDate.toLocal()} → ${sp.endDate.toLocal()}"),
                        trailing: selected?.id == sp.id
                            ? const Icon(Icons.check, color: Colors.green)
                            : null,
                        onTap: () {
                          provider.setSelectedSeasonalPricing(
                              _currentHotel!, sp);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                  );
                },
              );
            },
            child: SeasonalAppBar());
      },
    );
  }

  _buildAppBarSmall2() {
    return Consumer<HotelProvider>(
      builder: (_, provider, __) {
        final list = provider.seasonalPricing;
        SeasonalPricing? selected = provider.selectedSeasonalPricing;

        // ✅ Auto-select saison selon la date courante
        if (selected == null && list.isNotEmpty) {
          final now = DateTime.now();
          try {
            final found = list.firstWhere(
              (sp) =>
                  sp.startDate.isBefore(now) &&
                  sp.endDate.isAfter(now), // saison active
            );

            // 🚀 Appel repoussé après la fin du build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.setSelectedSeasonalPricing(_currentHotel!, found);
            });

            selected = found;
          } catch (e) {
            // aucune saison ne correspond à la date actuelle
            selected = null;
          }
        }
        final dateFormatter = DateFormat("EEE d MMMM yyyy", "fr_FR");
        return InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              builder: (_) {
                return ListView(
                  children: list.map((sp) {
                    return ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(sp.name),
                      subtitle: Text(
                          "Multiplicateur: ${sp.multiplier}x\n${sp.startDate.toLocal()} → ${sp.endDate.toLocal()}"),
                      trailing: selected?.id == sp.id
                          ? const Icon(Icons.check, color: Colors.green)
                          : null,
                      onTap: () {
                        provider.setSelectedSeasonalPricing(_currentHotel!, sp);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
                );
              },
            );
          },
          child: Tooltip(
            message: "${selected!.multiplier}x " +
                "${selected!.description}" +
                "\nDu ${dateFormatter.format(selected!.startDate)}" +
                "\nAu ${dateFormatter.format(selected.endDate)}",
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
              child: Text.rich(
                TextSpan(
                  children: [
                    // TextSpan(
                    //   text: "${_currentHotel?.name ?? 'Mon'} Hôtel ",
                    //   style: TextStyle(
                    //     fontSize: 25,
                    //     fontWeight: FontWeight.bold,
                    //     color: Theme.of(context).primaryColorLight,
                    //   ),
                    // ),
                    TextSpan(
                      text:
                          //  "${selected.name} - "
                          "x${selected.multiplier.toStringAsFixed(2)} ",
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w200,
                        color: Theme.of(context).primaryColorLight,
                      ),
                    ),
                    TextSpan(
                      children: [
                        if (selected != null) ...[
                          WidgetSpan(
                            child: Icon(Icons.play_arrow,
                                size: 20, color: Colors.greenAccent),
                          ),
                          TextSpan(
                            text:
                                " ${dateFormatter.format(selected.startDate)}  ",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).primaryColorLight,
                            ),
                          ),
                          WidgetSpan(
                            child: Icon(Icons.arrow_forward,
                                size: 20, color: Colors.white70),
                          ),
                          WidgetSpan(
                            child: Icon(Icons.flag,
                                size: 20, color: Colors.redAccent),
                          ),
                          TextSpan(
                            text: " ${dateFormatter.format(selected.endDate)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).primaryColorLight,
                            ),
                          ),
                        ],
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced ReservationDialogContent with Board Basis and Extra Services integration
class ReservationDialogContent extends StatefulWidget {
  final Room? preselectedRoom;
  final DateTime? preselectedDate;
  final Hotel currentHotel;
  final HotelProvider provider;
  final BuildContext parentContext;
  final VoidCallback onReservationAdded;
  final bool isEditing;
  final Reservation? existingReservation;
  final List<SeasonalPricing> seasonalPricings;
  final SeasonalPricing seasonSaved;

  const ReservationDialogContent({
    Key? key,
    this.preselectedRoom,
    this.preselectedDate,
    required this.currentHotel,
    required this.provider,
    required this.parentContext,
    required this.onReservationAdded,
    this.isEditing = false,
    this.existingReservation,
    required this.seasonalPricings,
    required this.seasonSaved,
  }) : super(key: key);

  @override
  State<ReservationDialogContent> createState() =>
      _ReservationDialogContentState();
}

class _ReservationDialogContentState extends State<ReservationDialogContent> {
  final _formKey = GlobalKey<FormState>();
  final _guestController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idCardController = TextEditingController();
  TextEditingController _priceController = TextEditingController();
  bool _isPriceManuallyEdited = false;
  SeasonalPricing? _selectedSeasonalPricing;
  Room? _selectedRoom;
  Employee? _selectedEmployee;
  List<Guest> _selectedGuests = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  String _status = "Confirmée";
  bool _isLoading = false;
  bool _isPriceEditable = false; // Nouveau: pour contrôler l'édition du prix

  // Board Basis and Extra Services
  BoardBasis? _selectedBoardBasis;
  List<ReservationExtraItem> _selectedExtras = [];

  // Variables pour l'édition de client
  bool _isEditingGuest = false;
  Guest? _guestBeingEdited;
  int? _editingGuestIndex;
  SeasonalPricing? seasonSaved;
  final List<String> _statuses = [
    "Confirmée",
    "En attente",
    "Arrivé",
    "Parti",
    "Annulée"
  ];

  List<SeasonalPricing> _seasonalPricings = [];
  late double _seasonalMultiplier;

// Ajouter après les contrôleurs existants
  final _discountPercentController = TextEditingController();
  final _discountAmountController = TextEditingController();

// Ajouter les variables pour la réduction
  double _discountPercent = 0.0;
  double _discountAmount = 0.0;
  String _discountType = 'percentage'; // 'percentage' ou 'amount'
  String _discountAppliedTo =
      'total'; // 'room', 'board', 'extras', 'total', 'specific'
  List<String> _selectedDiscountItems = [];

  @override
  void initState() {
    super.initState();
    print(seasonSaved);
    // Valeur par défaut sûre
    _seasonalMultiplier = 1.0;

    final provider = Provider.of<HotelProvider>(context, listen: false);

    // 1) Affecter la liste des tarifs saisonniers AVANT toute sélection
    _seasonalPricings = widget.seasonalPricings ?? [];

    // 2) Pré-sélectionner : prioriser le choix global du provider si présent
    final activeSeason = provider.selectedSeasonalPricing;
    if (activeSeason != null) {
      _selectedSeasonalPricing = activeSeason;
      _seasonalMultiplier = activeSeason.multiplier;
    } else {
      _preselectSeasonalByToday();
    }

    // Initialisation spécifique EDIT / NEW
    if (widget.isEditing && widget.existingReservation != null) {
      _initializeForEdit();
    } else {
      _initializeForNew();
    }

    // Créer _priceController une seule fois et avec texte initial éventuel
    _priceController = TextEditingController(
      text: widget.isEditing && widget.existingReservation != null
          ? widget.existingReservation!.pricePerNight.toString()
          : (_selectedRoom != null ? '' : ''),
    );

    _discountPercentController.text = _discountPercent.toString();
    _discountAmountController.text = _discountAmount.toString();

    // Après build, recalculer le multiplicateur sur la plage et mettre à jour le prix
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (_fromDate != null && _toDate != null) {
    //     _seasonalMultiplier =
    //         _calculateSeasonalMultiplier(_fromDate!, _toDate!);
    //     print('_seasonalMultiplier000');
    //     print(_seasonalMultiplier);
    //     _updateRoomPrice(); // doit utiliser _seasonalMultiplier ou la fonction per-night
    //     setState(() {}); // uniquement si UI doit se rafraichir
    //   }
    // });
    // print('_seasonalMultiplier apres');
    // print(_seasonalMultiplier);
    debugPrint('initState: seasonalPricings=${_seasonalPricings.length}, '
        'selectedSeason=${_selectedSeasonalPricing?.id}, multiplier=$_seasonalMultiplier');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<HotelProvider>(context, listen: true);
    final active = provider.selectedSeasonalPricing;

    if (active != null && active.id != _selectedSeasonalPricing?.id) {
      setState(() {
        _selectedSeasonalPricing = active;
        _seasonalMultiplier = active.multiplier;
        _updateRoomPrice();
      });
    }
  }

  void _preselectSeasonalByToday() {
    final now = DateTime.now();

    if (_seasonalPricings.isEmpty) {
      _selectedSeasonalPricing = null;
      _seasonalMultiplier = 1.0;
      return;
    }

    final selected = _seasonalPricings.firstWhere(
      (s) => s.isActive && s.isDateInSeason(now),
      orElse: () => _seasonalPricings.first,
    );

    _selectedSeasonalPricing = selected;
    _seasonalMultiplier = selected.multiplier;
  }

  void _initializeForEdit() {
    final reservation = widget.existingReservation!;
// Ajouter après l'initialisation du prix
    _discountPercent = reservation.discountPercent;
    _discountAmount = reservation.discountAmount;
    _discountPercentController.text = _discountPercent.toString();
    _discountAmountController.text = _discountAmount.toString();
    // Initialisation des objets existants
    final roomId = reservation.room.target?.id;
    _selectedRoom = roomId != null
        ? widget.currentHotel.rooms
            .cast<Room?>()
            .firstWhere((room) => room?.id == roomId, orElse: () => null)
        : null;

    final employeeId = reservation.receptionist.target?.id;
    _selectedEmployee = employeeId != null
        ? widget.provider.employees
            .cast<Employee?>()
            .firstWhere((emp) => emp?.id == employeeId, orElse: () => null)
        : null;

    _selectedGuests = reservation.guests.toList();
    _fromDate = reservation.from;
    _toDate = reservation.to;
    _status = reservation.status;
    _priceController.text = reservation.pricePerNight.toString();

    // CORRECTION: Récupération du BoardBasis
    if (reservation.boardBasis.target != null) {
      _selectedBoardBasis = reservation.boardBasis.target;
    }

    // CORRECTION: Récupération des extras avec mapping correct
    _selectedExtras = reservation.extras
        .map((re) => ReservationExtraItem(
              extraService: re.extraService.target!,
              quantity: re.quantity,
              unitPrice: re.unitPrice,
              scheduledDate: re.scheduledDate,
            ))
        .toList();

    // Calculer les prix des extras après initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAllExtraPrices();
    });
  }

  void _initializeForNew() {
    _selectedRoom = widget.preselectedRoom;
    _fromDate = widget.preselectedDate ?? DateTime.now();
    _toDate = _fromDate!.add(Duration(days: 1));

    // NOUVEAU: Initialiser le prix de base de la chambre sélectionnée
    if (_selectedRoom != null) {
      _updateRoomPrice();
    }

    // Set default board basis
    final defaultBoardBasis = widget.provider
        .getBoardBasisList()
        .where((bb) => bb.isActive && bb.code == 'RO')
        .firstOrNull;
    _selectedBoardBasis = defaultBoardBasis;
  }

  double _calculateSeasonalMultiplier(DateTime from, DateTime to) {
    if (_seasonalPricings.isEmpty || _selectedRoom == null) return 1.0;

    // Utiliser la saison sélectionnée si disponible
    if (_selectedSeasonalPricing != null &&
        _selectedSeasonalPricing!.isActive) {
      // Vérifier si la période chevauche
      bool overlaps = false;
      for (DateTime date = from;
          date.isBefore(to.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))) {
        if (_selectedSeasonalPricing!.isDateInSeason(date)) {
          overlaps = true;
          break;
        }
      }

      if (overlaps) {
        // Vérifier l'applicabilité
        if (_selectedSeasonalPricing!.applicationType == 'all_categories') {
          return _selectedSeasonalPricing!.multiplier;
        } else if (_selectedSeasonalPricing!.applicationType ==
            'specific_categories') {
          if (_selectedRoom!.category.target != null) {
            final roomCategoryId =
                _selectedRoom!.category.target!.id.toString();
            if (_selectedSeasonalPricing!.targetIds.contains(roomCategoryId)) {
              return _selectedSeasonalPricing!.multiplier;
            }
          }
        } else if (_selectedSeasonalPricing!.applicationType ==
            'specific_rooms') {
          final roomId = _selectedRoom!.id.toString();
          if (_selectedSeasonalPricing!.targetIds.contains(roomId)) {
            return _selectedSeasonalPricing!.multiplier;
          }
        }
      }
    }

    return 1.0;
  }

  // Add/Remove Extra Services
  void _addExtraService(ExtraService service) {
    final existingIndex = _selectedExtras
        .indexWhere((item) => item.extraService.id == service.id);

    if (existingIndex != -1) {
      setState(() {
        _selectedExtras[existingIndex].quantity++;
        _updateExtraPrice(_selectedExtras[existingIndex]);
      });
    } else {
      final extraItem = ReservationExtraItem(
        extraService: service,
        quantity: 1,
        unitPrice: service.price,
      );
      _updateExtraPrice(extraItem);

      setState(() {
        _selectedExtras.add(extraItem);
      });
    }
  }

  void _removeExtraService(ReservationExtraItem item) {
    setState(() {
      _selectedExtras.remove(item);
    });
  }

  void _updateExtraPrice(ReservationExtraItem item) {
    if (_fromDate != null && _toDate != null) {
      final nights = _toDate!.difference(_fromDate!).inDays;
      final persons = _selectedGuests.length;
      final roomPrice = double.tryParse(_priceController.text) ?? 0.0;

      item.totalPrice = item.extraService
          .calculatePrice(item.quantity, roomPrice, nights, persons);
    }
  }

  void _updateAllExtraPrices() {
    setState(() {
      for (final extra in _selectedExtras) {
        _updateExtraPrice(extra);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double w = constraints.maxWidth;

        if (w < 600) {
          return _buildMobileForm();
        } else if (w < 900) {
          return _buildTabletForm();
        } else {
          return _buildDesktopForm();
        }
      },
    );
  }

  // CORRECTION 7: Améliorer _buildDesktopForm pour inclure la section saisonnière
  Widget _buildDesktopForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildBasicInfoSection(),
                            SizedBox(height: 16),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Middle Column
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildBoardBasisSection(),
                            _buildGuestsSection(),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Right Column
                      Expanded(
                        flex: 2,
                        child: Column(children: [
                          _buildExtraServicesSection(),

                          // _buildSeasonalPricingSection2(),
                          // Dans _buildDesktopForm(), _buildMobileForm(), et _buildTabletForm()
                          // Remplacer SeasonalPricingDropdown() par :
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 16),
                            child: SeasonalPricingDropdown(
                              selectedValue: _selectedSeasonalPricing,
                              customSeasonalPricings: _seasonalPricings,
                              useLocalState: true,

                              onChanged:
                                  _onSeasonalPricingChanged, // Utiliser le nouveau callback
                            ),
                          ),
                          _buildDiscountSection(),
                        ]),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // CORRECTION: Placer la section saisonnière ici
                  _buildPricingSummary700(context),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildMobileForm() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildBasicInfoSection(),
                  SizedBox(height: 16),
                  _buildBoardBasisSection(),
                  SizedBox(height: 16),
                  _buildGuestsSection(),
                  SizedBox(height: 16),
                  _buildExtraServicesSection(),
                  SizedBox(height: 16),
                  // Dans _buildDesktopForm(), _buildMobileForm(), et _buildTabletForm()
// Remplacer SeasonalPricingDropdown() par

                  SeasonalPricingDropdown(
                    selectedValue: _selectedSeasonalPricing,
                    customSeasonalPricings: _seasonalPricings,
                    useLocalState: true,
                    onChanged: (SeasonalPricing? newValue) {
                      setState(() {
                        _selectedSeasonalPricing = newValue;
                        _seasonalMultiplier = newValue?.multiplier ?? 1.0;

                        // Mettre à jour le prix si pas édité manuellement
                        if (!_isPriceManuallyEdited) {
                          _updateRoomPrice();
                        }

                        _updateAllExtraPrices();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildDiscountSection(),
                  SizedBox(height: 16),
                  _buildPricingSummary600(context),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildTabletForm() {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _buildBasicInfoSection(),
                            SizedBox(height: 16),
                            _buildBoardBasisSection(),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          children: [
                            _buildGuestsSection(),
                            SizedBox(height: 16),
                            _buildExtraServicesSection(),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  // Dans _buildDesktopForm(), _buildMobileForm(), et _buildTabletForm()
// Remplacer SeasonalPricingDropdown() par :
                  SeasonalPricingDropdown(
                    selectedValue: _selectedSeasonalPricing,
                    customSeasonalPricings: _seasonalPricings,
                    useLocalState: true,
                    onChanged: (SeasonalPricing? newValue) {
                      setState(() {
                        _selectedSeasonalPricing = newValue;
                        _seasonalMultiplier = newValue?.multiplier ?? 1.0;

                        // Mettre à jour le prix si pas édité manuellement
                        if (!_isPriceManuallyEdited) {
                          _updateRoomPrice();
                        }

                        _updateAllExtraPrices();
                      });
                    },
                  ),
                  SizedBox(height: 16),
                  _buildPricingSummary700(context),
                  _buildDiscountSection(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
        _buildFooter(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(Icons.hotel, color: Colors.white, size: 28),
                SizedBox(width: 12),
                Flexible(
                  // Utilise Flexible pour le texte
                  child: Text(
                    widget.isEditing
                        ? 'Modifier la réservation'
                        : 'Nouvelle Réservation',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // 1. CORRECTION: Utiliser _calculateTotalPrice() dans _buildPricingSummary
  Widget _buildPricingSummary700(BuildContext context) {
    if (_fromDate == null || _toDate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Sélectionnez les dates pour voir le récapitulatif des prix',
          ),
        ),
      );
    }

    final nights = _toDate!.difference(_fromDate!).inDays;
    final persons = _selectedGuests.length;

    // UTILISER _calculateTotalPrice() au lieu de recalculer ici
    final grandTotal = _calculateTotalPrice();

    // Calcul des sous-totaux pour l'affichage
    final roomPricePerNight = _getEffectiveRoomPrice();
    final roomTotal = roomPricePerNight * nights;

    double boardBasisTotal = 0.0;
    if (_selectedBoardBasis != null) {
      boardBasisTotal = _selectedBoardBasis!.pricePerPerson * persons * nights;
    }

    double extrasTotal =
        _selectedExtras.fold(0.0, (sum, extra) => sum + extra.totalPrice);

    // Calculer les réductions appliquées
    double roomDiscount = 0.0;
    double boardDiscount = 0.0;
    double extrasDiscount = 0.0;
    double totalDiscount = 0.0;

    switch (_discountAppliedTo) {
      case 'room':
        roomDiscount = _calculateDiscount(roomTotal);
        break;
      case 'board':
        boardDiscount = _calculateDiscount(boardBasisTotal);
        break;
      case 'extras':
        extrasDiscount = _calculateDiscount(extrasTotal);
        break;
      case 'total':
        totalDiscount =
            _calculateDiscount(roomTotal + boardBasisTotal + extrasTotal);
        break;
      case 'specific':
        if (_selectedDiscountItems.contains('room')) {
          roomDiscount = _calculateDiscount(roomTotal);
        }
        if (_selectedDiscountItems.contains('board')) {
          boardDiscount = _calculateDiscount(boardBasisTotal);
        }
        for (int i = 0; i < _selectedExtras.length; i++) {
          final extra = _selectedExtras[i];
          if (_selectedDiscountItems
              .contains('extra_${extra.extraService.id}')) {
            extrasDiscount += _calculateDiscount(extra.totalPrice);
          }
        }
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif des prix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chambre
            _buildPriceRow600(
              '$nights Nuitée(s)                 ',
              '${roomTotal.toStringAsFixed(2)}',
            ),
            if (roomDiscount > 0)
              _buildPriceRow600(
                'Réduction chambre',
                '-${roomDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),

            // Multiplicateur saisonnier
            if (_seasonalMultiplier != 1.0)
              Container(
                color: Colors.deepPurple.shade100,
                child: _buildPriceRow600(
                  'Saison Indice ${((_seasonalMultiplier * 100) - 100).toStringAsFixed(2)}%',
                  '${(roomTotal - (roomTotal / _seasonalMultiplier)).toStringAsFixed(2)}',
                ),
              ),

            // Plan de pension
            if (_selectedBoardBasis != null) ...[
              _buildPriceRow600(
                '${_selectedBoardBasis!.name} ($persons personnes, $nights nuits)',
                '${boardBasisTotal.toStringAsFixed(2)}',
              ),
              if (boardDiscount > 0)
                _buildPriceRow600(
                  'Réduction pension',
                  '-${boardDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Services supplémentaires
            if (_selectedExtras.isNotEmpty) ...[
              _buildPriceRow600(
                'Services supplémentaires',
                '${extrasTotal.toStringAsFixed(2)}',
              ),
              if (extrasDiscount > 0)
                _buildPriceRow600(
                  'Réduction services',
                  '-${extrasDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Réduction totale
            if (totalDiscount > 0)
              _buildPriceRow600(
                'Réduction totale',
                '-${totalDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            const Divider(),
            _buildPriceRow600(
              'Total général',
              '${(extrasDiscount + roomTotal + boardBasisTotal + extrasTotal).toStringAsFixed(2)}',
              isTotal: true,
            ),
            const Divider(),
            _buildPriceRow2600(
              'Net à Payer',
              '${grandTotal.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingSummary600(BuildContext context) {
    if (_fromDate == null || _toDate == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: const Text(
            'Sélectionnez les dates pour voir le récapitulatif des prix',
          ),
        ),
      );
    }

    final nights = _toDate!.difference(_fromDate!).inDays;
    final persons = _selectedGuests.length;

    // UTILISER _calculateTotalPrice() au lieu de recalculer ici
    final grandTotal = _calculateTotalPrice();

    // Calcul des sous-totaux pour l'affichage
    final roomPricePerNight = _getEffectiveRoomPrice();
    final roomTotal = roomPricePerNight * nights;

    double boardBasisTotal = 0.0;
    if (_selectedBoardBasis != null) {
      boardBasisTotal = _selectedBoardBasis!.pricePerPerson * persons * nights;
    }

    double extrasTotal =
        _selectedExtras.fold(0.0, (sum, extra) => sum + extra.totalPrice);

    // Calculer les réductions appliquées
    double roomDiscount = 0.0;
    double boardDiscount = 0.0;
    double extrasDiscount = 0.0;
    double totalDiscount = 0.0;

    switch (_discountAppliedTo) {
      case 'room':
        roomDiscount = _calculateDiscount(roomTotal);
        break;
      case 'board':
        boardDiscount = _calculateDiscount(boardBasisTotal);
        break;
      case 'extras':
        extrasDiscount = _calculateDiscount(extrasTotal);
        break;
      case 'total':
        totalDiscount =
            _calculateDiscount(roomTotal + boardBasisTotal + extrasTotal);
        break;
      case 'specific':
        if (_selectedDiscountItems.contains('room')) {
          roomDiscount = _calculateDiscount(roomTotal);
        }
        if (_selectedDiscountItems.contains('board')) {
          boardDiscount = _calculateDiscount(boardBasisTotal);
        }
        for (int i = 0; i < _selectedExtras.length; i++) {
          final extra = _selectedExtras[i];
          if (_selectedDiscountItems
              .contains('extra_${extra.extraService.id}')) {
            extrasDiscount += _calculateDiscount(extra.totalPrice);
          }
        }
        break;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Récapitulatif des prix',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Chambre
            _buildPriceRow(
              '$nights Nuitée(s)                 ',
              '${roomTotal.toStringAsFixed(2)}',
            ),
            if (roomDiscount > 0)
              _buildPriceRow(
                'Réduction chambre',
                '-${roomDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),

            // Multiplicateur saisonnier
            if (_seasonalMultiplier != 1.0)
              Container(
                color: Colors.deepPurple.shade100,
                child: _buildPriceRow(
                  'Saison Indice ${((_seasonalMultiplier * 100) - 100).toStringAsFixed(2)}%',
                  '${(roomTotal - (roomTotal / _seasonalMultiplier)).toStringAsFixed(2)}',
                ),
              ),

            // Plan de pension
            if (_selectedBoardBasis != null) ...[
              _buildPriceRow(
                '${_selectedBoardBasis!.name} ($persons personnes, $nights nuits)',
                '${boardBasisTotal.toStringAsFixed(2)}',
              ),
              if (boardDiscount > 0)
                _buildPriceRow(
                  'Réduction pension',
                  '-${boardDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Services supplémentaires
            if (_selectedExtras.isNotEmpty) ...[
              _buildPriceRow(
                'Services supplémentaires',
                '${extrasTotal.toStringAsFixed(2)}',
              ),
              if (extrasDiscount > 0)
                _buildPriceRow(
                  'Réduction services',
                  '-${extrasDiscount.toStringAsFixed(2)}',
                  isDiscount: true,
                ),
            ],

            // Réduction totale
            if (totalDiscount > 0)
              _buildPriceRow(
                'Réduction totale',
                '-${totalDiscount.toStringAsFixed(2)}',
                isDiscount: true,
              ),
            const Divider(),
            _buildPriceRow(
              'Total général',
              '${(extrasDiscount + roomTotal + boardBasisTotal + extrasTotal).toStringAsFixed(2)}',
              isTotal: true,
            ),
            const Divider(),
            _buildPriceRow2(
              'Net à Payer',
              '${grandTotal.toStringAsFixed(2)}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding:
            EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations de base',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),

            // Room and Employee
            SizedBox(
              height: 160,
              child: Column(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      isExpanded: true,
                      value: _selectedEmployee?.id,
                      decoration: InputDecoration(
                        labelText: 'Réceptionniste *',
                        prefixIcon: Icon(Icons.person),
                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(8),
                        // ),
                      ),
                      items: widget.provider.employees.map((emp) {
                        return DropdownMenuItem<int>(
                          value: emp.id,
                          child: Text(emp.fullName),
                        );
                      }).toList(),
                      onChanged: (int? empId) {
                        setState(() {
                          _selectedEmployee = widget.provider.employees
                              .firstWhere((emp) => emp.id == empId);
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Choisissez un réceptionniste' : null,
                    ),
                  ),
                  SizedBox(height: 8),
                  Expanded(
                    child: DropdownButtonFormField<Room>(
                      isDense: false,
                      isExpanded: true,
                      value: _selectedRoom,
                      decoration: InputDecoration(
                        labelText: 'Chambre *',
                        // prefixIcon: Icon(Icons.bed),
                        // border: OutlineInputBorder(
                        //   borderRadius: BorderRadius.circular(8),
                        // ),
                      ),
                      items: widget.currentHotel.rooms.map((room) {
                        final categoryName =
                            widget.provider.getRoomCategoryName(room);
                        return DropdownMenuItem(
                          value: room,
                          child: Row(
                            children: [
                              Text('${room.code}'),
                              const SizedBox(width: 8),
                              // 👉 le texte peut s'adapter
                              Expanded(
                                child: Text(
                                  '$categoryName ${room.category.target!.bedType ?? ''}',
                                  overflow: TextOverflow.ellipsis,
                                  // coupe avec "..."
                                  maxLines: 1, // une seule ligne
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (room) {
                        setState(() {
                          _selectedRoom = room;
                          _updateRoomPrice(); // Recalculer le prix
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Choisissez une chambre' : null,
                    ),
                  )
                ],
              ),
            ),

            SizedBox(height: 16),

            // Dates
            Row(
              children: [
                Expanded(
                    child: _buildDateField(
                        FontAwesomeIcons.planeArrival, '  Arrivée', _fromDate,
                        (date) {
                  setState(() {
                    _fromDate = date;
                    if (_toDate != null &&
                        _toDate!.isBefore(date.add(Duration(days: 1)))) {
                      _toDate = date.add(Duration(days: 1));
                    }
                    _updateAllExtraPrices();
                  });
                }, true)),
                SizedBox(width: 16),
                Expanded(
                    child: _buildDateField(
                        FontAwesomeIcons.planeDeparture, '  Départ', _toDate,
                        (date) {
                  setState(() {
                    _toDate = date;
                    _updateAllExtraPrices();
                  });
                }, false)),
              ],
            ),

            SizedBox(height: 16),

            // ================= Price & Status Section =================
            Padding(
              padding: EdgeInsets.all(
                  MediaQuery.of(context).size.width < 600 ? 0 : 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  _buildPriceFieldImproved(),
                  const SizedBox(height: 32),
                  DropdownButtonFormField<String>(
                    isDense: true,
                    isExpanded: true,
                    value: _status,
                    decoration: InputDecoration(
                      labelText: 'Statut',
                      prefixIcon: const Icon(Icons.info_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (status) => setState(() => _status = status!),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Réductions',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  onPressed: _showDiscountDialog,
                  icon: Icon(Icons.percent),
                  tooltip: 'Configurer la réduction',
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_discountPercent > 0 || _discountAmount > 0) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_discountPercent > 0)
                      Text(
                          'Réduction: ${_discountPercent.toStringAsFixed(1)}%'),
                    if (_discountAmount > 0)
                      Text(
                          'Montant fixe: ${_discountAmount.toStringAsFixed(2)}'),
                    Text(
                      'Appliqué sur: ${_getDiscountAppliedToLabel()}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ] else
              Center(
                child: Text(
                  'Aucune réduction appliquée',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDiscountAppliedToLabel() {
    switch (_discountAppliedTo) {
      case 'room':
        return 'Chambre uniquement';
      case 'board':
        return 'Plan de pension uniquement';
      case 'extras':
        return 'Services supplémentaires uniquement';
      case 'total':
        return 'Total général';
      case 'specific':
        return 'Éléments sélectionnés';
      default:
        return 'Non défini';
    }
  }

  double _calculateTotalPrice() {
    if (_fromDate == null || _toDate == null) return 0.0;
    final nights = _toDate!.difference(_fromDate!).inDays;
    final persons = _selectedGuests.length;

    // Utiliser le prix effectif (auto ou manuel)
    final roomPricePerNight = _getEffectiveRoomPrice();
    double roomTotal = roomPricePerNight * nights;

    double boardBasisTotal = 0.0;
    if (_selectedBoardBasis != null) {
      boardBasisTotal = _selectedBoardBasis!.pricePerPerson * persons * nights;
    }

    double extrasTotal =
        _selectedExtras.fold(0.0, (sum, extra) => sum + extra.totalPrice);

    // Appliquer la réduction INSTANTANÉMENT selon la sélection
    double finalRoomTotal = roomTotal;
    double finalBoardTotal = boardBasisTotal;
    double finalExtrasTotal = extrasTotal;

    switch (_discountAppliedTo) {
      case 'room':
        finalRoomTotal = roomTotal - _calculateDiscount(roomTotal);
        break;
      case 'board':
        finalBoardTotal = boardBasisTotal - _calculateDiscount(boardBasisTotal);
        break;
      case 'extras':
        finalExtrasTotal = extrasTotal - _calculateDiscount(extrasTotal);
        break;
      case 'specific':
        if (_selectedDiscountItems.contains('room')) {
          finalRoomTotal = roomTotal - _calculateDiscount(roomTotal);
        }
        if (_selectedDiscountItems.contains('board')) {
          finalBoardTotal =
              boardBasisTotal - _calculateDiscount(boardBasisTotal);
        }
        // Pour chaque extra sélectionné
        for (int i = 0; i < _selectedExtras.length; i++) {
          final extra = _selectedExtras[i];
          if (_selectedDiscountItems
              .contains('extra_${extra.extraService.id}')) {
            final reduction = _calculateDiscount(extra.totalPrice);
            finalExtrasTotal -= reduction;
          }
        }
        break;
      case 'total':
        final subtotal = roomTotal + boardBasisTotal + extrasTotal;
        final totalReduction = _calculateDiscount(subtotal);
        return (subtotal - totalReduction).clamp(0, double.infinity);
    }

    return (finalRoomTotal + finalBoardTotal + finalExtrasTotal)
        .clamp(0, double.infinity);
  }

  double _calculateDiscount(double baseAmount) {
    if (_discountType == 'percentage') {
      return baseAmount * (_discountPercent / 100);
    } else {
      return _discountAmount;
    }
  }

  Widget _buildBoardBasisSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Row(
                children: [
                  Icon(Icons.restaurant),
                  SizedBox(width: 8),
                  Text('Plan de pension',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isDense: false,
              isExpanded: true,
              value: _selectedBoardBasis?.code,
              decoration: InputDecoration(
                labelText: 'Type de pension',
                // prefixIcon: Icon(Icons.restaurant),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                helperText: _selectedBoardBasis != null
                    ? '${_selectedBoardBasis!.pricePerPerson}/personne/nuitée'
                    : null,
                contentPadding:
                    EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              ),
              menuMaxHeight: 250,
              items: () {
                final allItems = widget.provider
                    .getBoardBasisList()
                    .where((bb) => bb.isActive)
                    .toList();

                final uniqueItems = <String, BoardBasis>{};
                for (final item in allItems) {
                  uniqueItems.putIfAbsent(item.code, () => item);
                }

                // Si le selected n'existe plus, on remet à null
                if (_selectedBoardBasis != null &&
                    !uniqueItems.containsKey(_selectedBoardBasis!.code)) {
                  _selectedBoardBasis = null;
                }

                return uniqueItems.values.map((boardBasis) {
                  return DropdownMenuItem<String>(
                    value: boardBasis.code,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${boardBasis.name} (${boardBasis.code})',
                            style: TextStyle(fontSize: 14)),
                        if (boardBasis.inclusionsSummary.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  boardBasis.inclusionsSummary,
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600]),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${boardBasis.pricePerPerson.toStringAsFixed(2)}/person',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList();
              }(),
              onChanged: (String? selectedCode) {
                setState(() {
                  final allItems = widget.provider
                      .getBoardBasisList()
                      .where((bb) => bb.isActive)
                      .toList();

                  // méthode sûre : retourne null si pas trouvé
                  final matches =
                      allItems.where((bb) => bb.code == selectedCode);
                  _selectedBoardBasis =
                      matches.isNotEmpty ? matches.first : null;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtraServicesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: FittedBox(
                    child: Text('Services supplémentaires',
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ),
                ),
                IconButton(
                  onPressed: _showExtraServicesDialog,
                  icon: Icon(Icons.add_circle),
                  tooltip: 'Ajouter un service',
                ),
              ],
            ),
            SizedBox(height: 16),
            if (_selectedExtras.isEmpty)
              Center(
                child: FittedBox(
                  child: Text(
                    'Aucun service supplémentaire sélectionné',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                // prend juste la hauteur nécessaire
                physics: NeverScrollableScrollPhysics(),
                // désactive le scroll interne
                itemCount: _selectedExtras.length,
                itemBuilder: (context, index) {
                  final extra = _selectedExtras[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExtraServiceDetailPage(
                              extraItem:
                                  extra, // Passez directement l'extraItem
                            ),
                          ),
                        );
                      },
                      onLongPress: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text(
                                "Voulez-vous vraiment supprimer ce service ?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Annuler"),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Supprimer"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          _removeExtraService(extra);
                        }
                      },
                      title: FittedBox(child: Text(extra.extraService.name)),
                      subtitle: FittedBox(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Text(extra.extraService.description),
                            // SizedBox(height: 4),
                            Text(
                              'Qtt: ${extra.quantity} | PU: ${extra.unitPrice} = ',
                              style: TextStyle(fontSize: 15),
                            ),
                            Text(
                              '${extra.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),

                      //     Row(
                      //   mainAxisSize: MainAxisSize.min,
                      //   children: [
                      //     Text(
                      //       '${extra.totalPrice.toStringAsFixed(2)}',
                      //       style: TextStyle(
                      //         fontWeight: FontWeight.bold,
                      //         color: Theme.of(context).primaryColor,
                      //       ),
                      //     ),
                      //     SizedBox(width: 8),
                      //     // IconButton(
                      //     //   onPressed: () => _removeExtraService(extra),
                      //     //   icon: Icon(Icons.delete, color: Colors.red),
                      //     // ),
                      //   ],
                      // ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // 2. CORRECTION: Améliorer _buildPriceRow pour supporter les réductions
  Widget _buildPriceRow(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  fontSize: isTotal ? 16 : 14,
                  color: isDiscount ? Colors.red : null,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal
                  ? Theme.of(context).primaryColor
                  : isDiscount
                      ? Colors.red
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow2(String label, String amount) {
    return Card(
      color: Theme.of(context).primaryColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Version desktop / tablette large
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  FittedBox(
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Version mobile (<600px)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // occupe toute la largeur
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FittedBox(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FittedBox(
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildPriceRow600(String label, String amount,
      {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                fontSize: isTotal ? 16 : 14,
                color: isDiscount ? Colors.red : null,
              ),
            ),
          ),
          SizedBox(
            width: 16,
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal
                  ? Theme.of(context).primaryColor
                  : isDiscount
                      ? Colors.red
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow2600(String label, String amount) {
    return Card(
      color: Theme.of(context).primaryColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            // Version desktop / tablette large
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  ),
                  Text(
                    amount,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 25,
                      color: Theme.of(context).colorScheme.onTertiary,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Version mobile (<600px)
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              // occupe toute la largeur
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: FittedBox(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w300,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: FittedBox(
                    child: Text(
                      amount,
                      style: TextStyle(
                        fontWeight: FontWeight.w400,
                        fontSize: 25,
                        color: Theme.of(context).colorScheme.onTertiary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

// 3. CORRECTION: Améliorer le champ prix avec prix automatique
  Widget _buildPriceFieldImproved() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage du prix de base de la chambre
        if (_selectedRoom?.category.target != null) ...[
          PriceCard(
            basePrice: _selectedRoom!.category.target!.basePrice,
            seasonalMultiplier: _seasonalMultiplier,
          ),
        ],
      ],
    );
  }

// 4. CORRECTION: Améliorer _getEffectiveRoomPrice pour gérer prix auto
  double _getEffectiveRoomPrice() {
    if (_priceController.text.isNotEmpty && _isPriceManuallyEdited) {
      // Prix manuel saisi - appliquer le multiplicateur saisonnier
      return (double.tryParse(_priceController.text) ?? 0.0) *
          _seasonalMultiplier;
    } else if (_selectedRoom?.category.target != null) {
      // Prix automatique basé sur la catégorie avec multiplicateur saisonnier
      return _selectedRoom!.category.target!.basePrice * _seasonalMultiplier;
    }
    return 0.0;
  }

// 5. CORRECTION: Callback pour mise à jour automatique des totaux lors du changement de saison
  void _onSeasonalPricingChanged(SeasonalPricing? newValue) {
    setState(() {
      _selectedSeasonalPricing = newValue;
      _seasonalMultiplier = newValue?.multiplier ?? 1.0;

      // Mettre à jour le prix si pas édité manuellement
      if (!_isPriceManuallyEdited && _selectedRoom?.category.target != null) {
        _updateRoomPrice();
      }

      // Recalculer tous les prix des extras
      _updateAllExtraPrices();

      // Forcer la mise à jour de l'affichage (les totaux se mettront à jour automatiquement)
    });
  }

// 6. CORRECTION: Améliorer _updateRoomPrice pour gérer le prix automatique
  void _updateRoomPrice() {
    if (_isPriceManuallyEdited) return; // Ne pas écraser si édité manuellement

    if (_selectedRoom != null && _selectedRoom!.category.target != null) {
      final basePrice = _selectedRoom!.category.target!.basePrice;
      // NE PAS appliquer le multiplicateur ici car il sera appliqué dans _getEffectiveRoomPrice
      // _priceController.text =
      //     (basePrice * _seasonalMultiplier).toStringAsFixed(2);
      basePrice.toStringAsFixed(2);
    }
  }

  void _showExtraServicesDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          height: 500,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter Des Services Supplémentaires'.capitalize,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.provider.getExtraServicesList().length,
                  itemBuilder: (context, index) {
                    final service =
                        widget.provider.getExtraServicesList()[index];
                    if (!service.isActive) return Container();

                    return Card(
                      child: ListTile(
                        onLongPress: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ExtraServiceDetailPage(
                                    extraService: service)),
                          );
                        },
                        onTap: () {
                          _addExtraService(service);
                          Navigator.pop(context);
                        },
                        title: Text(
                          service.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              service.description,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${service.price} DA ${_getPricingUnitText(service.pricingUnit)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPricingUnitText(String unit) {
    switch (unit) {
      case 'per_person':
        return 'par personne';
      case 'per_night':
        return 'par nuit';
      case 'per_stay':
        return 'par séjour';
      default:
        return 'par article';
    }
  }

  Widget _buildDateField(icon, String label, DateTime? date,
      Function(DateTime) onDateSelected, bool departarrive) {
    return InkWell(
      onTap: () async {
        final selectedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime.now().subtract(Duration(days: 30)),
          lastDate: DateTime.now().add(Duration(days: 365)),
        );
        if (selectedDate != null) {
          onDateSelected(selectedDate);
          // Recalculer le multiplicateur saisonnier
          if (_fromDate != null && _toDate != null) {
            setState(() {
              // _seasonalMultiplier =
              //     _calculateSeasonalMultiplier(_fromDate!, _toDate!);
            });
          }
        }
      },
      child: FittedBox(
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(label,
              //     style: TextStyle(
              //         fontSize: 16,
              //         color:
              //             departarrive ? Colors.green[600] : Colors.red[600])),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                      color: departarrive ? Colors.green[600] : Colors.red[600],
                      fontSize: 16),
                  children: [
                    WidgetSpan(
                      child: Icon(
                        icon,
                        size: 16,
                        color:
                            departarrive ? Colors.green[600] : Colors.red[600],
                      ),
                      alignment: PlaceholderAlignment.middle,
                    ),
                    TextSpan(
                        text: label, style: TextStyle(fontFamily: 'oswald')),
                  ],
                ),
              ),

              SizedBox(height: 4),
              Text(
                date != null ? _formatDate(date) : 'Sélectionner',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeasonalPricingSectionm() {
    if (_seasonalPricings.isEmpty) {
      return Container();
    }

    // Si pas de dates sélectionnées, afficher toutes les saisons actives
    if (_fromDate == null || _toDate == null) {
      final activeSeasonalPricings =
          _seasonalPricings.where((s) => s.isActive).toList();

      if (activeSeasonalPricings.isEmpty) return Container();

      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarifs saisonniers disponibles',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              ...activeSeasonalPricings.map((seasonal) {
                return Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${seasonal.name} (x${seasonal.multiplier})',
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Text(
                        '${_formatDate(seasonal.startDate)} - ${_formatDate(seasonal.endDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }

    // Avec dates sélectionnées, afficher les saisons applicables
    final applicableSeasonalPricings = _seasonalPricings.where((seasonal) {
      if (!seasonal.isActive) return false;

      for (DateTime date = _fromDate!;
          date.isBefore(_toDate!.add(Duration(days: 1)));
          date = date.add(Duration(days: 1))) {
        if (seasonal.isDateInSeason(date)) {
          return true;
        }
      }
      return false;
    }).toList();

    if (applicableSeasonalPricings.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tarifs saisonniers',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.info, size: 16, color: Colors.blue),
                  SizedBox(width: 8),
                  Text(
                    'Aucun tarif saisonnier applicable pour ces dates',
                    style: TextStyle(fontSize: 14, color: Colors.blue),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tarifs saisonniers applicables',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ...applicableSeasonalPricings.map((seasonal) {
              final isApplied = (_seasonalMultiplier == seasonal.multiplier);
              return Container(
                padding: EdgeInsets.all(8),
                margin: EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isApplied ? Colors.green.shade50 : null,
                  border: Border.all(
                    color: isApplied ? Colors.green : Colors.grey.shade300,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: isApplied ? Colors.green : null,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${seasonal.name} (x${seasonal.multiplier})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              isApplied ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      '${_formatDate(seasonal.startDate)} - ${_formatDate(seasonal.endDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    if (isApplied) ...[
                      SizedBox(width: 8),
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                    ],
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text('Annuler'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveReservation,
              child: _isLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(widget.isEditing
                      ? 'Modifier la réservation'
                      : 'Créer la réservation'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Add the missing methods from your original code
  Widget _buildGuestsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Clients',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Spacer(),
                IconButton(
                  onPressed: _showAddGuestDialog,
                  icon: Icon(Icons.person_add),
                  tooltip: 'Ajouter un client',
                ),
              ],
            ),
            SizedBox(height: 16),

            // Liste des clients sélectionnés
            if (_selectedGuests.isEmpty)
              Center(
                child: Text(
                  'Aucun client ajouté',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              )
            else
              // ListView.builder(
              //   shrinkWrap: true,
              //   physics: NeverScrollableScrollPhysics(),
              //   itemCount: _selectedGuests.length,
              //   itemBuilder: (context, index) {
              //     final guest = _selectedGuests[index];
              //     return Card(
              //       margin: EdgeInsets.only(bottom: 8),
              //       child: ListTile(
              //         onTap: () {
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //               builder: (_) => ClientDetailPage(guest: guest),
              //             ),
              //           );
              //         },
              //         leading: CircleAvatar(
              //           child:
              //               Text(guest.fullName.substring(0, 1).toUpperCase()),
              //         ),
              //         title: Text(guest.fullName),
              //         subtitle: Column(
              //           crossAxisAlignment: CrossAxisAlignment.start,
              //           children: [
              //             if (guest.phoneNumber.isNotEmpty)
              //               Text('Tél: ${guest.phoneNumber}'),
              //             // if (guest.idCardNumber.isNotEmpty)
              //             //   Text('ID: ${guest.idCardNumber}'),
              //           ],
              //         ),
              //         onLongPress: () async {
              //           final action = await showDialog<String>(
              //             context: context,
              //             builder: (context) => SimpleDialog(
              //               title: const Text("Choisissez une action"),
              //               children: [
              //                 SimpleDialogOption(
              //                   onPressed: () => Navigator.pop(context, "edit"),
              //                   child: Row(
              //                     children: const [
              //                       Icon(Icons.edit, color: Colors.blue),
              //                       SizedBox(width: 8),
              //                       Text("Éditer"),
              //                     ],
              //                   ),
              //                 ),
              //                 SimpleDialogOption(
              //                   onPressed: () =>
              //                       Navigator.pop(context, "delete"),
              //                   child: Row(
              //                     children: const [
              //                       Icon(Icons.delete, color: Colors.red),
              //                       SizedBox(width: 8),
              //                       Text("Supprimer"),
              //                     ],
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           );
              //
              //           if (action == "edit") {
              //             _editGuest(index);
              //           } else if (action == "delete") {
              //             final confirm = await showDialog<bool>(
              //               context: context,
              //               builder: (context) => AlertDialog(
              //                 title: const Text("Confirmation"),
              //                 content: const Text(
              //                     "Voulez-vous vraiment supprimer ce client ?"),
              //                 actions: [
              //                   TextButton(
              //                     onPressed: () =>
              //                         Navigator.of(context).pop(false),
              //                     child: const Text("Annuler"),
              //                   ),
              //                   ElevatedButton(
              //                     onPressed: () =>
              //                         Navigator.of(context).pop(true),
              //                     child: const Text("Supprimer"),
              //                   ),
              //                 ],
              //               ),
              //             );
              //
              //             if (confirm == true) {
              //               _removeGuest(index);
              //             }
              //           }
              //         },
              //       ),
              //     );
              //   },
              // ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(_selectedGuests.length, (index) {
                  final guest = _selectedGuests[index];

                  return InputChip(
                    avatar: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        guest.fullName.substring(0, 1).toUpperCase(),
                        style:
                            const TextStyle(color: Colors.blue, fontSize: 12),
                      ),
                    ),
                    label: Text(
                      guest.fullName.capitalize,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    backgroundColor: Colors.deepPurpleAccent,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClientDetailPage(guest: guest),
                        ),
                      );
                    },
                    onDeleted: () async {
                      final action = await showDialog<String>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text("Choisissez une action"),
                          children: [
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, "edit"),
                              child: Row(
                                children: const [
                                  Icon(Icons.edit, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text("Éditer"),
                                ],
                              ),
                            ),
                            SimpleDialogOption(
                              onPressed: () => Navigator.pop(context, "delete"),
                              child: Row(
                                children: const [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text("Supprimer"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (action == "edit") {
                        _editGuest(index);
                      } else if (action == "delete") {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Confirmation"),
                            content: const Text(
                                "Voulez-vous vraiment supprimer ce client ?"),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: const Text("Annuler"),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                child: const Text("Supprimer"),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          _removeGuest(index);
                        }
                      }
                    },
                    deleteIcon: const Icon(
                      Icons.delete,
                    ),
                  );
                }),
              )
          ],
        ),
      ),
    );
  }

  void _showAddGuestDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildGuestDialog(),
    );
  }

  void _editGuest(int index) {
    _isEditingGuest = true;
    _editingGuestIndex = index;
    _guestBeingEdited = _selectedGuests[index];

    // Pré-remplir les champs
    _guestController.text = _guestBeingEdited!.fullName;
    _phoneController.text = _guestBeingEdited!.phoneNumber;
    _idCardController.text = _guestBeingEdited!.idCardNumber;

    _showAddGuestDialog();
  }

  void _removeGuest(int index) {
    setState(() {
      _selectedGuests.removeAt(index);
      _updateAllExtraPrices(); // Recalculer les prix
    });
  }

  Widget _buildGuestDialog() {
    return AlertDialog(
      title: Text(_isEditingGuest ? 'Modifier le client' : 'Ajouter un client'),
      content: Container(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _guestController,
              decoration: InputDecoration(
                labelText: 'Nom complet *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _idCardController,
              decoration: InputDecoration(
                labelText: 'Numéro de carte d\'identité',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            _clearGuestForm();
            Navigator.pop(context);
          },
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _saveGuest,
          child: Text(_isEditingGuest ? 'Modifier' : 'Ajouter'),
        ),
      ],
    );
  }

  void _saveGuest() {
    if (_guestController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Le nom du client est requis')),
      );
      return;
    }

    final guest = Guest(
      fullName: _guestController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      idCardNumber: _idCardController.text.trim(),
    );

    setState(() {
      if (_isEditingGuest && _editingGuestIndex != null) {
        _selectedGuests[_editingGuestIndex!] = guest;
      } else {
        _selectedGuests.add(guest);
      }
      _updateAllExtraPrices(); // Recalculer les prix
    });

    _clearGuestForm();
    Navigator.pop(context);
  }

  void _clearGuestForm() {
    _guestController.clear();
    _phoneController.clear();
    _idCardController.clear();
    _isEditingGuest = false;
    _editingGuestIndex = null;
    _guestBeingEdited = null;
  }

  // ============================================================================
// 5. CORRECTION - _saveReservation() complète
// ============================================================================

  // CORRECTION 8: Améliorer la sauvegarde pour inclure BoardBasis et Extras
  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoom == null) {
      _showErrorSnackBar('Veuillez sélectionner une chambre');
      return;
    }
    if (_selectedEmployee == null) {
      _showErrorSnackBar('Veuillez sélectionner un réceptionniste');
      return;
    }
    if (_selectedGuests.isEmpty) {
      _showErrorSnackBar('Veuillez ajouter au moins un client');
      return;
    }
    if (_fromDate == null || _toDate == null) {
      _showErrorSnackBar('Veuillez sélectionner les dates');
      return;
    }
    if (_fromDate!.isAfter(_toDate!) || _fromDate!.isAtSameMomentAs(_toDate!)) {
      _showErrorSnackBar(
          'La date d\'arrivée doit être antérieure à la date de départ');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Dans _saveReservation, remplacer :
      // final pricePerNight = double.tryParse(_priceController.text) ?? 0.0;

// Par :
//       final pricePerNight = _priceController.text.isNotEmpty
//           ? (double.tryParse(_priceController.text) ?? 0.0)
//           : (_selectedRoom?.category.target?.basePrice ?? 0.0);
      // Calculer le prix effectif à utiliser pour la sauvegarde
      double priceToSave;

      if (_priceController.text.isNotEmpty && _isPriceManuallyEdited) {
        // Prix manuel saisi
        priceToSave = double.tryParse(_priceController.text) ?? 0.0;
      } else if (_selectedRoom?.category.target != null) {
        // Prix automatique basé sur la catégorie + saison
        priceToSave =
            _selectedRoom!.category.target!.basePrice * _seasonalMultiplier;
      } else {
        priceToSave = 0.0;
      }
      for (final guest in _selectedGuests) {
        if (guest.id == 0) {
          final guestId = await widget.provider.addGuest(guest);
          guest.id = guestId;
        }
      }

      ReservationResult result;

      if (widget.isEditing && widget.existingReservation != null) {
        widget.existingReservation!.seasonalPricing.target =
            _selectedSeasonalPricing;

        result = await widget.provider.updateReservationComplete(
          reservation: widget.existingReservation!,
          newRoom: _selectedRoom!,
          newReceptionist: _selectedEmployee!,
          newGuests: _selectedGuests,
          newFrom: _fromDate!,
          newTo: _toDate!,
          newPricePerNight: priceToSave,
          newStatus: _status,
          newBoardBasis: _selectedBoardBasis,
          newDiscountPercent: _discountPercent,
          newDiscountAmount: _discountAmount,
        );
      } else {
        final newReservation = Reservation(
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: priceToSave,
          status: _status,
        );

        newReservation.room.target = _selectedRoom!;
        newReservation.seasonalPricing.target = _selectedSeasonalPricing;
        newReservation.guests.addAll(_selectedGuests);

        result = await widget.provider.addReservation(
          room: _selectedRoom!,
          receptionist: _selectedEmployee!,
          guests: _selectedGuests,
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: priceToSave,
          status: _status,
          boardBasis: _selectedBoardBasis,
          discountPercent: _discountPercent,
          discountAmount: _discountAmount,
          seasonalPricing:
              _selectedSeasonalPricing, // si ton provider accepte en param
        );
      }

      if (result.isSuccess && result.id != null) {
        // Sauvegarder les extras si nécessaire
        if (_selectedExtras.isNotEmpty) {
          await _saveReservationExtras(result.id!);
        }

        widget.onReservationAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Réservation modifiée avec succès'
                : 'Réservation créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (result.conflict != null) {
        _showConflictDialog(result.conflict!);
      } else {
        _showErrorSnackBar(result.error ?? 'Erreur inconnue');
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReservationForced() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final pricePerNight = double.tryParse(_priceController.text) ?? 0.0;
      final result = await widget.provider.addReservation(
        room: _selectedRoom!,
        receptionist: _selectedEmployee!,
        guests: _selectedGuests,
        from: _fromDate!,
        to: _toDate!,
        pricePerNight: pricePerNight,
        status: _status,
        boardBasis: _selectedBoardBasis,
        forceOverride: true,
        discountPercent: _discountPercent,
        discountAmount: _discountAmount,
      );

      if (result.isSuccess && result.id != null) {
        if (_selectedExtras.isNotEmpty) {
          await _saveReservationExtras(result.id!);
        }

        widget.onReservationAdded();
        Navigator.pop(context);
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text('Réservation forcée créée avec succès'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// 9. CORRECTION: Mise à jour automatique lors du changement de réduction
  void _onDiscountChanged() {
    setState(() {
      // Forcer la mise à jour de l'affichage
      // _calculateTotalPrice() sera automatiquement appelé dans _buildPricingSummary
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showConflictDialog(ReservationConflict conflict) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Conflit de réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'La chambre ${conflict.room.code} n\'est pas disponible pour ces dates.'),
            SizedBox(height: 16),
            Text('Réservations en conflit:'),
            ...conflict.conflictingReservations.map((res) =>
                Text('• ${_formatDate(res.from)} - ${_formatDate(res.to)}')),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Forcer la sauvegarde malgré le conflit
              _saveReservationForced();
            },
            child: Text('Forcer la réservation'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  void dispose() {
    _guestController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _priceController.dispose();
    _discountPercentController.dispose();
    _discountAmountController.dispose();
    super.dispose();
  }

  Future<void> _saveReservationExtras(int reservationId) async {
    try {
      // Récupérer la réservation nouvellement créée/mise à jour
      final reservation =
          widget.provider.reservations.firstWhere((r) => r.id == reservationId);

      // Sauvegarder chaque extra
      for (final extraItem in _selectedExtras) {
        final extra = ReservationExtra(
          quantity: extraItem.quantity,
          unitPrice: extraItem.unitPrice,
          totalPrice: extraItem.totalPrice,
          status: 'Confirmed',
          scheduledDate: extraItem.scheduledDate,
        );
        extra.reservation.target = reservation;
        extra.extraService.target = extraItem.extraService;

        // Sauvegarder dans ObjectBox
        await widget.provider.reservationExtraBox.put(extra);
      }
    } catch (e) {
      debugPrint('Erreur lors de la sauvegarde des extras: $e');
      _showErrorSnackBar(
          'Erreur lors de la sauvegarde des services supplémentaires');
    }
  }

  void _showDiscountDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          child: Container(
            width: 700,
            height: 700,
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  child: Text('Configuration de la réduction',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(height: 16),

                // Type de réduction
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Type de réduction:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () {
                        // Réinitialiser
                        setDialogState(() {
                          _discountPercent = 0.0;
                          _discountAmount = 0.0;
                          _discountPercentController.text = "0";
                          _discountAmountController.text = "0";
                          _discountAppliedTo = 'total';
                          _selectedDiscountItems.clear();
                        });
                      },
                      child: Text('Tout Réinitialiser',
                          style: TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      // Version desktop / tablette large
                      return Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Pourcentage'),
                              value: 'percentage',
                              groupValue: _discountType,
                              onChanged: (value) =>
                                  setDialogState(() => _discountType = value!),
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: Text('Montant fixe'),
                              value: 'amount',
                              groupValue: _discountType,
                              onChanged: (value) =>
                                  setDialogState(() => _discountType = value!),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Version mobile (<600px)
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        // adapte la hauteur à son contenu
                        children: [
                          RadioListTile<String>(
                            title: const Text('Pourcentage'),
                            value: 'percentage',
                            groupValue: _discountType,
                            onChanged: (value) =>
                                setDialogState(() => _discountType = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text('Montant fixe'),
                            value: 'amount',
                            groupValue: _discountType,
                            onChanged: (value) =>
                                setDialogState(() => _discountType = value!),
                          ),
                        ],
                      );
                    }
                  },
                ),

                SizedBox(height: 16),

                // Valeur de la réduction
                if (_discountType == 'percentage')
                  TextFormField(
                    controller: _discountPercentController,
                    decoration: InputDecoration(
                      labelText: 'Pourcentage de réduction (%)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setDialogState(() {
                      _discountPercent = double.tryParse(value) ?? 0.0;
                      _discountAmount = 0.0;
                      _discountAmountController.text = "0";
                    }),
                  )
                else
                  TextFormField(
                    controller: _discountAmountController,
                    decoration: InputDecoration(
                      labelText: 'Montant de réduction (DA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => setDialogState(() {
                      _discountAmount = double.tryParse(value) ?? 0.0;
                      _discountPercent = 0.0;
                      _discountPercentController.text = "0";
                    }),
                  ),

                SizedBox(height: 16),

                // Application de la réduction
                Text('Appliquer la réduction sur:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RadioListTile<String>(
                          title: Text('Chambre'),
                          value: 'room',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        RadioListTile<String>(
                          title: Text(
                            'Pension',
                            overflow: TextOverflow.ellipsis,
                          ),
                          value: 'board',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        RadioListTile<String>(
                          title: Text('Services Supplément'),
                          value: 'extras',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        RadioListTile<String>(
                          title: Text('Total général'),
                          value: 'total',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),
                        RadioListTile<String>(
                          title: Text('Éléments spécifiques'),
                          value: 'specific',
                          groupValue: _discountAppliedTo,
                          onChanged: (value) =>
                              setDialogState(() => _discountAppliedTo = value!),
                        ),

                        // Sélection spécifique si nécessaire
                        if (_discountAppliedTo == 'specific') ...[
                          Divider(),
                          Text('Sélectionnez les éléments:',
                              style: TextStyle(fontWeight: FontWeight.bold)),

                          // Chambre
                          if (_selectedRoom != null)
                            CheckboxListTile(
                              title: Text('Chambre (${_selectedRoom!.code})'),
                              subtitle: Text(
                                  'Prix: ${(double.tryParse(_priceController.text) ?? 0.0 * _seasonalMultiplier).toStringAsFixed(2)}/nuit'),
                              value: _selectedDiscountItems.contains('room'),
                              onChanged: (bool? value) => setDialogState(() {
                                if (value == true) {
                                  _selectedDiscountItems.add('room');
                                } else {
                                  _selectedDiscountItems.remove('room');
                                }
                              }),
                            ),

                          // Plan de pension
                          if (_selectedBoardBasis != null)
                            CheckboxListTile(
                              title: Text(
                                  'Plan de pension (${_selectedBoardBasis!.name})'),
                              subtitle: Text(
                                  'Prix: ${_selectedBoardBasis!.pricePerPerson.toStringAsFixed(2)}/personne/nuit'),
                              value: _selectedDiscountItems.contains('board'),
                              onChanged: (bool? value) => setDialogState(() {
                                if (value == true) {
                                  _selectedDiscountItems.add('board');
                                } else {
                                  _selectedDiscountItems.remove('board');
                                }
                              }),
                            ),

                          // Services supplémentaires
                          ..._selectedExtras.map((extra) {
                            final itemId = 'extra_${extra.extraService.id}';
                            return CheckboxListTile(
                              title: Text(extra.extraService.name),
                              subtitle: Text(
                                  'Prix total: ${extra.totalPrice.toStringAsFixed(2)}'),
                              value: _selectedDiscountItems.contains(itemId),
                              onChanged: (bool? value) => setDialogState(() {
                                if (value == true) {
                                  _selectedDiscountItems.add(itemId);
                                } else {
                                  _selectedDiscountItems.remove(itemId);
                                }
                              }),
                            );
                          }).toList(),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 16),

                // Aperçu de la réduction
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aperçu:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(_getDiscountPreview()),
                    ],
                  ),
                ),
                SizedBox(
                  height: 16,
                ),
                // Boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Annuler'),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        _onDiscountChanged();
                        Navigator.pop(context);
                      },
                      child: Text('Appliquer'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getDiscountPreview() {
    if (_discountPercent == 0 && _discountAmount == 0) {
      return 'Aucune réduction configurée';
    }

    String discountText = _discountType == 'percentage'
        ? '${_discountPercent.toStringAsFixed(1)}%'
        : '${_discountAmount.toStringAsFixed(2)}';

    String appliedText = _getDiscountAppliedToLabel();

    return 'Réduction de $discountText appliquée sur: $appliedText';
  }
}

// class SeasonalPricingDropdown extends StatelessWidget {
//   final SeasonalPricing? selectedValue;
//   final Function(SeasonalPricing?)? onChanged;
//   final List<SeasonalPricing>? customSeasonalPricings;
//   final bool useLocalState;
//
//   const SeasonalPricingDropdown({
//     super.key,
//     this.selectedValue,
//     this.onChanged,
//     this.customSeasonalPricings,
//     this.useLocalState = false,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Consumer<HotelProvider>(
//       builder: (_, provider, __) {
//         final list = provider.seasonalPricing;
//         final selected = provider.selectedSeasonalPricing;
//
//         // 1. Élimine les doublons de la liste
//         final unique = <int, SeasonalPricing>{};
//         for (final sp in list) {
//           unique.putIfAbsent(sp.id, () => sp);
//         }
//         final uniqueList = unique.values.toList();
//
//         // 2. Cherche la bonne instance dans la liste unique
//         // C'est la correction clé. Au lieu de simplement vérifier si l'ID existe,
//         // nous trouvons l'objet réel dans `uniqueList` qui correspond à l'ID de `selected`.
//         // Cela garantit que l'objet passé à `value` est une instance qui existe dans `items`.
//         SeasonalPricing? validValue;
//         if (selected != null) {
//           try {
//             validValue =
//                 uniqueList.firstWhere((item) => item.id == selected.id);
//           } catch (e) {
//             // Si l'élément sélectionné n'est plus dans la liste (par exemple, après un filtre),
//             // la valeur doit être nulle pour éviter une erreur.
//             validValue = null;
//           }
//         }
//
//         return Padding(
//           padding: const EdgeInsets.all(8.0),
//           child: DropdownButtonFormField<SeasonalPricing>(
//             // Utilise l'instance trouvée dans la liste unique
//             value: validValue,
//             isExpanded: true,
//             decoration: InputDecoration(
//               labelText: 'Tarif saisonnier',
//               prefixIcon: const Icon(Icons.calendar_today),
//               border:
//                   OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             ),
//             items: uniqueList
//                 .map((sp) => DropdownMenuItem(
//                       value: sp,
//                       child: Text('${sp.name} - ${sp.multiplier}x'),
//                     ))
//                 .toList(),
//             // onChanged: (v) =>
//             //     provider.setSelectedSeasonalPricing(provider.currentHotel!, v),
//             onChanged: (SeasonalPricing? v) {
//               if (onChanged != null) {
//                 // Utiliser le callback personnalisé
//                 onChanged!(v);
//               } else {
//                 // Comportement par défaut
//                 provider.setSelectedSeasonalPricing(provider.currentHotel!, v);
//               }
//             },
//           ),
//         );
//       },
//     );
//   }
// }

class ReservationExtraItem {
  final ExtraService extraService;
  int quantity;
  double unitPrice;
  double totalPrice;
  DateTime? scheduledDate;
  String? notes;

  ReservationExtraItem({
    required this.extraService,
    this.quantity = 1,
    required this.unitPrice,
    this.totalPrice = 0.0,
    this.scheduledDate,
    this.notes,
  });
}

class SeasonalPricingDropdown extends StatelessWidget {
  final SeasonalPricing? selectedValue;
  final Function(SeasonalPricing?)? onChanged;
  final List<SeasonalPricing>? customSeasonalPricings;
  final bool useLocalState;
  final bool autoSave;

  const SeasonalPricingDropdown({
    super.key,
    this.selectedValue,
    this.onChanged,
    this.customSeasonalPricings,
    this.useLocalState = false,
    this.autoSave = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (context, provider, child) {
        // Utiliser les tarifs personnalisés si fournis, sinon ceux du provider
        final list = customSeasonalPricings ?? provider.getSeasonalPricings();

        // Utiliser la valeur sélectionnée personnalisée si fournie, sinon celle du provider
        final selected =
            useLocalState ? selectedValue : provider.selectedSeasonalPricing;

        // Éliminer les doublons de la liste
        final uniqueMap = <int, SeasonalPricing>{};
        for (final sp in list) {
          uniqueMap[sp.id] = sp;
        }
        final uniqueList = uniqueMap.values.toList();

        // Trier par priorité puis par nom
        uniqueList.sort((a, b) {
          final priorityComparison = b.priority.compareTo(a.priority);
          if (priorityComparison != 0) return priorityComparison;
          return a.name.compareTo(b.name);
        });

        // Trouver la bonne instance dans la liste unique
        SeasonalPricing? validValue;
        if (selected != null) {
          try {
            validValue =
                uniqueList.firstWhere((item) => item.id == selected.id);
          } catch (e) {
            // Si l'élément sélectionné n'est plus dans la liste
            validValue = null;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(0.0),
          child: DropdownButtonFormField<SeasonalPricing>(
            style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
                fontFamily: 'OSWALD'),
            value: validValue,
            isExpanded: true,
            isDense: false,
            decoration: InputDecoration(
              labelText: 'Tarif saisonnier',
              // prefixIcon: const Icon(Icons.calendar_today),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: uniqueList.map((sp) {
              return DropdownMenuItem(
                value: sp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Centrer verticalement
                  children: [
                    FittedBox(
                      child: Text(
                        '${sp.name} (${sp.multiplier}x)',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      _formatDateRange(sp),
                      style: const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            selectedItemBuilder: (context) {
              return uniqueList.map((sp) {
                return SizedBox(
                  // ✅ Contraint la hauteur affichée
                  height: 50, // Ajuste selon le design (par défaut 48px)
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${sp.name} (${sp.multiplier}x)',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        _formatDateRange(sp),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
            onChanged: (SeasonalPricing? newValue) {
              if (newValue == null) return;

              if (onChanged != null) {
                onChanged!(newValue);
              } else if (provider.currentHotel != null) {
                _handleSeasonChange(context, provider, newValue);
              }
            },
            validator: (value) {
              if (value == null) {
                return 'Veuillez sélectionner un tarif saisonnier';
              }
              return null;
            },
          ),
        );
      },
    );
  }

  /// Gère le changement de saison de manière asynchrone
  void _handleSeasonChange(
      BuildContext context, HotelProvider provider, SeasonalPricing newValue) {
    provider
        .setSelectedSeasonalPricing(
      provider.currentHotel!,
      newValue,
      autoSave: autoSave,
    )
        .then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saison "${newValue.name}" sélectionnée'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      }
    }).catchError((error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  String _formatDateRange(SeasonalPricing sp) {
    final startFormatted =
        '${sp.startDate.day}/${sp.startDate.month}/${sp.startDate.year}';
    final endFormatted =
        '${sp.endDate.day}/${sp.endDate.month}/${sp.endDate.year}';
    return '$startFormatted - $endFormatted';
  }

  String _getSeasonInfo(SeasonalPricing sp) {
    final now = DateTime.now();
    final isCurrentlyActive = sp.isDateInSeason(now);

    if (isCurrentlyActive) {
      return '✓ Saison active - ${_formatDateRange(sp)}';
    } else {
      return _formatDateRange(sp);
    }
  }
}

/// Widget pour afficher un indicateur de la saison actuelle
class CurrentSeasonIndicator extends StatelessWidget {
  const CurrentSeasonIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (context, provider, child) {
        final currentSeason = provider.selectedSeasonalPricing;

        if (currentSeason == null) {
          return Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text('Aucune saison sélectionnée',
                    style: TextStyle(fontSize: 12)),
              ],
            ),
          );
        }

        final now = DateTime.now();
        final isActive = currentSeason.isDateInSeason(now);

        return Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.shade100 : Colors.orange.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.schedule,
                size: 16,
                color: isActive ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(
                '${currentSeason.name} (${currentSeason.multiplier}x)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
