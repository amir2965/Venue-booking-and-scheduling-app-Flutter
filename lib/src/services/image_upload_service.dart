import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as path;
import 'package:crypto/crypto.dart';
import 'dart:convert';

class ImageUploadService {
  static FirebaseStorage? _storage;
  static const String bucketUrl = 'gs://pool-4b84e.firebasestorage.app';

  static FirebaseStorage get storage {
    _storage ??= FirebaseStorage.instanceFor(bucket: bucketUrl);
    return _storage!;
  }

  // Initialize Firebase Storage with error handling
  static Future<void> initializeStorage() async {
    try {
      _storage = FirebaseStorage.instanceFor(bucket: bucketUrl);

      // Test connection - just check if we can create a reference
      if (kDebugMode) {
        print('Firebase Storage initialized with bucket: $bucketUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Storage initialization error: $e');
      }
      rethrow;
    }
  }

  // Test Firebase Storage connection
  static Future<bool> testConnection() async {
    try {
      // Try to create a reference to test connectivity
      final testRef = storage.ref().child('userprof').child('test.txt');

      if (kDebugMode) {
        print('Firebase Storage connection test successful');
        print('Bucket URL: $bucketUrl');
        print('Test reference path: ${testRef.fullPath}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Firebase Storage connection test failed: $e');
      }
      return false;
    }
  }

  // Upload profile image with multiple size variants
  static Future<Map<String, String>> uploadProfileImage({
    required File imageFile,
    required String userId,
  }) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(imageFile.path);
      final baseFileName = 'profile_${userId}_$timestamp';

      // Read and process image
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);

      if (originalImage == null) {
        throw Exception('Invalid image format');
      }

      // Create different size variants
      final variants = await _createImageVariants(originalImage, baseFileName);

      // Upload all variants
      final urls = <String, String>{};

      for (final variant in variants.entries) {
        try {
          final uploadTask = storage
              .ref()
              .child('userprof')
              .child('${variant.key}$extension')
              .putData(
                variant.value,
                SettableMetadata(contentType: 'image/jpeg'),
              );

          final snapshot = await uploadTask;
          final downloadUrl = await snapshot.ref.getDownloadURL();

          // Map size names to URLs
          if (variant.key.contains('_thumb')) {
            urls['thumbnail'] = downloadUrl;
          } else if (variant.key.contains('_medium')) {
            urls['medium'] = downloadUrl;
          } else if (variant.key.contains('_large')) {
            urls['large'] = downloadUrl;
          } else {
            urls['original'] = downloadUrl;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to upload variant ${variant.key}: $e');
          }
          // Continue with other variants even if one fails
        }
      }

      if (urls.isEmpty) {
        throw Exception('Failed to upload any image variants');
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
        final ref = storage.refFromURL(url);
        await ref.delete();
      }
    } catch (e) {
      // Log error but don't throw - deletion failures shouldn't block updates
      if (kDebugMode) {
        print('Warning: Failed to delete old profile images: $e');
      }
    }
  }

  // Get the appropriate image URL based on size
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

  // Validate image file
  static Future<bool> validateImage(File imageFile) async {
    try {
      // Check file size (max 10MB)
      final fileSizeInBytes = await imageFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 10) {
        throw Exception('Image file size exceeds 10MB limit');
      }

      // Check if it's a valid image by trying to decode it
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);

      if (image == null) {
        throw Exception('Invalid image format');
      }

      // Check image dimensions (minimum 100x100)
      if (image.width < 100 || image.height < 100) {
        throw Exception('Image must be at least 100x100 pixels');
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
      ImageUploadService.getImageUrl(this, ImageSize.thumbnail,
          fallbackUrl: fallback);

  String mediumUrl([String? fallback]) =>
      ImageUploadService.getImageUrl(this, ImageSize.medium,
          fallbackUrl: fallback);

  String largeUrl([String? fallback]) =>
      ImageUploadService.getImageUrl(this, ImageSize.large,
          fallbackUrl: fallback);

  String originalUrl([String? fallback]) =>
      ImageUploadService.getImageUrl(this, ImageSize.original,
          fallbackUrl: fallback);
}
