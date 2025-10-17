import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:cryptography/helpers.dart' as Nonce;

import 'p2p_managers.dart';

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

  Future<void> initialize() async {
    await _generateKeyPair();
    await _deriveSessionKey();
  }

  Future<void> _generateKeyPair() async {
    _localKeyPair = await _ecdhAlgorithm.newKeyPair();
    _localPublicKey = await _localKeyPair!.extractPublicKey();
    print('🔑 Clé publique générée');
  }

  String? get publicKeyBase64 {
    if (_localPublicKey == null) return null;
    return base64Encode(_localPublicKey!.bytes);
  }

  Future<void> _deriveSessionKey() async {
    final baseKey = SecretKey(List<int>.generate(32, (i) => i));
    final hkdf = Hkdf(hmac: _hmacAlgorithm, outputLength: 32);
    _aesSessionKey = await hkdf.deriveKey(
      secretKey: baseKey,
      info: utf8.encode('hospital-p2p-session'),
      nonce: Uint8List(0),
    );
  }

  Future<Map<String, dynamic>> encryptDelta(Map<String, dynamic> delta) async {
    final jsonString = jsonEncode(delta);
    final plaintext = utf8.encode(jsonString);

    final nonceBytes = Nonce.randomBytes(12);
    final secretKey = _aesSessionKey!;
    final encrypted = await _aesAlgorithm.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonceBytes,
    );

    return {
      'ciphertext': base64Encode(encrypted.cipherText),
      'nonce': base64Encode(nonceBytes),
      'tag': base64Encode(encrypted.mac.bytes),
      'version': '1.0',
    };
  }

  Future<Map<String, dynamic>> decryptDelta(
      Map<String, dynamic> encrypted) async {
    final ciphertext = base64Decode(encrypted['ciphertext']);
    final nonceBytes = base64Decode(encrypted['nonce']);
    final tagBytes = base64Decode(encrypted['tag']);

    final secretKey = _aesSessionKey!;
    final decrypted = await _aesAlgorithm.decrypt(
      SecretBox(ciphertext, nonce: nonceBytes, mac: Mac(tagBytes)),
      secretKey: secretKey,
    );

    return jsonDecode(utf8.decode(decrypted));
  }

  /// 🔁 Rotation manuelle des clés ECDH
  Future<void> rotateKeys() async {
    await _generateKeyPair();
    print('🧩 Clés cryptographiques régénérées.');
  }

  /// 🧩 Vérifie l’intégrité d’un delta reçu via HMAC
  Future<bool> verifyDelta(Map<String, dynamic> encrypted) async {
    try {
      // On reconstruit les morceaux du message
      final ciphertext = base64Decode(encrypted['ciphertext']);
      final tagBytes = base64Decode(encrypted['tag']);
      final nonceBytes = base64Decode(encrypted['nonce']);
      final secretKey = _aesSessionKey!;

      // Tenter une décryption test (sans erreur = message authentique)
      await _aesAlgorithm.decrypt(
        SecretBox(ciphertext, nonce: nonceBytes, mac: Mac(tagBytes)),
        secretKey: secretKey,
      );

      print('✅ Delta vérifié et authentique');
      return true;
    } catch (e) {
      print('⚠️ Vérification du delta échouée : $e');
      return false;
    }
  }

  /// 🧾 Génère un QR Code d'onboarding pour ajouter un nœud
  Map<String, dynamic> generateOnboardingQR() {
    return {
      'nodeId': P2PManager().nodeId,
      'publicKey': publicKeyBase64 ?? 'no-key',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0',
    };
  }
}
