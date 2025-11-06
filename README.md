# flutter_image_cache

A Flutter package for efficient **image caching** with automatic cache management.  
It downloads images from the web, stores them in a local cache, and automatically cleans old or unused images to stay within the specified cache size.

## Features

- Automatic caching of images downloaded from URLs.
- Cache size management with automatic cleanup.
- Cache usage tracking.
- Customizable placeholder, error handling, and frame builders.
- Thread-safe downloads and cache access using mutexes.

## Limitations
- The package currently supports **only one cache instance at a time**.
<br> 
  Concurrent use of multiple `CacheManager` objects is **not supported** and may lead to unexpected behavior.
<br> 
  It is therefore recommended to use a **single, global instance** of `CacheManager` throughout the entire application.


## Getting Started

### Installation

Add the `flutter_image_cache` package to your [pubspec dependencies](https://pub.dev/packages/flutter_image_cache/install).

## Usage
Create a static `CacheManager` and pass it to the `CachedImage` widget constructor.
<br>
The API is similar to `Image.file()`.

```dart
import "package:flutter_image_cache/flutter_image_cache.dart";

final CacheSize cacheSize = CacheSize(miB: 10); // Create a cache of maximum size 10 MiB
final static CacheManager cacheManager = CacheManager(maxCacheSize: cacheSize);

// Create the widget
CachedImage(
  "https://example.com/image.jpg",
  cacheManager: cacheManager,
)
```
