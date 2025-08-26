import 'dart:math';

import 'package:faker/faker.dart' show Faker;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../hotelScreen.dart';
import 'home_Hotel.dart';

// ========================= MODÈLE CHAMBRE =========================

class HotelRoom {
  final String roomNumber;
  final int floor;
  final double basePrice;
  bool isAvailable;
  RoomState currentState;

  HotelRoom({
    required this.roomNumber,
    required this.floor,
    required this.basePrice,
    this.isAvailable = true,
    this.currentState = RoomState.empty,
  });

  String get id => 'room_$roomNumber';
}

enum RoomState {
  empty, // Blanche - aucune réservation
  occupied, // Verte - occupée aujourd'hui
  waitingGuest, // Bleue - libre aujourd'hui mais réservation future
}

// ========================= MODÈLE HOTEL =========================

class Hotel {
  final String name;
  final int totalFloors;
  final int roomsPerFloor;
  final List<String> avoidedNumbers;
  final List<HotelRoom> rooms;

  Hotel({
    required this.name,
    required this.totalFloors,
    required this.roomsPerFloor,
    required this.avoidedNumbers,
    required this.rooms,
  });
}

// ========================= DATA SOURCE =========================

class HotelReservationDataSource extends CalendarDataSource {
  HotelReservationDataSource(
      List<Reservation> reservations, List<HotelRoom> rooms) {
    appointments = reservations;
    resources = rooms
        .map((room) => CalendarResource(
              id: room.id,
              displayName: room.roomNumber,
              color: _getRoomColor(room),
            ))
        .toList();
  }

