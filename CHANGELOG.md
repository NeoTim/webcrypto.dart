# 0.2.1
 * Added finalizers for `ssl.EVP_PKEY` and running tests under `valgrind` unable
   to find any obvious memory leaks.
 * Increased Flutter SDK constraint to `>=1.22.0-12.1.pre` (current beta).

# 0.2.0
 * Added `ios` support.
 * Added `<2.0.0` upper-bound on Flutter SDK constraint.

# 0.1.2
 * Fixed sizeof `ssl.CBB` causing occasional segfaults, as we previously
   allocated too few bytes.
 * Ported `flutter pub run webcrypto:setup` to work on Mac when `cmake` is
   installed.

# 0.1.1
 * Removed unused code referencing `dart:cli`, causing analysis errors on
   [pub.dev](https://pub.dev/packages/webcrypto).
 * Added more API documentation for `AesCbcSecretKey`.

# 0.1.0
 * Initial release.
