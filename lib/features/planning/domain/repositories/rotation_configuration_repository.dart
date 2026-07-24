import '../entities/rotation_configuration.dart';
import '../entities/rotation_period.dart';

abstract interface class RotationConfigurationRepository {
  Future<RotationConfiguration?> findById(String id);

  Future<RotationConfiguration?> findActive();

  Future<RotationPeriod?> findPeriodFor(DateTime date);
}