  Color _getRoomColor(HotelRoom room) {
    switch (room.currentState) {
      case RoomState.empty:
        return Colors.white;
      case RoomState.occupied:
        return Colors.green.shade100;
      case RoomState.waitingGuest:
        return Colors.blue.shade100;
    }
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Reservation).startDate;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as Reservation).endDate;
  }

  @override
  String getSubject(int index) {
    final reservation = appointments![index] as Reservation;
    final totalPrice = reservation.pricePerNight *
        reservation.endDate.difference(reservation.startDate).inDays;
    return '${reservation.clientName}\nNuitée : ${reservation.pricePerNight.toStringAsFixed(2)} DZD = Total : ${totalPrice.toStringAsFixed(2)} DZD \nStatus : ${reservation.status}';
  }

  @override
  List<Object> getResourceIds(int index) {
    final reservation = appointments![index] as Reservation;
    return ['room_${reservation.roomName}'];
  }

  @override
  MaterialColor getColor(int index) {
    // Couleurs aléatoires pour les barres
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

class Hotel_ManagementA extends StatefulWidget {
  @override
  _Hotel_ManagementAState createState() => _Hotel_ManagementAState();
}

class _Hotel_ManagementAState extends State<Hotel_ManagementA> {
  Hotel? _currentHotel;
  List<Reservation> _reservations = [];
  late HotelReservationDataSource _dataSource;
  final CalendarController _calendarController = CalendarController();
  CalendarView _currentView = CalendarView.timelineMonth;

  @override
  void initState() {
    super.initState();
    _checkHotelExists();
  }

  void _checkHotelExists() {
    // Simuler la vérification de l'existence d'un hôtel
    if (_currentHotel == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showHotelCreationDialog();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentHotel == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel, size: 100, color: Colors.grey),
              SizedBox(height: 20),
              Text('Créez votre hôtel pour commencer',
                  style: TextStyle(fontSize: 18, color: Colors.grey)),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _showHotelCreationDialog,
                child: Text('Créer un hôtel'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildHotelInfo(),
          _buildRoomStatusLegend(),
          Expanded(child: _buildCalendar()),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  // ========================= CONSTRUCTION UI =========================

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

        // Bouton ajouter/modifier hôtel
        Tooltip(
          message: "Créer / Modifier un hôtel",
          child: IconButton(
            icon: Icon(Icons.add_business_rounded),
            onPressed: _showHotelCreationDialog,
          ),
        ),

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
        const SizedBox(width: 8),
      ],
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
                        "${_currentHotel!.totalFloors} étages",
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

  // Widget _buildLegendItem(Color color, String label, IconData icon) {
  //   return Row(
  //     mainAxisSize: MainAxisSize.min,
  //     children: [
  //       Container(
  //         width: 20,
  //         height: 20,
  //         decoration: BoxDecoration(
  //           color: color,
  //           border: Border.all(color: Colors.grey),
  //           borderRadius: BorderRadius.circular(4),
  //         ),
  //         child: Icon(icon, size: 12),
  //       ),
  //       SizedBox(width: 4),
  //       Text(label, style: TextStyle(fontSize: 12)),
  //     ],
  //   );
  // }

  Widget _buildCalendar() {
    final today = DateTime.now();
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
        visibleResourceCount: _calculateVisibleRooms(),
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

  Widget _appointmentBuilder(
      BuildContext context, CalendarAppointmentDetails details) {
    if (details.appointments.isEmpty) return Container();
    final reservation = details.appointments.first as Reservation;
    final nights = reservation.endDate.difference(reservation.startDate).inDays;
    final totalPrice = reservation.pricePerNight * nights;

    return Container(
      width: details.bounds.width,
      height: details.bounds.height,
      // Utilisez toute la hauteur disponible

      // decoration: BoxDecoration(
      //   color: _getRandomColorForReservation(reservation.clientName.hashCode),
      //   borderRadius: BorderRadius.circular(14),
      //   border: Border.all(color: Colors.white, width: 1),
      //   boxShadow: [
      //     BoxShadow(
      //       color: Colors.black.withOpacity(0.1),
      //       blurRadius: 2,
      //       offset: Offset(0, 1),
      //     ),
      //   ],
      // ),
      decoration: BoxDecoration(
        color: _getRandomColorForReservation(reservation.clientName.hashCode)
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
      child: Text(
        reservation.clientName,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // child:  Row(
      //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
      //   children: [
      //     Text(
      //       reservation.clientName,
      //       style: TextStyle(
      //         color: Colors.white,
      //         fontWeight: FontWeight.bold,
      //         fontSize: 13,
      //       ),
      //       maxLines: 1,
      //       overflow: TextOverflow.ellipsis,
      //     ),
      //     Row(
      //       children: [
      //         Text(
      //           '${totalPrice.toStringAsFixed(2)} DZD',
      //           style: TextStyle(
      //             color: Colors.white,
      //             fontSize: 12,
      //             fontWeight: FontWeight.w600,
      //           ),
      //         ),
      //         Text(
      //           reservation.status,
      //           style: TextStyle(
      //             color: Colors.white70,
      //             fontSize: 11,
      //             fontWeight: FontWeight.w500,
      //           ),
      //           maxLines: 1,
      //           overflow: TextOverflow.ellipsis,
      //         ),
      //       ],
      //     ),
      //   ],
      // ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy', 'fr_FR').format(date);
  }

  String _formatDayName(DateTime date) {
    return DateFormat('EEEE', 'fr_FR').format(date);
  }

  String _formatDayNumber(DateTime date) {
    return DateFormat('d', 'fr_FR').format(date);
  }

  String _formatShortDayName(DateTime date) {
    return DateFormat('EEE', 'fr_FR').format(date);
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        FloatingActionButton(
          heroTag: "add",
          onPressed: _showAddReservationDialog,
          backgroundColor: Colors.green,
          child: Icon(Icons.add, color: Colors.white),
        ),
        SizedBox(height: 10),
        FloatingActionButton(
          heroTag: "edit",
          onPressed: () => _showEditOptions(),
          backgroundColor: Colors.orange,
          child: Icon(Icons.edit, color: Colors.white),
        ),
      ],
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
              _createHotel(
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
      [String? preselectedRoom, DateTime? preselectedDate]) {
    final clientNameController = TextEditingController();
    final priceController = TextEditingController();
    String selectedRoom =
        preselectedRoom ?? _currentHotel!.rooms.first.roomNumber;
    DateTime startDate = preselectedDate ?? DateTime.now();
    DateTime endDate = startDate.add(Duration(days: 1));
    String selectedStatus = "Confirmée";

    final statuses = ["Confirmée", "En attente", "Arrivé", "Parti", "Annulée"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Nouvelle Réservation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: clientNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du client',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: InputDecoration(
                    labelText: 'Chambre',
                    border: OutlineInputBorder(),
                  ),
                  items: _currentHotel!.rooms
                      .map(
                        (room) => DropdownMenuItem(
                          value: room.roomNumber,
                          child: Text('Chambre ${room.roomNumber}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedRoom = value!),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate:
                                DateTime.now().subtract(Duration(days: 30)),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() {
                              startDate = date;
                              endDate = startDate.add(Duration(days: 1));
                            });
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Arrivée: ${_formatDate(startDate)}'),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate.add(Duration(days: 1)),
                            lastDate: startDate.add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Départ: ${_formatDate(endDate)}'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prix par nuit (€)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                  ),
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem(
                            value: status, child: Text(status)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedStatus = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _addReservation(
                  clientNameController.text,
                  selectedRoom,
                  startDate,
                  endDate,
                  double.tryParse(priceController.text) ?? 0.0,
                  selectedStatus,
                );
                Navigator.pop(context);
              },
              child: Text('Ajouter'),
            ),
          ],
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
                _showReservationList(isEdit: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Supprimer une réservation'),
              onTap: () {
                Navigator.pop(context);
                _showReservationList(isDelete: true);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReservationList({bool isEdit = false, bool isDelete = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isDelete
            ? 'Supprimer une réservation'
            : 'Modifier une réservation'),
        content: Container(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _reservations.length,
            itemBuilder: (context, index) {
              final reservation = _reservations[index];
              return ListTile(
                title: Text(reservation.clientName),
                subtitle: Text(
                    '${reservation.roomName} - ${_formatDate(reservation.startDate)}'),
                trailing: Icon(
                  isDelete ? Icons.delete : Icons.edit,
                  color: isDelete ? Colors.red : Colors.blue,
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isDelete) {
                    _confirmDeleteReservation(index);
                  } else {
                    _showEditReservationDialog(index);
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showEditReservationDialog(int index) {
    final reservation = _reservations[index];
    final clientNameController =
        TextEditingController(text: reservation.clientName);
    final priceController =
        TextEditingController(text: reservation.pricePerNight.toString());
    String selectedRoom = reservation.roomName;
    DateTime startDate = reservation.startDate;
    DateTime endDate = reservation.endDate;
    String selectedStatus = reservation.status;

    final statuses = ["Confirmée", "En attente", "Arrivé", "Parti", "Annulée"];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier la réservation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: clientNameController,
                  decoration: InputDecoration(
                    labelText: 'Nom du client',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRoom,
                  decoration: InputDecoration(
                    labelText: 'Chambre',
                    border: OutlineInputBorder(),
                  ),
                  items: _currentHotel!.rooms
                      .map(
                        (room) => DropdownMenuItem(
                          value: room.roomNumber,
                          child: Text('Chambre ${room.roomNumber}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedRoom = value!),
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate:
                                DateTime.now().subtract(Duration(days: 30)),
                            lastDate: DateTime.now().add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => startDate = date);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Arrivée: ${_formatDate(startDate)}'),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate,
                            firstDate: startDate.add(Duration(days: 1)),
                            lastDate: startDate.add(Duration(days: 365)),
                          );
                          if (date != null) {
                            setDialogState(() => endDate = date);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('Départ: ${_formatDate(endDate)}'),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Prix par nuit (€)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Statut',
                    border: OutlineInputBorder(),
                  ),
                  items: statuses
                      .map(
                        (status) => DropdownMenuItem(
                            value: status, child: Text(status)),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setDialogState(() => selectedStatus = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                _editReservation(
                  index,
                  clientNameController.text,
                  selectedRoom,
                  startDate,
                  endDate,
                  double.tryParse(priceController.text) ?? 0.0,
                  selectedStatus,
                );
                Navigator.pop(context);
              },
              child: Text('Modifier'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteReservation(int index) {
    final reservation = _reservations[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression'),
        content: Text(
            'Êtes-vous sûr de vouloir supprimer la réservation de ${reservation.clientName} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteReservation(index);
              Navigator.pop(context);
            },
            child: Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
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
      _showAddReservationDialog(roomNumber, details.date);
    }
  }

  void _onCalendarLongPress(CalendarLongPressDetails details) {
    if (details.appointments != null && details.appointments!.isNotEmpty) {
      final reservation = details.appointments!.first as Reservation;
      _showQuickActions(reservation);
    }
  }

  void _showReservationDetails1(Reservation reservation) {
    final nights = reservation.endDate.difference(reservation.startDate).inDays;
    final totalPrice = reservation.pricePerNight * nights;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: FittedBox(
          child: Text(
            'Réservation Détail\n${reservation.clientName}\nChambre ${reservation.roomName}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête avec le nom du client et de la chambre
                _buildHeaderSection(
                    reservation.clientName, reservation.roomName),
                SizedBox(height: 16),
                // Timeline du séjour
                _buildReservationTimeline(
                    reservation.startDate, reservation.endDate, nights),
                SizedBox(height: 16),
                // Détails tarifaires
                _buildPricingSection(
                    nights, reservation.pricePerNight, totalPrice),
                SizedBox(height: 16),
                // Statut de la réservation
                _buildStatusSection(reservation.status),
              ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fermer',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReservationDetails(Reservation reservation) {
    final nights = reservation.endDate.difference(reservation.startDate).inDays;
    final totalPrice = reservation.pricePerNight * nights;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          width: 350,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==== HEADER violet comme l’image ====
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
                // Padding(
                //   padding: const EdgeInsets.all(16.0),
                //   child: Column(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       _buildDetailRow("Client", reservation.clientName),
                //       _buildDetailRow("Chambre", reservation.roomName),
                //       SizedBox(height: 12),
                //       _buildDetailRow("Arrivée",
                //           "${reservation.startDate.toLocal()}".split(' ')[0]),
                //       _buildDetailRow("Départ",
                //           "${reservation.endDate.toLocal()}".split(' ')[0]),
                //       _buildDetailRow("Nuitées", "$nights nuit(s)"),
                //       Divider(),
                //       _buildDetailRow("Prix/nuit",
                //           "${reservation.pricePerNight.toStringAsFixed(2)} DZD"),
                //       _buildDetailRow(
                //         "Total",
                //         "${totalPrice.toStringAsFixed(2)} DZD",
                //         isHighlighted: true,
                //       ),
                //       SizedBox(height: 12),
                //       _buildStatusSection(reservation.status),
                //     ],
                //   ),
                // ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // En-tête avec le nom du client et de la chambre
                        _buildHeaderSection(
                            reservation.clientName, reservation.roomName),
                        SizedBox(height: 16),
                        // Timeline du séjour
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28.0),
                          child: _buildReservationTimeline(
                              reservation.startDate,
                              reservation.endDate,
                              nights),
                        ),
                        SizedBox(height: 16),
                        // Détails tarifaires
                        _buildPricingSection(
                            nights, reservation.pricePerNight, totalPrice),
                        SizedBox(height: 16),
                        // Statut de la réservation
                        _buildStatusSection(reservation.status),
                      ]),
                ),
                //==== FOOTER style coupon vert ====
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.green.shade400,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20),
                      bottomRight: Radius.circular(20),
                    ),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "🎉 Félicitations ${reservation.clientName} 🎉",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Vous avez réservez",
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "ROOM-${reservation.roomName.toUpperCase()}",
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
              reservation.clientName,
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
                final index = _reservations.indexOf(reservation);
                if (index != -1) _showEditReservationDialog(index);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: Colors.red),
              title: Text('Supprimer'),
              onTap: () {
                Navigator.pop(context);
                final index = _reservations.indexOf(reservation);
                if (index != -1) _confirmDeleteReservation(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ========================= MÉTHODES DE DONNÉES =========================

  void _createHotel(
      String name, int floors, int roomsPerFloor, List<String> avoidedNumbers) {
    final rooms = <HotelRoom>[];

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
          rooms.add(HotelRoom(
            roomNumber: roomNumber,
            floor: floor,
            basePrice:
                80 + Random().nextDouble() * 120, // Prix entre 80 et 200€
          ));
        }
      }
    }

    setState(() {
      _currentHotel = Hotel(
        name: name.isNotEmpty ? name : 'Mon Hôtel',
        totalFloors: floors,
        roomsPerFloor: roomsPerFloor,
        avoidedNumbers: avoidedNumbers,
        rooms: rooms,
      );
      _reservations = _generateRandomReservations();
      _updateRoomStates();
      _dataSource =
          HotelReservationDataSource(_reservations, _currentHotel!.rooms);
    });
  }

  List<Reservation> _generateRandomReservations() {
    final reservations = <Reservation>[];
    final faker = Faker();
    final random = Random();
    final statuses = ["Confirmée", "En attente", "Arrivé", "Parti", "Annulée"];

    // Générer des réservations pour environ 60% des chambres
    final roomsToBook = (_currentHotel!.rooms.length * 0.6).round();
    final selectedRooms = List.from(_currentHotel!.rooms)..shuffle(random);

    for (int i = 0; i < roomsToBook; i++) {
      final room = selectedRooms[i];

      // Générer 1 à 3 réservations par chambre
      final reservationCount = random.nextInt(3) + 1;

      // On part d'une date de base (par ex. 30 jours avant aujourd'hui)
      DateTime currentDate = DateTime.now().subtract(Duration(days: 30));

      for (int j = 0; j < reservationCount; j++) {
        // Durée de séjour entre 1 et 20 nuits
        final nights = random.nextInt(20) + 1;

        // La prochaine réservation commence après la fin de la précédente,
        // avec un "gap" aléatoire de 1 à 10 jours entre les réservations
        final startDate =
            currentDate.add(Duration(days: random.nextInt(10) + 1));
        final endDate = startDate.add(Duration(days: nights));

        reservations.add(Reservation(
          clientName: faker.person.name(),
          roomName: room.roomNumber,
          startDate: startDate,
          endDate: endDate,
          pricePerNight: room.basePrice + (random.nextDouble() * 50 - 25),
          // ±25€
          status: statuses[random.nextInt(statuses.length)],
        ));

        // Mettre à jour la base pour la prochaine réservation
        currentDate = endDate;
      }
    }

    return reservations;
  }

  void _updateRoomStates() {
    if (_currentHotel == null) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final room in _currentHotel!.rooms) {
      // Trouver les réservations pour cette chambre
      final roomReservations = _reservations
          .where((r) => r.roomName == room.roomNumber && r.status != "Annulée")
          .toList();

      // Vérifier si occupée aujourd'hui
      final isOccupiedToday = roomReservations.any((r) =>
          r.startDate.isBefore(today.add(Duration(days: 1))) &&
          r.endDate.isAfter(today));

      if (isOccupiedToday) {
        room.currentState = RoomState.occupied;
      } else {
        // Vérifier s'il y a une réservation future
        final hasFutureReservation =
            roomReservations.any((r) => r.startDate.isAfter(today));

        if (hasFutureReservation) {
          room.currentState = RoomState.waitingGuest;
        } else {
          room.currentState = RoomState.empty;
        }
      }
    }
  }

  // void _addReservation(String clientName, String roomName, DateTime startDate,
  //     DateTime endDate, double pricePerNight, String status) {
  //   if (clientName.isEmpty) return;
  //
  //   // ⭐ Vérifier les conflits de réservation pour la même chambre
  //   final hasConflict = _reservations.any((existing) {
  //     if (existing.roomName != roomName || existing.status == "Annulée") {
  //       return false;
  //     }
  //
  //     // Vérifier si les dates se chevauchent
  //     return (startDate.isBefore(existing.endDate) &&
  //         endDate.isAfter(existing.startDate));
  //   });
  //
  //   if (hasConflict) {
  //     // Afficher un message d'erreur
  //     showDialog(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: Text('Conflit de réservation'),
  //         content: Text(
  //             'Une réservation existe déjà pour cette chambre sur cette période.'),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.pop(context),
  //             child: Text('OK'),
  //           ),
  //         ],
  //       ),
  //     );
  //     return;
  //   }
  //
  //   setState(() {
  //     _reservations.add(Reservation(
  //       clientName: clientName,
  //       roomName: roomName,
  //       startDate: startDate,
  //       endDate: endDate,
  //       pricePerNight: pricePerNight,
  //       status: status,
  //     ));
  //     _updateRoomStates();
  //     _dataSource =
  //         HotelReservationDataSource(_reservations, _currentHotel!.rooms);
  //   });
  // }
  void _addReservation(String clientName, String roomName, DateTime startDate,
      DateTime endDate, double pricePerNight, String status) {
    if (clientName.isEmpty) return;

    if (_hasConflict(roomName, startDate, endDate)) {
      final nextAvailable = _findNextAvailableDate(roomName, startDate);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Conflit de réservation'),
          content: Text(
            'Cette chambre est déjà réservée pour cette période.\n'
            'Prochaine date disponible : ${_formatDate(nextAvailable ?? endDate)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _reservations.add(Reservation(
        clientName: clientName,
        roomName: roomName,
        startDate: startDate,
        endDate: endDate,
        pricePerNight: pricePerNight,
        status: status,
      ));
      _updateRoomStates();
      _dataSource =
          HotelReservationDataSource(_reservations, _currentHotel!.rooms);
    });
  }

  bool _hasConflict(String roomName, DateTime startDate, DateTime endDate,
      [int? excludeIndex]) {
    return _reservations.asMap().entries.any((entry) {
      final i = entry.key;
      final existing = entry.value;
      if (excludeIndex != null && i == excludeIndex) return false;
      if (existing.roomName != roomName || existing.status == "Annulée")
        return false;
      return startDate.isBefore(existing.endDate) &&
          endDate.isAfter(existing.startDate);
    });
  }

  DateTime? _findNextAvailableDate(String roomName, DateTime startDate) {
    final roomReservations = _reservations
        .where((r) => r.roomName == roomName && r.status != "Annulée")
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    DateTime currentDate = startDate;
    for (final reservation in roomReservations) {
      if (currentDate.isBefore(reservation.startDate)) {
        return currentDate;
      }
      currentDate = reservation.endDate;
    }
    return currentDate;
  }

  void _editReservation(
      int index,
      String clientName,
      String roomName,
      DateTime startDate,
      DateTime endDate,
      double pricePerNight,
      String status) {
    if (clientName.isEmpty || index < 0 || index >= _reservations.length)
      return;

    // ⭐ Vérifier les conflits (en excluant la réservation en cours de modification)
    final hasConflict = _reservations.asMap().entries.any((entry) {
      final i = entry.key;
      final existing = entry.value;

      // Ignorer la réservation en cours de modification
      if (i == index ||
          existing.roomName != roomName ||
          existing.status == "Annulée") {
        return false;
      }

      // Vérifier si les dates se chevauchent
      return (startDate.isBefore(existing.endDate) &&
          endDate.isAfter(existing.startDate));
    });

    if (hasConflict) {
      // Afficher un message d'erreur
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Conflit de réservation'),
          content: Text(
              'Une autre réservation existe déjà pour cette chambre sur cette période.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() {
      _reservations[index] = Reservation(
        clientName: clientName,
        roomName: roomName,
        startDate: startDate,
        endDate: endDate,
        pricePerNight: pricePerNight,
        status: status,
      );
      _updateRoomStates();
      _dataSource =
          HotelReservationDataSource(_reservations, _currentHotel!.rooms);
    });
  }

  void _deleteReservation(int index) {
    if (index < 0 || index >= _reservations.length) return;

    setState(() {
      _reservations.removeAt(index);
      _updateRoomStates();
      _dataSource =
          HotelReservationDataSource(_reservations, _currentHotel!.rooms);
    });
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
