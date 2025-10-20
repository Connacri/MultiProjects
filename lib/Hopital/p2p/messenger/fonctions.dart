import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

import '../../../objectBox/Entity.dart';
import 'messaging_entities.dart';

String? getBranchForNode(String nodeId) {
  try {
    final staffBox = objectBoxGlobal.store.box<Staff>();
    // Supposons que `nodeId` correspond à l'ID du staff
    final staff = staffBox.get(int.tryParse(nodeId) ?? 0);
    return staff?.branch.target?.branchNom;
  } catch (e) {
    return null;
  }
}

Future<String> getCurrentPlatform() async {
  final deviceInfo = DeviceInfoPlugin();
  if (kIsWeb) {
    return 'Web';
  } else {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return 'iOS ${iosInfo.systemVersion}';
      } else if (Platform.isWindows) {
        return 'Windows';
      } else if (Platform.isMacOS) {
        return 'macOS';
      } else if (Platform.isLinux) {
        return 'Linux';
      } else {
        return 'Inconnu';
      }
    } catch (e) {
      return 'Inconnu';
    }
  }
}
