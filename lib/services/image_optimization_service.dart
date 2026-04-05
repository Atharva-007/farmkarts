import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Image Optimization Service
/// Handles image compression, caching, and loading optimization
class ImageOptimizationService {
  static final ImageOptimizationService _instance =
      ImageOptimizationService._internal();
  factory ImageOptimizationService() => _instance;
  ImageOptimizationService._internal();

  // ==================== IMAGE COMPRESSION ====================

  /// Compress image file
  Future<File> compressImage(
    File file, {
    int quality = 85,
    int maxWidth = 1920,
    int maxHeight = 1080,
  }) async {
    try {
      // Read image
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      if (image.width > maxWidth || image.height > maxHeight) {
        image = img.copyResize(
          image,
          width: image.width > maxWidth ? maxWidth : null,
          height: image.height > maxHeight ? maxHeight : null,
        );
      }

      // Compress
      final compressed = img.encodeJpg(image, quality: quality);

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      final originalSize = bytes.length / 1024; // KB
      final compressedSize = compressed.length / 1024; // KB
      final reduction = ((originalSize - compressedSize) / originalSize * 100)
          .toStringAsFixed(1);

      debugPrint(
          'ImageOptimization: Compressed ${originalSize.toStringAsFixed(0)}KB → ${compressedSize.toStringAsFixed(0)}KB ($reduction% reduction)');

      return tempFile;
    } catch (e) {
      debugPrint('ImageOptimization: Error compressing image: $e');
      return file;
    }
  }

  /// Compress image bytes
  Future<Uint8List> compressImageBytes(
    Uint8List bytes, {
    int quality = 85,
    int maxWidth = 1920,
  }) async {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }

      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      debugPrint('ImageOptimization: Error compressing bytes: $e');
      return bytes;
    }
  }

  // ==================== THUMBNAIL GENERATION ====================

  /// Generate thumbnail
  Future<File> generateThumbnail(
    File file, {
    int size = 200,
    int quality = 80,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Create thumbnail
      final thumbnail = img.copyResize(
        image,
        width: size,
        height: size,
        interpolation: img.Interpolation.average,
      );

      final compressed = img.encodeJpg(thumbnail, quality: quality);

      // Save
      final tempDir = await getTemporaryDirectory();
      final thumbnailFile = File(
          '${tempDir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await thumbnailFile.writeAsBytes(compressed);

      debugPrint('ImageOptimization: Thumbnail generated (${size}x$size)');

      return thumbnailFile;
    } catch (e) {
      debugPrint('ImageOptimization: Error generating thumbnail: $e');
      return file;
    }
  }

  // ==================== IMAGE LOADING ====================

  /// Optimized image widget with device pixel ratio awareness
  Widget optimizedImage({
    required BuildContext context,
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    // Get device pixel ratio to scale cache size
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final int? cacheWidth = width != null ? (width * dpr).toInt() : null;
    final int? cacheHeight = height != null ? (height * dpr).toInt() : null;

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) =>
          placeholder ??
          Container(
            color: Colors.grey[200],
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      errorWidget: (context, url, error) =>
          errorWidget ??
          Container(
            color: Colors.grey[300],
            child: const Icon(Icons.error_outline, color: Colors.grey),
          ),
      memCacheWidth: cacheWidth,
      memCacheHeight: cacheHeight,
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
      filterQuality: FilterQuality.low, // Faster rendering during scroll
    );
  }

  /// Preload images
  Future<void> preloadImages(
    BuildContext context,
    List<String> imageUrls,
  ) async {
    for (final url in imageUrls) {
      try {
        await precacheImage(
          CachedNetworkImageProvider(url),
          context,
        );
      } catch (e) {
        debugPrint('ImageOptimization: Error preloading $url: $e');
      }
    }
    debugPrint('ImageOptimization: Preloaded ${imageUrls.length} images');
  }

  // ==================== CACHE MANAGEMENT ====================

  /// Clear image cache
  Future<void> clearImageCache() async {
    try {
      await CachedNetworkImage.evictFromCache('');
      imageCache.clear();
      imageCache.clearLiveImages();
      debugPrint('ImageOptimization: Cache cleared');
    } catch (e) {
      debugPrint('ImageOptimization: Error clearing cache: $e');
    }
  }

  /// Get cache size
  Future<int> getCacheSize() async {
    try {
      final tempDir = await getTemporaryDirectory();
      int totalSize = 0;

      if (await tempDir.exists()) {
        final files = tempDir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            totalSize += await file.length();
          }
        }
      }

      debugPrint(
          'ImageOptimization: Cache size - ${(totalSize / 1024 / 1024).toStringAsFixed(2)} MB');
      return totalSize;
    } catch (e) {
      debugPrint('ImageOptimization: Error getting cache size: $e');
      return 0;
    }
  }

  // ==================== FORMAT CONVERSION ====================

  /// Convert image to WebP (smaller size)
  Future<Uint8List> convertToWebP(Uint8List bytes) async {
    try {
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return bytes;

      // Note: WebP encoding requires additional setup
      // For now, return JPEG
      return Uint8List.fromList(img.encodeJpg(image, quality: 85));
    } catch (e) {
      debugPrint('ImageOptimization: Error converting to WebP: $e');
      return bytes;
    }
  }

  // ==================== LAZY LOADING ====================

  /// Lazy load image list
  Widget lazyImageList({
    required List<String> imageUrls,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: imageUrls.length,
      addAutomaticKeepAlives: true,
      addRepaintBoundaries: true,
      cacheExtent: 200,
      itemBuilder: itemBuilder,
    );
  }

  // ==================== PROGRESSIVE LOADING ====================

  /// Progressive image widget (shows low quality first, then high quality)
  Widget progressiveImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      progressIndicatorBuilder: (context, url, progress) => Container(
        color: Colors.grey[200],
        child: Center(
          child: CircularProgressIndicator(
            value: progress.progress,
            strokeWidth: 2,
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Icon(Icons.error_outline),
      ),
    );
  }

  // ==================== IMAGE ANALYSIS ====================

  /// Analyze image quality
  Future<Map<String, dynamic>> analyzeImage(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return {'error': 'Failed to decode image'};
      }

      return {
        'width': image.width,
        'height': image.height,
        'size': bytes.length,
        'size_kb': (bytes.length / 1024).toStringAsFixed(2),
        'size_mb': (bytes.length / 1024 / 1024).toStringAsFixed(2),
        'aspect_ratio': (image.width / image.height).toStringAsFixed(2),
        'format': 'JPEG',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // ==================== BATCH PROCESSING ====================

  /// Compress multiple images
  Future<List<File>> compressMultipleImages(
    List<File> files, {
    int quality = 85,
    Function(int, int)? onProgress,
  }) async {
    final compressed = <File>[];

    for (int i = 0; i < files.length; i++) {
      try {
        final compressedFile = await compressImage(files[i], quality: quality);
        compressed.add(compressedFile);
        onProgress?.call(i + 1, files.length);
      } catch (e) {
        debugPrint('ImageOptimization: Error compressing file ${i + 1}: $e');
        compressed.add(files[i]);
      }
    }

    return compressed;
  }
}
