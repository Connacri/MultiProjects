import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../MyProviders.dart';
import 'hotelScreen.dart';
// Import du RoomProvider
// import '../providers/room_provider.dart'; // Ajustez le chemin selon votre structure

// ==================== UI: HomeScreenv4 ====================

class HomeScreenv4 extends StatefulWidget {
  const HomeScreenv4({super.key});

  @override
  State<HomeScreenv4> createState() => _HomeScreenv4State();
}

class _HomeScreenv4State extends State<HomeScreenv4> {
  @override
  void initState() {
    super.initState();
    // Charger les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadRoomsFromBox();
    });
  }

  @override
  Widget build(BuildContext context) {
    final from = DateTime.now().subtract(const Duration(days: 180));
    final to = DateTime.now().add(const Duration(days: 180));

    // Données de test - remplacez par les vraies réservations du provider
    final sampleReservations = <Reservation>[
      Reservation(
        clientName: "Mohamed Amine",
        roomName: "103",
        startDate: DateTime(2025, 8, 14),
        endDate: DateTime(2025, 8, 18),
        pricePerNight: 120.0,
        status: "Confirmée",
      ),
      Reservation(
        clientName: "Sarah Benali",
        roomName: "104",
        startDate: DateTime(2025, 8, 15),
        endDate: DateTime(2025, 8, 20),
        pricePerNight: 180.0,
        status: "Arrivée",
      ),
      Reservation(
        clientName: "Karim Boudjema",
        roomName: "105",
        startDate: DateTime(2025, 8, 16),
        endDate: DateTime(2025, 8, 22),
        pricePerNight: 200.0,
        status: "Confirmée",
      ),
      Reservation(
        clientName: "Leila Hadjadj",
        roomName: "101",
        startDate: DateTime(2025, 8, 17),
        endDate: DateTime(2025, 8, 25),
        pricePerNight: 150.0,
        status: "En attente",
      ),
      Reservation(
        clientName: "Hicham Rahmani",
        roomName: "108",
        startDate: DateTime(2025, 9, 15),
        endDate: DateTime(2025, 9, 22),
        pricePerNight: 150.0,
        status: "Confirmée",
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning Hôtel'),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => RoomGeneratorDialog(
                  roomProvider:
                      context.read<RoomProvider>(), // Passer le provider
                  onRoomsGenerated: (generatedRooms) {
                    // La sauvegarde est maintenant gérée dans le dialog
                    print('Chambres générées: ${generatedRooms.length}');
                  },
                ),
              );
            },
            icon: const Icon(Icons.room_preferences_outlined),
          ),
          const SizedBox(width: 100),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Consumer<RoomProvider>(
          builder: (context, roomProvider, child) {
            return CalendarTableWithDragging(
              fromDate: from,
              toDate: to,
              roomNames: roomProvider.rooms,
              reservations: sampleReservations,
            );
          },
        ),
      ),
    );
  }
}

// ==================== UI: CalendarTableWithDragging (inchangé) ====================

