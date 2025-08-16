import 'package:flutter/material.dart';

import '../../timely_x.dart';

class TyxResourceOption {
  final double? timeslotHeight;
  final Duration? timelotSlotDuration;
  final DateTime? initialDate;
  final TimeOfDay? timeslotStartTime;
  final double? cellWidth;
  final double? timesCellWidth;
  final double? resourceHeaderHeight;

  final List<TyxResource>? resources;
  final List<TyxEvent>? events;

  Widget Function(BuildContext context, TyxEventEnhanced item)? eventBuilder;
  Widget Function(BuildContext context, TyxResourceEnhanced item)?
      resourceBuilder;
  TyxResourceOption({
    this.timeslotHeight,
    this.timelotSlotDuration,
    this.initialDate,
    this.timeslotStartTime,
    this.cellWidth,
    this.timesCellWidth,
    this.resourceHeaderHeight,
    this.resources,
    this.events,
    this.eventBuilder,
    this.resourceBuilder,
  });
}
