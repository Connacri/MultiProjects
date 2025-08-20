import 'dart:math';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../hotelScreen.dart';

class ReservationDataSource extends CalendarDataSource {
  ReservationDataSource(
      List<Reservation> reservations, List<CalendarResource> resources) {
    appointments = reservations;
    this.resources = resources; // ✅ assignation des ressources
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
    return (appointments![index] as Reservation).clientName;
  }

  @override
  List<Object>? getResourceIds(int index) {
    return [(appointments![index] as Reservation).roomName];
  }
}

// class ReservationDataSource extends CalendarDataSource {
//   ReservationDataSource({
//     required List<Reservation> reservations,
//     required List<CalendarResource> resources,
//   }) {
//     appointments = reservations;
//     this.resources = resources;
//   }
//
//   Reservation _getReservation(int index) => appointments![index] as Reservation;
//
//   @override
//   DateTime getStartTime(int index) => _getReservation(index).startDate;
//
//   @override
//   DateTime getEndTime(int index) => _getReservation(index).endDate;
//
//   @override
//   String getSubject(int index) {
//     final res = _getReservation(index);
//     final nights = res.endDate.difference(res.startDate).inDays;
//     return "${res.clientName} • ${res.pricePerNight * nights}€ • ${res.status}";
//   }
//
//   @override
//   List<Object>? getResourceIds(int index) => [_getReservation(index).roomName];
//
//   @override
//   Color getColor(int index) {
//     // couleur aléatoire pour la barre de réservation
//     final random = Random(_getReservation(index).hashCode);
//     return Colors.primaries[random.nextInt(Colors.primaries.length)];
//   }
// }

class HotelRoomTimelineScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Exemple de données
    final List<String> rooms = ['Chambre 101', 'Chambre 102', 'Chambre 103'];
    final List<Reservation> reservations = <Reservation>[
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
                    reservations.where((r) => r.roomName == room).toList();
                return ListTile(
                  title: Text(room),
                  subtitle: Row(
                    children: roomReservations.map((res) {
                      return Expanded(
                        flex: res.endDate.difference(res.startDate).inHours,
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 24,
                          color: Colors.blueAccent,
                          child: Center(
                            child: Text(
                              '${res.startDate.hour}h-${res.endDate.hour}h',
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
        reservations.add(Reservation(
            roomName: room,
            startDate: start,
            endDate: end,
            clientName: 'Guedouar'));
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
              minDate: now.subtract(Duration(days: 365)),
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
                    reservations.where((r) => r.roomName == room).toList();
                return ListTile(
                  title: Text(room),
                  subtitle: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: roomReservations.map((res) {
                        return Container(
                          width: 60 +
                              (res.endDate.difference(res.startDate).inHours *
                                  10),
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          height: 20,
                          color: Colors
                              .primaries[index % Colors.primaries.length]
                              .withOpacity(0.6),
                          child: Center(
                            child: Text(
                              '${res.startDate.day}/${res.startDate.month} ${res.startDate.hour}h-${res.endDate.hour}h',
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

class HotelRoomTimelineScreen2 extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Générer 100 chambres
    final List<String> rooms =
        List.generate(50, (i) => 'Chambre ${i + 1}'.padLeft(3, '0'));

    // Générer des réservations aléatoires
    final List<Reservation> reservations = _generateReservations(rooms);

    // Définir les ressources (chambres)
    final List<CalendarResource> resources = rooms
        .map((room) => CalendarResource(id: room, displayName: room))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Gestion des réservations - 100 chambres')),
      body: SfCalendar(
        specialRegions: _getTimeRegions(),
        view: CalendarView.timelineMonth,
        //allowDragAndDrop: true,
        // allowedViews: const [
        //   CalendarView.timelineDay,
        //   CalendarView.timelineWeek,
        //   CalendarView.timelineWorkWeek,
        //   CalendarView.timelineMonth,
        // ],

        // timelineDay | timelineWeek | timelineMonth
        dataSource: ReservationDataSource(reservations, resources),
        todayHighlightColor: Colors.green,
        timeZone: 'Romance Standard Time',
        showTodayButton: true,
        showDatePickerButton: true,
        showCurrentTimeIndicator: true,
        timeSlotViewSettings: TimeSlotViewSettings(
          timeInterval: Duration(hours: 1),
          timeFormat: 'HH',
        ),
        resourceViewSettings: ResourceViewSettings(
          visibleResourceCount: 20, // affiche 20 chambres en même temps
          size: 100, // hauteur de chaque chambre
        ),
        allowViewNavigation: true,
        // navigation infinie possible

        blackoutDatesTextStyle: TextStyle(
            fontStyle: FontStyle.italic,
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.black54),
        showWeekNumber: true,
        weekNumberStyle: const WeekNumberStyle(),
        allowAppointmentResize: true,
      ),
    );
  }

  /// Génère des réservations aléatoires pour les chambres
  // List<Reservation> _generateReservations(List<String> rooms) {
  //   final Random random = Random();
  //   final List<Reservation> reservations = [];
  //
  //   for (final room in rooms) {
  //     // Chaque chambre a entre 2 et 5 réservations
  //     final int count = random.nextInt(4) + 2;
  //
  //     for (int i = 0; i < count; i++) {
  //       final DateTime start = DateTime.now()
  //           .add(Duration(days: random.nextInt(30), hours: random.nextInt(24)));
  //       final DateTime end = start.add(Duration(hours: random.nextInt(6) + 2));
  //       final nameGuest = Faker().person.name();
  //
  //       reservations.add(Reservation(
  //         roomName: room,
  //         startDate: start,
  //         endDate: end,
  //         clientName: nameGuest,
  //       ));
  //     }
  //   }
  //
  //   return reservations;
  // }
  List<Reservation> _generateReservations(List<String> rooms) {
    final Random random = Random();
    final List<Reservation> reservations = [];

    for (final room in rooms) {
      final int count = random.nextInt(3) + 1; // 1 à 3 résas par chambre
      for (int i = 0; i < count; i++) {
        final DateTime start = DateTime.now().add(
          Duration(days: random.nextInt(30)), // dans les 30j
        );
        final int nights = random.nextInt(20) + 1; // 1 à 20 nuitées
        final DateTime end = start.add(Duration(days: nights));

        reservations.add(Reservation(
          roomName: room,
          startDate: start,
          endDate: end,
          clientName: "Client ${random.nextInt(999)}",
          pricePerNight: 50 + random.nextInt(100).toDouble(),
          status: random.nextBool() ? "Confirmée" : "En attente",
        ));
      }
    }

    return reservations;
  }

  List<TimeRegion> _getTimeRegions() {
    final List<TimeRegion> regions = <TimeRegion>[];
    regions.add(TimeRegion(
        startTime: DateTime.now(),
        endTime: DateTime.now().add(Duration(hours: 1)),
        enablePointerInteraction: false,
        color: Colors.grey.withOpacity(0.2),
        text: 'Break'));

    return regions;
  }
}
