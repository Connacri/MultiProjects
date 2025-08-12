import 'package:faker/faker.dart' show faker;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'hotelScreen.dart';

// class CalendarTableWithDragging extends StatefulWidget {
//   final DateTime fromDate;
//   final DateTime toDate;
//   final List<Reservation> reservations;
//   final List<String> roomNames;
//
//   CalendarTableWithDragging({
//     required this.fromDate,
//     required this.toDate,
//     required this.reservations,
//     required this.roomNames,
//   });
//
//   @override
//   _CalendarTableWithDraggingState createState() =>
//       _CalendarTableWithDraggingState();
// }
//
// class _CalendarTableWithDraggingState extends State<CalendarTableWithDragging> {
//   final ScrollController _horizontalController = ScrollController();
//   final ScrollController _verticalController = ScrollController();
//   final ScrollController _headerHorizontalController = ScrollController();
//   final ScrollController _roomNamesVerticalController = ScrollController();
//
//   double heightLigne = 60;
//   double widthLigne = 100;
//   bool _isDragging = false;
//   Offset? _lastPosition;
//
//   @override
//   void initState() {
//     super.initState();
//     _headerHorizontalController.addListener(_syncScrollControllers);
//     _roomNamesVerticalController.addListener(_syncScrollControllers);
//   }
//
//   @override
//   void dispose() {
//     _headerHorizontalController.removeListener(_syncScrollControllers);
//     _roomNamesVerticalController.removeListener(_syncScrollControllers);
//     _horizontalController.dispose();
//     _verticalController.dispose();
//     _headerHorizontalController.dispose();
//     _roomNamesVerticalController.dispose();
//     super.dispose();
//   }
//
//   void _syncScrollControllers() {
//     if (_headerHorizontalController.hasClients) {
//       _horizontalController.jumpTo(_headerHorizontalController.offset);
//     }
//     if (_roomNamesVerticalController.hasClients) {
//       _verticalController.jumpTo(_roomNamesVerticalController.offset);
//     }
//   }
//
//   void _handleDragStart(Offset position) {
//     setState(() {
//       _isDragging = true;
//     });
//     _lastPosition = position;
//   }
//
//   void _handleDragEnd(Offset position) {
//     setState(() {
//       _isDragging = false;
//     });
//     _lastPosition = null;
//   }
//
//   void _handleDragUpdate(Offset position) {
//     if (!_isDragging || _lastPosition == null) return;
//
//     final double dx = position.dx - _lastPosition!.dx;
//     final double dy = position.dy - _lastPosition!.dy;
//
//     if (_horizontalController.hasClients) {
//       _horizontalController.jumpTo(
//         (_horizontalController.offset - dx).clamp(
//           0.0,
//           _horizontalController.position.maxScrollExtent,
//         ),
//       );
//       _headerHorizontalController.jumpTo(_horizontalController.offset);
//     }
//
//     if (_verticalController.hasClients) {
//       _verticalController.jumpTo(
//         (_verticalController.offset - dy).clamp(
//           0.0,
//           _verticalController.position.maxScrollExtent,
//         ),
//       );
//       _roomNamesVerticalController.jumpTo(_verticalController.offset);
//     }
//
//     _lastPosition = position;
//   }
//
//   List<String> generateDates() {
//     final List<String> dates = [];
//     for (int i = 0;
//         i <= widget.toDate.difference(widget.fromDate).inDays;
//         i++) {
//       final date = widget.fromDate.add(Duration(days: i));
//       dates.add("${date.day}/${date.month}");
//     }
//     return dates;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final dates = generateDates();
//     final rooms = widget.roomNames;
//
//     return Scaffold(
//       appBar: AppBar(title: Text("Tableau Dragging")),
//       body: MouseRegion(
//         cursor:
//             _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
//         child: Listener(
//           onPointerDown: (event) => _handleDragStart(event.position),
//           onPointerUp: (event) => _handleDragEnd(event.position),
//           onPointerMove: (event) => _handleDragUpdate(event.position),
//           child: Stack(
//             children: [
//               // Main Table Reservation
//               MainTableReservation(
//                 verticalController: _verticalController,
//                 horizontalController: _horizontalController,
//                 widget: widget,
//                 dates: dates,
//                 widthLigne: widthLigne,
//                 heightLigne: heightLigne,
//               ),
//               // Fixed Horizontal Header Calendar
//               FixedHeaderHorizontalCalendar(
//                 widthLigne: widthLigne,
//                 heightLigne: heightLigne,
//                 fromDate: widget.fromDate,
//                 toDate: widget.toDate,
//                 dates: dates,
//                 headerHorizontalController: _headerHorizontalController,
//               ),
//               FixedChambresDates(
//                   widthLigne: widthLigne, heightLigne: heightLigne),
//               // Fixed Vertical Rooms Column
//               VerticalRoomsColumn(
//                 heightLigne: heightLigne,
//                 roomNamesVerticalController: _roomNamesVerticalController,
//                 rooms: rooms,
//                 widthLigne: widthLigne,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

