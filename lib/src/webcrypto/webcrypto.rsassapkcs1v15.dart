// Copyright 2020 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of webcrypto;

/// RSASSA-PKCS1-v1_5 private key for signing messages.
///
/// An [RsassaPkcs1V15PrivateKey] instance hold a private RSA key for computing
/// signatures using the RSASSA-PKCS1-v1_5 scheme as specified in [RFC 3447][1].
///
/// Instances of [RsassaPkcs1V15PrivateKey] can be imported using
/// [RsassaPkcs1V15PrivateKey.importPkcs8Key] or generated using
/// [RsassaPkcs1V15PrivateKey.generateKey] which generates a public-private
/// key-pair.
///
/// [1]: https://tools.ietf.org/html/rfc3447
@sealed
abstract class RsassaPkcs1V15PrivateKey {
  RsassaPkcs1V15PrivateKey._(); // keep the constructor private.

  /// Import RSASSA-PKCS1-v1_5 private key in PKCS #8 format.
  ///
  /// Creates an [RsassaPkcs1V15PrivateKey] from [keyData] given as the DER
  /// encoding of the _PrivateKeyInfo structure_ specified in [RFC 5208][1].
  /// The hash algorithm to be used is specified by [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.privateKey).decode("""
  ///   -----BEGIN PRIVATE KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PRIVATE KEY-----
  /// """);
  ///
  /// // Import private key from binary PEM decoded data.
  /// final privateKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the key again (print it in same format as it was given).
  /// List<int> rawKeyData = await privateKey.exportPkcs8Key();
  /// print(PemCodec(PemLabel.privateKey).encode(rawKeyData));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5208
  static Future<RsassaPkcs1V15PrivateKey> importPkcs8Key(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    return impl.rsassaPkcs1V15PrivateKey_importPkcs8Key(keyData, hash);
  }

