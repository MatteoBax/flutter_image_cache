import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';

/// A utility class providing helper functions for file downloading and hashing.
///
/// This class cannot be instantiated.
class Tools {
  Tools._();

  /// Internal Dio client configured with a 5-second connect and receive timeout.
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),
  );

  /// Downloads a file from the given [url] and saves it in the temporary directory
  /// using the provided [filename].
  ///
  /// Returns a [File] pointing to the downloaded file.
  ///
  /// Throws a [DioException] if the download fails.
  static Future<File> downloadFile(String url, String filename) async {
    final dir = await getTemporaryDirectory();
    final filePath = '${dir.path}/$filename';

    await _dio.download(url, filePath);

    return File(filePath);
  }

  /// Computes the SHA-256 hash of the given [toHash] string synchronously.
  ///
  /// Returns the hash as a hexadecimal string.
  static String sha256HashSync(String toHash) {
    return sha256.convert(utf8.encode(toHash)).toString();
  }

  /// Computes the SHA-256 hash of the given [toHash] string asynchronously.
  ///
  /// This is useful for offloading expensive computations to a separate isolate.
  /// Returns the hash as a hexadecimal string.
  static Future<String> sha256HashAsync(String toHash) {
    return compute(_sha256Worker, toHash);
  }
}

/// Worker function used by [Tools.sha256HashAsync] in a separate isolate.
String _sha256Worker(String input) {
  return sha256.convert(utf8.encode(input)).toString();
}