class FixedHeaderHorizontalCalendar extends StatelessWidget {
  const FixedHeaderHorizontalCalendar({
    required this.widthLigne,
    required this.heightLigne,
    required this.fromDate,
    required this.toDate,
    required this.dates,
    required ScrollController headerHorizontalController,
  }) : _headerHorizontalController = headerHorizontalController;

  final ScrollController _headerHorizontalController;
  final double widthLigne;
  final double heightLigne;
  final DateTime fromDate;
  final DateTime toDate;
  final List<String> dates;

  List<String> generateDates() {
    final List<String> dates = [];
    for (int i = 0; i <= toDate.difference(fromDate).inDays; i++) {
      final date = fromDate.add(Duration(days: i));
      dates.add("${date.day}/${date.month}");
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: widthLigne, // Adjust based on your room column width
      right: 0,
      child: SingleChildScrollView(
        controller: _headerHorizontalController,
        scrollDirection: Axis.horizontal,
        child: Stack(
          children: [
            Row(
              children: dates.map((date) => buildDayRow(date)).toList(),
            ),
            //  buildMonthRow(),
          ],
        ),
      ),
    );
  }

  Widget buildDayRow(String date) {
    List<Widget> days = [];
    DateTime currentDate = fromDate;
    while (!currentDate.isAfter(toDate)) {
      days.add(Container(
        width: widthLigne,
        height: heightLigne,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade200,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _getDayName(currentDate.weekday),
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                "${currentDate.day}",
                style: TextStyle(fontSize: 14),
              ),
              Text(
                date,
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ));
      currentDate = currentDate.add(Duration(days: 1));
    }
    return Row(children: days);
  }

  String _getDayName(int weekday) {
    const dayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    return dayNames[weekday - 1];
  }

  Widget buildMonthRow() {
    List<Widget> months = [];
    DateTime currentDate = DateTime.now();
    int currentDay = currentDate.day;
    int currentMonth = currentDate.month;
    int currentYear = currentDate.year;
    int displayedDays = 90;
    int remainingDays = displayedDays;

    int getDaysInMonth(int year, int month) {
      return DateTime(year, month + 1, 0).day;
    }

    while (remainingDays > 0) {
      int daysInCurrentMonth = getDaysInMonth(currentYear, currentMonth);
      int visibleDaysInMonth = daysInCurrentMonth - currentDay + 1;
      if (visibleDaysInMonth > remainingDays) {
        visibleDaysInMonth = remainingDays;
      }
      String monthName = DateFormat('MMMM yyyy', 'fr_FR')
          .format(DateTime(currentYear, currentMonth));
      months.add(Container(
        width: visibleDaysInMonth * widthLigne,
        height: heightLigne / 2,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          //  color: Colors.amberAccent,
        ),
        child: Center(
          child: Text(
            monthName,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ));
      remainingDays -= visibleDaysInMonth;
      currentDay = 1;
      currentMonth++;
      if (currentMonth > 12) {
        currentMonth = 1;
        currentYear++;
      }
    }
    return Row(children: months);
  }
}

class VerticalRoomsColumn extends StatelessWidget {
  const VerticalRoomsColumn({
    required this.heightLigne,
    required ScrollController roomNamesVerticalController,
    required this.rooms,
    required this.widthLigne,
  }) : _roomNamesVerticalController = roomNamesVerticalController;

