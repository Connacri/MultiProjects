import 'dart:math';

import 'package:flutter/material.dart';

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
    this.pricePerNight = 0.0,
    this.status = "Confirmée",
  });
}

class HotelReservationChart extends StatefulWidget {
  final DateTime fromDate;
  final DateTime toDate;
  final List<Reservation> reservations;
  final List<String> roomNames;

  const HotelReservationChart({
    super.key,
    required this.fromDate,
    required this.toDate,
    required this.reservations,
    required this.roomNames,
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
  void dispose() {
    _horizontalController.dispose();
    _verticalController.dispose();
    super.dispose();
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
      appBar: AppBar(title: const Text('Réservations')),
      body: MouseRegion(
        cursor:
            _isDragging ? SystemMouseCursors.grabbing : SystemMouseCursors.grab,
        child: Listener(
          onPointerDown: (e) => _handlePointer(e, 'down'),
          onPointerUp: (e) => _handlePointer(e, 'up'),
          onPointerMove: (e) => _handlePointer(e, 'move'),
          child: Column(
            children: [_buildHeader(), Expanded(child: _buildBody())],
          ),
        ),
      ),
    );
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

  Widget _buildBody() {
    return Row(
      children: [
        SingleChildScrollView(
          controller: _verticalController,
          child: Column(
            children: widget.roomNames
                .map((room) => Container(
                      width: roomNameWidth,
                      height: roomHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.grey.shade100,
                      ),
                      child: Text(room,
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
              controller: ScrollController(),
              // New controller for vertical scrolling in the body
              scrollDirection: Axis.vertical,
              child: Column(
                children: widget.roomNames.map((room) {
                  final roomRes = widget.reservations
                      .where((r) => r.roomName == room)
                      .toList();
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
                            left: calculateLeftOffset(res.startDate),
                            top: 4,
                            child: Tooltip(
                              message:
                                  '${res.clientName} (${res.status})\nDu ${res.startDate.day}/${res.startDate.month} au ${res.endDate.day}/${res.endDate.month}\n${res.pricePerNight.toStringAsFixed(2)} DA/nuit',
                              child: Container(
                                width: calculateBarWidth(
                                    res.startDate, res.endDate),
                                height: roomHeight - 8,
                                decoration: BoxDecoration(
                                    color: _generateColor(),
                                    borderRadius: BorderRadius.circular(6)),
                                alignment: Alignment.center,
                                child: Text(res.clientName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 10, color: Colors.white)),
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

  String _getDayShort(int weekday) {
    const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return days[(weekday - 1) % 7];
  }
}
