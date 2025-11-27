import 'package:flutter/material.dart';
import '../services/image_upload_service.dart';
import '../theme/theme.dart';
import 'dart:io';

class ProfileImageWidget extends StatelessWidget {
  final Map<String, String>? imageUrls;
  final String? fallbackImageUrl;
  final String? userName;
  final double size;
  final ImageSize imageSize;
  final bool showBorder;
  final bool showOnlineIndicator;
  final bool isOnline;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderWidth;

  const ProfileImageWidget({
    Key? key,
    this.imageUrls,
    this.fallbackImageUrl,
    this.userName,
    this.size = 50,
    this.imageSize = ImageSize.medium,
    this.showBorder = true,
    this.showOnlineIndicator = false,
    this.isOnline = false,
    this.onTap,
    this.borderColor,
    this.borderWidth = 2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = ImageUploadService.getImageUrl(
      imageUrls,
      imageSize,
      fallbackUrl: fallbackImageUrl,
    );

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(
                      color:
                          borderColor ?? AppTheme.primaryGreen.withOpacity(0.3),
                      width: borderWidth,
                    )
                  : null,
            ),
            child: ClipOval(
              child: imageUrl.isNotEmpty
                  ? _buildImageFromPath(imageUrl)
                  : _buildFallback(),
            ),
          ),

          // Online indicator
          if (showOnlineIndicator)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: size * 0.04,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageFromPath(String imagePath) {
    // Check if it's a local file path or URL
    if (imagePath.startsWith('http')) {
      // Network image - would be used with Firebase Storage
      return Image.network(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    } else {
      // Local file image
      return Image.file(
        File(imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.white.withOpacity(0.1),
      child: Center(
        child: SizedBox(
          width: size * 0.3,
          height: size * 0.3,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppTheme.primaryGreen.withOpacity(0.7),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    final initial = _getUserInitial();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryGreen,
            AppTheme.primaryGreen.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.4,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  String _getUserInitial() {
    if (userName?.isNotEmpty == true) {
      return userName![0].toUpperCase();
    }
    return '?';
  }
}

// Profile image with edit overlay for profile setup
class EditableProfileImage extends StatelessWidget {
  final Map<String, String>? imageUrls;
  final String? userName;
  final double size;
  final VoidCallback onEditTap;
  final bool isLoading;

  const EditableProfileImage({
    Key? key,
    this.imageUrls,
    this.userName,
    this.size = 120,
    required this.onEditTap,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEditTap,
      child: Stack(
        children: [
          ProfileImageWidget(
            imageUrls: imageUrls,
            userName: userName,
            size: size,
            imageSize: ImageSize.large,
            borderWidth: 3,
          ),

          // Edit overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(0.3),
              ),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        width: size * 0.3,
                        height: size * 0.3,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Container(
                        padding: EdgeInsets.all(size * 0.08),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          imageUrls?.isNotEmpty == true
                              ? Icons.edit
                              : Icons.camera_alt,
                          color: Colors.white,
                          size: size * 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Match card profile image with gradient border
class MatchCardProfileImage extends StatelessWidget {
  final Map<String, String>? imageUrls;
  final String? userName;
  final double size;
  final bool isActive;

  const MatchCardProfileImage({
    Key? key,
    this.imageUrls,
    this.userName,
    this.size = 80,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isActive
            ? LinearGradient(
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreen.withOpacity(0.6),
                ],
              )
            : null,
        border: !isActive
            ? Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              )
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(isActive ? 3 : 0),
        child: ProfileImageWidget(
          imageUrls: imageUrls,
          userName: userName,
          size: size - (isActive ? 6 : 0),
          imageSize: ImageSize.medium,
          showBorder: false,
        ),
      ),
    );
  }
}

// Chat list profile image with message indicator
class ChatListProfileImage extends StatelessWidget {
  final Map<String, String>? imageUrls;
  final String? userName;
  final bool hasUnreadMessages;
  final int unreadCount;
  final bool isOnline;

  const ChatListProfileImage({
    Key? key,
    this.imageUrls,
    this.userName,
    this.hasUnreadMessages = false,
    this.unreadCount = 0,
    this.isOnline = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ProfileImageWidget(
          imageUrls: imageUrls,
          userName: userName,
          size: 60,
          imageSize: ImageSize.medium,
          showOnlineIndicator: true,
          isOnline: isOnline,
        ),

        // Unread message indicator
        if (hasUnreadMessages && unreadCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
              ),
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
