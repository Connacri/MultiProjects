import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Entity.dart';
import '../../../classeObjectBox.dart';
import 'provider_hotel.dart';

class deepseek extends StatelessWidget {
  const deepseek({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gestion Hôtelière',
      home: HotelReservationChart(
        fromDate: DateTime.now().subtract(const Duration(days: 30)),
        toDate: DateTime.now().add(const Duration(days: 30)),
        rooms: context.read<ObjectBox>().roomBox.getAll(),
      ),
    );
  }
}

class HotelReservationChart extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Room> rooms; // Maintenant on passe les objets Room complets

  const HotelReservationChart({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.rooms,
  });

  @override
  State<HotelReservationChart> createState() => _HotelReservationChartState();
}

class _HotelReservationChartState extends State<HotelReservationChart> {
  final ScrollController _horizontalController = ScrollController();
  final ScrollController _verticalController = ScrollController();
  final double dayWidth = 40.0;
  final double roomHeight = 36.0;
  final double roomNameWidth = 100.0;
  Offset? _lastPosition;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    // Initialisation des données via le Provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<HotelProvider>(context, listen: false);
      // Les données sont déjà chargées dans le provider
    });
  }

  int get totalDays => widget.toDate.difference(widget.fromDate).inDays + 1;

  double calculateLeftOffset(DateTime startDate) {
    return max(0, startDate.difference(widget.fromDate).inDays) * dayWidth;
  }

  double calculateBarWidth(DateTime start, DateTime end) {
    DateTime effectiveStart =
        start.isBefore(widget.fromDate) ? widget.fromDate : start;
    DateTime effectiveEnd = end.isAfter(widget.toDate) ? widget.toDate : end;
    return (effectiveEnd.difference(effectiveStart).inDays + 1) * dayWidth;
  }

  Color _generateColor() {
    final r = Random();
    return Color.fromRGBO(r.nextInt(200), r.nextInt(200), r.nextInt(200), 0.8);
  }

  void _handlePointer(PointerEvent e, String type) {
    if (type == 'down') {
      _isDragging = true;
      _lastPosition = e.position;
    } else if (type == 'up') {
      _isDragging = false;
      _lastPosition = null;
    } else if (type == 'move' && _isDragging && _lastPosition != null) {
      final dx = e.position.dx - _lastPosition!.dx;
      final dy = e.position.dy - _lastPosition!.dy;
      _horizontalController.jumpTo((_horizontalController.offset + dx)
          .clamp(0.0, _horizontalController.position.maxScrollExtent));
      _verticalController.jumpTo((_verticalController.offset + dy)
          .clamp(0.0, _verticalController.position.maxScrollExtent));
      _lastPosition = e.position;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Réservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddReservationDialog(context),
          ),
        ],
      ),
      body: Consumer<HotelProvider>(
        builder: (context, provider, child) {
          return MouseRegion(
            cursor: _isDragging
                ? SystemMouseCursors.grabbing
                : SystemMouseCursors.grab,
            child: Listener(
              onPointerDown: (e) => _handlePointer(e, 'down'),
              onPointerUp: (e) => _handlePointer(e, 'up'),
              onPointerMove: (e) => _handlePointer(e, 'move'),
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(child: _buildBody(provider))
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Boîte de dialogue pour ajouter une réservation
  void _showAddReservationDialog(BuildContext context) {
    // Implémentez votre dialogue d'ajout de réservation ici
    // Utilisez Provider.of<ReservationProvider>(context, listen: false).addReservation()
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          Container(
            width: roomNameWidth,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const Text("Chambre",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: _horizontalController,
              child: Row(
                children: List.generate(totalDays, (index) {
                  final date = widget.fromDate.add(Duration(days: index));
                  return Container(
                    width: dayWidth,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      color: date.weekday == DateTime.sunday
                          ? Colors.red.shade50
                          : Colors.grey.shade100,
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${date.day}/${date.month}',
                            style: const TextStyle(fontSize: 11)),
                        Text(_getDayShort(date.weekday),
                            style: const TextStyle(fontSize: 10)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBody(HotelProvider provider) {
    return Row(
      children: [
        SingleChildScrollView(
          controller: _verticalController,
          child: Column(
            children: widget.rooms
                .map((room) => Container(
                      width: roomNameWidth,
                      height: roomHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(room.code,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ))
                .toList(),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            controller: _horizontalController,
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: widget.rooms.map((room) {
                  final roomRes = provider.getReservationsByRoom(room);
                  return Stack(
                    children: [
                      Row(
                        children: List.generate(
                            totalDays,
                            (_) => Container(
                                width: dayWidth,
                                height: roomHeight,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.grey.shade200)))),
                      ),
                      ...roomRes.map((res) => Positioned(
                            left: calculateLeftOffset(res.from),
                            top: 4,
                            child: GestureDetector(
                              onLongPress: () {
                                _showReservationOptions(context, res, provider);
                              },
                              child: Tooltip(
                                message:
                                    '${provider.getPrimaryGuestName(res)} (${res.status})\n'
                                    'Du ${res.from.day}/${res.from.month} au ${res.to.day}/${res.to.month}\n'
                                    '${res.pricePerNight.toStringAsFixed(2)} DA/nuit',
                                child: Container(
                                  width: calculateBarWidth(res.from, res.to),
                                  height: roomHeight - 8,
                                  decoration: BoxDecoration(
                                      color: _generateColor(),
                                      borderRadius: BorderRadius.circular(6)),
                                  alignment: Alignment.center,
                                  child: Text(
                                    provider.getPrimaryGuestName(res),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white),
                                  ),
                                ),
                              ),
                            ),
                          ))
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Options pour une réservation (modifier/supprimer)
  void _showReservationOptions(
      BuildContext context, Reservation reservation, HotelProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Supprimer'),
                onTap: () {
                  provider.deleteReservation(reservation.id);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getDayShort(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[(weekday - 1) % 7];
  }
}
