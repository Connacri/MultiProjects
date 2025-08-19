import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class HotelRoomTimelineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Exemple de données
    final List<String> rooms = ['Chambre 101', 'Chambre 102', 'Chambre 103'];
    final List<Reservation> reservations = [
      Reservation(
        room: 'Chambre 101',
        start: DateTime.now(),
        end: DateTime.now().add(Duration(hours: 6)),
      ),
      Reservation(
        room: 'Chambre 102',
        start: DateTime.now().add(Duration(hours: 1)),
        end: DateTime.now().add(Duration(hours: 8)),
      ),
      Reservation(
        room: 'Chambre 103',
        start: DateTime.now().add(Duration(hours: 2)),
        end: DateTime.now().add(Duration(hours: 5)),
      ),
    ];

    final List<CalendarResource> resources = rooms
        .map((room) => CalendarResource(id: room, displayName: room))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Gestion des réservations')),
      body: Column(
        children: [
          // Calendrier horizontal
          SizedBox(
            height: 200,
            child: SfCalendar(
              view: CalendarView.timelineDay,
              dataSource: ReservationDataSource(reservations, resources),
              timeSlotViewSettings: TimeSlotViewSettings(
                startHour: 0,
                endHour: 24,
                timeInterval: Duration(hours: 1),
                timeFormat: 'HH',
              ),
              resourceViewSettings: ResourceViewSettings(
                visibleResourceCount: rooms.length,
              ),
            ),
          ),

          // Liste des chambres avec barres de réservations
          Expanded(
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomReservations =
                    reservations.where((r) => r.room == room).toList();
                return ListTile(
                  title: Text(room),
                  subtitle: Row(
                    children: roomReservations.map((res) {
                      return Expanded(
                        flex: res.end.difference(res.start).inHours,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 24,
                          color: Colors.blueAccent,
                          child: Center(
                            child: Text(
                              '${res.start.hour}h-${res.end.hour}h',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// =========================
// Classes
// =========================

class Reservation {
  final String room;
  final DateTime start;
  final DateTime end;

  Reservation({required this.room, required this.start, required this.end});
}

class ReservationDataSource extends CalendarDataSource {
  ReservationDataSource(
      List<Reservation> reservations, List<CalendarResource> resources) {
    appointments = reservations;
    this.resources = resources; // ✅ assignation des ressources
  }

  @override
  DateTime getStartTime(int index) {
    return (appointments![index] as Reservation).start;
  }

  @override
  DateTime getEndTime(int index) {
    return (appointments![index] as Reservation).end;
  }

  @override
  String getSubject(int index) {
    return (appointments![index] as Reservation).room;
  }

  @override
  List<Object>? getResourceIds(int index) {
    return [(appointments![index] as Reservation).room];
  }
}

class HotelRoomTimelineInfiniteScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> rooms = List.generate(100, (i) => 'Chambre ${i + 1}');
    final now = DateTime.now();

    // Génère des réservations aléatoires pour chaque chambre
    final List<Reservation> reservations = [];
    final random = Random();
    for (final room in rooms) {
      // Nombre aléatoire de réservations par chambre (entre 2 et 6)
      int n = 2 + random.nextInt(5);
      for (int i = 0; i < n; i++) {
        // Date de début aléatoire sur les 30 prochains jours
        final startDayOffset = random.nextInt(30);
        final startHour = random.nextInt(18); // entre 0h et 17h
        final start = DateTime(now.year, now.month, now.day)
            .add(Duration(days: startDayOffset, hours: startHour));
        // Durée aléatoire entre 2 et 8 heures
        final duration = 2 + random.nextInt(7);
        final end = start.add(Duration(hours: duration));
        reservations.add(Reservation(room: room, start: start, end: end));
      }
    }

    final List<CalendarResource> resources = rooms
        .map((room) => CalendarResource(id: room, displayName: room))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Planning Hôtel (100 chambres)')),
      body: Column(
        children: [
          // Calendrier horizontal infini (scrollable à travers le mois)
          SizedBox(
            height: 260,
            child: SfCalendar(
              view: CalendarView.timelineMonth,
              allowedViews: const [
                CalendarView.timelineDay,
                CalendarView.timelineWeek,
                CalendarView.timelineWorkWeek,
                CalendarView.timelineMonth,
              ],
              dataSource: ReservationDataSource(reservations, resources),
              timeSlotViewSettings: TimeSlotViewSettings(
                timeInterval: Duration(hours: 1),
                timeFormat: 'HH',
              ),
              resourceViewSettings: ResourceViewSettings(
                visibleResourceCount:
                    20, // pour afficher plus de chambres à l'écran
              ),
              minDate: now.subtract(Duration(days: 30)),
              maxDate: now.add(Duration(days: 365)),
              showDatePickerButton: true,
              showNavigationArrow: true,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final roomReservations =
                    reservations.where((r) => r.room == room).toList();
                return ListTile(
                  title: Text(room),
                  subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: roomReservations.map((res) {
                        return Container(
                          width:
                              60 + (res.end.difference(res.start).inHours * 10),
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 20,
                          color: Colors
                              .primaries[index % Colors.primaries.length]
                              .withOpacity(0.6),
                          child: Center(
                            child: Text(
                              '${res.start.day}/${res.start.month} ${res.start.hour}h-${res.end.hour}h',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 10),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/////////////////////////////////////////////////////

class HotelRoomTimelineScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Générer 100 chambres
    final List<String> rooms =
        List.generate(100, (i) => 'Chambre ${i + 1}'.padLeft(3, '0'));

    // Générer des réservations aléatoires
    final List<Reservation> reservations = _generateReservations(rooms);

    // Définir les ressources (chambres)
    final List<CalendarResource> resources = rooms
        .map((room) => CalendarResource(id: room, displayName: room))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Gestion des réservations - 100 chambres')),
      body: SfCalendar(
        view: CalendarView.timelineMonth,
        // timelineDay | timelineWeek | timelineMonth
        dataSource: ReservationDataSource(reservations, resources),
        showDatePickerButton: true,
        timeSlotViewSettings: TimeSlotViewSettings(
          timeInterval: Duration(hours: 1),
          timeFormat: 'HH',
        ),
        resourceViewSettings: ResourceViewSettings(
          visibleResourceCount: 20, // affiche 20 chambres en même temps
          size: 80, // hauteur de chaque chambre
        ),
        allowViewNavigation: true, // navigation infinie possible
      ),
    );
  }

  /// Génère des réservations aléatoires pour les chambres
  List<Reservation> _generateReservations(List<String> rooms) {
    final Random random = Random();
    final List<Reservation> reservations = [];

    for (final room in rooms) {
      // Chaque chambre a entre 2 et 5 réservations
      final int count = random.nextInt(4) + 2;

      for (int i = 0; i < count; i++) {
        final DateTime start = DateTime.now()
            .add(Duration(days: random.nextInt(30), hours: random.nextInt(24)));
        final DateTime end = start.add(Duration(hours: random.nextInt(6) + 2));

        reservations.add(Reservation(
          room: room,
          start: start,
          end: end,
        ));
      }
    }

    return reservations;
  }
}