  /// Import RSASSA-PKCS1-v1_5 private key in [JWK][1] format.
  ///
  /// TODO: finish documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  static Future<RsassaPkcs1V15PrivateKey> importJsonWebKey(
    Map<String, dynamic> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    return impl.rsassaPkcs1V15PrivateKey_importJsonWebKey(jwk, hash);
  }

  /// Generate an RSASSA-PKCS1-v1_5 public/private key-pair.
  ///
  /// Generate an RSA key with given [modulusLength], this should be at-least
  /// `2048` (though `4096` is often recommended). [publicExponent] should be
  /// `3` or `65537` these are the only values [supported by Chrome][1], unless
  /// you have a good reason to use something else `65537` is recommended.
  ///
  /// The hash algorithm to be used is specified by [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Export public, so Alice can use it later.
  /// final rawPublicKey = await keyPair.publicKey.exportSpkiKey();
  /// final pemPublicKey = PemCodec(PemLabel.publicKey).encode(rawPublicKey);
  /// print(pemPublicKey); // print key in PEM format: -----BEGIN PUBLIC KEY....
  ///
  /// // Sign a message for Alice.
  /// final message = 'Hi Alice';
  /// final signature = await keyPair.privateKey.signBytes(
  ///   utf8.encode(message),
  /// );
  ///
  /// // On the other side of the world, Alice has written down the pemPublicKey
  /// // on a trusted piece of paper, but receives the message and signature
  /// // from an untrusted source (thus, desires to verify the signature).
  /// final publicKey = await RsassaPkcs1V15PublicKey.importSpkiKey(
  ///   PemCodec(PemLabel.publicKey).decode(pemPublicKey),
  ///   Hash.sha256,
  /// );
  /// final isValid = await publicKey.verifyBytes(
  ///   signature,
  ///   utf8.encode(message),
  /// );
  /// if (isValid) {
  ///   print('Authentic message from Bob: $message');
  /// }
  /// ```
  ///
  /// [1]: https://chromium.googlesource.com/chromium/src/+/43d62c50b705f88c67b14539e91fd8fd017f70c4/components/webcrypto/algorithms/rsa.cc#286
  static Future<KeyPair<RsassaPkcs1V15PrivateKey, RsassaPkcs1V15PublicKey>>
      generateKey(
    int modulusLength,
    BigInt publicExponent,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(modulusLength, 'modulusLength');
    ArgumentError.checkNotNull(publicExponent, 'publicExponent');
    ArgumentError.checkNotNull(hash, 'hash');

    return impl.rsassaPkcs1V15PrivateKey_generateKey(
      modulusLength,
      publicExponent,
      hash,
    );
  }

  /// Sign [data] with this RSASSA-PKCS1-v1_5 private key.
  ///
  /// Returns a signature as a list of raw bytes. This uses the [Hash]
  /// specified when the key was generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8, base64;
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read prviate key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.privateKey).decode("""
  ///   -----BEGIN PRIVATE KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PRIVATE KEY-----
  /// """);
  ///
  /// // Import private key from binary PEM decoded data.
  /// final privatKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Create a signature for UTF-8 encoded message
  /// final message = 'hello world';
  /// final signature = await privateKey.signBytes(utf8.encode(message));
  ///
  /// print('signature: ${base64.encode(signature)}');
  /// ```
  Future<Uint8List> signBytes(List<int> data);

  /// Sign [data] with this RSASSA-PKCS1-v1_5 private key.
  ///
  /// Returns a signature as a list of raw bytes. This uses the [Hash]
  /// specified when the key was generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8, base64;
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read prviate key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.privateKey).decode("""
  ///   -----BEGIN PRIVATE KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PRIVATE KEY-----
  /// """);
  ///
  /// // Import private key from binary PEM decoded data.
  /// final privatKey = await RsassaPkcs1V15PrivateKey.importPkcs8Key(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Create a signature for UTF-8 encoded message
  /// final message = 'hello world';
  /// final signature = await privateKey.signStream(Stream.fromIterable([
  ///   utf8.encode(message),
  /// ]));
  ///
  /// print('signature: ${base64.encode(signature)}');
  /// ```
  Future<Uint8List> signStream(Stream<List<int>> data);

  /// Export this RSASSA-PKCS1-v1_5 private key in PKCS #8 format.
  ///
  /// Returns the DER encoding of the _PrivateKeyInfo structure_ specified in
  /// [RFC 5208][1] as a list of bytes.
  ///
  /// **Example**
  /// ```dart
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the private key.
  /// final rawPrivateKey = await keypair.privateKey.exportPkcs8Key();
  ///
  /// // Private keys are often encoded as PEM.
  /// // This encodes the key in base64 and wraps it with:
  /// // '-----BEGIN PRIVATE KEY----'...
  /// print(PemCodec(PemLabel.privateKey).encode(rawPrivateKey));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5208
  Future<Uint8List> exportPkcs8Key();

  /// Export RSASSA-PKCS1-v1_5 private key in [JWK][1] format.
  ///
  /// TODO: finish documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  Future<Map<String, dynamic>> exportJsonWebKey();
}

/// RSASSA-PKCS1-v1_5 public key for signing messages.
///
/// An [RsassaPkcs1V15PublicKey] instance hold a public RSA key for verification
/// of signatures following the RSASSA-PKCS1-v1_5 scheme as specified
/// in [RFC 3447][1].
///
/// Instances of [RsassaPkcs1V15PublicKey] can be imported using
/// [RsassaPkcs1V15PublicKey.importSpkiKey] or generated using
/// [RsassaPkcs1V15PrivateKey.generateKey] which generates a public-private
/// key-pair.
///
/// [1]: https://tools.ietf.org/html/rfc3447
@sealed
abstract class RsassaPkcs1V15PublicKey {
  RsassaPkcs1V15PublicKey._(); // keep the constructor private.

  /// Import RSASSA-PKCS1-v1_5 public key in SPKI format.
  ///
  /// Creates an [RsassaPkcs1V15PublicKey] from [keyData] given as the DER
  /// encoding of the _SubjectPublicKeyInfo structure_ specified in
  /// [RFC 5280][1]. The hash algorithm to be used is specified by [hash].
  ///
  /// **Example**
  /// ```dart
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Read key data from PEM encoded block. This will remove the
  /// // '----BEGIN...' padding, decode base64 and return encoded bytes.
  /// List<int> keyData = PemCodec(PemLabel.publicKey).decode("""
  ///   -----BEGIN PUBLIC KEY-----
  ///   MIGEAgEAMBAGByqG...
  ///   -----END PUBLIC KEY-----
  /// """);
  ///
  /// // Import public key from binary PEM decoded data.
  /// final publicKey = await RsassaPkcs1V15PublicKey.importSpkiKey(
  ///   keyData,
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the key again (print it in same format as it was given).
  /// List<int> rawKeyData = await publicKey.exportSpkiKey();
  /// print(PemCodec(PemLabel.publicKey).encode(rawKeyData));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5280
  static Future<RsassaPkcs1V15PublicKey> importSpkiKey(
    List<int> keyData,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(keyData, 'keyData');
    ArgumentError.checkNotNull(hash, 'hash');

    return impl.rsassaPkcs1V15PublicKey_importSpkiKey(keyData, hash);
  }

