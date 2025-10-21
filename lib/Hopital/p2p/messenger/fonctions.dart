import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../objectBox/classeObjectBox.dart';
import '../../../objectbox.g.dart';

/// ✅ CORRECTION: Récupérer la branche pour un nodeId donné
/// Cette fonction essaie de trouver un staff correspondant au nodeId
/// et retourne sa branche associée
String? getBranchForNode(String nodeId) {
  try {
    final objectBox = ObjectBox();
    final staffBox = objectBox.staffBox;

    // Le nodeId a le format: 'node-{timestamp}-{hostname}'
    // On essaie de trouver un staff dont le nom correspond au hostname
    final hostname = _extractHostnameFromNodeId(nodeId);

    if (hostname == null) {
      print(
          '[getBranchForNode] ⚠️ Impossible d\'extraire hostname de: $nodeId');
      return null;
    }

    // Chercher un staff dont le nom contient le hostname
    final query = staffBox
        .query(Staff_.nom.contains(hostname, caseSensitive: false))
        .build();

    final staff = query.findFirst();
    query.close();

    if (staff != null) {
      final branchName = staff.branch.target?.branchNom;
      print('[getBranchForNode] ✅ Branche trouvée pour $nodeId: $branchName');
      return branchName;
    }

    print('[getBranchForNode] ⚠️ Aucun staff trouvé pour: $hostname');
    return null;
  } catch (e) {
    print('[getBranchForNode] ❌ Erreur: $e');
    return null;
  }
}

/// ✅ NOUVEAU: Récupérer la branche de l'utilisateur courant
/// Basé sur le hostname de la machine locale
String? getBranchForCurrentUser() {
  try {
    final objectBox = ObjectBox();
    final staffBox = objectBox.staffBox;

    // Récupérer le hostname local
    final hostname = Platform.localHostname;

    if (hostname.isEmpty) {
      print('[getBranchForCurrentUser] ⚠️ Hostname vide');
      return null;
    }

    // Chercher un staff correspondant
    final query = staffBox
        .query(Staff_.nom.contains(hostname, caseSensitive: false))
        .build();

    final staff = query.findFirst();
    query.close();

    if (staff != null) {
      final branchName = staff.branch.target?.branchNom;
      print('[getBranchForCurrentUser] ✅ Branche locale: $branchName');
      return branchName;
    }

    // Si aucun staff trouvé, retourner le premier staff (fallback)
    final allStaffs = staffBox.getAll();
    if (allStaffs.isNotEmpty) {
      final firstStaffBranch = allStaffs.first.branch.target?.branchNom;
      print(
          '[getBranchForCurrentUser] ⚠️ Utilisation du premier staff: $firstStaffBranch');
      return firstStaffBranch;
    }

    print('[getBranchForCurrentUser] ⚠️ Aucun staff trouvé');
    return null;
  } catch (e) {
    print('[getBranchForCurrentUser] ❌ Erreur: $e');
    return null;
  }
}

/// Extraire le hostname d'un nodeId
/// Format: 'node-{timestamp}-{hostname}'
String? _extractHostnameFromNodeId(String nodeId) {
  try {
    final parts = nodeId.split('-');
    if (parts.length >= 3) {
      // Retourner tout sauf 'node' et le timestamp
      return parts.skip(2).join('-');
    }
    return null;
  } catch (e) {
    return null;
  }
}

/// ✅ Fonction existante améliorée
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
        final windowsInfo = await deviceInfo.windowsInfo;
        return 'Windows ${windowsInfo.productName}';
      } else if (Platform.isMacOS) {
        final macInfo = await deviceInfo.macOsInfo;
        return 'macOS ${macInfo.osRelease}';
      } else if (Platform.isLinux) {
        final linuxInfo = await deviceInfo.linuxInfo;
        return 'Linux ${linuxInfo.name}';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print('[getCurrentPlatform] ❌ Erreur: $e');
      return 'Unknown';
    }
  }
}

/// ✅ NOUVEAU: Obtenir les informations complètes de l'appareil
Future<Map<String, String>> getDeviceInfo() async {
  try {
    final platform = await getCurrentPlatform();
    final hostname = Platform.localHostname;
    final branch = getBranchForCurrentUser();

    return {
      'platform': platform,
      'hostname': hostname,
      'branch': branch ?? 'No Branch',
    };
  } catch (e) {
    print('[getDeviceInfo] ❌ Erreur: $e');
    return {
      'platform': 'Unknown',
      'hostname': 'Unknown',
      'branch': 'No Branch',
    };
  }
}

/// ✅ Icône selon la plateforme
IconData getPlatformIcon(String platform) {
  final platformLower = platform.toLowerCase();

  if (platformLower.contains('android')) {
    return Icons.android;
  } else if (platformLower.contains('ios')) {
    return Icons.apple;
  } else if (platformLower.contains('windows')) {
    return Icons.desktop_windows;
  } else if (platformLower.contains('macos')) {
    return Icons.laptop_mac;
  } else if (platformLower.contains('linux')) {
    return Icons.computer;
  } else if (platformLower.contains('web')) {
    return Icons.language;
  }

  return Icons.device_unknown;
}
