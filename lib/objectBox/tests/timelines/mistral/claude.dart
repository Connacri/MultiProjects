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
import 'ReservationDialogContent.dart';
import 'claude_crud.dart';
import 'home_Hotel.dart';
import 'reservationDetailView.dart';

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
            'ATTENTION: Réservation pour chambre ${room
                .code} non trouvée dans la liste');
        return false;
      }

      return true;
    }).toList();

    // debugPrint(
    //     'DataSource: ${validReservations.length} réservations valides sur ${reservations.length}');

    appointments = validReservations;

    resources = rooms
        .map((room) =>
        CalendarResource(
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
        reservation.to
            .difference(reservation.from)
            .inDays;

    return '$guestName\nNuitée : ${reservation.pricePerNight.toStringAsFixed(
        2)} DA\nTotal : ${totalPrice.toStringAsFixed(
        2)} DA\nStatus : ${reservation.status}';
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
                SnackBar(
                    content:
                    Text("Calibrage Saison Actuelle : ${seasonal.name}")),
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
          itemBuilder: (context) =>
          [
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
          itemBuilder: (context) =>
          [
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
      builder: (context) =>
          AlertDialog(
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
                  if (nameController.text
                      .trim()
                      .isEmpty) {
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
      builder: (context) =>
          AlertDialog(
            title: const Text('Supprimer l\'hôtel'),
            content: Text(
                'Êtes-vous sûr de vouloir supprimer l\'hôtel "${hotel
                    .name}" ?'),
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
              color: Theme
                  .of(context)
                  .primaryColor
                  .withOpacity(0.7),
            ),
            const SizedBox(height: 32),
            Text(
              'Bienvenue !',
              style: Theme
                  .of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Créez votre premier hôtel pour commencer à gérer vos réservations',
              textAlign: TextAlign.center,
              style: Theme
                  .of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(
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
      builder: (context) =>
          AlertDialog(
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
                  if (nameController.text
                      .trim()
                      .isEmpty) {
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

  Future<void> createHotel(HotelProvider provider,
      String name,
      int floors,
      int roomsPerFloor,
      List<String> avoidedNumbers,
      BuildContext context,) async {
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

  Widget _appointmentBuilder(BuildContext context,
      CalendarAppointmentDetails details) {
    if (details.appointments.isEmpty) return Container();
    final reservation = details.appointments.first as Reservation;
    final nights = reservation.to
        .difference(reservation.from)
        .inDays;
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
      builder: (context) =>
          AlertDialog(
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
                    avoidedController.text
                        .split(',')
                        .map((e) => e.trim())
                        .toList(),
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
      builder: (dialogContext) =>
          ChangeNotifierProvider.value(
            value: context.read<HotelProvider>(),
            child: Dialog(
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width < 600
                    ? MediaQuery
                    .of(context)
                    .size
                    .width
                    : MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery
                        .of(context)
                        .size
                        .height * 0.9),
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
                ),
              ),
            ),
          ),
    );
  }

  void ReservationDetailViewDialog(
      [Room? preselectedRoom, DateTime? preselectedDate]) {
    final provider = Provider.of<HotelProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          ChangeNotifierProvider.value(
            value: context.read<HotelProvider>(),
            child: Dialog(
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width < 600
                    ? MediaQuery
                    .of(context)
                    .size
                    .width
                    : MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery
                        .of(context)
                        .size
                        .height * 0.9),
                child: ReservationDetailView(
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
                ),
              ),
            ),
          ),
    );
  }

  void _showEditOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) =>
          Container(
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
      builder: (context) =>
          AlertDialog(
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
                          '${provider.getRoomNameForReservation(
                              reservation)} - ${_formatDate(
                              reservation.from)} → ${_formatDate(
                              reservation.to)}',
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
      builder: (dialogContext) =>
          AlertDialog(
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
                  'Période: ${_formatDate(reservation.from)} → ${_formatDate(
                      reservation.to)}',
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
                  final success = await provider.deleteReservation(
                      reservation.id);

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
      builder: (dialogContext) =>
          ChangeNotifierProvider.value(
            value: context.read<HotelProvider>(),
            child: Dialog(
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery
                        .of(context)
                        .size
                        .height * 0.8),
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
                ),
              ),
            ),
          ),
    );
  }

  void showViewReservationDialog(Reservation reservation) {
    final provider = Provider.of<HotelProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) =>
          ChangeNotifierProvider.value(
            value: context.read<HotelProvider>(),
            child: Dialog(
              shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: MediaQuery
                    .of(context)
                    .size
                    .width * 0.8,
                constraints: BoxConstraints(
                    maxHeight: MediaQuery
                        .of(context)
                        .size
                        .height * 0.8),
                child: ReservationDetailView(
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
                ),
              ),
            ),
          ),
    );
  }

  // ========================= GESTIONNAIRES D'ÉVÉNEMENTS =========================

  void _onCalendarTap(CalendarTapDetails details) {
    Room? room;
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final reservation = details.appointments!.first as Reservation;
      //_showReservationDetails(reservation);
      showViewReservationDialog(reservation);
    } else if (details.targetElement == CalendarElement.calendarCell) {
      String? roomNumber = details.resource?.displayName;
      // ✅ Handle the case where no room is found

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
    final nights = reservation.to
        .difference(reservation.from)
        .inDays;
    final totalPrice = reservation.pricePerNight * nights;

    // 🔹 Récupération de la chambre liée
    final roomCode = reservation.room.target?.code ?? "N/A";

    showDialog(
      context: context,
      builder: (context) =>
          Dialog(
            insetPadding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 24),
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
                          color: Theme
                              .of(context)
                              .primaryColorDark,
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
                            reservation.guests.map((g) => g.fullName).join(
                                ", "),
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
                                        borderRadius:
                                        BorderRadius.circular(16),
                                        border: Border.all(
                                            color: Colors.white
                                                .withOpacity(0.3)),
                                      ),
                                      child: ReservationExtrasList(
                                        extras: reservation.extras,
                                        reservation: reservation,
                                      )

                                    // ListView.builder(
                                    //   shrinkWrap: true,
                                    //   physics:
                                    //       const NeverScrollableScrollPhysics(),
                                    //   itemCount: reservation.extras.length,
                                    //   itemBuilder: (context, index) {
                                    //     final extra =
                                    //         reservation.extras[index];
                                    //     return Tooltip(
                                    //       message:
                                    //           extra.extraService.target!.name,
                                    //       child: ListTile(
                                    //         onTap: () => Navigator.push(
                                    //           context,
                                    //           MaterialPageRoute(
                                    //             builder: (context) =>
                                    //                 ExtraServiceDetailPage(
                                    //               reservationExtra: extra,
                                    //             ),
                                    //           ),
                                    //         ),
                                    //         leading: const Icon(Icons.check,
                                    //             color: Colors.green),
                                    //         title: Text(
                                    //           extra.extraService.target!.name,
                                    //           overflow: TextOverflow.ellipsis,
                                    //           // texte visible
                                    //         ),
                                    //         trailing: Text(
                                    //             "${extra.extraService.target!.price.toStringAsFixed(2)} DA"),
                                    //         dense: true,
                                    //       ),
                                    //     );
                                    //   },
                                    // ),
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
                          Text(reservation.discountAmount.toString()),
                          Text(reservation.discountPercent.toString()),
                          // Exemple dans une colonne ou une carte de réservation
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Réservation #${reservation.id}"),
                              Text(
                                  "Prix total: ${reservation.totalPrice
                                      .toStringAsFixed(2)} DA"),
                              SizedBox(height: 8),
                              buildDiscountInfo(reservation),
                              // 👉 Affiche les infos réduction
                            ],
                          ),

                          const SizedBox(height: 16),
                          // 🔹 Saison appliquée
                          BentoCard(
                              season: reservation.seasonalPricing.target!),
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
                            "🎉 Félicitations ${reservation.guests.map((g) =>
                            g.fullName).join(", ")} 🎉",
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

  Widget buildDiscountInfo(Reservation reservation) {
    String discountType;

    if (reservation.discountPercent > 0 && reservation.discountAmount == 0) {
      discountType = "Réduction en %";
    } else if (reservation.discountAmount > 0 &&
        reservation.discountPercent == 0) {
      discountType = "Réduction en montant fixe";
    } else if (reservation.discountAmount > 0 &&
        reservation.discountPercent > 0) {
      discountType = "Mixte (montant + %)";
    } else {
      discountType = "Aucune réduction";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Montant: ${reservation.discountAmount.toStringAsFixed(2)} DA"),
        Text(
            "Pourcentage: ${reservation.discountPercent.toStringAsFixed(1)} %"),
        Text("Type: $discountType"),
      ],
    );
  }