  /// Import RSASSA-PKCS1-v1_5 public key from [JWK][1].
  ///
  /// TODO: finish documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  static Future<RsassaPkcs1V15PublicKey> importJsonWebKey(
    Map<String, dynamic> jwk,
    Hash hash,
  ) {
    ArgumentError.checkNotNull(jwk, 'jwk');
    ArgumentError.checkNotNull(hash, 'hash');

    return impl.rsassaPkcs1V15PublicKey_importJsonWebKey(jwk, hash);
  }

  /// Verify [signature] of [data] using this RSASSA-PKCS1-v1_5 public key.
  ///
  /// Returns `true` if the signature was made the private key matching this
  /// public key. This uses the [Hash] specified when the key was
  /// generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'package:webcrypto/webcrypto.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Using privateKey Bob can sign a message for Alice.
  /// final message = 'Hi Alice';
  /// final signature = await keyPair.privateKey.signBytes(utf8.encode(message));
  ///
  /// // Given publicKey and signature Alice can verify the message from Bob.
  /// final isValid = await keypair.publicKey.verifyBytes(
  ///   signature,
  ///   utf8.encode(message),
  /// );
  /// if (isValid) {
  ///   print('Authentic message from Bob: $message');
  /// }
  /// ```
  Future<bool> verifyBytes(List<int> signature, List<int> data);

  /// Verify [signature] of [data] using this RSASSA-PKCS1-v1_5 public key.
  ///
  /// Returns `true` if the signature was made the private key matching this
  /// public key. This uses the [Hash] specified when the key was
  /// generated or imported.
  ///
  /// **Example**
  /// ```dart
  /// import 'dart:convert' show utf8;
  /// import 'package:webcrypto/webcrypto.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Using privateKey Bob can sign a message for Alice.
  /// final message = 'Hi Alice';
  /// final signature = await keyPair.privateKey.signBytes(utf8.encode(message));
  ///
  /// // Given publicKey and signature Alice can verify the message from Bob.
  /// final isValid = await keypair.publicKey.verifyStream(
  ///   signature,
  ///   Stream.fromIterable([utf8.encode(message)]),
  /// );
  /// if (isValid) {
  ///   print('Authentic message from Bob: $message');
  /// }
  /// ```
  Future<bool> verifyStream(List<int> signature, Stream<List<int>> data);

  /// Export this RSASSA-PKCS1-v1_5 private key in SPKI format.
  ///
  /// Returns the DER encoding of the _SubjectPublicKeyInfo structure_ specified
  /// in [RFC 5280][1] as a list of bytes. This operation is only allowed if the
  /// key was imported or generated with the [extractable] bit set to `true`.
  ///
  /// **Example**
  /// ```dart
  /// import 'package:webcrypto/webcrypto.dart';
  /// import 'package:pem/pem.dart';
  ///
  /// // Generate a key-pair.
  /// final keyPair = await RsassaPkcs1V15PrivateKey.generateKey(
  ///   4096,
  ///   BigInt.from(65537),
  ///   Hash.sha256,
  /// );
  ///
  /// // Export the public key.
  /// final rawPublicKey = await keyPair.publicKey.exportSpkiKey();
  ///
  /// // Public keys are often encoded as PEM.
  /// // This encode the key in base64 and wraps it with:
  /// // '-----BEGIN PUBLIC KEY-----'...
  /// print(PemCodec(PemLabel.publicKey).encode(rawPublicKey));
  /// ```
  ///
  /// [1]: https://tools.ietf.org/html/rfc5280
  Future<Uint8List> exportSpkiKey();

  /// Export RSASSA-PKCS1-v1_5 public key in [JWK][1] format.
  ///
  /// TODO: finish documentation.
  ///
  /// [1]: https://tools.ietf.org/html/rfc7517
  Future<Map<String, dynamic>> exportJsonWebKey();
}
