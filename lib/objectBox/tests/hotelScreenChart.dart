import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Reservation {
  final String clientName;
  final String roomName;
  final DateTime startDate;
  final DateTime endDate;
  final double pricePerNight;
  final String status;

  Reservation({
    required this.clientName,
    required this.roomName,
    required this.startDate,
    required this.endDate,
    required this.pricePerNight,
    required this.status,
  });
}

class HomeScreenTimely extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final from = DateTime.now().subtract(const Duration(days: 180));
    final to = DateTime.now().add(const Duration(days: 180));
    // 1 an après
    final rooms = List.generate(
        80,
        (i) => (101 + i)
            .toString()); // ["101", "102", "103", "104", "105", "108"];

    // Mise à jour des dates des réservations pour 2025
    final sampleReservations = [
      Reservation(
        clientName: "Mohamed Amine",
        roomName: "201",
        startDate: DateTime(2025, 8, 14),
        endDate: DateTime(2025, 8, 18),
        pricePerNight: 120.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Sarah Benali",
        roomName: "202",
        startDate: DateTime(2025, 8, 15),
        endDate: DateTime(2025, 8, 20),
        pricePerNight: 180.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "Karim Boudjema",
        roomName: "301",
        startDate: DateTime(2025, 8, 16),
        endDate: DateTime(2025, 8, 22),
        pricePerNight: 200.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Leila Hadjadj",
        roomName: "103",
        startDate: DateTime(2025, 8, 17),
        endDate: DateTime(2025, 8, 25),
        pricePerNight: 150.0,
        status: "Pending",
      ),
      Reservation(
        clientName: "Yacine Meziani",
        roomName: "104",
        startDate: DateTime(2025, 8, 20),
        endDate: DateTime(2025, 8, 28),
        pricePerNight: 130.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Fatima Zohra",
        roomName: "205",
        startDate: DateTime(2025, 8, 22),
        endDate: DateTime(2025, 8, 30),
        pricePerNight: 160.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "Nassim Boumediene",
        roomName: "302",
        startDate: DateTime(2025, 8, 25),
        endDate: DateTime(2025, 9, 5),
        pricePerNight: 190.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Amel Taleb",
        roomName: "106",
        startDate: DateTime(2025, 9, 1),
        endDate: DateTime(2025, 9, 10),
        pricePerNight: 140.0,
        status: "Checked Out",
      ),
      Reservation(
        clientName: "Djamel Khelifa",
        roomName: "207",
        startDate: DateTime(2025, 9, 5),
        endDate: DateTime(2025, 9, 12),
        pricePerNight: 170.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Soraya Hamidi",
        roomName: "303",
        startDate: DateTime(2025, 9, 10),
        endDate: DateTime(2025, 9, 18),
        pricePerNight: 220.0,
        status: "Checked In",
      ),
      Reservation(
        clientName: "Hicham Rahmani",
        roomName: "108",
        startDate: DateTime(2025, 9, 15),
        endDate: DateTime(2025, 9, 22),
        pricePerNight: 150.0,
        status: "Confirmed",
      ),
      Reservation(
        clientName: "Nadia Ferhat",
        roomName: "209",
        startDate: DateTime(2025, 9, 20),
        endDate: DateTime(2025, 9, 28),
        pricePerNight: 180.0,
        status: "Pending",
      ),
      Reservation(
        clientName: "Rachid Bouda",
        roomName: "304",
        startDate: DateTime(2025, 10, 1),
        endDate: DateTime(2025, 10, 10),
        pricePerNight: 210.0,
        status: "Confirmed",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo: Planning Hôtel'),
        actions: [],
      ),
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

  const CalendarTableWithDragging({
    Key? key,
    required this.fromDate,
    required this.toDate,
    required this.reservations,
    required this.roomNames,
  }) : super(key: key);

  @override
  _CalendarTableWithDraggingState createState() =>
      _CalendarTableWithDraggingState();
}

class _CalendarTableWithDraggingState extends State<CalendarTableWithDragging> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _headerController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final ScrollController _roomsController = ScrollController();

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
    // Centrer sur la date actuelle après la construction
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnToday();
    });
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

  void _centerOnToday() {
    final today = DateTime.now();
    final todayIndex = _allDays.indexWhere((date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day);

    if (todayIndex != -1) {
      final targetOffset = (todayIndex * dayWidth) -
          (MediaQuery.of(context).size.width / 2) +
          60;
      final maxOffset = (_allDays.length * dayWidth) -
          MediaQuery.of(context).size.width +
          120;
      final clampedOffset =
          targetOffset.clamp(0.0, maxOffset.clamp(0.0, double.infinity));

      if (_horizontalController.hasClients && _headerController.hasClients) {
        _horizontalController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _headerController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
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

        if (_horizontalController.hasClients && _headerController.hasClients) {
          final maxExtent = _horizontalController.position.maxScrollExtent;
          final minExtent = 0.0;
          final newOffset = (_horizontalController.offset - deltaX)
              .clamp(minExtent, maxExtent);
          _horizontalController.jumpTo(newOffset);
          _headerController.jumpTo(newOffset);
        }

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
          // Cellule fixe en haut à gauche
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
              child: const Text(
                'Chambres / Dates',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Ligne des mois (fixe en haut, scrollable horizontalement)
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

          // Ligne des jours (fixe en haut sous les mois)
          Positioned(
            top: rowHeight / 2,
            left: 120,
            right: 0,
            height: rowHeight / 2,
            child: ListView.builder(
              controller: _headerController,
              scrollDirection: Axis.horizontal,
              itemCount: days.length,
              itemExtent: dayWidth,
              // Largeur fixe pour chaque jour
              itemBuilder: (context, index) {
                final d = days[index];
                return Container(
                  width: dayWidth,
                  height: rowHeight / 2,
                  decoration: BoxDecoration(
                    border:
                        Border(right: BorderSide(color: Colors.grey.shade300)),
                    color: Colors.grey.shade50,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _shortDayName(d.weekday),
                        style:
                            const TextStyle(fontSize: 17, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.day}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Ligne des jours (nouveau HorizontalCalendar)

          // Colonne des chambres (fixe à gauche, scrollable verticalement)
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
                      .map(
                        (r) => Container(
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
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),

          // Grille principale (scrollable sur les deux axes)
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
                    // Grille de base : lignes x jours
                    Column(
                      children: rooms.map((r) {
                        return Row(
                          children: days
                              .map(
                                (d) => Container(
                                  width: dayWidth,
                                  height: rowHeight,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      right: BorderSide(
                                          color: Colors.grey.shade300),
                                      bottom: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      DateFormat('d', 'fr_FR').format(d),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }).toList(),
                    ),

                    // Superposition des réservations
                    ...widget.reservations.map((res) {
                      final rowIndex = rooms.indexOf(res.roomName);

                      if (rowIndex == -1) return const SizedBox.shrink();

                      final startIndex = res.startDate.isBefore(widget.fromDate)
                          ? 0
                          : res.startDate.difference(widget.fromDate).inDays;

                      final endIndex = res.endDate.isAfter(widget.toDate)
                          ? widget.toDate.difference(widget.fromDate).inDays
                          : res.endDate.difference(widget.fromDate).inDays;

                      // Correction : enlever +1 ici, car difference() + jour inclus = double comptage
                      final left = (startIndex + 1) * dayWidth;
                      final width = (endIndex - startIndex + 1) * dayWidth;

                      // Génération d'une couleur aléatoire mais cohérente pour chaque réservation
                      final color = Colors
                          .primaries[rowIndex % Colors.primaries.length]
                          .withOpacity(0.8);

                      return Positioned(
                          top: rowIndex * rowHeight + 6,
                          left: left,
                          width: width,
                          height: rowHeight - 12,
                          child: GestureDetector(
                            onTap: () => _showReservationDialog(context, res),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(8),
                                // Coins plus arrondis
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                                border: Border.all(
                                    color: Colors.white
                                        .withOpacity(0.2)), // Bordure subtile
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () =>
                                      _showReservationDialog(context, res),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Icône moderne (alternative à Icons.person)
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Icon(
                                          Icons.bed_outlined,
                                          // ou Icons.person_outline
                                          size: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      // Texte hiérarchisé
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              res.clientName,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                height: 1.2,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                            const SizedBox(height: 2),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                Text(
                                                  '${DateFormat('d MMM').format(res.startDate)} – ${DateFormat('d MMM').format(res.endDate)}',
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2,
                                                  ),
                                                ),
                                                Text(
                                                  res.status,
                                                  style: TextStyle(
                                                    color: Colors.white
                                                        .withOpacity(0.9),
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ],
                                            )
                                          ],
                                        ),
                                      ),
                                      // Indicateur visuel de réservation (optionnel)
                                      //if (res.isConfirmed ?? true)
                                      const Icon(
                                        Icons.check_circle,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ));
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
        .map(
          (d) => Container(
            width: dayWidth,
            height: rowHeight / 2,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
              color: Colors.grey.shade50,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _shortDayName(d.weekday),
                  style: const TextStyle(fontSize: 17, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  '${d.day}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        )
        .toList();
  }

  List<Widget> _buildMonthWidgets(List<DateTime> days) {
    final widgets = <Widget>[];
    if (days.isEmpty) return widgets;

    DateTime cursor = DateTime(days.first.year, days.first.month, 1);
    final end = days.last;

    while (cursor.isBefore(end.add(const Duration(days: 1)))) {
      final monthStart = DateTime(cursor.year, cursor.month, 1);
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);
      final visibleStart =
          monthStart.isBefore(days.first) ? days.first : monthStart;
      final visibleEnd = monthEnd.isAfter(days.last) ? days.last : monthEnd;

      final startIndex = days.indexWhere(
        (d) =>
            d.year == visibleStart.year &&
            d.month == visibleStart.month &&
            d.day == visibleStart.day,
      );
      final endIndex = days.lastIndexWhere(
        (d) =>
            d.year == visibleEnd.year &&
            d.month == visibleEnd.month &&
            d.day == visibleEnd.day,
      );

      final visibleDays =
          (startIndex >= 0 && endIndex >= 0) ? (endIndex - startIndex + 1) : 0;

      widgets.add(
        Container(
          width: visibleDays * dayWidth,
          height: rowHeight / 2,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Colors.grey.shade300)),
            color: Colors.grey.shade100,
          ),
          child: Text(
            DateFormat('MMMM yyyy', 'fr_FR').format(monthStart).toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );

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
          'Chambre: ${res.roomName}\n${DateFormat('dd/MM/yyyy').format(res.startDate)} - ${DateFormat('dd/MM/yyyy').format(res.endDate)}',
        ),
        actions: [
          // TextButton(
          //   onPressed: () => Navigator.of(context).pop(),
          //   child: const Text('Fermer'),
          // ),
        ],
      ),
    );
  }
}
