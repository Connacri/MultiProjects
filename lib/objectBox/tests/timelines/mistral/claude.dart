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
          onPressed: () async {
            final provider = Provider.of<HotelProvider>(context, listen: false);
            await provider.autoSelectSeasonalPricing(_currentHotel!);
          },
          tooltip: "Sélectionner la saison actuelle",
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

  Widget _buildRoomStatusLegend() {
    final legendItems = [
      {
        "color": Colors.white,
        "label": "Libre",
        "icon": Icons.bed_outlined,
        "iconColor": Colors.grey.shade600,
      },
      {
        "color": Colors.green.shade100,
        "label": "Occupée",
        "icon": Icons.bed_rounded,
        "iconColor": Colors.green.shade700,
      },
      {
        "color": Colors.blue.shade100,
        "label": "En attente",
        "icon": Icons.schedule_rounded,
        "iconColor": Colors.blue.shade700,
      },
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 16,
        runSpacing: 8,
        children: legendItems.map((item) {
          return _buildLegendItem(
            item["color"] as Color,
            item["label"] as String,
            item["icon"] as IconData,
            item["iconColor"] as Color,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLegendItem(
      Color bgColor, String label, IconData icon, Color iconColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(color: iconColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: iconColor.withOpacity(0.15),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ],
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
          width: 350,
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
                        reservation.guests.map((g) => g.fullName).join(", "),
                        roomCode, // ✅ Correction : on passe le code de la chambre
                      ),
                      const SizedBox(height: 16),

                      // Timeline du séjour
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 28.0),
                        child: _buildReservationTimeline(
                          reservation.from,
                          reservation.to,
                          nights,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Détails tarifaires
                      _buildPricingSection(
                        nights,
                        reservation.pricePerNight,
                        totalPrice,
                      ),
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
                    children: [
                      Text(
                        "🎉 Félicitations ${reservation.guests.map((g) => g.fullName).join(", ")} 🎉",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
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
  Widget _buildHeaderSection(String clientName, String roomName) {
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
            _buildDetailRow('Client', clientName, isHeader: true),
            SizedBox(height: 8),
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
      case 'confirmé':
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

    return Row(
      children: [
        Icon(statusIcon, color: statusColor),
        SizedBox(width: 8),
        Text(
          'Statut: ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          status,
          style: TextStyle(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

// Ligne de détail générique
  Widget _buildDetailRow(String label, String value,
      {bool isHeader = false, bool isHighlighted = false, IconData? icon}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(icon, size: 20, color: Colors.grey.shade600),
            ),
          SizedBox(
            width: isHeader ? 80 : 100,
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
        Text(
          "Durée du séjour $nights Nuitées",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            // Check-in
            Column(
              children: [
                Icon(Icons.login_rounded,
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
                Icon(Icons.logout_rounded,
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
            child: SeasonalAppBar()

            // child: Padding(
            //   padding: const EdgeInsets.fromLTRB(8, 12, 20, 12),
            //   child: Text.rich(
            //     TextSpan(
            //       children: [
            //         TextSpan(
            //           text: "${_currentHotel?.name ?? 'Mon'} Hôtel ",
            //           style: TextStyle(
            //             fontSize: 25,
            //             fontWeight: FontWeight.bold,
            //             color: Theme.of(context).primaryColorLight,
            //           ),
            //         ),
            //         TextSpan(
            //           text: selected != null
            //               ? "${selected.name} - x${selected.multiplier.toStringAsFixed(2)} "
            //               : "",
            //           style: TextStyle(
            //             fontSize: 23,
            //             fontWeight: FontWeight.w200,
            //             color: Theme.of(context).primaryColorLight,
            //           ),
            //         ),
            //         TextSpan(
            //           children: [
            //             if (selected != null) ...[
            //               WidgetSpan(
            //                 child: Icon(Icons.play_arrow,
            //                     size: 20, color: Colors.greenAccent),
            //               ),
            //               TextSpan(
            //                 text:
            //                     " ${dateFormatter.format(selected.startDate)}  ",
            //                 style: TextStyle(
            //                   fontSize: 18,
            //                   fontWeight: FontWeight.w400,
            //                   color: Theme.of(context).primaryColorLight,
            //                 ),
            //               ),
            //               WidgetSpan(
            //                 child: Icon(Icons.arrow_forward,
            //                     size: 20, color: Colors.white70),
            //               ),
            //               WidgetSpan(
            //                 child: Icon(Icons.flag,
            //                     size: 20, color: Colors.redAccent),
            //               ),
            //               TextSpan(
            //                 text: " ${dateFormatter.format(selected.endDate)}",
            //                 style: TextStyle(
            //                   fontSize: 18,
            //                   fontWeight: FontWeight.w400,
            //                   color: Theme.of(context).primaryColorLight,
            //                 ),
            //               ),
            //             ],
            //           ],
            //         )
            //       ],
            //     ),
            //   ),
            // ),
            );
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
                    TextSpan(
                      text: "${_currentHotel?.name ?? 'Mon'} Hôtel ",
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColorLight,
                      ),
                    ),
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
                    // TextSpan(
                    //   children: [
                    //     if (selected != null) ...[
                    //       WidgetSpan(
                    //         child: Icon(Icons.play_arrow,
                    //             size: 20, color: Colors.greenAccent),
                    //       ),
                    //       TextSpan(
                    //         text:
                    //             " ${dateFormatter.format(selected.startDate)}  ",
                    //         style: TextStyle(
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.w400,
                    //           color: Theme.of(context).primaryColorLight,
                    //         ),
                    //       ),
                    //       WidgetSpan(
                    //         child: Icon(Icons.arrow_forward,
                    //             size: 20, color: Colors.white70),
                    //       ),
                    //       WidgetSpan(
                    //         child: Icon(Icons.flag,
                    //             size: 20, color: Colors.redAccent),
                    //       ),
                    //       TextSpan(
                    //         text: " ${dateFormatter.format(selected.endDate)}",
                    //         style: TextStyle(
                    //           fontSize: 18,
                    //           fontWeight: FontWeight.w400,
                    //           color: Theme.of(context).primaryColorLight,
                    //         ),
                    //       ),
                    //     ],
                    //   ],
                    // )
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

  final List<String> _statuses = [
    "Confirmée",
    "En attente",
    "Arrivé",
    "Parti",
    "Annulée"
  ];

  List<SeasonalPricing> _seasonalPricings = [];
  double _seasonalMultiplier = 1.0;

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
    _seasonalPricings = widget.seasonalPricings;
    _preselectSeasonalByToday();

    if (widget.isEditing && widget.existingReservation != null) {
      _initializeForEdit();
    } else {
      _initializeForNew();
    }

    // Calculer le multiplicateur saisonnier dès l'initialisation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_fromDate != null && _toDate != null) {
        setState(() {
          _seasonalMultiplier =
              _calculateSeasonalMultiplier(_fromDate!, _toDate!);
          _updateRoomPrice(); // Nouveau: mettre à jour le prix de la chambre
        });
      }
    });
    _priceController = TextEditingController();
    // Initialiser le prix uniquement si nécessaire
    if (widget.isEditing && widget.existingReservation != null) {
      _priceController.text =
          widget.existingReservation!.pricePerNight.toString();
    } else if (_selectedRoom != null) {
      _updateRoomPrice(); // Calculer le prix initial
    }
    // Ajouter dans initState() après l'initialisation des autres contrôleurs
    _discountPercentController.text = "0";
    _discountAmountController.text = "0";

    if (widget.isEditing && widget.existingReservation != null) {
      // Après l'initialisation du prix
      _discountPercent = widget.existingReservation!.discountPercent;
      _discountAmount = widget.existingReservation!.discountAmount;
      _discountPercentController.text = _discountPercent.toString();
      _discountAmountController.text = _discountAmount.toString();
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

  // NOUVEAU: Méthode pour mettre à jour le prix de la chambre
  // void _updateRoomPrice() {
  //   if (_isPriceManuallyEdited) return; // Ne pas écraser si édité manuellement
  //   if (_selectedRoom != null && _selectedRoom!.category.target != null) {
  //     final basePrice = _selectedRoom!.category.target!.basePrice;
  //     final seasonalMultiplier = _selectedSeasonalPricing?.multiplier ?? 1.0;
  //     final effectivePrice = basePrice * seasonalMultiplier;
  //     _priceController.text = effectivePrice.toStringAsFixed(2);
  //   }
  // }

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
                              // onChanged: (SeasonalPricing? newValue) {
                              //   setState(() {
                              //     _selectedSeasonalPricing = newValue;
                              //     _seasonalMultiplier =
                              //         newValue?.multiplier ?? 1.0;
                              //
                              //     // Mettre à jour le prix si pas édité manuellement
                              //     if (!_isPriceManuallyEdited) {
                              //       _updateRoomPrice();
                              //     }
                              //
                              //     _updateAllExtraPrices();
                              //   });
                              // },
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
        padding: EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix de base de la chambre
                  // if (_selectedRoom?.category.target != null)
                  //   Padding(
                  //     padding: const EdgeInsets.only(bottom: 8),
                  //     child: Text(
                  //       'Prix de base chambre: ${_selectedRoom!.category.target!.basePrice.toStringAsFixed(2)} /nuit',
                  //       style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                  //     ),
                  //   ),

                  // Champ prix par nuit réservation
                  // TextFormField(
                  //   controller: _priceController,
                  //   decoration: InputDecoration(
                  //     labelText: 'Prix réservation/nuit (DA)',
                  //     hintText: _selectedRoom?.category.target != null
                  //         ? 'Laisser vide pour prix auto (${(_selectedRoom!.category.target!.basePrice * _seasonalMultiplier).toStringAsFixed(2)} DA)'
                  //         : 'Entrer le prix',
                  //     prefixIcon: const Icon(Icons.attach_money),
                  //     border: OutlineInputBorder(
                  //       borderRadius: BorderRadius.circular(10),
                  //     ),
                  //   ),
                  //   keyboardType: TextInputType.number,
                  //   onChanged: (value) {
                  //     _isPriceManuallyEdited = value.isNotEmpty;
                  //     _updateAllExtraPrices();
                  //     setState(() {}); // refresh totaux
                  //   },
                  //   validator: (value) {
                  //     if ((value == null || value.isEmpty) &&
                  //         _selectedRoom?.category.target != null) {
                  //       return null; // prix auto utilisé
                  //     }
                  //     if (value == null || value.isEmpty) return 'Prix requis';
                  //     if (double.tryParse(value) == null)
                  //       return 'Prix invalide';
                  //     return null;
                  //   },
                  // ),

                  const SizedBox(height: 8),

                  // Champs supplémentaires (prix amélioré)
                  // _buildPriceFieldImproved(),
                  _buildPriceSection(),
                  const SizedBox(height: 32),
                  // Affichage du prix effectif avec saison
                  // if (_selectedSeasonalPricing != null &&
                  //     _seasonalMultiplier != 1.0)
                  //   Padding(
                  //     padding: const EdgeInsets.only(top: 6, bottom: 12),
                  //     child: Text(
                  //       'Prix avec saison (x${_seasonalMultiplier}): ${_getEffectiveRoomPrice().toStringAsFixed(2)}/nuitée',
                  //       style: TextStyle(
                  //         fontSize: 13,
                  //         color: Colors.blue[700],
                  //         fontWeight: FontWeight.w600,
                  //       ),
                  //     ),
                  //   ),

                  // Dropdown Statut
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
    final String aug = _seasonalMultiplier > 0 ? 'Augmente de ' : 'Diminue de ';
    final String sign = _seasonalMultiplier > 0 ? '+' : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Affichage du prix de base de la chambre
        if (_selectedRoom?.category.target != null) ...[
          FittedBox(
            child: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Text(
                'Prix de base: ${_selectedRoom!.category.target!.basePrice.toStringAsFixed(2)}/nuitée',
                style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w400),
              ),
            ),
          ),
          // Affichage du prix avec saison si applicable
          if (_selectedSeasonalPricing != null && _seasonalMultiplier != 1.0)
            FittedBox(
              child: Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Prix de saison (${((_seasonalMultiplier * 100) - 100).toStringAsFixed(2)}%): ${(_selectedRoom!.category.target!.basePrice * _seasonalMultiplier).toStringAsFixed(2)}/nuitée',
                  style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[600],
                      fontWeight: FontWeight.w400),
                ),
              ),
            ),
        ],

        // Champ de saisie du prix
        TextFormField(
          controller: _priceController,
          decoration: InputDecoration(
            labelText: 'Prix réservation/nuit (DA)',
            hintText: _selectedRoom?.category.target != null
                ? 'Laisser vide pour prix auto (${(_selectedRoom!.category.target!.basePrice * _seasonalMultiplier).toStringAsFixed(2)})'
                : 'Entrer le prix',
            prefixIcon: Icon(Icons.attach_money),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            helperText: 'Laissez vide pour utiliser le prix automatique',
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            setState(() {
              _isPriceManuallyEdited = value.isNotEmpty;
              _updateAllExtraPrices();
            });
          },
          validator: (value) {
            // Permettre vide si on a une chambre sélectionnée (prix auto)
            if ((value == null || value.isEmpty) &&
                _selectedRoom?.category.target != null) {
              return null;
            }
            if (value == null || value.isEmpty) return 'Prix requis';
            if (double.tryParse(value) == null) return 'Prix invalide';
            return null;
          },
        ),
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
      _priceController.text = basePrice.toStringAsFixed(2);
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
              _seasonalMultiplier =
                  _calculateSeasonalMultiplier(_fromDate!, _toDate!);
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

  Widget _buildSeasonalPricingSection23() {
    // Liste à afficher selon le contexte
    final List<SeasonalPricing> toShow = _fromDate == null || _toDate == null
        ? _seasonalPricings.where((s) => s.isActive).toList()
        : _seasonalPricings.where((s) {
            if (!s.isActive) return false;
            for (DateTime d = _fromDate!;
                d.isBefore(_toDate!.add(const Duration(days: 1)));
                d = d.add(const Duration(days: 1))) {
              if (s.isDateInSeason(d)) return true;
            }
            return false;
          }).toList();

    if (toShow.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _fromDate == null || _toDate == null
                ? 'Aucun tarif saisonnier disponible'
                : 'Aucun tarif saisonnier applicable pour ces dates',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tarifs saisonniers',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...toShow.map((seasonal) {
              final isSelected = _selectedSeasonalPricing?.id == seasonal.id;
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedSeasonalPricing = isSelected ? null : seasonal;
                    _seasonalMultiplier =
                        _selectedSeasonalPricing?.multiplier ?? 1.0;
                  });
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? Colors.green.shade50 : Colors.grey.shade50,
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_on
                            : Icons.radio_button_off,
                        color: isSelected ? Colors.green : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              seasonal.name,
                              style: TextStyle(
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              '${_formatDate(seasonal.startDate)} – ${_formatDate(seasonal.endDate)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '× ${seasonal.multiplier}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.green : Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSeasonalPricingSection24() {
    return Column(
      children: _seasonalPricings.map((seasonal) {
        final isSelected = _selectedSeasonalPricing?.id == seasonal.id;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedSeasonalPricing = isSelected ? null : seasonal;
              _seasonalMultiplier = _selectedSeasonalPricing?.multiplier ?? 1.0;
            });
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_on : Icons.radio_button_off,
                  color: isSelected ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(seasonal.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                      Text(
                        '${_formatDate(seasonal.startDate)} – ${_formatDate(seasonal.endDate)}',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  '× ${seasonal.multiplier}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.green : Colors.deepPurple,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSeasonalPricingSection2() {
    // Filtrage (garde ta logique actuelle)
    final toShow = _fromDate == null || _toDate == null
        ? _seasonalPricings.where((s) => s.isActive).toList()
        : _seasonalPricings.where((s) {
            if (!s.isActive) return false;
            for (DateTime d = _fromDate!;
                d.isBefore(_toDate!.add(const Duration(days: 1)));
                d = d.add(const Duration(days: 1))) {
              if (s.isDateInSeason(d)) return true;
            }
            return false;
          }).toList();

    if (toShow.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _fromDate == null || _toDate == null
                ? 'Aucun tarif saisonnier disponible'
                : 'Aucun tarif saisonnier applicable pour ces dates',
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      );
    }

    // Garantit que la valeur est dans la liste des items
    final currentValue = (_selectedSeasonalPricing != null &&
            toShow.any((s) => s.id == _selectedSeasonalPricing!.id))
        ? _selectedSeasonalPricing
        : toShow.first; // fallback sûr

    return DropdownButtonFormField<SeasonalPricing>(
      isExpanded: true,
      value: currentValue,
      decoration: InputDecoration(
        labelText: 'Tarif saisonnier',
        prefixIcon: const Icon(Icons.event),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: toShow.map((seasonal) {
        return DropdownMenuItem<SeasonalPricing>(
          value: seasonal,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(seasonal.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${_formatDate(seasonal.startDate)} – ${_formatDate(seasonal.endDate)}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Text('× ${seasonal.multiplier}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.deepPurple)),
            ],
          ),
        );
      }).toList(),
      onChanged: (SeasonalPricing? newValue) {
        setState(() {
          _selectedSeasonalPricing = newValue;
          _seasonalMultiplier = newValue?.multiplier ?? 1.0;
          _updateRoomPrice(); // Recalculer le prix
        });
      },
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

                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InputChip(
                        avatar: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: Text(
                            guest.fullName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Colors.blue, fontSize: 12),
                          ),
                        ),
                        label: Text(
                          guest.fullName.capitalize,
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
                                  onPressed: () =>
                                      Navigator.pop(context, "edit"),
                                  child: Row(
                                    children: const [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text("Éditer"),
                                    ],
                                  ),
                                ),
                                SimpleDialogOption(
                                  onPressed: () =>
                                      Navigator.pop(context, "delete"),
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
                      ),
                      // IconButton(
                      //   icon: const Icon(Icons.edit, color: Colors.blue),
                      //   onPressed: () async {
                      //     final action = await showDialog<String>(
                      //       context: context,
                      //       builder: (context) => SimpleDialog(
                      //         title: const Text("Choisissez une action"),
                      //         children: [
                      //           SimpleDialogOption(
                      //             onPressed: () => Navigator.pop(context, "edit"),
                      //             child: Row(
                      //               children: const [
                      //                 Icon(Icons.edit, color: Colors.blue),
                      //                 SizedBox(width: 8),
                      //                 Text("Éditer"),
                      //               ],
                      //             ),
                      //           ),
                      //           SimpleDialogOption(
                      //             onPressed: () =>
                      //                 Navigator.pop(context, "delete"),
                      //             child: Row(
                      //               children: const [
                      //                 Icon(Icons.delete, color: Colors.red),
                      //                 SizedBox(width: 8),
                      //                 Text("Supprimer"),
                      //               ],
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     );
                      //
                      //     if (action == "edit") {
                      //       _editGuest(index);
                      //     } else if (action == "delete") {
                      //       final confirm = await showDialog<bool>(
                      //         context: context,
                      //         builder: (context) => AlertDialog(
                      //           title: const Text("Confirmation"),
                      //           content: const Text(
                      //               "Voulez-vous vraiment supprimer ce client ?"),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () =>
                      //                   Navigator.of(context).pop(false),
                      //               child: const Text("Annuler"),
                      //             ),
                      //             ElevatedButton(
                      //               onPressed: () =>
                      //                   Navigator.of(context).pop(true),
                      //               child: const Text("Supprimer"),
                      //             ),
                      //           ],
                      //         ),
                      //       );
                      //
                      //       if (confirm == true) {
                      //         _removeGuest(index);
                      //       }
                      //     }
                      //   },
                      // ),
                    ],
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
      final basePrice = _selectedRoom!.category.target!.basePrice;
      final seasonalMultiplier = _selectedSeasonalPricing?.multiplier ?? 1.0;
      final effectivePrice = basePrice * seasonalMultiplier;
      if (widget.isEditing && widget.existingReservation != null) {
        result = await widget.provider.updateReservationComplete(
          reservation: widget.existingReservation!,
          newRoom: _selectedRoom!,
          newReceptionist: _selectedEmployee!,
          newGuests: _selectedGuests,
          newFrom: _fromDate!,
          newTo: _toDate!,
          newPricePerNight: // effectivePrice,
              priceToSave,
          //  pricePerNight,
          newStatus: _status,
          newBoardBasis: _selectedBoardBasis,
          newDiscountPercent: _discountPercent,
          newDiscountAmount: _discountAmount,
        );
      } else {
        result = await widget.provider.addReservation(
          room: _selectedRoom!,
          receptionist: _selectedEmployee!,
          guests: _selectedGuests,
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: //effectivePrice,
              priceToSave,
          //     pricePerNight,
          status: _status,
          boardBasis: _selectedBoardBasis,
          discountPercent: _discountPercent,
          discountAmount: _discountAmount,
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

// 8. CORRECTION: Remplacer dans _buildBasicInfoSection le champ prix par:
  Widget _buildPriceSection() {
    return _buildPriceFieldImproved();
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

class SeasonalPricingDropdown extends StatelessWidget {
  final SeasonalPricing? selectedValue;
  final Function(SeasonalPricing?)? onChanged;
  final List<SeasonalPricing>? customSeasonalPricings;
  final bool useLocalState;

  const SeasonalPricingDropdown({
    super.key,
    this.selectedValue,
    this.onChanged,
    this.customSeasonalPricings,
    this.useLocalState = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<HotelProvider>(
      builder: (_, provider, __) {
        final list = provider.seasonalPricing;
        final selected = provider.selectedSeasonalPricing;

        // 1. Élimine les doublons de la liste
        final unique = <int, SeasonalPricing>{};
        for (final sp in list) {
          unique.putIfAbsent(sp.id, () => sp);
        }
        final uniqueList = unique.values.toList();

        // 2. Cherche la bonne instance dans la liste unique
        // C'est la correction clé. Au lieu de simplement vérifier si l'ID existe,
        // nous trouvons l'objet réel dans `uniqueList` qui correspond à l'ID de `selected`.
        // Cela garantit que l'objet passé à `value` est une instance qui existe dans `items`.
        SeasonalPricing? validValue;
        if (selected != null) {
          try {
            validValue =
                uniqueList.firstWhere((item) => item.id == selected.id);
          } catch (e) {
            // Si l'élément sélectionné n'est plus dans la liste (par exemple, après un filtre),
            // la valeur doit être nulle pour éviter une erreur.
            validValue = null;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DropdownButtonFormField<SeasonalPricing>(
            // Utilise l'instance trouvée dans la liste unique
            value: validValue,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: 'Tarif saisonnier',
              prefixIcon: const Icon(Icons.calendar_today),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            items: uniqueList
                .map((sp) => DropdownMenuItem(
                      value: sp,
                      child: Text('${sp.name} - ${sp.multiplier}x'),
                    ))
                .toList(),
            // onChanged: (v) =>
            //     provider.setSelectedSeasonalPricing(provider.currentHotel!, v),
            onChanged: (SeasonalPricing? v) {
              if (onChanged != null) {
                // Utiliser le callback personnalisé
                onChanged!(v);
              } else {
                // Comportement par défaut
                provider.setSelectedSeasonalPricing(provider.currentHotel!, v);
              }
            },
          ),
        );
      },
    );
  }
}
// class SeasonalPricingDropdown extends StatelessWidget {
//   const SeasonalPricingDropdown({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return _buildSeasonalPricingDropdown();
//
//     // return Consumer<HotelProvider>(
//     //   builder: (context, provider, child) {
//     //     final seasonalPricings = provider.seasonalPricing;
//     //     final selected = provider.selectedSeasonalPricing;
//     //
//     //     return DropdownButtonFormField<SeasonalPricing>(
//     //       value: selected,
//     //       isExpanded: true,
//     //       decoration: InputDecoration(
//     //         labelText: "Tarif saisonnier",
//     //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//     //         prefixIcon: const Icon(Icons.calendar_today),
//     //       ),
//     //       items: seasonalPricings.map((sp) {
//     //         return DropdownMenuItem<SeasonalPricing>(
//     //           value: sp,
//     //           child: Text("${sp.name} - ${sp.multiplier}x"),
//     //         );
//     //       }).toList(),
//     //       onChanged: (newValue) {
//     //         provider.setSelectedSeasonalPricing(newValue);
//     //       },
//     //     );
//     //   },
//     // );
//   }
//
//   Widget _buildSeasonalPricingDropdown() {
//     return Consumer<HotelProvider>(
//       builder: (context, provider, child) {
//         final seasonalPricings = provider.seasonalPricing;
//         final selected = provider.selectedSeasonalPricing;
//
//         // 🔥 Élimine les doublons par ID
//         final uniqueItems = <int, SeasonalPricing>{};
//         for (final sp in seasonalPricings) {
//           uniqueItems.putIfAbsent(sp.id, () => sp);
//         }
//         final uniqueList = uniqueItems.values.toList();
//
//         // 🔥 Vérifie que la valeur est dans la liste
//         final validValue =
//             uniqueList.any((e) => e.id == selected?.id) ? selected : null;
//
//         return DropdownButtonFormField<SeasonalPricing>(
//           value: validValue,
//           isExpanded: true,
//           decoration: InputDecoration(
//             labelText: "Tarif saisonnier",
//             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//             prefixIcon: const Icon(Icons.calendar_today),
//           ),
//           items: uniqueList.map((sp) {
//             return DropdownMenuItem<SeasonalPricing>(
//               value: sp,
//               child: Text("${sp.name} - ${sp.multiplier}x"),
//             );
//           }).toList(),
//           onChanged: (newValue) {
//             provider.setSelectedSeasonalPricing(newValue);
//           },
//         );
//       },
//     );
//   }
// }

// Helper class for managing extra services in the UI
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
// 2. Version modifiée de ReservationDialogContent pour supporter l'édition
// class ReservationDialogContent extends StatefulWidget {
//   final Room? preselectedRoom;
//   final DateTime? preselectedDate;
//   final Hotel currentHotel;
//   final HotelProvider provider;
//   final BuildContext parentContext;
//   final VoidCallback onReservationAdded;
//   final bool isEditing; // Nouveau paramètre
//   final Reservation? existingReservation; // Nouveau paramètre
//
//   const ReservationDialogContent({
//     Key? key,
//     this.preselectedRoom,
//     this.preselectedDate,
//     required this.currentHotel,
//     required this.provider,
//     required this.parentContext,
//     required this.onReservationAdded,
//     this.isEditing = false, // Valeur par défaut
//     this.existingReservation, // Peut être null pour nouveaux
//   }) : super(key: key);
//
//   @override
//   State<ReservationDialogContent> createState() =>
//       _ReservationDialogContentState();
// }
//
// class _ReservationDialogContentState extends State<ReservationDialogContent> {
//   final _formKey = GlobalKey<FormState>();
//   final _guestController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _idCardController = TextEditingController();
//   final _priceController = TextEditingController();
//
//   Room? _selectedRoom;
//   Employee? _selectedEmployee;
//   List<Guest> _selectedGuests = [];
//   DateTime? _fromDate;
//   DateTime? _toDate;
//   String _status = "Confirmée";
//   bool _isLoading = false;
//
//   // Variables pour l'édition de client
//   bool _isEditingGuest = false;
//   Guest? _guestBeingEdited;
//   int? _editingGuestIndex;
//
//   final List<String> _statuses = [
//     "Confirmée",
//     "En attente",
//     "Arrivé",
//     "Parti",
//     "Annulée"
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//
//     if (widget.isEditing && widget.existingReservation != null) {
//       // Mode édition - pré-remplir avec les données existantes
//       _initializeForEdit();
//     } else {
//       // Mode création - utiliser les valeurs par défaut
//       _initializeForNew();
//     }
//   }
//
//   void _initializeForEdit() {
//     final reservation = widget.existingReservation!;
//
//     // Trouver la chambre correspondante dans la liste des chambres de l'hôtel
//     // pour éviter les problèmes de référence d'objet ObjectBox
//     final roomId = reservation.room.target?.id;
//     _selectedRoom = roomId != null
//         ? widget.currentHotel.rooms
//             .cast<Room?>()
//             .firstWhere((room) => room?.id == roomId, orElse: () => null)
//         : null;
//
//     // Même logique pour l'employé
//     final employeeId = reservation.receptionist.target?.id;
//     _selectedEmployee = employeeId != null
//         ? widget.provider.employees
//             .cast<Employee?>()
//             .firstWhere((emp) => emp?.id == employeeId, orElse: () => null)
//         : null;
//
//     _selectedGuests = reservation.guests.toList();
//     _fromDate = reservation.from;
//     _toDate = reservation.to;
//     _status = reservation.status;
//     _priceController.text = reservation.pricePerNight.toString();
//   }
//
//   void _initializeForNew() {
//     _selectedRoom = widget.preselectedRoom;
//     _fromDate = widget.preselectedDate ?? DateTime.now();
//     _toDate = _fromDate!.add(Duration(days: 1));
//   }
//
//   @override
//   void dispose() {
//     _guestController.dispose();
//     _phoneController.dispose();
//     _idCardController.dispose();
//     _priceController.dispose();
//     super.dispose();
//   }
//
//   void _addGuest() {
//     if (_guestController.text.trim().isEmpty ||
//         _phoneController.text.trim().isEmpty ||
//         _idCardController.text.trim().isEmpty) {
//       _showSnackBar('Veuillez remplir tous les champs du client',
//           isError: true);
//       return;
//     }
//
//     final trimmedName = _guestController.text.trim();
//
//     // Vérifier si le client existe déjà (seulement pour l'ajout, pas l'édition)
//     if (!_isEditingGuest &&
//         _selectedGuests.any((guest) =>
//             guest.fullName.toLowerCase() == trimmedName.toLowerCase())) {
//       _showSnackBar('Ce client est déjà ajouté', isError: true);
//       return;
//     }
//
//     if (_isEditingGuest) {
//       // Mode édition - utiliser la méthode de sauvegarde
//       _saveGuestEdit();
//     } else {
//       // Mode ajout - créer un nouveau client
//       final newGuest = Guest(
//         fullName: trimmedName,
//         phoneNumber: _phoneController.text.trim(),
//         idCardNumber: _idCardController.text.trim(),
//       );
//
//       setState(() {
//         _selectedGuests.add(newGuest);
//         _guestController.clear();
//         _phoneController.clear();
//         _idCardController.clear();
//       });
//
//       _showSnackBar('Client ajouté avec succès');
//     }
//   }
//
//   void _removeGuest(Guest guest) {
//     setState(() {
//       _selectedGuests.remove(guest);
//     });
//   }
//
//   void _showSnackBar(String message, {bool isError = false}) {
//     ScaffoldMessenger.of(widget.parentContext).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: isError ? Colors.red : Colors.green,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//       ),
//     );
//   }
//
//   void _handleKeyPress(KeyEvent event) {
//     // Détecter la touche Entrée
//     if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
//       if (_guestController.text.trim().isNotEmpty ||
//           _phoneController.text.trim().isNotEmpty ||
//           _idCardController.text.trim().isNotEmpty) {
//         _addGuest();
//       }
//     }
//   }
//
//   void _editGuest(Guest guest, int index) {
//     setState(() {
//       _isEditingGuest = true;
//       _guestBeingEdited = guest;
//       _editingGuestIndex = index;
//
//       // Pré-remplir les champs avec les données du client
//       _guestController.text = guest.fullName;
//       _phoneController.text = guest.phoneNumber ?? '';
//       _idCardController.text = guest.idCardNumber ?? '';
//     });
//   }
//
//   void _cancelGuestEdit() {
//     setState(() {
//       _isEditingGuest = false;
//       _guestBeingEdited = null;
//       _editingGuestIndex = null;
//
//       // Vider les champs
//       _guestController.clear();
//       _phoneController.clear();
//       _idCardController.clear();
//     });
//   }
//
//   void _saveGuestEdit() async {
//     if (_guestController.text.trim().isEmpty ||
//         _phoneController.text.trim().isEmpty ||
//         _idCardController.text.trim().isEmpty) {
//       _showSnackBar('Veuillez remplir tous les champs du client',
//           isError: true);
//       return;
//     }
//
//     final trimmedName = _guestController.text.trim();
//
//     // Vérifier si le nom existe déjà (sauf pour le client en cours d'édition)
//     bool nameExists = false;
//     for (int i = 0; i < _selectedGuests.length; i++) {
//       if (i != _editingGuestIndex &&
//           _selectedGuests[i].fullName.toLowerCase() ==
//               trimmedName.toLowerCase()) {
//         nameExists = true;
//         break;
//       }
//     }
//
//     if (nameExists) {
//       _showSnackBar('Ce nom de client existe déjà', isError: true);
//       return;
//     }
//
//     try {
//       // Mettre à jour le client existant
//       final guestToUpdate = _selectedGuests[_editingGuestIndex!];
//       guestToUpdate.fullName = trimmedName;
//       guestToUpdate.phoneNumber = _phoneController.text.trim();
//       guestToUpdate.idCardNumber = _idCardController.text.trim();
//
//       // Sauvegarder dans ObjectBox si le client a un ID (existe déjà dans la DB)
//       if (guestToUpdate.id != 0) {
//         await widget.provider.updateGuest(guestToUpdate);
//       }
//       // Si l'ID est 0, c'est un nouveau client qui sera sauvegardé lors de la sauvegarde de la réservation
//
//       setState(() {
//         // Réinitialiser l'état d'édition
//         _isEditingGuest = false;
//         _guestBeingEdited = null;
//         _editingGuestIndex = null;
//
//         // Vider les champs
//         _guestController.clear();
//         _phoneController.clear();
//         _idCardController.clear();
//       });
//
//       _showSnackBar('Client modifié avec succès');
//     } catch (e) {
//       _showSnackBar('Erreur lors de la modification du client: $e',
//           isError: true);
//     }
//   }
//
//   Future<void> _saveReservation() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     // Ajouter le client en cours si les champs sont remplis
//     if (_guestController.text.trim().isNotEmpty) {
//       _addGuest();
//     }
//
//     if (_selectedRoom == null ||
//         _selectedEmployee == null ||
//         _fromDate == null ||
//         _toDate == null ||
//         _selectedGuests.isEmpty ||
//         _priceController.text.trim().isEmpty) {
//       _showSnackBar('Veuillez remplir tous les champs obligatoires',
//           isError: true);
//       return;
//     }
//
//     if (_fromDate!.isAfter(_toDate!) || _fromDate!.isAtSameMomentAs(_toDate!)) {
//       _showSnackBar('La date de départ doit être après la date d\'arrivée',
//           isError: true);
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       if (widget.isEditing && widget.existingReservation != null) {
//         // Mode édition - mettre à jour toutes les propriétés directement
//         final reservation = widget.existingReservation!;
//
//         // Mettre à jour toutes les propriétés
//         reservation.receptionist.target = _selectedEmployee;
//         reservation.pricePerNight = double.parse(_priceController.text);
//         reservation.status = _status;
//
//         // Gérer les clients - sauvegarder nouveaux et mis à jour
//         for (final guest in _selectedGuests) {
//           if (guest.id == 0) {
//             // Nouveau client
//             await widget.provider.addGuest(guest);
//           } else {
//             // Client existant - s'assurer qu'il est à jour dans ObjectBox
//             await widget.provider.updateGuest(guest);
//           }
//         }
//
//         // Mettre à jour la liste des clients
//         reservation.guests.clear();
//         reservation.guests.addAll(_selectedGuests);
//
//         // Maintenant faire la mise à jour avec vérification de disponibilité
//         final result = await widget.provider.updateReservation(
//           reservation,
//           newRoom: _selectedRoom,
//           newFrom: _fromDate,
//           newTo: _toDate,
//         );
//
//         if (result.isSuccess) {
//           widget.onReservationAdded();
//           Navigator.pop(context);
//           _showSnackBar('Réservation modifiée avec succès');
//         } else if (result.conflict != null) {
//           _showConflictDialog(result.conflict!);
//         } else {
//           _showSnackBar(result.error ?? 'Erreur lors de la modification',
//               isError: true);
//         }
//       } else {
//         // Sauvegarder nouveaux et clients mis à jour
//         for (final guest in _selectedGuests) {
//           if (guest.id == 0) {
//             // Nouveau client
//             await widget.provider.addGuest(guest);
//           } else {
//             // Client existant - s'assurer qu'il est à jour dans ObjectBox
//             await widget.provider.updateGuest(guest);
//           }
//         }
//
//         final result = await widget.provider.addReservation(
//           room: _selectedRoom!,
//           receptionist: _selectedEmployee!,
//           guests: _selectedGuests,
//           from: _fromDate!,
//           to: _toDate!,
//           pricePerNight: double.parse(_priceController.text),
//           status: _status,
//         );
//
//         if (result.isSuccess) {
//           widget.onReservationAdded();
//           Navigator.pop(context);
//           _showSnackBar('Réservation créée avec succès');
//         } else if (result.conflict != null) {
//           _showConflictDialog(result.conflict!);
//         } else {
//           _showSnackBar(result.error ?? 'Erreur lors de la création',
//               isError: true);
//         }
//       }
//     } catch (e) {
//       _showSnackBar('Erreur lors de l\'opération: $e', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   void _showConflictDialog(ReservationConflict conflict) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text('Conflit de réservation'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//                 'La chambre ${conflict.room.code} est déjà réservée pour cette période.'),
//             SizedBox(height: 16),
//             Text('Réservations en conflit:'),
//             ...conflict.conflictingReservations.map((res) => Padding(
//                   padding: EdgeInsets.only(left: 8, top: 4),
//                   child: Text(
//                       '• ${_formatDate(res.from)} → ${_formatDate(res.to)}'),
//                 )),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: Text('Annuler'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               // Forcer la réservation malgré le conflit
//               _saveWithForce();
//             },
//             child: Text('Forcer quand même'),
//             style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Future<void> _saveWithForce() async {
//     setState(() => _isLoading = true);
//
//     try {
//       if (widget.isEditing && widget.existingReservation != null) {
//         // Sauvegarder d'abord les nouveaux clients
//         for (final guest in _selectedGuests) {
//           if (guest.id == 0) {
//             await widget.provider.addGuest(guest);
//           }
//         }
//
//         final result = await widget.provider.updateReservation(
//           widget.existingReservation!,
//           newRoom: _selectedRoom,
//           newFrom: _fromDate,
//           newTo: _toDate,
//           forceOverride: true,
//         );
//
//         if (result.isSuccess) {
//           widget.onReservationAdded();
//           Navigator.pop(context);
//           _showSnackBar('Réservation modifiée avec succès (forcée)');
//         }
//       } else {
//         // Sauvegarder d'abord les nouveaux clients
//         for (final guest in _selectedGuests) {
//           if (guest.id == 0) {
//             await widget.provider.addGuest(guest);
//           }
//         }
//
//         final result = await widget.provider.addReservation(
//           room: _selectedRoom!,
//           receptionist: _selectedEmployee!,
//           guests: _selectedGuests,
//           from: _fromDate!,
//           to: _toDate!,
//           pricePerNight: double.parse(_priceController.text),
//           status: _status,
//           forceOverride: true,
//         );
//
//         if (result.isSuccess) {
//           widget.onReservationAdded();
//           Navigator.pop(context);
//           _showSnackBar('Réservation créée avec succès (forcée)');
//         }
//       }
//     } catch (e) {
//       _showSnackBar('Erreur lors de l\'opération forcée: $e', isError: true);
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//
//   String _formatDate(DateTime date) {
//     return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         double w = constraints.maxWidth;
//
//         if (w < 600) {
//           // 📱 Mobile
//           return buildForm();
//         } else if (w < 1200) {
//           // 💻 Tablette
//           return buildForm2();
//         } else {
//           // 🖥️ Desktop
//           return buildForm2();
//         }
//       },
//     );
//   }
//
//   Column buildForm() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Header - Titre dynamique selon le mode
//         Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Theme.of(context).primaryColor,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(16),
//               topRight: Radius.circular(16),
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.hotel, color: Colors.white, size: 28),
//               SizedBox(width: 12),
//               Text(
//                 widget.isEditing
//                     ? 'Modifier la réservation'
//                     : 'Nouvelle Réservation',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Spacer(),
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: Icon(Icons.close, color: Colors.white),
//               ),
//             ],
//           ),
//         ),
//
//         // Content - Même contenu que votre formulaire existant mais avec les données pré-remplies
//         Expanded(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.all(20),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Chambre et Employé
//                   SizedBox(
//                     height: 120,
//                     child: Column(
//                       children: [
//                         DropdownButtonFormField<int>(
//                           isExpanded: true,
//                           isDense: true,
//                           value: _selectedEmployee?.id,
//                           decoration: InputDecoration(
//                             labelText: 'Réceptionniste *',
//                             prefixIcon: Icon(Icons.person),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           items: widget.provider.employees.map((emp) {
//                             return DropdownMenuItem<int>(
//                               value: emp.id,
//                               // Utilisez l'ID comme valeur unique
//                               child: Text(emp.fullName),
//                             );
//                           }).toList(),
//                           onChanged: (int? empId) {
//                             setState(() {
//                               _selectedEmployee = widget.provider.employees
//                                   .firstWhere((emp) => emp.id == empId);
//                             });
//                           },
//                           validator: (value) => value == null
//                               ? 'Choisissez un réceptionniste'
//                               : null,
//                         ),
//                         Spacer(),
//                         DropdownButtonFormField<Room>(
//                           isExpanded: true,
//                           isDense: true,
//                           value: _selectedRoom,
//                           decoration: InputDecoration(
//                             labelText: 'Chambre *',
//                             prefixIcon: Icon(Icons.room),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           items: widget.currentHotel.rooms.map((room) {
//                             final categoryName =
//                                 widget.provider.getRoomCategoryName(room);
//                             return DropdownMenuItem(
//                               value: room,
//                               child: Text(
//                                   '${room.code} $categoryName ${room.type ?? ''}'),
//                             );
//                           }).toList(),
//                           onChanged: (room) =>
//                               setState(() => _selectedRoom = room),
//                           validator: (value) =>
//                               value == null ? 'Choisissez une chambre' : null,
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(height: 24),
//
//                   // Section Clients
//                   // Section Clients
//                   Card(
//                     elevation: 2,
//                     shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8)),
//                     child: Padding(
//                       padding: EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           SizedBox(
//                             height: 30,
//                             child: Row(
//                               children: [
//                                 Text(
//                                   _isEditingGuest
//                                       ? 'Modifier Client'
//                                       : 'Informations Client',
//                                   style: TextStyle(
//                                       fontSize: 16,
//                                       fontWeight: FontWeight.bold),
//                                 ),
//                                 if (_isEditingGuest) ...[
//                                   Spacer(),
//                                   TextButton(
//                                     onPressed: _cancelGuestEdit,
//                                     child: Text(
//                                       'Annuler',
//                                       style: TextStyle(color: Colors.grey[600]),
//                                     ),
//                                   ),
//                                 ],
//                               ],
//                             ),
//                           ),
//                           SizedBox(height: 16),
//                           KeyboardListener(
//                             focusNode: FocusNode(),
//                             onKeyEvent: _handleKeyPress,
//                             child: Column(
//                               children: [
//                                 TextFormField(
//                                   controller: _guestController,
//                                   decoration: InputDecoration(
//                                     labelText: 'Nom complet',
//                                     prefixIcon: Icon(Icons.person_outline),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   onFieldSubmitted: (_) => _addGuest(),
//                                 ),
//                                 SizedBox(height: 12),
//                                 TextFormField(
//                                   controller: _phoneController,
//                                   decoration: InputDecoration(
//                                     labelText: 'Téléphone',
//                                     prefixIcon: Icon(Icons.phone),
//                                     border: OutlineInputBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                   ),
//                                   keyboardType: TextInputType.phone,
//                                   onFieldSubmitted: (_) => _addGuest(),
//                                 ),
//                                 SizedBox(height: 12),
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: TextFormField(
//                                         controller: _idCardController,
//                                         decoration: InputDecoration(
//                                           labelText: 'Carte d\'identité',
//                                           prefixIcon: Icon(Icons.credit_card),
//                                           border: OutlineInputBorder(
//                                             borderRadius:
//                                                 BorderRadius.circular(8),
//                                           ),
//                                         ),
//                                         onFieldSubmitted: (_) => _addGuest(),
//                                       ),
//                                     ),
//                                     SizedBox(width: 12),
//                                     ElevatedButton.icon(
//                                       onPressed: _addGuest,
//                                       icon: Icon(_isEditingGuest
//                                           ? Icons.save
//                                           : Icons.add),
//                                       label: Text(_isEditingGuest
//                                           ? 'Sauvegarder'
//                                           : 'Ajouter'),
//                                       style: ElevatedButton.styleFrom(
//                                         backgroundColor: _isEditingGuest
//                                             ? Colors.orange
//                                             : null,
//                                         foregroundColor: _isEditingGuest
//                                             ? Colors.white
//                                             : null,
//                                         padding: EdgeInsets.symmetric(
//                                             horizontal: 16, vertical: 12),
//                                         shape: RoundedRectangleBorder(
//                                           borderRadius:
//                                               BorderRadius.circular(8),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           if (_selectedGuests.isNotEmpty) ...[
//                             SizedBox(height: 16),
//                             Text('Clients ajoutés:',
//                                 style: TextStyle(fontWeight: FontWeight.w500)),
//                             SizedBox(height: 8),
//                             Wrap(
//                               spacing: 8,
//                               runSpacing: 4,
//                               children:
//                                   _selectedGuests.asMap().entries.map((entry) {
//                                 final int index = entry.key;
//                                 final Guest guest = entry.value;
//                                 final bool isBeingEdited = _isEditingGuest &&
//                                     _editingGuestIndex == index;
//
//                                 return InkWell(
//                                   onTap: () => _editGuest(guest, index),
//                                   onDoubleTap: () => _cancelGuestEdit(),
//                                   child: Chip(
//                                     avatar: CircleAvatar(
//                                       backgroundColor: isBeingEdited
//                                           ? Colors.orange
//                                           : Colors.deepPurple,
//                                       child: Icon(
//                                         isBeingEdited
//                                             ? Icons.edit
//                                             : Icons.person,
//                                         size: 16,
//                                         color: Colors.white,
//                                       ),
//                                     ),
//                                     label: Text(
//                                       guest.fullName,
//                                       style: TextStyle(
//                                         fontWeight: FontWeight.w500,
//                                         color: Theme.of(context)
//                                             .colorScheme
//                                             .onSurface,
//                                       ),
//                                     ),
//                                     deleteIcon: Icon(
//                                       Icons.close,
//                                       size: 18,
//                                       color:
//                                           Theme.of(context).colorScheme.error,
//                                     ),
//                                     onDeleted: () => _removeGuest(guest),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(8),
//                                     ),
//                                     backgroundColor: isBeingEdited
//                                         ? Colors.orange.withOpacity(0.1)
//                                         : Theme.of(context)
//                                             .colorScheme
//                                             .surfaceContainerHighest,
//                                     // side: BorderSide(
//                                     //   color: isBeingEdited
//                                     //       ? Colors.orange
//                                     //       : Theme.of(context)
//                                     //           .colorScheme
//                                     //           .outlineVariant,
//                                     //   width: isBeingEdited ? 2 : 1,
//                                     // ),
//                                     padding: const EdgeInsets.symmetric(
//                                         horizontal: 8, vertical: 4),
//                                     materialTapTargetSize:
//                                         MaterialTapTargetSize.shrinkWrap,
//                                     visualDensity: VisualDensity.compact,
//                                   ),
//                                 );
//                               }).toList(),
//                             ),
//                           ],
//                         ],
//                       ),
//                     ),
//                   ),
//
//                   SizedBox(height: 24),
//
//                   // Dates
//                   Row(
//                     children: [
//                       Expanded(
//                         child: InkWell(
//                           onTap: () async {
//                             final date = await showDatePicker(
//                               context: context,
//                               initialDate: _fromDate ?? DateTime.now(),
//                               firstDate:
//                                   DateTime.now().subtract(Duration(days: 30)),
//                               lastDate: DateTime.now().add(Duration(days: 365)),
//                             );
//                             if (date != null) {
//                               setState(() {
//                                 _fromDate = date;
//                                 if (_toDate != null &&
//                                     _toDate!.isBefore(
//                                         date.add(Duration(days: 1)))) {
//                                   _toDate = date.add(Duration(days: 1));
//                                 }
//                               });
//                             }
//                           },
//                           child: Container(
//                             padding: EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey[300]!),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Arrivée *',
//                                     style: TextStyle(
//                                         fontSize: 12, color: Colors.grey[600])),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   _fromDate != null
//                                       ? _formatDate(_fromDate!)
//                                       : 'Sélectionner',
//                                   style: TextStyle(fontSize: 16),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                       SizedBox(width: 16),
//                       Expanded(
//                         child: InkWell(
//                           onTap: () async {
//                             final date = await showDatePicker(
//                               context: context,
//                               initialDate: _toDate ??
//                                   (_fromDate?.add(Duration(days: 1)) ??
//                                       DateTime.now().add(Duration(days: 1))),
//                               firstDate: _fromDate?.add(Duration(days: 1)) ??
//                                   DateTime.now(),
//                               lastDate: DateTime.now().add(Duration(days: 365)),
//                             );
//                             if (date != null) {
//                               setState(() => _toDate = date);
//                             }
//                           },
//                           child: Container(
//                             padding: EdgeInsets.all(16),
//                             decoration: BoxDecoration(
//                               border: Border.all(color: Colors.grey[300]!),
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text('Départ *',
//                                     style: TextStyle(
//                                         fontSize: 12, color: Colors.grey[600])),
//                                 SizedBox(height: 4),
//                                 Text(
//                                   _toDate != null
//                                       ? _formatDate(_toDate!)
//                                       : 'Sélectionner',
//                                   style: TextStyle(fontSize: 16),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//
//                   SizedBox(height: 16),
//
//                   // Prix et Statut
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: _priceController,
//                           decoration: InputDecoration(
//                             labelText: 'Prix par nuit (DA) *',
//                             prefixIcon: Icon(Icons.attach_money),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           keyboardType: TextInputType.number,
//                           validator: (value) {
//                             if (value == null || value.isEmpty)
//                               return 'Prix requis';
//                             if (double.tryParse(value) == null)
//                               return 'Prix invalide';
//                             return null;
//                           },
//                         ),
//                       ),
//                       SizedBox(width: 16),
//                       Expanded(
//                         child: DropdownButtonFormField<String>(
//                           isExpanded: true,
//                           isDense: true,
//                           value: _status,
//                           decoration: InputDecoration(
//                             labelText: 'Statut',
//                             prefixIcon: Icon(Icons.info_outline),
//                             border: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           items: _statuses.map((status) {
//                             return DropdownMenuItem(
//                               value: status,
//                               child: Text(status),
//                             );
//                           }).toList(),
//                           onChanged: (status) =>
//                               setState(() => _status = status!),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         // Footer - Bouton dynamique selon le mode
//         Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(16),
//               bottomRight: Radius.circular(16),
//             ),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: _isLoading ? null : () => Navigator.pop(context),
//                   child: Text('Annuler'),
//                   style: OutlinedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _saveReservation,
//                   child: _isLoading
//                       ? SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : Text(widget.isEditing
//                           ? 'Modifier la réservation'
//                           : 'Créer la réservation'),
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   /// Retourne le nom de la catégorie d'une chambre
//   String getRoomCategoryName(Room room) {
//     return room.category.target?.name ?? 'Aucune catégorie';
//   }
//
//   Column buildForm2() {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         // Header - Titre dynamique selon le mode
//         Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Theme.of(context).primaryColor,
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(16),
//               topRight: Radius.circular(16),
//             ),
//           ),
//           child: Row(
//             children: [
//               Icon(Icons.hotel, color: Colors.white, size: 28),
//               SizedBox(width: 12),
//               Text(
//                 widget.isEditing
//                     ? 'Modifier la réservation'
//                     : 'Nouvelle Réservation',
//                 style: TextStyle(
//                   color: Colors.white,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               Spacer(),
//               IconButton(
//                 onPressed: () => Navigator.pop(context),
//                 icon: Icon(Icons.close, color: Colors.white),
//               ),
//             ],
//           ),
//         ),
//
//         // Content - Fixed layout structure
//         Expanded(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.all(20),
//             child: Form(
//               key: _formKey,
//               child: Row(
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: [
//                   // Left Column - Chambre et Employé + Section Clients
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Chambre et Employé Row
//                         Row(
//                           children: [
//                             Expanded(
//                               child: DropdownButtonFormField<Room>(
//                                 isExpanded: true,
//                                 isDense: true,
//                                 value: _selectedRoom,
//                                 decoration: InputDecoration(
//                                   labelText: 'Chambre *',
//                                   prefixIcon: Icon(Icons.room),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 items: widget.currentHotel.rooms.map((room) {
//                                   final categoryName =
//                                       widget.provider.getRoomCategoryName(room);
//                                   return DropdownMenuItem(
//                                     value: room,
//                                     child: Text(
//                                         '${room.code} $categoryName ${room.type ?? ''}'),
//                                   );
//                                 }).toList(),
//                                 onChanged: (room) =>
//                                     setState(() => _selectedRoom = room),
//                                 validator: (value) => value == null
//                                     ? 'Choisissez une chambre'
//                                     : null,
//                               ),
//                             ),
//                             SizedBox(width: 16),
//                             Expanded(
//                               child: DropdownButtonFormField<int>(
//                                 value: _selectedEmployee?.id,
//                                 decoration: InputDecoration(
//                                   labelText: 'Réceptionniste *',
//                                   prefixIcon: Icon(Icons.person),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 items: widget.provider.employees.map((emp) {
//                                   return DropdownMenuItem<int>(
//                                     value: emp.id,
//                                     // Utilisez l'ID comme valeur unique
//                                     child: Text(emp.fullName),
//                                   );
//                                 }).toList(),
//                                 onChanged: (int? empId) {
//                                   setState(() {
//                                     _selectedEmployee = widget
//                                         .provider.employees
//                                         .firstWhere((emp) => emp.id == empId);
//                                   });
//                                 },
//                                 validator: (value) => value == null
//                                     ? 'Choisissez un réceptionniste'
//                                     : null,
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         SizedBox(height: 16),
//                         // Dates Row
//                         Row(
//                           children: [
//                             Expanded(
//                               child: InkWell(
//                                 onTap: () async {
//                                   final date = await showDatePicker(
//                                     context: context,
//                                     initialDate: _fromDate ?? DateTime.now(),
//                                     firstDate: DateTime.now()
//                                         .subtract(Duration(days: 30)),
//                                     lastDate:
//                                         DateTime.now().add(Duration(days: 365)),
//                                   );
//                                   if (date != null) {
//                                     setState(() {
//                                       _fromDate = date;
//                                       if (_toDate != null &&
//                                           _toDate!.isBefore(
//                                               date.add(Duration(days: 1)))) {
//                                         _toDate = date.add(Duration(days: 1));
//                                       }
//                                     });
//                                   }
//                                 },
//                                 child: Container(
//                                   padding: EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     border:
//                                         Border.all(color: Colors.grey[300]!),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text('Arrivée *',
//                                           style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600])),
//                                       SizedBox(height: 4),
//                                       Text(
//                                         _fromDate != null
//                                             ? _formatDate(_fromDate!)
//                                             : 'Sélectionner',
//                                         style: TextStyle(fontSize: 16),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                             SizedBox(width: 16),
//                             Expanded(
//                               child: InkWell(
//                                 onTap: () async {
//                                   final date = await showDatePicker(
//                                     context: context,
//                                     initialDate: _toDate ??
//                                         (_fromDate?.add(Duration(days: 1)) ??
//                                             DateTime.now()
//                                                 .add(Duration(days: 1))),
//                                     firstDate:
//                                         _fromDate?.add(Duration(days: 1)) ??
//                                             DateTime.now(),
//                                     lastDate:
//                                         DateTime.now().add(Duration(days: 365)),
//                                   );
//                                   if (date != null) {
//                                     setState(() => _toDate = date);
//                                   }
//                                 },
//                                 child: Container(
//                                   padding: EdgeInsets.all(16),
//                                   decoration: BoxDecoration(
//                                     border:
//                                         Border.all(color: Colors.grey[300]!),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Column(
//                                     crossAxisAlignment:
//                                         CrossAxisAlignment.start,
//                                     children: [
//                                       Text('Départ *',
//                                           style: TextStyle(
//                                               fontSize: 12,
//                                               color: Colors.grey[600])),
//                                       SizedBox(height: 4),
//                                       Text(
//                                         _toDate != null
//                                             ? _formatDate(_toDate!)
//                                             : 'Sélectionner',
//                                         style: TextStyle(fontSize: 16),
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//
//                         SizedBox(height: 16),
//
//                         // Prix et Statut Row
//                         Row(
//                           children: [
//                             Expanded(
//                               child: TextFormField(
//                                 controller: _priceController,
//                                 decoration: InputDecoration(
//                                   labelText: 'Prix par nuit (DA) *',
//                                   prefixIcon: Icon(Icons.attach_money),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 keyboardType: TextInputType.number,
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty)
//                                     return 'Prix requis';
//                                   if (double.tryParse(value) == null)
//                                     return 'Prix invalide';
//                                   return null;
//                                 },
//                               ),
//                             ),
//                             SizedBox(width: 16),
//                             Expanded(
//                               child: DropdownButtonFormField<String>(
//                                 value: _status,
//                                 decoration: InputDecoration(
//                                   labelText: 'Statut',
//                                   prefixIcon: Icon(Icons.info_outline),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                 ),
//                                 items: _statuses.map((status) {
//                                   return DropdownMenuItem(
//                                     value: status,
//                                     child: Text(
//                                       status,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   );
//                                 }).toList(),
//                                 onChanged: (status) =>
//                                     setState(() => _status = status!),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   SizedBox(width: 16),
//
//                   // Right Column - Dates and Price/Status
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.stretch,
//                       children: [
//                         // Section Clients - Fixed height to prevent layout issues
//                         Container(
//                           height: 350, // Fixed height instead of Expanded
//                           child: Card(
//                             elevation: 2,
//                             shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(8)),
//                             child: Padding(
//                               padding: EdgeInsets.all(16),
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   SizedBox(
//                                     height: 30,
//                                     child: Row(
//                                       children: [
//                                         Text(
//                                           _isEditingGuest
//                                               ? 'Modifier Client (Guest)'
//                                               : 'Informations Client (Guest)',
//                                           style: TextStyle(
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.bold),
//                                         ),
//                                         if (_isEditingGuest) ...[
//                                           Spacer(),
//                                           TextButton(
//                                             onPressed: _cancelGuestEdit,
//                                             child: Text(
//                                               'Annuler',
//                                               style: TextStyle(
//                                                   color: Colors.grey[600]),
//                                             ),
//                                           ),
//                                         ],
//                                       ],
//                                     ),
//                                   ),
//                                   SizedBox(height: 16),
//                                   KeyboardListener(
//                                     focusNode: FocusNode(),
//                                     onKeyEvent: _handleKeyPress,
//                                     child: Column(
//                                       children: [
//                                         TextFormField(
//                                           controller: _guestController,
//                                           decoration: InputDecoration(
//                                             labelText: 'Nom complet',
//                                             prefixIcon:
//                                                 Icon(Icons.person_outline),
//                                             border: OutlineInputBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                           ),
//                                           onFieldSubmitted: (_) => _addGuest(),
//                                         ),
//                                         SizedBox(height: 12),
//                                         TextFormField(
//                                           controller: _phoneController,
//                                           decoration: InputDecoration(
//                                             labelText: 'Téléphone',
//                                             prefixIcon: Icon(Icons.phone),
//                                             border: OutlineInputBorder(
//                                               borderRadius:
//                                                   BorderRadius.circular(8),
//                                             ),
//                                           ),
//                                           keyboardType: TextInputType.phone,
//                                           onFieldSubmitted: (_) => _addGuest(),
//                                         ),
//                                         SizedBox(height: 12),
//                                         Row(
//                                           children: [
//                                             Expanded(
//                                               child: TextFormField(
//                                                 controller: _idCardController,
//                                                 decoration: InputDecoration(
//                                                   labelText:
//                                                       'Carte d\'identité',
//                                                   prefixIcon:
//                                                       Icon(Icons.credit_card),
//                                                   border: OutlineInputBorder(
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                             8),
//                                                   ),
//                                                 ),
//                                                 onFieldSubmitted: (_) =>
//                                                     _addGuest(),
//                                               ),
//                                             ),
//                                             SizedBox(width: 12),
//                                             ElevatedButton.icon(
//                                               onPressed: _addGuest,
//                                               icon: Icon(_isEditingGuest
//                                                   ? Icons.save
//                                                   : Icons.add),
//                                               label: Text(_isEditingGuest
//                                                   ? 'Sauvegarder'
//                                                   : 'Ajouter'),
//                                               style: ElevatedButton.styleFrom(
//                                                 backgroundColor: _isEditingGuest
//                                                     ? Colors.orange
//                                                     : null,
//                                                 foregroundColor: _isEditingGuest
//                                                     ? Colors.white
//                                                     : null,
//                                                 padding: EdgeInsets.symmetric(
//                                                     horizontal: 16,
//                                                     vertical: 12),
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(8),
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   if (_selectedGuests.isNotEmpty) ...[
//                                     SizedBox(height: 16),
//                                     Text('Clients ajoutés:',
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.w500)),
//                                     SizedBox(height: 8),
//                                     Expanded(
//                                       child: SingleChildScrollView(
//                                         child: Wrap(
//                                           spacing: 8,
//                                           runSpacing: 4,
//                                           children: _selectedGuests
//                                               .asMap()
//                                               .entries
//                                               .map((entry) {
//                                             final int index = entry.key;
//                                             final Guest guest = entry.value;
//                                             final bool isBeingEdited =
//                                                 _isEditingGuest &&
//                                                     _editingGuestIndex == index;
//
//                                             return InkWell(
//                                               onTap: () =>
//                                                   _editGuest(guest, index),
//                                               onDoubleTap: () =>
//                                                   _cancelGuestEdit(),
//                                               child: Chip(
//                                                 avatar: CircleAvatar(
//                                                   backgroundColor: isBeingEdited
//                                                       ? Colors.orange
//                                                       : Colors.deepPurple,
//                                                   child: Icon(
//                                                     isBeingEdited
//                                                         ? Icons.edit
//                                                         : Icons.person,
//                                                     size: 16,
//                                                     color: Colors.white,
//                                                   ),
//                                                 ),
//                                                 label: Text(
//                                                   guest.fullName,
//                                                   style: TextStyle(
//                                                     fontWeight: FontWeight.w500,
//                                                     color: Theme.of(context)
//                                                         .colorScheme
//                                                         .onSurface,
//                                                   ),
//                                                 ),
//                                                 deleteIcon: Icon(
//                                                   Icons.close,
//                                                   size: 18,
//                                                   color: Theme.of(context)
//                                                       .colorScheme
//                                                       .error,
//                                                 ),
//                                                 onDeleted: () =>
//                                                     _removeGuest(guest),
//                                                 shape: RoundedRectangleBorder(
//                                                   borderRadius:
//                                                       BorderRadius.circular(8),
//                                                 ),
//                                                 backgroundColor: isBeingEdited
//                                                     ? Colors.orange
//                                                         .withOpacity(0.1)
//                                                     : Theme.of(context)
//                                                         .colorScheme
//                                                         .surfaceContainerHighest,
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                         horizontal: 8,
//                                                         vertical: 4),
//                                                 materialTapTargetSize:
//                                                     MaterialTapTargetSize
//                                                         .shrinkWrap,
//                                                 visualDensity:
//                                                     VisualDensity.compact,
//                                               ),
//                                             );
//                                           }).toList(),
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//
//         // Footer - Bouton dynamique selon le mode
//         Container(
//           padding: EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: Colors.grey[50],
//             borderRadius: BorderRadius.only(
//               bottomLeft: Radius.circular(16),
//               bottomRight: Radius.circular(16),
//             ),
//           ),
//           child: Row(
//             children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: _isLoading ? null : () => Navigator.pop(context),
//                   child: Text('Annuler'),
//                   style: OutlinedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//               SizedBox(width: 16),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _saveReservation,
//                   child: _isLoading
//                       ? SizedBox(
//                           height: 20,
//                           width: 20,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             valueColor:
//                                 AlwaysStoppedAnimation<Color>(Colors.white),
//                           ),
//                         )
//                       : Text(widget.isEditing
//                           ? 'Modifier la réservation'
//                           : 'Créer la réservation'),
//                   style: ElevatedButton.styleFrom(
//                     padding: EdgeInsets.symmetric(vertical: 12),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }
