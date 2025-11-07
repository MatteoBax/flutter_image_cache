import 'dart:async';
import 'dart:io';

import 'package:flutter_image_cache/src/dbElements/_cached_image_element.dart';
import 'package:flutter_image_cache/src/tools/_tools.dart';
import 'package:flutter_image_cache/src/types/cache_size.dart';

import 'package:mutex/mutex.dart';

/// Manages cached image files with automatic cleanup and controlled access.
///
/// [CacheManager] provides functionality to:
/// - Download images from URLs and cache them locally.
/// - Serve cached images efficiently to avoid duplicate downloads.
/// - Automatically clean the cache if it exceeds the configured maximum size.
/// - Ensure safe concurrent access to cached files using mutexes.
///
/// Example usage:
/// ```dart
/// final cacheManager = CacheManager(maxCacheSize: CacheSize(miB: 100));
///
/// // Get a cached image file (downloads if not already cached)
/// final file = await cacheManager.getFile("https://example.com/image.png");
///
/// // Check current cache usage
/// final usage = await cacheManager.cacheUsage;
/// print("Cache usage: $usage");
/// ```
class CacheManager {
  /// Maximum allowed cache size. Must be at least 10 MiB.
  final CacheSize maxCacheSize;

  /// Tracks ongoing file retrieval requests to prevent duplicate downloads.
  final Map<String, Future<File>> _getFileRequests = {};

  /// Timer that periodically triggers cache cleanup.
  late final Timer periodicCleanTimer;

  /// Indicates whether a cache cleanup is currently in progress.
  bool _isCleaning = false;

  /// Mutex to synchronize access to [_getFileRequests].
  final Mutex _lock = Mutex();

  /// Mutex to prevent deletion of a file while it is being used.
  final Mutex _fileLock = Mutex();

  /// Creates a [CacheManager] with the given [maxCacheSize].
  ///
  /// Throws an [AssertionError] if [maxCacheSize] is less than 10 MiB.
  /// The cache cleanup runs automatically every 10 seconds.
  CacheManager({required this.maxCacheSize}) : assert(maxCacheSize.inMiB >= 10, "Cache must be at least 10 MiB") {
    periodicCleanTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      if(_isCleaning) {
        return;
      }
      _isCleaning = true;

      try {
        final usage = await cacheUsage;
        if(usage.inBytes > maxCacheSize.inBytes) {
          final cacheElements = await CachedImageElementProvider.list(orderByUsageAsc: true);
          if(cacheElements.isNotEmpty) {
            final cacheElement = cacheElements.first;
            final f = File(cacheElement.path);
            await _fileLock.protect(() async {
              if (DateTime.now().difference(cacheElement.lastUsage) > const Duration(seconds: 10)) {
                if(await f.exists()) {
                  await f.delete();
                  await CachedImageElementProvider.remove(cacheElement.id!);
                }
              }
            });
          }
        }
      } finally {
        _isCleaning = false;
      }
    });
  }

  /// Internal helper to get the file for a given [url].
  ///
  /// If the file is already cached, it:
  /// - Updates its last usage timestamp.
  /// - Increments its usage count.
  /// - Returns the cached file.
  ///
  /// If the file is not cached, it:
  /// - Downloads the file.
  /// - Stores it in the cache with an initial usage count of 1.
  /// - Returns the downloaded file.
  /// The method automatically retries up to 10 times if a cache entry exists but the
  /// corresponding file has been deleted or is no longer accessible.
  ///
  /// Throws an [Exception] if the maximum retry limit (10) is exceeded. 
  Future<File> _getFileFuture({required String url, int retryNum = 0}) async {
    CachedImageElement? cachedImage = await CachedImageElementProvider.get(url);
    // cache hit
    if(cachedImage != null) {
      bool needsRetry = false;
      File? result;
      await _fileLock.protect(() async {
        await CachedImageElementProvider.updateLastUsage(cachedImage.id!, DateTime.now(), incrementUsageCount: true);
        File f = File(cachedImage.path);
        if(await f.exists() == false) {
          await CachedImageElementProvider.remove(cachedImage.id!);
          needsRetry = true;
        } else {
          result = f;
        }
      });

      if(needsRetry) {
        if(retryNum == 10) {
          throw Exception("Cannot load image: maximum retry count exceeded.");
        }
        return _getFileFuture(url: url, retryNum: ++retryNum);
      } else {
        return result!;
      }
    } else {
      // Cache miss: download file
      File? file;
      try {
        file = await Tools.downloadFile(url, await Tools.sha256HashAsync(url));
        await CachedImageElementProvider.insert(CachedImageElement(url: url, path: file.path, usageCount: 1, lastUsage: DateTime.now()));
      } catch (_) {
        await file?.delete();
        rethrow;
      }

      return file;
    }
  }

  /// Retrieves the cached file for the given [url].
  ///
  /// If the file is already being downloaded, this method waits for the
  /// existing download to complete instead of starting a new one.
  Future<File> getFile(String url) async {
    Future<File>? future;
    await _lock.protect(() async {
      future = _getFileRequests[url];
      if(future == null) {
        future = _getFileFuture(url: url)
          .whenComplete(() {
            _getFileRequests.remove(url);
          });
        _getFileRequests[url] = future!;
      }
    });
    return future!;
  }

  /// Returns the current total cache usage as a [CacheSize].
  ///
  /// Computes the total size of all cached files by summing their lengths
  /// in bytes.
  Future<CacheSize> get cacheUsage async  {
    int totalSizeInBytes = 0;
    final cacheElements = await CachedImageElementProvider.list();
    for(final cacheElement in cacheElements) {
      File f = File(cacheElement.path);
      if(await f.exists()) {
        totalSizeInBytes += await f.length();
      }
    }
    return CacheSize(bytes: totalSizeInBytes);
  }
}