  final double heightLigne;
  final ScrollController _roomNamesVerticalController;
  final List<String> rooms;
  final double widthLigne;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: heightLigne,
      left: 0,
      bottom: 0,
      child: SingleChildScrollView(
        controller: _roomNamesVerticalController,
        scrollDirection: Axis.vertical,
        child: Column(
          children: rooms.map((room) {
            return Container(
              width: widthLigne,
              height: heightLigne,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                color: Colors.grey.shade200,
              ),
              child: Text(
                '$room',
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class FixedChambresDates extends StatelessWidget {
  const FixedChambresDates({
    required this.widthLigne,
    required this.heightLigne,
  });

  final double widthLigne;
  final double heightLigne;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      child: Container(
        width: widthLigne,
        height: heightLigne,
        child: Center(
          child: Text(
            "Chambres/Date",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
        ),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          color: Colors.grey.shade200,
        ),
      ),
    );
  }
}

class MainTableReservation extends StatelessWidget {
  const MainTableReservation({
    required ScrollController verticalController,
    required ScrollController horizontalController,
    required this.widget,
    required this.dates,
    required this.widthLigne,
    required this.heightLigne,
  })  : _verticalController = verticalController,
        _horizontalController = horizontalController;

  final ScrollController _verticalController;
  final ScrollController _horizontalController;
  final CalendarTableWithDragging widget;
  final List<String> dates;
  final double widthLigne;
  final double heightLigne;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: heightLigne, left: widthLigne),
      child: SingleChildScrollView(
        controller: _verticalController,
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          controller: _horizontalController,
          scrollDirection: Axis.horizontal,
          child: Column(
            children: widget.roomNames.map((roomName) {
              return Row(
                children: dates.map((date) {
                  return Container(
                    width: widthLigne,
                    height: heightLigne,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text("-"),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// calendar_table_with_dragging.dart
// Version améliorée pour :
// - Affichage des mois au-dessus des jours (largeur proportionnelle au nombre de jours)
// - Ligne des jours avec nom de jour (Français) et numéro
// - Affichage des réservations sous forme de barres positionnées (span plusieurs jours)
// - Scroll synchronisé entre header et table, et drag-to-pan (souris / tactile)

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final from = DateTime.now();
    final to = from.add(Duration(days: 60));

    final rooms = List.generate(12, (i) => 'Room ${i + 1}');

    final sampleReservations = [
      Reservation(
        clientName: "John Doe",
        roomName: "101",
        startDate: DateTime(2024, 1, 5),
        endDate: DateTime(2024, 1, 9),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "102",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "103",
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "104",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "105",
        startDate: DateTime(2024, 1, 2),
        endDate: DateTime(2024, 1, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "108",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "101",
        startDate: DateTime(2024, 1, 5),
        endDate: DateTime(2024, 1, 9),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "102",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "103",
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "104",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "105",
        startDate: DateTime(2024, 1, 2),
        endDate: DateTime(2024, 1, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "108",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "101",
        startDate: DateTime(2024, 1, 5),
        endDate: DateTime(2024, 1, 9),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "102",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "103",
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "104",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "105",
        startDate: DateTime(2024, 1, 2),
        endDate: DateTime(2024, 1, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "108",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "101",
        startDate: DateTime(2024, 1, 5),
        endDate: DateTime(2024, 1, 9),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "102",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "103",
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "104",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "105",
        startDate: DateTime(2024, 1, 2),
        endDate: DateTime(2024, 1, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "108",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "101",
        startDate: DateTime(2024, 1, 5),
        endDate: DateTime(2024, 1, 9),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "102",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "103",
        startDate: DateTime(2024, 2, 1),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "104",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "John Doe",
        roomName: "105",
        startDate: DateTime(2024, 1, 2),
        endDate: DateTime(2024, 1, 5),
        pricePerNight: 100.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Jane Smith",
        roomName: "108",
        startDate: DateTime(2024, 2, 4),
        endDate: DateTime(2024, 2, 5),
        pricePerNight: 150.0,
        status: "Checked In",
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Demo: Planning Hôtel')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Expanded(
              child: CalendarTableWithDragging(
                fromDate: from,
                toDate: to,
                roomNames: rooms,
                reservations: sampleReservations,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalendarTableWithDragging extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Reservation> reservations;
  final List<String> roomNames;

  CalendarTableWithDragging({
    required this.fromDate,
    required this.toDate,
    required this.reservations,
    required this.roomNames,
  });

  @override
  _CalendarTableWithDraggingState createState() =>
      _CalendarTableWithDraggingState();
}

class _CalendarTableWithDraggingState extends State<CalendarTableWithDragging> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _roomsController = ScrollController();

  // appearance
  final double dayWidth = 50;
  final double rowHeight = 120;
  bool _syncingHeader = false;
  bool _syncingBody = false;

  List<DateTime> get _allDays => _generateDates(widget.fromDate, widget.toDate);

  @override
  void initState() {
    super.initState();
    _headerController.addListener(_onHeaderScroll);
    _horizontalController.addListener(_onBodyScroll);
    _roomsController.addListener(_onRoomsScroll);
    _verticalController.addListener(_onBodyVerticalScroll);
  }

  @override
  void dispose() {
    _headerController.removeListener(_onHeaderScroll);
    _horizontalController.removeListener(_onBodyScroll);
    _roomsController.removeListener(_onRoomsScroll);
    _verticalController.removeListener(_onBodyVerticalScroll);

    _headerController.dispose();
    _horizontalController.dispose();
    _roomsController.dispose();
    _verticalController.dispose();
    super.dispose();
  }

  void _onHeaderScroll() {
    if (_syncingHeader) return;
    _syncingBody = true;
    if (_horizontalController.hasClients) {
      _horizontalController.jumpTo(_headerController.offset);
    }
    _syncingBody = false;
  }

  void _onBodyScroll() {
    if (_syncingBody) return;
    _syncingHeader = true;
    if (_headerController.hasClients) {
      _headerController.jumpTo(_horizontalController.offset);
    }
    _syncingHeader = false;
  }

  void _onRoomsScroll() {
    if (_verticalController.hasClients) {
      _verticalController.jumpTo(_roomsController.offset);
    }
  }

  void _onBodyVerticalScroll() {
    if (_roomsController.hasClients) {
      _roomsController.jumpTo(_verticalController.offset);
    }
  }

  List<DateTime> _generateDates(DateTime from, DateTime to) {
    final days = <DateTime>[];
    for (int i = 0; i <= to.difference(from).inDays; i++) {
      days.add(from.add(Duration(days: i)));
    }
    return days;
  }

  @override
  Widget build(BuildContext context) {
    final days = _allDays;
    final rooms = widget.roomNames;

    return GestureDetector(
      onPanUpdate: (details) {
        double deltaX = details.delta.dx;
        double deltaY = details.delta.dy;

        // Scroll horizontal synchronisé
        if (_horizontalController.hasClients && _headerController.hasClients) {
          final maxExtent = _horizontalController.position.maxScrollExtent;
          final minExtent = 0.0;

          final newOffset = (_horizontalController.offset - deltaX)
              .clamp(minExtent, maxExtent);

          _horizontalController.jumpTo(newOffset);
          _headerController.jumpTo(newOffset);
        }

        // Scroll vertical synchronisé
        if (_verticalController.hasClients && _roomsController.hasClients) {
          final maxExtent = _verticalController.position.maxScrollExtent;
          final minExtent = 0.0;

          final newOffset =
              (_verticalController.offset - deltaY).clamp(minExtent, maxExtent);

          _verticalController.jumpTo(newOffset);
          _roomsController.jumpTo(newOffset);
        }
      },
      child: Stack(
        children: [
          // Top-left fixed cell
          Positioned(
            top: 0,
            left: 0,
            width: 120,
            height: rowHeight,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.yellow.shade200,
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text('Chambres / Dates',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),

          // Months Row (fixed top, horizontally scrollable)
          Positioned(
            top: 0,
            left: 120,
            right: 0,
            height: rowHeight / 2,
            child: SingleChildScrollView(
              controller: _headerController,
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildMonthWidgets(days)),
            ),
          ),

          // Days Row (fixed top under months)
          Positioned(
            top: rowHeight / 2,
            left: 120,
            right: 0,
            height: rowHeight / 2,
            child: SingleChildScrollView(
              controller: _headerController,
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildDayWidgets(days)),
            ),
          ),

          // Rooms column (fixed left, vertically scrollable)
          Positioned(
            top: rowHeight,
            left: 0,
            bottom: 0,
            width: 120,
            child: Container(
              color: Colors.grey.shade200,
              child: SingleChildScrollView(
                controller: _roomsController,
                child: Column(
                  children: rooms
                      .map((r) => Container(
                            width: 120,
                            height: rowHeight,
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(color: Colors.grey.shade300),
                                right: BorderSide(color: Colors.grey.shade300),
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(r),
                          ))
                      .toList(),
                ),
              ),
            ),
          ),

          // Main grid (scrollable both axes)
          Positioned(
            top: rowHeight,
            left: 120,
            right: 0,
            bottom: 0,
            child: SingleChildScrollView(
              controller: _verticalController,
              child: SingleChildScrollView(
                controller: _horizontalController,
                scrollDirection: Axis.horizontal,
                child: Stack(
                  children: [
                    // grid base: rows x days
                    Column(
                      children: rooms.map((r) {
                        return Row(
                          children: days
                              .map((d) => Container(
                                    width: dayWidth,
                                    height: rowHeight,
                                    decoration: BoxDecoration(
                                      border: Border(
                                          right: BorderSide(
                                              color: Colors.grey.shade300),
                                          bottom: BorderSide(
                                              color: Colors.grey.shade300)),
                                    ),
                                    child: Center(
                                        child: Text(DateFormat('d', 'fr_FR')
                                            .format(d))),
                                  ))
                              .toList(),
                        );
                      }).toList(),
                    ),

                    // reservations overlay
                    ...widget.reservations.map((res) {
                      final rowIndex = rooms.indexOf(res.roomName);
                      if (rowIndex == -1) return SizedBox.shrink();

                      final startIndex = res.startDate.isBefore(widget.fromDate)
                          ? 0
                          : res.startDate.difference(widget.fromDate).inDays;
                      final endIndex = res.endDate.isAfter(widget.toDate)
                          ? widget.toDate.difference(widget.fromDate).inDays
                          : res.endDate.difference(widget.fromDate).inDays;

                      final left = startIndex * dayWidth;
                      final width = (endIndex - startIndex + 1) * dayWidth;
                      Map<String, Color> colorMap = {
                        'Red': Colors.red.shade500,
                        'Blue': Colors.blue.shade500,
                        'Green': Colors.green.shade500,
                        'Yellow': Colors.yellow.shade500,
                        'Purple': Colors.purple.shade500,
                        'Orange': Colors.orange.shade500,
                      };

                      final colorName = faker.color.color();
                      final color = colorMap[colorName] ??
                          Colors.grey; // Fallback si non trouvé
                      return Positioned(
                        top: rowIndex * rowHeight + 6,
                        left: left,
                        width: width,
                        height: rowHeight - 12,
                        child: GestureDetector(
                          onTap: () => _showReservationDialog(context, res),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(
                              // color: res.color.withOpacity(0.95),
                              color: color,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Icon(Icons.person,
                                    size: 16, color: Colors.white),
                                SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    '${res.clientName} (${DateFormat('d/MM').format(res.startDate)}-${DateFormat('d/MM').format(res.endDate)})',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDayWidgets(List<DateTime> days) {
    return days
        .map((d) => Container(
              width: dayWidth,
              height: rowHeight / 2,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
                color: Colors.grey.shade50,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_shortDayName(d.weekday),
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                  SizedBox(height: 4),
                  Text('${d.day}', style: TextStyle(fontSize: 14)),
                ],
              ),
            ))
        .toList();
  }

  List<Widget> _buildMonthWidgets(List<DateTime> days) {
    final widgets = <Widget>[];
    if (days.isEmpty) return widgets;

    DateTime cursor = DateTime(days.first.year, days.first.month, 1);
    final end = days.last;

    while (cursor.isBefore(end.add(Duration(days: 1)))) {
      final monthStart = DateTime(cursor.year, cursor.month, 1);
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);

      final visibleStart =
          monthStart.isBefore(days.first) ? days.first : monthStart;
      final visibleEnd = monthEnd.isAfter(days.last) ? days.last : monthEnd;

      // Chercher les index (comparer day/month/year)
      final startIndex = days.indexWhere((d) =>
          d.year == visibleStart.year &&
          d.month == visibleStart.month &&
          d.day == visibleStart.day);
      final endIndex = days.lastIndexWhere((d) =>
          d.year == visibleEnd.year &&
          d.month == visibleEnd.month &&
          d.day == visibleEnd.day);

      final visibleDays =
          (startIndex >= 0 && endIndex >= 0) ? (endIndex - startIndex + 1) : 0;

      widgets.add(Container(
        width: visibleDays * dayWidth,
        height: rowHeight / 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border(right: BorderSide(color: Colors.grey.shade300)),
          color: Colors.grey.shade100,
        ),
        child: Text(
          DateFormat('MMMM yyyy', 'fr_FR').format(monthStart).toUpperCase(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ));

      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }

    return widgets;
  }

  String _shortDayName(int weekday) {
    const dayNames = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    return dayNames[weekday - 1];
  }

  void _showReservationDialog(BuildContext context, Reservation res) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(res.clientName),
        content: Text(
            'Chambre: ${res.roomName}\n${DateFormat('dd/MM/yyyy').format(res.startDate)} - ${DateFormat('dd/MM/yyyy').format(res.endDate)}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: Text('Fermer'))
        ],
      ),
    );
  }
}
