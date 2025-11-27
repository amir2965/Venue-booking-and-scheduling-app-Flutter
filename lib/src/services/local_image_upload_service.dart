import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';

class LocalImageUploadService {
  // For development/testing - store images locally
  static Future<Map<String, String>> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final baseFileName = 'profile_${userId}_$timestamp';

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();
      final profileImagesDir = Directory('${directory.path}/profile_images');

      // Create directory if it doesn't exist
      if (!await profileImagesDir.exists()) {
        await profileImagesDir.create(recursive: true);
      }

      // Read and process image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Invalid image format');
      }

      // Create different size variants
      final variants = await _createImageVariants(originalImage, baseFileName);

      // Save all variants locally and create file URLs
      final urls = <String, String>{};

      for (final variant in variants.entries) {
        final fileName = '${variant.key}$extension';
        final file = File('${profileImagesDir.path}/$fileName');

        await file.writeAsBytes(variant.value);

        // For local storage, use file path as URL
        // In production, this would be actual URLs from Firebase Storage
        final localUrl = file.path;

        // Map size names to URLs
        if (variant.key.contains('_thumb')) {
          urls['thumbnail'] = localUrl;
        } else if (variant.key.contains('_medium')) {
          urls['medium'] = localUrl;
        } else if (variant.key.contains('_large')) {
          urls['large'] = localUrl;
        } else {
          urls['original'] = localUrl;
        }
      }

      return urls;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create different size variants of the image
  static Future<Map<String, Uint8List>> _createImageVariants(
    img.Image originalImage,
    String baseFileName,
  ) async {
    final variants = <String, Uint8List>{};

    // Original (max 1024x1024)
    final original = img.copyResize(
      originalImage,
      width: originalImage.width > 1024 ? 1024 : originalImage.width,
      height: originalImage.height > 1024 ? 1024 : originalImage.height,
      maintainAspect: true,
    );
    variants['${baseFileName}_original'] = Uint8List.fromList(
      img.encodeJpg(original, quality: 85),
    );

    // Large (512x512) - for detailed profile views
    final large = img.copyResize(
      originalImage,
      width: 512,
      height: 512,
      maintainAspect: true,
    );
    variants['${baseFileName}_large'] = Uint8List.fromList(
      img.encodeJpg(large, quality: 80),
    );

    // Medium (256x256) - for chat avatars
    final medium = img.copyResize(
      originalImage,
      width: 256,
      height: 256,
      maintainAspect: true,
    );
    variants['${baseFileName}_medium'] = Uint8List.fromList(
      img.encodeJpg(medium, quality: 75),
    );

    // Thumbnail (128x128) - for match cards and lists
    final thumbnail = img.copyResize(
      originalImage,
      width: 128,
      height: 128,
      maintainAspect: true,
    );
    variants['${baseFileName}_thumb'] = Uint8List.fromList(
      img.encodeJpg(thumbnail, quality: 70),
    );

    return variants;
  }

  // Delete old profile images when updating
  static Future<void> deleteProfileImages({
    required String userId,
    required Map<String, String> imageUrls,
  }) async {
    try {
      for (final url in imageUrls.values) {
        final file = File(url);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      // Log error but don't throw - deletion failures shouldn't block updates
      if (kDebugMode) {
        print('Warning: Failed to delete old profile images: $e');
      }
    }
  }

  // Get image URL by size preference
  static String getImageUrl(
    Map<String, String>? imageUrls,
    ImageSize size, {
    String? fallbackUrl,
  }) {
    if (imageUrls == null || imageUrls.isEmpty) {
      return fallbackUrl ?? '';
    }

    switch (size) {
      case ImageSize.thumbnail:
        return imageUrls['thumbnail'] ??
            imageUrls['medium'] ??
            imageUrls['large'] ??
            imageUrls['original'] ??
            fallbackUrl ??
            '';
      case ImageSize.medium:
        return imageUrls['medium'] ??
            imageUrls['large'] ??
            imageUrls['original'] ??
            imageUrls['thumbnail'] ??
            fallbackUrl ??
            '';
      case ImageSize.large:
        return imageUrls['large'] ??
            imageUrls['original'] ??
            imageUrls['medium'] ??
            imageUrls['thumbnail'] ??
            fallbackUrl ??
            '';
      case ImageSize.original:
        return imageUrls['original'] ??
            imageUrls['large'] ??
            imageUrls['medium'] ??
            imageUrls['thumbnail'] ??
            fallbackUrl ??
            '';
    }
  }

  // Validate image before upload
  static Future<bool> validateImage(File imageFile) async {
    try {
      // Check file size (max 10MB)
      final fileSizeInBytes = await imageFile.length();
      if (fileSizeInBytes > 10 * 1024 * 1024) {
        throw Exception('Image size must be less than 10MB');
      }

      // Check if it's a valid image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Invalid image format');
      }

      // Check minimum dimensions
      if (image.width < 128 || image.height < 128) {
        throw Exception('Image must be at least 128x128 pixels');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Image validation failed: $e');
      }
      return false;
    }
  }

  // Generate cache key for images
  static String generateCacheKey(String url) {
    final bytes = utf8.encode(url);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}

enum ImageSize {
  thumbnail, // 128x128 - for lists and small avatars
  medium, // 256x256 - for chat avatars
  large, // 512x512 - for profile details
  original, // up to 1024x1024 - for full-screen views
}

// Extension to add image URL getters to PlayerProfile model
extension PlayerProfileImageExtension on Map<String, String>? {
  String thumbnailUrl([String? fallback]) =>
      LocalImageUploadService.getImageUrl(this, ImageSize.thumbnail,
          fallbackUrl: fallback);

  String mediumUrl([String? fallback]) =>
      LocalImageUploadService.getImageUrl(this, ImageSize.medium,
          fallbackUrl: fallback);

  String largeUrl([String? fallback]) =>
      LocalImageUploadService.getImageUrl(this, ImageSize.large,
          fallbackUrl: fallback);

  String originalUrl([String? fallback]) =>
      LocalImageUploadService.getImageUrl(this, ImageSize.original,
          fallbackUrl: fallback);
}
