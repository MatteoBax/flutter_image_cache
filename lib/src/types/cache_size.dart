/// Represents the size of a cache in bytes, KiB, MiB, GiB, or TiB.
///
/// The [CacheSize] class allows you to specify a size using **one** of the
/// supported units: TiB, GiB, MiB, KiB, or bytes. Internally, the size is
/// stored in bytes. You can retrieve the size in any unit via the provided getters.
///
/// Example usage:
/// ```dart
/// // Create a cache size of 512 MiB
/// final cacheSize = CacheSize(miB: 512);
///
/// print(cacheSize.inBytes); // 536870912
/// print(cacheSize.inGiB);   // 0.5
/// print(cacheSize);         // "512.00 MiB"
/// ```
///
/// Only one unit can be specified at a time; specifying more than one will
/// throw an assertion error.
class CacheSize {
  final int _bytes;

  /// Creates a [CacheSize] instance.
  ///
  /// You must specify **exactly one** of the following:
  /// - [tiB]: Size in tebibytes (TiB)
  /// - [giB]: Size in gibibytes (GiB)
  /// - [miB]: Size in mebibytes (MiB)
  /// - [kiB]: Size in kibibytes (KiB)
  /// - [bytes]: Size in bytes (B)
  ///
  /// Throws an [AssertionError] if more than one unit is specified.
  CacheSize({double? tiB, double? giB, double? miB, double? kiB, int? bytes}) : assert (
    [tiB, giB, miB, kiB, bytes].where((el) => el != null).length == 1,
    "Specify only one unit"
  ),

  _bytes = (
    (tiB != null) ? tiB * 1024 * 1024 * 1024 * 1024 :
    (giB != null) ? giB * 1024 * 1024 * 1024 :
    (miB != null) ? miB * 1024 * 1024 :
    (kiB != null) ? kiB * 1024 :
    (bytes ?? 0)
  ).round();

  /// Returns the size in bytes.
  int get inBytes => _bytes;

  /// Returns the size in kibibytes (KiB).
  double get inKiB => _bytes.toDouble() / 1024;

  /// Returns the size in mebibytes (MiB).
  double get inMiB => inKiB / 1024;

  /// Returns the size in gibibytes (GiB).
  double get inGiB => inMiB / 1024;

  /// Returns the size in tebibytes (TiB)
  double get inTiB => inGiB / 1024;

  /// Returns a human-readable string representation of the cache size.
  ///
  /// The largest suitable unit is chosen automatically with 2 decimal precision.
  /// For example: "512.00 MiB", "0.50 GiB", "1024 B"
  @override
  String toString() {
    return
      (inTiB >= 1) ? "${inTiB.toStringAsFixed(2)} TiB" :
      (inGiB >= 1) ? "${inGiB.toStringAsFixed(2)} GiB" :
      (inMiB >= 1) ? "${inMiB.toStringAsFixed(2)} MiB" :
      (inKiB >= 1) ? "${inKiB.toStringAsFixed(2)} KiB" :
      "$_bytes B";
  }
}