// Section pour l'en-tête (client et chambre)
  Widget _buildHeaderSection(Reservation reservation, String clientName,
      String roomName) {
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
                        )
                          ..layout();

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
                                  builder: (_) =>
                                      AlertDialog(
                                        title: const Text("Tous les clients"),
                                        content: SizedBox(
                                          width: double.maxFinite,
                                          child: ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: reservation.guests
                                                .length,
                                            itemBuilder: (context, index) {
                                              final g = reservation
                                                  .guests[index];
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
                                                title: Text(
                                                    g.fullName.capitalize),
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
  Widget _buildPricingSection(int nights, double pricePerNight,
      double totalPrice) {
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
            width: isHeader ? 85 : 100,
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
                color: isHighlighted ? Theme
                    .of(context)
                    .primaryColor : null,
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
              color: Theme
                  .of(context)
                  .primaryColor,
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
      builder: (context) =>
          Container(
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
                  title: Text('View Details'),
                  onTap: () {
                    Navigator.pop(context);
                    //showEditReservationDialog(reservation);
                    showViewReservationDialog(reservation);
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
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
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
                            "Multiplicateur: ${sp.multiplier}x\n${sp.startDate
                                .toLocal()} → ${sp.endDate.toLocal()}"),
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
                          "Multiplicateur: ${sp.multiplier}x\n${sp.startDate
                              .toLocal()} → ${sp.endDate.toLocal()}"),
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
                        color: Theme
                            .of(context)
                            .primaryColorLight,
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
                              color: Theme
                                  .of(context)
                                  .primaryColorLight,
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
                              color: Theme
                                  .of(context)
                                  .primaryColorLight,
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