class CalendarTableWithDragging extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Reservation> reservations;
  final List<String> roomNames;

  const CalendarTableWithDragging({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.reservations,
    required this.roomNames,
  });

  @override
  State<CalendarTableWithDragging> createState() =>
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
  bool _didInitialCenter = false;

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
      days.add(
          DateTime(from.year, from.month, from.day).add(Duration(days: i)));
    }
    return days;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Color _weekdayBgColor(DateTime d, {bool forHeader = false}) {
    if (_isSameDay(d, DateTime.now())) {
      return Colors.green.withOpacity(forHeader ? 0.18 : 0.12);
    }
    if (d.weekday == DateTime.friday) {
      return Colors.orange.withOpacity(forHeader ? 0.18 : 0.08);
    }
    if (d.weekday == DateTime.saturday) {
      return Colors.blue.withOpacity(forHeader ? 0.18 : 0.08);
    }
    return forHeader ? Colors.grey.shade50 : Colors.white;
  }

  String _shortDayName(int weekday) {
    const dayNames = ['Lu', 'Ma', 'Me', 'Je', 'Ve', 'Sa', 'Di'];
    return dayNames[weekday - 1];
  }

  void _centerOnTodayOnce(BuildContext context, int todayIndex) {
    if (_didInitialCenter) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_horizontalController.hasClients || !_headerController.hasClients)
        return;

      final viewportWidth =
          MediaQuery.of(context).size.width - 120; // 120 = colonne chambres
      final target = todayIndex * dayWidth - (viewportWidth - dayWidth) / 2;

      final maxExtent = _horizontalController.position.maxScrollExtent;
      final clamped = target.clamp(0.0, maxExtent);

      _horizontalController.jumpTo(clamped);
      _headerController.jumpTo(clamped);
    });
    _didInitialCenter = true;
  }

  @override
  Widget build(BuildContext context) {
    final days = _allDays;
    final rooms = widget.roomNames;

    int todayIndex = days.indexWhere((d) => _isSameDay(d, DateTime.now()));
    if (todayIndex == -1) {
      todayIndex = DateTime.now().isBefore(days.first) ? 0 : days.length - 1;
    }

    _centerOnTodayOnce(context, todayIndex);

    return GestureDetector(
      onPanUpdate: (details) {
        final dx = details.delta.dx;
        final dy = details.delta.dy;

        if (_horizontalController.hasClients && _headerController.hasClients) {
          final max = _horizontalController.position.maxScrollExtent;
          final min = 0.0;
          final newOffset = (_horizontalController.offset - dx).clamp(min, max);
          _horizontalController.jumpTo(newOffset);
          _headerController.jumpTo(newOffset);
        }
        if (_verticalController.hasClients && _roomsController.hasClients) {
          final max = _verticalController.position.maxScrollExtent;
          final min = 0.0;
          final newOffset = (_verticalController.offset - dy).clamp(min, max);
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

          // HEADER (mois + jours)
          Positioned(
            top: 0,
            left: 120,
            right: 0,
            height: rowHeight,
            child: SingleChildScrollView(
              controller: _headerController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: days.length * dayWidth,
                height: rowHeight,
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: rowHeight / 2,
                          child: Row(children: _buildMonthWidgets(days)),
                        ),
                        SizedBox(
                          height: rowHeight / 2,
                          child: Row(
                            children: List.generate(days.length, (index) {
                              final d = days[index];
                              return Container(
                                width: dayWidth,
                                height: rowHeight / 2,
                                decoration: BoxDecoration(
                                  color: _weekdayBgColor(d, forHeader: true),
                                  border: Border(
                                    right:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _shortDayName(d.weekday),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade700,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text('${d.day}',
                                        style: const TextStyle(fontSize: 13)),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),

                    // Trait vertical vert pour aujourd'hui
                    Positioned(
                      left: todayIndex * dayWidth,
                      top: 0,
                      bottom: 0,
                      width: 2,
                      child: Container(color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Colonne des chambres
          Positioned(
            top: rowHeight,
            left: 0,
            bottom: 0,
            width: 120,
            child: ListView.builder(
              controller: _roomsController,
              itemCount: rooms.length,
              itemExtent: rowHeight,
              itemBuilder: (context, index) {
                final r = rooms[index];
                return Container(
                  width: 120,
                  height: rowHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade300),
                      right: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(r,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),

          // Grille principale
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
                child: SizedBox(
                  width: days.length * dayWidth,
                  height: rooms.length * rowHeight,
                  child: Stack(
                    children: [
                      // Colonne du jour courant
                      Positioned(
                        left: todayIndex * dayWidth,
                        top: 0,
                        bottom: 0,
                        width: dayWidth,
                        child: IgnorePointer(
                          child:
                              Container(color: Colors.green.withOpacity(0.08)),
                        ),
                      ),
                      Positioned(
                        left: todayIndex * dayWidth,
                        top: 0,
                        bottom: 0,
                        width: 2,
                        child: IgnorePointer(
                            child: Container(color: Colors.green)),
                      ),

                      // Grille de base
                      Column(
                        children: List.generate(rooms.length, (row) {
                          return Row(
                            children: List.generate(days.length, (col) {
                              final d = days[col];
                              return Container(
                                width: dayWidth,
                                height: rowHeight,
                                decoration: BoxDecoration(
                                  color: _weekdayBgColor(d),
                                  border: Border(
                                    right:
                                        BorderSide(color: Colors.grey.shade300),
                                    bottom:
                                        BorderSide(color: Colors.grey.shade300),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    DateFormat('d', 'fr_FR').format(d),
                                    style: TextStyle(
                                      color: d.weekday == DateTime.sunday
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          );
                        }),
                      ),

                      // Réservations
                      ...widget.reservations.map((res) {
                        final rowIndex = rooms.indexOf(res.roomName);
                        if (rowIndex == -1) return const SizedBox.shrink();

                        final startIndex = res.startDate
                                .isBefore(widget.fromDate)
                            ? 0
                            : res.startDate.difference(widget.fromDate).inDays;

                        final endIndex = res.endDate.isAfter(widget.toDate)
                            ? widget.toDate.difference(widget.fromDate).inDays
                            : res.endDate.difference(widget.fromDate).inDays;

                        final double left = (startIndex + 1) * dayWidth;
                        final double width =
                            (endIndex - startIndex + 1) * dayWidth;

                        final color = Colors
                            .primaries[rowIndex % Colors.primaries.length]
                            .withOpacity(0.85);

                        return Positioned(
                          top: rowIndex * rowHeight + 6,
                          left: left,
                          width: width,
                          height: rowHeight - 12,
                          child: _ReservationCard(color: color, res: res),
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildMonthWidgets(List<DateTime> days) {
    final widgets = <Widget>[];
    if (days.isEmpty) return widgets;

    DateTime cursor = DateTime(days.first.year, days.first.month, 1);
    final end = days.last;

    bool _isSameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    while (cursor.isBefore(end.add(const Duration(days: 1)))) {
      final monthStart = DateTime(cursor.year, cursor.month, 1);
      final monthEnd = DateTime(cursor.year, cursor.month + 1, 0);

      final visibleStart =
          monthStart.isBefore(days.first) ? days.first : monthStart;
      final visibleEnd = monthEnd.isAfter(days.last) ? days.last : monthEnd;

      final startIndex = days.indexWhere((d) => _isSameDay(d, visibleStart));
      final endIndex = days.lastIndexWhere((d) => _isSameDay(d, visibleEnd));

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
}

// ==================== Carte Réservation (inchangée) ====================

class _ReservationCard extends StatelessWidget {
  final Color color;
  final Reservation res;

  const _ReservationCard({required this.color, required this.res});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showReservationDialog(context, res),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [
              BoxShadow(
                  color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))
            ],
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bed_outlined,
                    size: 16, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(res.clientName,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.1)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          '${DateFormat('d MMM', 'fr_FR').format(res.startDate)} – ${DateFormat('d MMM', 'fr_FR').format(res.endDate)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: 8),
                        const Text('•',
                            style:
                                TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Text('${res.pricePerNight.toStringAsFixed(0)} DZD/nuit',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 8),
                    Text(res.status,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservationDialog(BuildContext context, Reservation res) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(res.clientName),
        content: Text(
          'Chambre: ${res.roomName}\n'
          '${DateFormat('dd/MM/yyyy').format(res.startDate)} - ${DateFormat('dd/MM/yyyy').format(res.endDate)}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer')),
        ],
      ),
    );
  }
}

// ==================== Dialog Générateur (utilise le RoomProvider) ====================

class RoomGeneratorDialog extends StatefulWidget {
  final RoomProvider roomProvider;
  final Function(List<String>) onRoomsGenerated;

  const RoomGeneratorDialog({
    Key? key,
    required this.roomProvider,
    required this.onRoomsGenerated,
  }) : super(key: key);

  @override
  _RoomGeneratorDialogState createState() => _RoomGeneratorDialogState();
}

class _RoomGeneratorDialogState extends State<RoomGeneratorDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _firstRoomController = TextEditingController();
  final TextEditingController _lastRoomController = TextEditingController();
  final TextEditingController _excludeRoomsController = TextEditingController();

  List<String> _generatedRooms = [];
  bool _showPreview = false;

  @override
  void initState() {
    super.initState();
    _floorsController.text = '3';
    _firstRoomController.text = '01';
    _lastRoomController.text = '08';
  }

  void _generateRooms() {
    if (!_formKey.currentState!.validate()) return;

    try {
      final floors = int.parse(_floorsController.text.trim());
      final firstRoom = int.parse(_firstRoomController.text.trim());
      final lastRoom = int.parse(_lastRoomController.text.trim());

      final excludeText = _excludeRoomsController.text.trim();
      final excludeRooms = <String>{};
      if (excludeText.isNotEmpty) {
        for (final r in excludeText.split(',')) {
          final t = r.trim();
          if (t.isNotEmpty) excludeRooms.add(t);
        }
      }

      // Utilisation de la méthode du RoomProvider
      final rooms = widget.roomProvider.generateRoomsList(
        floors: floors,
        firstRoom: firstRoom,
        lastRoom: lastRoom,
        excludeRooms: excludeRooms,
      );

      setState(() {
        _generatedRooms = rooms;
        _showPreview = true;
      });
    } catch (e) {
      _showErrorDialog('Erreur lors de la génération des chambres: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Générateur de Chambres',
          style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNumberField(
                  controller: _floorsController,
                  label: "Nombre d'étages",
                  hint: "Ex: 3",
                  icon: Icons.layers,
                  min: 1,
                  max: 20,
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _firstRoomController,
                  label: "Premier numéro de chambre (par étage)",
                  hint: "Ex: 01",
                  icon: Icons.first_page,
                  min: 1,
                  max: 99,
                ),
                const SizedBox(height: 16),
                _buildNumberField(
                  controller: _lastRoomController,
                  label: "Dernier numéro de chambre (par étage)",
                  hint: "Ex: 08",
                  icon: Icons.last_page,
                  min: 1,
                  max: 99,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _excludeRoomsController,
                  decoration: const InputDecoration(
                    labelText: 'Chambres à exclure (optionnel)',
                    hintText: 'Ex: 106, 107, 205',
                    prefixIcon: Icon(Icons.remove_circle_outline),
                    border: OutlineInputBorder(),
                    helperText: 'Séparez par des virgules',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateRooms,
                    icon: const Icon(Icons.auto_fix_high),
                    label: const Text('Générer les chambres'),
                  ),
                ),
                if (_showPreview) _buildPreview(),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler')),
        ElevatedButton.icon(
          onPressed: _generatedRooms.isEmpty
              ? null
              : () async {
                  try {
                    await widget.roomProvider.saveRoomsToBox(_generatedRooms);

                    widget.onRoomsGenerated(_generatedRooms);
                    Navigator.of(context).pop();

                    // Message de succès
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            '${_generatedRooms.length} chambres générées avec succès!'),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  } catch (e) {
                    print('Erreur lors de la sauvegarde: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              'Erreur lors de la sauvegarde des chambres: $e'),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 5),
                        ),
                      );
                    }
                    // On peut choisir de fermer quand même le dialog ou pas
                    // Navigator.of(context).pop();
                  }
                },
          icon: const Icon(Icons.check),
          label: const Text('Appliquer'),
        ),
      ],
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required int min,
    required int max,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty)
          return 'Veuillez entrer une valeur';
        final number = int.tryParse(value.trim());
        if (number == null) return 'Veuillez entrer un nombre valide';
        if (number < min || number > max) return 'Entre $min et $max';
        return null;
      },
    );
  }

  Widget _buildPreview() {
    return Column(
      children: [
        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 10),
        Row(
          children: const [
            Icon(Icons.preview, color: Colors.orange),
            SizedBox(width: 8),
            Text('Prévisualisation',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 150,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _generatedRooms
                  .map(
                    (room) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Text(room,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 12)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _floorsController.dispose();
    _firstRoomController.dispose();
    _lastRoomController.dispose();
    _excludeRoomsController.dispose();
    super.dispose();
  }
}

void showRoomGeneratorDialog(
  BuildContext context,
  RoomProvider roomProvider,
  Function(List<String>) onRoomsGenerated,
) {
  showDialog(
    context: context,
    builder: (context) => RoomGeneratorDialog(
      roomProvider: roomProvider,
      onRoomsGenerated: onRoomsGenerated,
    ),
  );
}
