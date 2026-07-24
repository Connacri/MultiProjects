import 'dart:convert';

import '../../domain/entities/rotation_configuration.dart';
import '../../domain/enums/rotation_policy.dart';
import '../../domain/enums/shift_type.dart';
import '../objectbox/rotation_configuration_entity.dart';

/// Converts versioned rotation configurations between the domain and ObjectBox.
///
/// A configuration is a historical business definition. Its version and
/// `teamOrder` are persisted together so a later reorder creates a new
/// configuration version instead of silently changing historical planning.
class RotationConfigurationMapper {
  const RotationConfigurationMapper();

  RotationConfiguration fromObjectBox(RotationConfigurationEntity entity) {
    final teamOrder = _decodeStringList(entity.teamOrderJson);
    final cycle = _decodeStringList(entity.cycleJson)
        .map(_shiftFromString)
        .toList(growable: false);

    return RotationConfiguration(
      id: entity.name.isEmpty ? 'obx-${entity.id}' : entity.name,
      version: entity.version,
      teamOrder: List.unmodifiable(teamOrder),
      cycle: List.unmodifiable(cycle),
      policy: _policyFromInt(entity.policy),
      referenceDate: DateTime.fromMillisecondsSinceEpoch(
        entity.referenceDateEpochMs,
      ),
      referencePhaseIndex: entity.referencePhaseIndex,
    );
  }

  RotationConfigurationEntity toObjectBox({
    required RotationConfiguration configuration,
    required int branchId,
  }) {
    return RotationConfigurationEntity()
      ..branchId = branchId
      ..version = configuration.version
      ..name = configuration.id
      ..teamOrderJson = jsonEncode(configuration.teamOrder)
      ..cycleJson = jsonEncode(
        configuration.cycle.map((shift) => shift.name).toList(growable: false),
      )
      ..policy = _policyToInt(configuration.policy)
      ..referenceDateEpochMs =
          configuration.referenceDate.millisecondsSinceEpoch
      ..referencePhaseIndex = configuration.referencePhaseIndex
      ..active = true;
  }

  List<String> _decodeStringList(String value) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((item) => item.toString()).toList(growable: false);
      }
    } catch (_) {
      // Invalid persisted configuration is rejected by the domain validation
      // layer rather than crashing ObjectBox reads.
    }
    return const [];
  }

  ShiftType _shiftFromString(String value) {
    switch (value.toLowerCase()) {
      case 'day':
        return ShiftType.day;
      case 'night':
        return ShiftType.night;
      case 'leave':
        return ShiftType.leave;
      case 'training':
        return ShiftType.training;
      case 'activity':
        return ShiftType.activity;
      default:
        return ShiftType.rest;
    }
  }

  RotationPolicy _policyFromInt(int value) {
    if (value < 0 || value >= RotationPolicy.values.length) {
      return RotationPolicy.continueFromPreviousPublished;
    }
    return RotationPolicy.values[value];
  }

  int _policyToInt(RotationPolicy policy) => policy.index;
}
