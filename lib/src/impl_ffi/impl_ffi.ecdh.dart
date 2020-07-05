part of impl_ffi;

Future<EcdhPrivateKey> ecdhPrivateKey_importPkcs8Key(
  List<int> keyData,
  EllipticCurve curve,
) async =>
    _EcdhPrivateKey(_importPkcs8EcPrivateKey(keyData, curve));

Future<EcdhPrivateKey> ecdhPrivateKey_importJsonWebKey(
  Map<String, dynamic> jwk,
  EllipticCurve curve,
) async =>
    _EcdhPrivateKey(_importJwkEcPrivateOrPublicKey(
      JsonWebKey.fromJson(jwk),
      curve,
      isPrivateKey: true,
      expectedUse: 'enc',
      expectedAlg: null, // ECDH has no validation of 'jwk.alg'
    ));

Future<KeyPair<EcdhPrivateKey, EcdhPublicKey>> ecdhPrivateKey_generateKey(
  EllipticCurve curve,
) async {
  final p = _generateEcKeyPair(curve);
  return _KeyPair(
    privateKey: _EcdhPrivateKey(p.privateKey),
    publicKey: _EcdhPublicKey(p.publicKey),
  );
}

Future<EcdhPublicKey> ecdhPublicKey_importRawKey(
  List<int> keyData,
  EllipticCurve curve,
) async =>
    _EcdhPublicKey(_importRawEcPublicKey(keyData, curve));

Future<EcdhPublicKey> ecdhPublicKey_importSpkiKey(
  List<int> keyData,
  EllipticCurve curve,
) async =>
    _EcdhPublicKey(_importSpkiEcPublicKey(keyData, curve));

Future<EcdhPublicKey> ecdhPublicKey_importJsonWebKey(
  Map<String, dynamic> jwk,
  EllipticCurve curve,
) async =>
    _EcdhPublicKey(_importJwkEcPrivateOrPublicKey(
      JsonWebKey.fromJson(jwk),
      curve,
      isPrivateKey: false,
      expectedUse: 'enc',
      expectedAlg: null, // ECDH has no validation of 'jwk.alg'
    ));

class _EcdhPrivateKey with _Disposable implements EcdhPrivateKey {
  final ffi.Pointer<ssl.EVP_PKEY> _key;

  _EcdhPrivateKey(this._key);

  @override
  void _finalize() {
    ssl.EVP_PKEY_free(_key);
  }

  @override
  Future<Uint8List> deriveBits(int length, EcdhPublicKey publicKey) async {
    ArgumentError.checkNotNull(length, 'length');
    ArgumentError.checkNotNull(publicKey, 'publicKey');
    if (publicKey is! _EcdhPublicKey) {
      throw ArgumentError.value(
        publicKey,
        'publicKey',
        'custom implementations of EcdhPublicKey is not supported',
      );
    }
    if (length <= 0) {
      throw ArgumentError.value(length, 'length', 'must be positive');
    }
    final _publicKey = publicKey as _EcdhPublicKey;

    final pubEcKey = ssl.EVP_PKEY_get0_EC_KEY(_publicKey._key);
    final privEcKey = ssl.EVP_PKEY_get0_EC_KEY(_key);

    // Check that public/private key uses the same elliptic curve.
    if (ssl.EC_GROUP_get_curve_name(ssl.EC_KEY_get0_group(pubEcKey)) !=
        ssl.EC_GROUP_get_curve_name(ssl.EC_KEY_get0_group(privEcKey))) {
      // Note: web crypto will throw an InvalidAccessError here.
      throw ArgumentError.value(
        publicKey,
        'publicKey',
        'Public and private key for ECDH key derivation have the same '
            'elliptic curve',
      );
    }

    // Field size rounded up to 8 bits is the maximum number of bits we can
    // derive. The most significant bits will be zero in this case.
    final fieldSize = ssl.EC_GROUP_get_degree(ssl.EC_KEY_get0_group(privEcKey));
    final maxLength = 8 * (fieldSize / 8).ceil();
    if (length > maxLength) {
      throw _OperationError(
        'Length in ECDH key derivation is too large. '
        'Maximum allowed is $maxLength bits.',
      );
    }

    if (length == 0) {
      return Uint8List.fromList([]);
    }

    final lengthInBytes = (length / 8).ceil();
    final derived = _withOutPointer(lengthInBytes, (ffi.Pointer<ssl.Data> p) {
      final outLen = ssl.ECDH_compute_key(
        p,
        lengthInBytes,
        ssl.EC_KEY_get0_public_key(pubEcKey),
        privEcKey,
        ffi.nullptr,
      );
      _checkOp(outLen != -1, fallback: 'ECDH key derivation failed');
      _checkOp(
        outLen == lengthInBytes,
        message: 'internal error in ECDH key derivation',
      );
    });

    // Only return the first [length] bits from derived.
    final zeroBits = lengthInBytes * 8 - length;
    assert(zeroBits < 8);
    if (zeroBits > 0) {
      derived.last &= ((0xff << zeroBits) & 0xff);
    }

    return derived;
  }

  @override
  Future<Map<String, dynamic>> exportJsonWebKey() async =>
      // Neither Chrome or Firefox produces 'use': 'enc' for ECDH, we choose to
      // omit it for better interoperability. Chrome incorrectly forbids during
      // import (though we strip 'use' to mitigate this).
      // See also: https://crbug.com/641499 (and importJsonWebKey in JS)
      _exportJwkEcPrivateOrPublicKey(_key, isPrivateKey: true, jwkUse: null);

  @override
  Future<Uint8List> exportPkcs8Key() async {
    return _withOutCBB((cbb) {
      _checkOp(ssl.EVP_marshal_private_key(cbb, _key) == 1);
    });
  }
}

class _EcdhPublicKey with _Disposable implements EcdhPublicKey {
  final ffi.Pointer<ssl.EVP_PKEY> _key;

  _EcdhPublicKey(this._key);

  @override
  void _finalize() {
    ssl.EVP_PKEY_free(_key);
  }

  @override
  Future<Map<String, dynamic>> exportJsonWebKey() async =>
      // Neither Chrome or Firefox produces 'use': 'enc' for ECDH, we choose to
      // omit it for better interoperability. Chrome incorrectly forbids during
      // import (though we strip 'use' to mitigate this).
      // See also: https://crbug.com/641499 (and importJsonWebKey in JS)
      _exportJwkEcPrivateOrPublicKey(_key, isPrivateKey: false, jwkUse: null);

  @override
  Future<Uint8List> exportRawKey() async => _exportRawEcPublicKey(_key);

  @override
  Future<Uint8List> exportSpkiKey() async {
    return _withOutCBB((cbb) {
      _checkOp(ssl.EVP_marshal_public_key(cbb, _key) == 1);
    });
  }
}