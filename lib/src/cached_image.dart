import 'dart:io';

import 'package:flutter_image_cache/src/cache_manager.dart';
import 'package:flutter/material.dart';

/// A widget that displays an image from a URL using a [CacheManager].
///
/// [CachedImage] automatically caches downloaded images locally and
/// serves them from the cache if available, reducing network requests
/// and improving performance.
///
/// Supports most parameters of [Image.file], including scaling, fitting,
/// alignment, color, opacity, and error/placeholder widgets.
///
/// Example usage:
/// ```dart
/// CachedImage(
///   "https://example.com/image.png",
///   cacheManager: myCacheManager,
///   width: 200,
///   height: 200,
///   placeholder: CircularProgressIndicator(),
///   errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
/// );
/// ```
class CachedImage extends StatefulWidget {
  /// The [CacheManager] used to manage cached images.
  final CacheManager cacheManager;

  /// The URL of the image to display.
  final String url;

  /// The scale for the image. (See [Image.file])
  final double scale;

  /// Custom builder for frames while the image is loading. (See [Image.file])
  final Widget Function(BuildContext, Widget, int?, bool)? frameBuilder;

  /// Custom builder for errors during image loading. (See [Image.file])
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  /// Semantic label for accessibility. (See [Image.file])
  final String? semanticLabel;

  /// Whether to exclude the image from semantics. (See [Image.file])
  final bool excludeFromSemantics;

  /// Width of the image.
  final double? width;

  /// Height of the image.
  final double? height;

  /// Color to blend with the image. (See [Image.file])
  final Color? color;

  /// Opacity animation for the image. (See [Image.file])
  final Animation<double>? opacity;

  /// Blend mode for [color]. (See [Image.file])
  final BlendMode? colorBlendMode;

  /// How the image should be inscribed into the space allocated during layout. (See [Image.file])
  final BoxFit? fit;

  /// How to align the image within its bounds. (See [Image.file])
  final AlignmentGeometry alignment;

  /// How to repeat the image if it does not fill its space. (See [Image.file])
  final ImageRepeat repeat;

  /// Part of the image to display (for slicing/stretching). (See [Image.file])
  final Rect? centerSlice;

  /// Whether the image should match the text direction. (See [Image.file])
  final bool matchTextDirection;

  /// Whether to perform gapless playback (prevent flicker on reloads). (See [Image.file])
  final bool gaplessPlayback;

  /// The quality level of image filtering. (See [Image.file])
  final FilterQuality filterQuality;

  /// Whether the image should be anti-aliased. (See [Image.file])
  final bool isAntiAlias;

  /// Resize the image to this width before caching/displaying. (See [Image.file])
  final int? cacheWidth;

  /// Resize the image to this height before caching/displaying. (See [Image.file])
  final int? cacheHeight;

  /// Widget to show while the image is loading.
  final Widget? placeholder;

  /// Creates a [CachedImage] widget.
  const CachedImage(this.url, {
    super.key,
    required this.cacheManager,
    this.scale = 1.0,
    this.frameBuilder,
    this.errorBuilder,
    this.semanticLabel,
    this.excludeFromSemantics = false,
    this.width,
    this.height,
    this.color,
    this.opacity,
    this.colorBlendMode,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.centerSlice,
    this.matchTextDirection = false,
    this.gaplessPlayback = false,
    this.filterQuality = FilterQuality.medium,
    this.isAntiAlias = false,
    this.cacheWidth,
    this.cacheHeight,
    this.placeholder,
  });

  @override
  CachedImageState createState() => CachedImageState();
}

/// State for [CachedImage].
///
/// Handles retrieving the file from [CacheManager], showing a placeholder
/// while loading, and displaying an error widget if the image fails to load.
class CachedImageState extends State<CachedImage> {
  late final Future<File> _fileFuture;

  @override
  void initState() {
    super.initState();
    _fileFuture = widget.cacheManager.getFile(widget.url);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File>(
      future: _fileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return Image.file(
            snapshot.data!,
            scale: widget.scale,
            frameBuilder: widget.frameBuilder,
            errorBuilder: widget.errorBuilder,
            semanticLabel: widget.semanticLabel,
            excludeFromSemantics: widget.excludeFromSemantics,
            width: widget.width,
            height: widget.height,
            color: widget.color,
            opacity: widget.opacity,
            colorBlendMode: widget.colorBlendMode,
            fit: widget.fit,
            alignment: widget.alignment,
            repeat: widget.repeat,
            centerSlice: widget.centerSlice,
            matchTextDirection: widget.matchTextDirection,
            gaplessPlayback: widget.gaplessPlayback,
            filterQuality: widget.filterQuality,
            isAntiAlias: widget.isAntiAlias,
            cacheWidth: widget.cacheWidth,
            cacheHeight: widget.cacheHeight,
          );
        } else if (snapshot.hasError) {
          if(widget.errorBuilder != null) {
            final e = snapshot.error;
            final st = snapshot.stackTrace; 
            return widget.errorBuilder!(context, e!, st);
          } else {
            return Icon(Icons.broken_image);
          }
        } else {
          return SizedBox(
            width: widget.width,
            height: widget.height,
            child: widget.placeholder ?? const Center(child: CircularProgressIndicator()),
          );
        }
      }
    );
  }
}
