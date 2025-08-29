import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:kenzy/objectBox/tests/timelines/mistral/provider_hotel.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../../Entity.dart';
import 'HotelDataInitializer.dart';
import 'claude_crud.dart';
import 'home_Hotel.dart';

class HotelReservationDataSource extends CalendarDataSource {
  HotelReservationDataSource(List<Reservation> reservations, List<Room> rooms) {
    appointments = reservations;
    resources = rooms
        .map((room) => CalendarResource(
              id: room.id,
              // L'ID doit correspondre à celui utilisé dans getResourceIds
              displayName: room.code,
              color: Colors.black45,
            ))
        .toList();
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Reservation).from;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as Reservation).to;
  }

  @override
  String getSubject(int index) {
    final reservation = appointments![index] as Reservation;
    final guestName = reservation.guests.isNotEmpty
        ? reservation.guests.first.fullName
        : 'Aucun client';
    final totalPrice = reservation.pricePerNight *
        reservation.to.difference(reservation.from).inDays;
    return '$guestName\nNuitée : ${reservation.pricePerNight.toStringAsFixed(2)} DZD\nTotal : ${totalPrice.toStringAsFixed(2)} DZD\nStatus : ${reservation.status}';
  }

  @override
  List<Object> getResourceIds(int index) {
    final reservation = appointments![index] as Reservation;
    // Retourner l'ID de la chambre, pas l'objet Room
    return [
      reservation.room.target!.id
    ]; // ou reservation.room.targetId si disponible
  }

  @override
  Color getColor(int index) {
    // Couleurs pour les barres
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
      drawer: const AppDrawer(),
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
              _buildHotelInfo(),
              Wrap(
                children: [
                  Expanded(
                    // ou Flexible
                    child: _buildRoomStatusLegend(),
                  ),
                  FilledButton.icon(
                    onPressed: _showEditOptions,
                    icon: const Icon(
                      Icons.list,
                      // Icône "outlined" pour un look plus épuré
                      size: 18,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Lists',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.deepPurple.shade400,
                      // Couleur principale du thème
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                            12), // Coins arrondis pour un style moderne
                      ),
                      elevation: 3,
                      // Ombre légère pour le relief
                      shadowColor: Colors.deepPurple.shade200,
                      // Ombre colorée subtile
                      textStyle: const TextStyle(
                        fontFamily: 'OSWALD',
                        fontWeight: FontWeight.w600,
                      ),
                      visualDensity: VisualDensity.standard,
                      // Densité adaptée
                      minimumSize: const Size(120,
                          40), // Taille minimale pour un bouton confortable
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      final hotelProvider = context.read<HotelProvider>();
                      final initializer = HotelDataInitializer(hotelProvider);

                      await initializer.initializeAllDefaultData();
                    },
                    child: const Text("Initialiser les données"),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final hotelProvider = context.read<HotelProvider>();
                      await hotelProvider.clearAllTestData();
                    },
                    child: const Text("♻️ Reset & Re-init Data"),
                  ),
                ],
              ),
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
        visibleResourceCount: 10, //_calculateVisibleRooms(),
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
      //  automaticallyImplyLeading: false,
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
      title: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 10),
          Text(
            _currentHotel?.name ?? "Gestion Hôtel",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: Colors.white,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () async {
            final hotelProvider = context.read<HotelProvider>();
            final initializer = HotelDataInitializer(hotelProvider);

            await initializer.initializeAllDefaultData();
          },
          child: const Text("Initialiser les données"),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            final hotelProvider = context.read<HotelProvider>();
            await hotelProvider.clearAllTestData();
          },
          child: const Text("♻️ Reset & Re-init Data"),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (ctx) => HotelListPage()));
          },
          icon: Icon(Icons.ac_unit_outlined),
        ),
        IconButton(
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (context) => ReservationPage())),
            icon: Icon(Icons.hotel)),
        // Bouton "Aujourd'hui"
        Tooltip(
          message: "Aller à aujourd'hui",
          child: IconButton(
            icon: Icon(Icons.today_rounded),
            onPressed: () => _calendarController.displayDate = DateTime.now(),
          ),
        ),
        const SizedBox(width: 8),
        // Bouton ajouter/modifier hôtel
        Tooltip(
          message: "Créer / Modifier un hôtel",
          child: IconButton(
            icon: Icon(Icons.add_business_rounded),
            onPressed: _showHotelCreationDialog,
          ),
        ),
        const SizedBox(width: 8),
        // Menu vue calendrier
        PopupMenuButton<CalendarView>(
          tooltip: "Changer la vue du calendrier",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          icon: Icon(Icons.view_week_rounded, color: Colors.white),
          onSelected: (view) => setState(() => _currentView = view),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: CalendarView.timelineDay,
              child: Row(
                children: [
                  Icon(Icons.calendar_view_day, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Jour'),
                ],
              ),
            ),
            PopupMenuItem(
              value: CalendarView.timelineWeek,
              child: Row(
                children: [
                  Icon(Icons.view_week, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Semaine'),
                ],
              ),
            ),
            PopupMenuItem(
              value: CalendarView.timelineMonth,
              child: Row(
                children: [
                  Icon(Icons.calendar_month, color: Colors.deepPurple),
                  SizedBox(width: 8),
                  Text('Mois'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 40),
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
              );
              Navigator.pop(context);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  void createHotel(HotelProvider provider, String name, int floors,
      int roomsPerFloor, List<String> avoidedNumbers) {
    // Créer l'hôtel
    final hotel = Hotel(
      name: name.isNotEmpty ? name : 'Mon Hôtel',
      floors: floors,
      roomsPerFloor: roomsPerFloor,
    );

    // Stocker les numéros évités
    hotel.avoidedNumbers = avoidedNumbers.join(',');

    // Ajouter l'hôtel au provider d'abord (pour obtenir l'ID)
    provider.addHotel(hotel);

    // Générer les chambres comme dans votre ancien code
    final rooms = <Room>[]; // Utiliser Room au lieu de HotelRoom

    for (int floor = 1; floor <= floors; floor++) {
      for (int roomNum = 1; roomNum <= roomsPerFloor; roomNum++) {
        final roomNumber =
            '${floor.toString()}${roomNum.toString().padLeft(2, '0')}';

        // Vérifier si ce numéro doit être évité
        bool shouldAvoid = false;
        for (String avoided in avoidedNumbers) {
          if (avoided.isNotEmpty && roomNumber.contains(avoided)) {
            shouldAvoid = true;
            break;
          }
        }

        if (!shouldAvoid) {
          final room = Room(
            code: roomNumber,
            // Utiliser 'code' au lieu de 'roomNumber'

            basePrice: 80 + Random().nextDouble() * 120,
            // Prix entre 80 et 200€
            status: 'available', // Statut par défaut
          );

          rooms.add(room);
        }
      }
    }

    // Ajouter toutes les chambres à l'hôtel en une seule fois
    provider.addRoomsToHotel(hotel, rooms);

    // Générer les réservations aléatoires si vous avez cette fonctionnalité
    // final randomReservations = generateRandomReservations(hotel);
    // for (final reservation in randomReservations) {
    //   provider.addReservation(reservation);
    // }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hôtel "$name" créé avec ${rooms.length} chambres !'),
        backgroundColor: Colors.green,
      ),
    );
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
                    '${totalPrice.toStringAsFixed(2)} DZD',
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
    //             '${totalPrice.toStringAsFixed(2)} DZD',
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              'Prix/nuit',
              '${pricePerNight.toStringAsFixed(2)} DZD',
              icon: Icons.attach_money_rounded,
            ),
            Divider(),
            _buildDetailRow(
              'Prix total',
              '${totalPrice.toStringAsFixed(2)} DZD',
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
}

// 2. Version modifiée de ReservationDialogContent pour supporter l'édition
class ReservationDialogContent extends StatefulWidget {
  final Room? preselectedRoom;
  final DateTime? preselectedDate;
  final Hotel currentHotel;
  final HotelProvider provider;
  final BuildContext parentContext;
  final VoidCallback onReservationAdded;
  final bool isEditing; // Nouveau paramètre
  final Reservation? existingReservation; // Nouveau paramètre

  const ReservationDialogContent({
    Key? key,
    this.preselectedRoom,
    this.preselectedDate,
    required this.currentHotel,
    required this.provider,
    required this.parentContext,
    required this.onReservationAdded,
    this.isEditing = false, // Valeur par défaut
    this.existingReservation, // Peut être null pour nouveaux
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
  final _priceController = TextEditingController();

  Room? _selectedRoom;
  Employee? _selectedEmployee;
  List<Guest> _selectedGuests = [];
  DateTime? _fromDate;
  DateTime? _toDate;
  String _status = "Confirmée";
  bool _isLoading = false;

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

  @override
  void initState() {
    super.initState();

    if (widget.isEditing && widget.existingReservation != null) {
      // Mode édition - pré-remplir avec les données existantes
      _initializeForEdit();
    } else {
      // Mode création - utiliser les valeurs par défaut
      _initializeForNew();
    }
  }

  void _initializeForEdit() {
    final reservation = widget.existingReservation!;

    // Trouver la chambre correspondante dans la liste des chambres de l'hôtel
    // pour éviter les problèmes de référence d'objet ObjectBox
    final roomId = reservation.room.target?.id;
    _selectedRoom = roomId != null
        ? widget.currentHotel.rooms
            .cast<Room?>()
            .firstWhere((room) => room?.id == roomId, orElse: () => null)
        : null;

    // Même logique pour l'employé
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
  }

  void _initializeForNew() {
    _selectedRoom = widget.preselectedRoom;
    _fromDate = widget.preselectedDate ?? DateTime.now();
    _toDate = _fromDate!.add(Duration(days: 1));
  }

  @override
  void dispose() {
    _guestController.dispose();
    _phoneController.dispose();
    _idCardController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _addGuest() {
    if (_guestController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _idCardController.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs du client',
          isError: true);
      return;
    }

    final trimmedName = _guestController.text.trim();

    // Vérifier si le client existe déjà (seulement pour l'ajout, pas l'édition)
    if (!_isEditingGuest &&
        _selectedGuests.any((guest) =>
            guest.fullName.toLowerCase() == trimmedName.toLowerCase())) {
      _showSnackBar('Ce client est déjà ajouté', isError: true);
      return;
    }

    if (_isEditingGuest) {
      // Mode édition - utiliser la méthode de sauvegarde
      _saveGuestEdit();
    } else {
      // Mode ajout - créer un nouveau client
      final newGuest = Guest(
        fullName: trimmedName,
        phoneNumber: _phoneController.text.trim(),
        idCardNumber: _idCardController.text.trim(),
      );

      setState(() {
        _selectedGuests.add(newGuest);
        _guestController.clear();
        _phoneController.clear();
        _idCardController.clear();
      });

      _showSnackBar('Client ajouté avec succès');
    }
  }

  void _removeGuest(Guest guest) {
    setState(() {
      _selectedGuests.remove(guest);
    });
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(widget.parentContext).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _handleKeyPress(KeyEvent event) {
    // Détecter la touche Entrée
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      if (_guestController.text.trim().isNotEmpty ||
          _phoneController.text.trim().isNotEmpty ||
          _idCardController.text.trim().isNotEmpty) {
        _addGuest();
      }
    }
  }

  void _editGuest(Guest guest, int index) {
    setState(() {
      _isEditingGuest = true;
      _guestBeingEdited = guest;
      _editingGuestIndex = index;

      // Pré-remplir les champs avec les données du client
      _guestController.text = guest.fullName;
      _phoneController.text = guest.phoneNumber ?? '';
      _idCardController.text = guest.idCardNumber ?? '';
    });
  }

  void _cancelGuestEdit() {
    setState(() {
      _isEditingGuest = false;
      _guestBeingEdited = null;
      _editingGuestIndex = null;

      // Vider les champs
      _guestController.clear();
      _phoneController.clear();
      _idCardController.clear();
    });
  }

  void _saveGuestEdit() async {
    if (_guestController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _idCardController.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs du client',
          isError: true);
      return;
    }

    final trimmedName = _guestController.text.trim();

    // Vérifier si le nom existe déjà (sauf pour le client en cours d'édition)
    bool nameExists = false;
    for (int i = 0; i < _selectedGuests.length; i++) {
      if (i != _editingGuestIndex &&
          _selectedGuests[i].fullName.toLowerCase() ==
              trimmedName.toLowerCase()) {
        nameExists = true;
        break;
      }
    }

    if (nameExists) {
      _showSnackBar('Ce nom de client existe déjà', isError: true);
      return;
    }

    try {
      // Mettre à jour le client existant
      final guestToUpdate = _selectedGuests[_editingGuestIndex!];
      guestToUpdate.fullName = trimmedName;
      guestToUpdate.phoneNumber = _phoneController.text.trim();
      guestToUpdate.idCardNumber = _idCardController.text.trim();

      // Sauvegarder dans ObjectBox si le client a un ID (existe déjà dans la DB)
      if (guestToUpdate.id != 0) {
        await widget.provider.updateGuest(guestToUpdate);
      }
      // Si l'ID est 0, c'est un nouveau client qui sera sauvegardé lors de la sauvegarde de la réservation

      setState(() {
        // Réinitialiser l'état d'édition
        _isEditingGuest = false;
        _guestBeingEdited = null;
        _editingGuestIndex = null;

        // Vider les champs
        _guestController.clear();
        _phoneController.clear();
        _idCardController.clear();
      });

      _showSnackBar('Client modifié avec succès');
    } catch (e) {
      _showSnackBar('Erreur lors de la modification du client: $e',
          isError: true);
    }
  }

  Future<void> _saveReservation() async {
    if (!_formKey.currentState!.validate()) return;

    // Ajouter le client en cours si les champs sont remplis
    if (_guestController.text.trim().isNotEmpty) {
      _addGuest();
    }

    if (_selectedRoom == null ||
        _selectedEmployee == null ||
        _fromDate == null ||
        _toDate == null ||
        _selectedGuests.isEmpty ||
        _priceController.text.trim().isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs obligatoires',
          isError: true);
      return;
    }

    if (_fromDate!.isAfter(_toDate!) || _fromDate!.isAtSameMomentAs(_toDate!)) {
      _showSnackBar('La date de départ doit être après la date d\'arrivée',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.isEditing && widget.existingReservation != null) {
        // Mode édition - mettre à jour toutes les propriétés directement
        final reservation = widget.existingReservation!;

        // Mettre à jour toutes les propriétés
        reservation.receptionist.target = _selectedEmployee;
        reservation.pricePerNight = double.parse(_priceController.text);
        reservation.status = _status;

        // Gérer les clients - sauvegarder nouveaux et mis à jour
        for (final guest in _selectedGuests) {
          if (guest.id == 0) {
            // Nouveau client
            await widget.provider.addGuest(guest);
          } else {
            // Client existant - s'assurer qu'il est à jour dans ObjectBox
            await widget.provider.updateGuest(guest);
          }
        }

        // Mettre à jour la liste des clients
        reservation.guests.clear();
        reservation.guests.addAll(_selectedGuests);

        // Maintenant faire la mise à jour avec vérification de disponibilité
        final result = await widget.provider.updateReservation(
          reservation,
          newRoom: _selectedRoom,
          newFrom: _fromDate,
          newTo: _toDate,
        );

        if (result.isSuccess) {
          widget.onReservationAdded();
          Navigator.pop(context);
          _showSnackBar('Réservation modifiée avec succès');
        } else if (result.conflict != null) {
          _showConflictDialog(result.conflict!);
        } else {
          _showSnackBar(result.error ?? 'Erreur lors de la modification',
              isError: true);
        }
      } else {
        // Sauvegarder nouveaux et clients mis à jour
        for (final guest in _selectedGuests) {
          if (guest.id == 0) {
            // Nouveau client
            await widget.provider.addGuest(guest);
          } else {
            // Client existant - s'assurer qu'il est à jour dans ObjectBox
            await widget.provider.updateGuest(guest);
          }
        }

        final result = await widget.provider.addReservation(
          room: _selectedRoom!,
          receptionist: _selectedEmployee!,
          guests: _selectedGuests,
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: double.parse(_priceController.text),
          status: _status,
        );

        if (result.isSuccess) {
          widget.onReservationAdded();
          Navigator.pop(context);
          _showSnackBar('Réservation créée avec succès');
        } else if (result.conflict != null) {
          _showConflictDialog(result.conflict!);
        } else {
          _showSnackBar(result.error ?? 'Erreur lors de la création',
              isError: true);
        }
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'opération: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
                'La chambre ${conflict.room.code} est déjà réservée pour cette période.'),
            SizedBox(height: 16),
            Text('Réservations en conflit:'),
            ...conflict.conflictingReservations.map((res) => Padding(
                  padding: EdgeInsets.only(left: 8, top: 4),
                  child: Text(
                      '• ${_formatDate(res.from)} → ${_formatDate(res.to)}'),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Forcer la réservation malgré le conflit
              _saveWithForce();
            },
            child: Text('Forcer quand même'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
        ],
      ),
    );
  }

  Future<void> _saveWithForce() async {
    setState(() => _isLoading = true);

    try {
      if (widget.isEditing && widget.existingReservation != null) {
        // Sauvegarder d'abord les nouveaux clients
        for (final guest in _selectedGuests) {
          if (guest.id == 0) {
            await widget.provider.addGuest(guest);
          }
        }

        final result = await widget.provider.updateReservation(
          widget.existingReservation!,
          newRoom: _selectedRoom,
          newFrom: _fromDate,
          newTo: _toDate,
          forceOverride: true,
        );

        if (result.isSuccess) {
          widget.onReservationAdded();
          Navigator.pop(context);
          _showSnackBar('Réservation modifiée avec succès (forcée)');
        }
      } else {
        // Sauvegarder d'abord les nouveaux clients
        for (final guest in _selectedGuests) {
          if (guest.id == 0) {
            await widget.provider.addGuest(guest);
          }
        }

        final result = await widget.provider.addReservation(
          room: _selectedRoom!,
          receptionist: _selectedEmployee!,
          guests: _selectedGuests,
          from: _fromDate!,
          to: _toDate!,
          pricePerNight: double.parse(_priceController.text),
          status: _status,
          forceOverride: true,
        );

        if (result.isSuccess) {
          widget.onReservationAdded();
          Navigator.pop(context);
          _showSnackBar('Réservation créée avec succès (forcée)');
        }
      }
    } catch (e) {
      _showSnackBar('Erreur lors de l\'opération forcée: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double w = constraints.maxWidth;

        if (w < 600) {
          // 📱 Mobile
          return buildForm();
        } else if (w < 1200) {
          // 💻 Tablette
          return buildForm2();
        } else {
          // 🖥️ Desktop
          return buildForm2();
        }
      },
    );
  }

  Column buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header - Titre dynamique selon le mode
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.hotel, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                widget.isEditing
                    ? 'Modifier la réservation'
                    : 'Nouvelle Réservation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Content - Même contenu que votre formulaire existant mais avec les données pré-remplies
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Chambre et Employé
                  SizedBox(
                    height: 120,
                    child: Column(
                      children: [
                        DropdownButtonFormField<int>(
                          isExpanded: true,
                          isDense: true,
                          value: _selectedEmployee?.id,
                          decoration: InputDecoration(
                            labelText: 'Réceptionniste *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: widget.provider.employees.map((emp) {
                            return DropdownMenuItem<int>(
                              value: emp.id,
                              // Utilisez l'ID comme valeur unique
                              child: Text(emp.fullName),
                            );
                          }).toList(),
                          onChanged: (int? empId) {
                            setState(() {
                              _selectedEmployee = widget.provider.employees
                                  .firstWhere((emp) => emp.id == empId);
                            });
                          },
                          validator: (value) => value == null
                              ? 'Choisissez un réceptionniste'
                              : null,
                        ),
                        Spacer(),
                        DropdownButtonFormField<Room>(
                          isExpanded: true,
                          isDense: true,
                          value: _selectedRoom,
                          decoration: InputDecoration(
                            labelText: 'Chambre *',
                            prefixIcon: Icon(Icons.room),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: widget.currentHotel.rooms.map((room) {
                            final categoryName =
                                widget.provider.getRoomCategoryName(room);
                            return DropdownMenuItem(
                              value: room,
                              child: Text(
                                  '${room.code} $categoryName ${room.type ?? ''}'),
                            );
                          }).toList(),
                          onChanged: (room) =>
                              setState(() => _selectedRoom = room),
                          validator: (value) =>
                              value == null ? 'Choisissez une chambre' : null,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 24),

                  // Section Clients
                  // Section Clients
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 30,
                            child: Row(
                              children: [
                                Text(
                                  _isEditingGuest
                                      ? 'Modifier Client'
                                      : 'Informations Client',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                if (_isEditingGuest) ...[
                                  Spacer(),
                                  TextButton(
                                    onPressed: _cancelGuestEdit,
                                    child: Text(
                                      'Annuler',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: _handleKeyPress,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _guestController,
                                  decoration: InputDecoration(
                                    labelText: 'Nom complet',
                                    prefixIcon: Icon(Icons.person_outline),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _addGuest(),
                                ),
                                SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Téléphone',
                                    prefixIcon: Icon(Icons.phone),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  keyboardType: TextInputType.phone,
                                  onFieldSubmitted: (_) => _addGuest(),
                                ),
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _idCardController,
                                        decoration: InputDecoration(
                                          labelText: 'Carte d\'identité',
                                          prefixIcon: Icon(Icons.credit_card),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        onFieldSubmitted: (_) => _addGuest(),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    ElevatedButton.icon(
                                      onPressed: _addGuest,
                                      icon: Icon(_isEditingGuest
                                          ? Icons.save
                                          : Icons.add),
                                      label: Text(_isEditingGuest
                                          ? 'Sauvegarder'
                                          : 'Ajouter'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isEditingGuest
                                            ? Colors.orange
                                            : null,
                                        foregroundColor: _isEditingGuest
                                            ? Colors.white
                                            : null,
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 12),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (_selectedGuests.isNotEmpty) ...[
                            SizedBox(height: 16),
                            Text('Clients ajoutés:',
                                style: TextStyle(fontWeight: FontWeight.w500)),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children:
                                  _selectedGuests.asMap().entries.map((entry) {
                                final int index = entry.key;
                                final Guest guest = entry.value;
                                final bool isBeingEdited = _isEditingGuest &&
                                    _editingGuestIndex == index;

                                return InkWell(
                                  onTap: () => _editGuest(guest, index),
                                  onDoubleTap: () => _cancelGuestEdit(),
                                  child: Chip(
                                    avatar: CircleAvatar(
                                      backgroundColor: isBeingEdited
                                          ? Colors.orange
                                          : Colors.deepPurple,
                                      child: Icon(
                                        isBeingEdited
                                            ? Icons.edit
                                            : Icons.person,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    label: Text(
                                      guest.fullName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    deleteIcon: Icon(
                                      Icons.close,
                                      size: 18,
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    onDeleted: () => _removeGuest(guest),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    backgroundColor: isBeingEdited
                                        ? Colors.orange.withOpacity(0.1)
                                        : Theme.of(context)
                                            .colorScheme
                                            .surfaceContainerHighest,
                                    // side: BorderSide(
                                    //   color: isBeingEdited
                                    //       ? Colors.orange
                                    //       : Theme.of(context)
                                    //           .colorScheme
                                    //           .outlineVariant,
                                    //   width: isBeingEdited ? 2 : 1,
                                    // ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 24),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _fromDate ?? DateTime.now(),
                              firstDate:
                                  DateTime.now().subtract(Duration(days: 30)),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() {
                                _fromDate = date;
                                if (_toDate != null &&
                                    _toDate!.isBefore(
                                        date.add(Duration(days: 1)))) {
                                  _toDate = date.add(Duration(days: 1));
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Arrivée *',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                                SizedBox(height: 4),
                                Text(
                                  _fromDate != null
                                      ? _formatDate(_fromDate!)
                                      : 'Sélectionner',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _toDate ??
                                  (_fromDate?.add(Duration(days: 1)) ??
                                      DateTime.now().add(Duration(days: 1))),
                              firstDate: _fromDate?.add(Duration(days: 1)) ??
                                  DateTime.now(),
                              lastDate: DateTime.now().add(Duration(days: 365)),
                            );
                            if (date != null) {
                              setState(() => _toDate = date);
                            }
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Départ *',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600])),
                                SizedBox(height: 4),
                                Text(
                                  _toDate != null
                                      ? _formatDate(_toDate!)
                                      : 'Sélectionner',
                                  style: TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Prix et Statut
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(
                            labelText: 'Prix par nuit (DZD) *',
                            prefixIcon: Icon(Icons.attach_money),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'Prix requis';
                            if (double.tryParse(value) == null)
                              return 'Prix invalide';
                            return null;
                          },
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          isDense: true,
                          value: _status,
                          decoration: InputDecoration(
                            labelText: 'Statut',
                            prefixIcon: Icon(Icons.info_outline),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          items: _statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            );
                          }).toList(),
                          onChanged: (status) =>
                              setState(() => _status = status!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // Footer - Bouton dynamique selon le mode
        Container(
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
        ),
      ],
    );
  }

  /// Retourne le nom de la catégorie d'une chambre
  String getRoomCategoryName(Room room) {
    return room.category.target?.name ?? 'Aucune catégorie';
  }

  Column buildForm2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header - Titre dynamique selon le mode
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.hotel, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                widget.isEditing
                    ? 'Modifier la réservation'
                    : 'Nouvelle Réservation',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
        ),

        // Content - Fixed layout structure
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Left Column - Chambre et Employé + Section Clients
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Chambre et Employé Row
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<Room>(
                                isExpanded: true,
                                isDense: true,
                                value: _selectedRoom,
                                decoration: InputDecoration(
                                  labelText: 'Chambre *',
                                  prefixIcon: Icon(Icons.room),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: widget.currentHotel.rooms.map((room) {
                                  final categoryName =
                                      widget.provider.getRoomCategoryName(room);
                                  return DropdownMenuItem(
                                    value: room,
                                    child: Text(
                                        '${room.code} $categoryName ${room.type ?? ''}'),
                                  );
                                }).toList(),
                                onChanged: (room) =>
                                    setState(() => _selectedRoom = room),
                                validator: (value) => value == null
                                    ? 'Choisissez une chambre'
                                    : null,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedEmployee?.id,
                                decoration: InputDecoration(
                                  labelText: 'Réceptionniste *',
                                  prefixIcon: Icon(Icons.person),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: widget.provider.employees.map((emp) {
                                  return DropdownMenuItem<int>(
                                    value: emp.id,
                                    // Utilisez l'ID comme valeur unique
                                    child: Text(emp.fullName),
                                  );
                                }).toList(),
                                onChanged: (int? empId) {
                                  setState(() {
                                    _selectedEmployee = widget
                                        .provider.employees
                                        .firstWhere((emp) => emp.id == empId);
                                  });
                                },
                                validator: (value) => value == null
                                    ? 'Choisissez un réceptionniste'
                                    : null,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),
                        // Dates Row
                        Row(
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _fromDate ?? DateTime.now(),
                                    firstDate: DateTime.now()
                                        .subtract(Duration(days: 30)),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _fromDate = date;
                                      if (_toDate != null &&
                                          _toDate!.isBefore(
                                              date.add(Duration(days: 1)))) {
                                        _toDate = date.add(Duration(days: 1));
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Arrivée *',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                      SizedBox(height: 4),
                                      Text(
                                        _fromDate != null
                                            ? _formatDate(_fromDate!)
                                            : 'Sélectionner',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: InkWell(
                                onTap: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _toDate ??
                                        (_fromDate?.add(Duration(days: 1)) ??
                                            DateTime.now()
                                                .add(Duration(days: 1))),
                                    firstDate:
                                        _fromDate?.add(Duration(days: 1)) ??
                                            DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setState(() => _toDate = date);
                                  }
                                },
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Départ *',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600])),
                                      SizedBox(height: 4),
                                      Text(
                                        _toDate != null
                                            ? _formatDate(_toDate!)
                                            : 'Sélectionner',
                                        style: TextStyle(fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // Prix et Statut Row
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _priceController,
                                decoration: InputDecoration(
                                  labelText: 'Prix par nuit (DZD) *',
                                  prefixIcon: Icon(Icons.attach_money),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Prix requis';
                                  if (double.tryParse(value) == null)
                                    return 'Prix invalide';
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _status,
                                decoration: InputDecoration(
                                  labelText: 'Statut',
                                  prefixIcon: Icon(Icons.info_outline),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: _statuses.map((status) {
                                  return DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (status) =>
                                    setState(() => _status = status!),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 16),

                  // Right Column - Dates and Price/Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Section Clients - Fixed height to prevent layout issues
                        Container(
                          height: 350, // Fixed height instead of Expanded
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 30,
                                    child: Row(
                                      children: [
                                        Text(
                                          _isEditingGuest
                                              ? 'Modifier Client (Guest)'
                                              : 'Informations Client (Guest)',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        if (_isEditingGuest) ...[
                                          Spacer(),
                                          TextButton(
                                            onPressed: _cancelGuestEdit,
                                            child: Text(
                                              'Annuler',
                                              style: TextStyle(
                                                  color: Colors.grey[600]),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  KeyboardListener(
                                    focusNode: FocusNode(),
                                    onKeyEvent: _handleKeyPress,
                                    child: Column(
                                      children: [
                                        TextFormField(
                                          controller: _guestController,
                                          decoration: InputDecoration(
                                            labelText: 'Nom complet',
                                            prefixIcon:
                                                Icon(Icons.person_outline),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          onFieldSubmitted: (_) => _addGuest(),
                                        ),
                                        SizedBox(height: 12),
                                        TextFormField(
                                          controller: _phoneController,
                                          decoration: InputDecoration(
                                            labelText: 'Téléphone',
                                            prefixIcon: Icon(Icons.phone),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          keyboardType: TextInputType.phone,
                                          onFieldSubmitted: (_) => _addGuest(),
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _idCardController,
                                                decoration: InputDecoration(
                                                  labelText:
                                                      'Carte d\'identité',
                                                  prefixIcon:
                                                      Icon(Icons.credit_card),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                                onFieldSubmitted: (_) =>
                                                    _addGuest(),
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            ElevatedButton.icon(
                                              onPressed: _addGuest,
                                              icon: Icon(_isEditingGuest
                                                  ? Icons.save
                                                  : Icons.add),
                                              label: Text(_isEditingGuest
                                                  ? 'Sauvegarder'
                                                  : 'Ajouter'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: _isEditingGuest
                                                    ? Colors.orange
                                                    : null,
                                                foregroundColor: _isEditingGuest
                                                    ? Colors.white
                                                    : null,
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (_selectedGuests.isNotEmpty) ...[
                                    SizedBox(height: 16),
                                    Text('Clients ajoutés:',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500)),
                                    SizedBox(height: 8),
                                    Expanded(
                                      child: SingleChildScrollView(
                                        child: Wrap(
                                          spacing: 8,
                                          runSpacing: 4,
                                          children: _selectedGuests
                                              .asMap()
                                              .entries
                                              .map((entry) {
                                            final int index = entry.key;
                                            final Guest guest = entry.value;
                                            final bool isBeingEdited =
                                                _isEditingGuest &&
                                                    _editingGuestIndex == index;

                                            return InkWell(
                                              onTap: () =>
                                                  _editGuest(guest, index),
                                              onDoubleTap: () =>
                                                  _cancelGuestEdit(),
                                              child: Chip(
                                                avatar: CircleAvatar(
                                                  backgroundColor: isBeingEdited
                                                      ? Colors.orange
                                                      : Colors.deepPurple,
                                                  child: Icon(
                                                    isBeingEdited
                                                        ? Icons.edit
                                                        : Icons.person,
                                                    size: 16,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                label: Text(
                                                  guest.fullName,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                                ),
                                                deleteIcon: Icon(
                                                  Icons.close,
                                                  size: 18,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .error,
                                                ),
                                                onDeleted: () =>
                                                    _removeGuest(guest),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                backgroundColor: isBeingEdited
                                                    ? Colors.orange
                                                        .withOpacity(0.1)
                                                    : Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 4),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
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

        // Footer - Bouton dynamique selon le mode
        Container(
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
        ),
      ],
    );
  }
}
