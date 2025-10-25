import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart' as Nonce;

import 'p2p_manager.dart';

/// Gestionnaire cryptographique - Singleton
/// Responsabilité: Chiffrement/déchiffrement des deltas P2P
class CryptoManager {
  static final CryptoManager _instance = CryptoManager._internal();

  factory CryptoManager() => _instance;

  CryptoManager._internal();

  final _ecdhAlgorithm = X25519();
  SimpleKeyPair? _localKeyPair;
  SimplePublicKey? _localPublicKey;

  SecretKey? _aesSessionKey;
  final _aesAlgorithm = AesGcm.with256bits();
  final _hmacAlgorithm = Hmac.sha256();

  /// Initialise le gestionnaire cryptographique
  Future<void> initialize() async {
    try {
      await _generateKeyPair();
      await _deriveSessionKey();
      print('[Crypto] ✅ CryptoManager initialisé');
    } catch (e) {
      print('[Crypto] ❌ Erreur initialisation: $e');
      rethrow;
    }
  }

  /// Génère une paire de clés ECDH X25519
  Future<void> _generateKeyPair() async {
    try {
      _localKeyPair = await _ecdhAlgorithm.newKeyPair();
      _localPublicKey = await _localKeyPair!.extractPublicKey();
      print('[Crypto] 🔑 Paire de clés générée');
    } catch (e) {
      print('[Crypto] ❌ Erreur génération clés: $e');
      rethrow;
    }
  }

  /// Récupère la clé publique en Base64
  String? get publicKeyBase64 {
    if (_localPublicKey == null) return null;
    return base64Encode(_localPublicKey!.bytes);
  }

  /// Dérive une clé de session AES-256 de manière déterministe
  Future<void> _deriveSessionKey() async {
    try {
      final infoBytes = utf8.encode('hospital-p2p-session-key-v1');
      final sha256 = Sha256();
      final digest = await sha256.hash(infoBytes);
      _aesSessionKey = SecretKey(digest.bytes);

      if (_aesSessionKey == null) {
        throw Exception('Dérivation de clé échouée');
      }

      print('[Crypto] 🔐 Clé de session dérivée (SHA256)');
    } catch (e) {
      print('[Crypto] ❌ Erreur dérivation clé: $e');
      rethrow;
    }
  }

  /// Chiffre un delta avec AES-256-GCM
  Future<Map<String, dynamic>> encryptDelta(
    Map<String, dynamic> delta,
  ) async {
    if (_aesSessionKey == null) {
      throw Exception('Clé de session non initialisée');
    }

    try {
      final jsonString = jsonEncode(delta);
      final plaintext = utf8.encode(jsonString);
      final nonceBytes = Nonce.randomBytes(12);
      final secretKey = _aesSessionKey!;

      final encrypted = await _aesAlgorithm.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: nonceBytes,
      );

      print('[Crypto] 🔒 Delta chiffré (${plaintext.length} bytes)');

      return {
        'ciphertext': base64Encode(encrypted.cipherText),
        'nonce': base64Encode(nonceBytes),
        'tag': base64Encode(encrypted.mac.bytes),
        'version': '1.0',
      };
    } catch (e) {
      print('[Crypto] ❌ Erreur chiffrement: $e');
      rethrow;
    }
  }

  /// Déchiffre un delta avec AES-256-GCM
  Future<Map<String, dynamic>> decryptDelta(
    Map<String, dynamic> encrypted,
  ) async {
    if (_aesSessionKey == null) {
      throw Exception('Clé de session non initialisée');
    }

    try {
      final ciphertext = base64Decode(encrypted['ciphertext'] as String);
      final nonceBytes = base64Decode(encrypted['nonce'] as String);
      final tagBytes = base64Decode(encrypted['tag'] as String);
      final secretKey = _aesSessionKey!;

      final decrypted = await _aesAlgorithm.decrypt(
        SecretBox(ciphertext, nonce: nonceBytes, mac: Mac(tagBytes)),
        secretKey: secretKey,
      );

      final result = jsonDecode(utf8.decode(decrypted));
      print('[Crypto] 🔓 Delta déchiffré et vérifié');
      return result;
    } catch (e) {
      print('[Crypto] ❌ Erreur déchiffrement: $e');
      rethrow;
    }
  }

  /// Vérifie l'intégrité d'un delta via authentification GCM
  Future<bool> verifyDelta(Map<String, dynamic> encrypted) async {
    try {
      final ciphertext = base64Decode(encrypted['ciphertext'] as String);
      final tagBytes = base64Decode(encrypted['tag'] as String);
      final nonceBytes = base64Decode(encrypted['nonce'] as String);
      final secretKey = _aesSessionKey!;

      // Le déchiffrement échoue automatiquement si le tag est invalide
      await _aesAlgorithm.decrypt(
        SecretBox(ciphertext, nonce: nonceBytes, mac: Mac(tagBytes)),
        secretKey: secretKey,
      );

      print('[Crypto] ✅ Delta authentique');
      return true;
    } catch (e) {
      print('[Crypto] ⚠️ Vérification delta échouée: $e');
      return false;
    }
  }

  /// Effectue une rotation des clés (régénère la paire ECDH)
  Future<void> rotateKeys() async {
    try {
      await _generateKeyPair();
      print('[Crypto] 🔄 Clés cryptographiques régénérées');
    } catch (e) {
      print('[Crypto] ❌ Erreur rotation clés: $e');
      rethrow;
    }
  }

  /// Génère un QR code d'onboarding pour ajouter un nouveau nœud
  Map<String, dynamic> generateOnboardingQR() {
    return {
      'nodeId': P2PManager().nodeId,
      'publicKey': publicKeyBase64 ?? 'no-key',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }
}
