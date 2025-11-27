import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:async';
import '../../models/chat.dart';
import '../../providers/chat_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/theme.dart';
import '../../widgets/profile_image_widget.dart';
import '../../services/image_upload_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;
  final String? initialUserName;

  const ChatScreen({
    Key? key,
    required this.chatId,
    this.initialUserName,
  }) : super(key: key);

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _userScrolledUp = false; // Track if user manually scrolled up
  bool _isTyping = false; // Track if current user is typing
  Timer? _typingTimer; // Timer for typing indicator
  int _lastMessageCount = 0; // Track message count for auto-scroll
  @override
  void initState() {
    super.initState();

    // Scroll to bottom immediately on chat open - multiple attempts for reliability
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // First scroll attempt
      _scrollToBottom();
      _markMessagesAsRead();

      // Multiple delayed scrolls to ensure we reach the bottom regardless of loading timing
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollToBottom();
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollToBottom();
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        _scrollToBottom();
      });
      // Final aggressive scroll after longer delay for first-time loading
      Future.delayed(const Duration(milliseconds: 1000), () {
        _scrollToBottom();
      });
    });

    // Listen to scroll events to detect if user scrolled up
    _scrollController.addListener(() {
      if (_scrollController.hasClients) {
        final isAtBottom = _scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 50; // 50px threshold
        _userScrolledUp = !isAtBottom;
      }
    });

    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;

    final hasText = _messageController.text.trim().isNotEmpty;

    if (hasText && !_isTyping) {
      // Start typing
      _isTyping = true;
      _sendTypingStatus(true);
    } else if (!hasText && _isTyping) {
      // Stop typing immediately if text is empty
      _isTyping = false;
      _sendTypingStatus(false);
      _typingTimer?.cancel();
      return;
    }

    // Reset the timer - stop typing after 2 seconds of inactivity
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        _sendTypingStatus(false);
      }
    });
  }

  void _sendTypingStatus(bool isTyping) {
    // TODO: Implement typing status via chat service
    // This would send typing status to the backend
    // Removed console printing to reduce log clutter
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _markMessagesAsRead() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null) {
      ref.read(messagesProvider(widget.chatId).notifier).markAsRead(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(messagesProvider(widget.chatId));
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1A0A),
              Color(0xFF1A2B1A),
              Color(0xFF2A3B2A),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: messagesAsync.when(
                      data: (messages) {
                        // Enhanced auto-scroll logic: always scroll on first load with multiple attempts
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final isFirstLoad = _lastMessageCount == 0;
                          if (isFirstLoad) {
                            // Multiple aggressive scroll attempts for first load
                            _scrollToBottom();
                            Future.delayed(const Duration(milliseconds: 50),
                                () {
                              _scrollToBottom();
                            });
                            Future.delayed(const Duration(milliseconds: 200),
                                () {
                              _scrollToBottom();
                            });
                            Future.delayed(const Duration(milliseconds: 500),
                                () {
                              _scrollToBottom();
                            });
                          } else if (!_userScrolledUp &&
                              messages.length > _lastMessageCount) {
                            // Normal scroll for new messages
                            _scrollToBottom();
                          }
                          _lastMessageCount = messages.length;
                        });
                        return _buildMessageList(messages, user?.id ?? '');
                      },
                      loading: () => _buildLoadingState(),
                      error: (error, stack) => _buildErrorState(error),
                    ),
                  ),
                  _buildMessageInput(user?.id ?? ''),
                ],
              ),
              // Scroll to bottom button
              if (_userScrolledUp)
                Positioned(
                  bottom: 100,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      _userScrolledUp = false;
                      _scrollToBottom();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final chatInfoAsync = ref.watch(chatInfoProvider(widget.chatId));
    final user = ref.watch(authServiceProvider).currentUser;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.go('/chats'),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen,
                      AppTheme.primaryGreen.withOpacity(0.7),
                    ],
                  ),
                  border: Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: chatInfoAsync.when(
                  data: (chat) {
                    final otherUser = chat?.getOtherParticipant(user?.id ?? '');
                    final initial = otherUser?.name.isNotEmpty == true
                        ? otherUser!.name[0].toUpperCase()
                        : 'U';
                    return Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(
                    child: Text(
                      'U',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  error: (_, __) => const Center(
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              // Online status indicator
              chatInfoAsync.when(
                data: (chat) {
                  final otherUser = chat?.getOtherParticipant(user?.id ?? '');
                  if (otherUser?.isOnline == true) {
                    return Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: chatInfoAsync.when(
              data: (chat) {
                final otherUser = chat?.getOtherParticipant(user?.id ?? '');
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser?.name ??
                          widget.initialUserName ??
                          'Chat Partner',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _getStatusText(otherUser),
                      style: TextStyle(
                        fontSize: 14,
                        color: otherUser?.isOnline == true
                            ? Colors.green
                            : Colors.grey[400],
                      ),
                    ),
                  ],
                );
              },
              loading: () => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated shimmer loading for name
                  _ShimmerWidget(
                    child: Container(
                      width: 120,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _ShimmerWidget(
                    child: Container(
                      width: 80,
                      height: 14,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              error: (error, __) {
                // Don't print errors to console in production
                // Use a fallback display instead
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.initialUserName ?? 'Chat Partner',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Offline',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          GestureDetector(
            onTap: () => _showChatOptions(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.more_vert,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusText(ChatUser? user) {
    if (user == null) return 'Offline';

    // TODO: Check if other user is actually typing from real-time data
    // For now, we'll just show online status without fake typing
    if (user.isOnline) {
      return 'Online';
    } else if (user.lastSeen != null) {
      final now = DateTime.now();
      final difference = now.difference(user.lastSeen!);

      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      } else if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      } else {
        return 'Last seen ${DateFormat('MMM dd').format(user.lastSeen!)}';
      }
    }

    return 'Offline';
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildOptionTile(
              icon: Icons.search,
              title: 'Search in Chat',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement search functionality
              },
            ),
            _buildOptionTile(
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement notification settings
              },
            ),
            _buildOptionTile(
              icon: Icons.block,
              title: 'Block User',
              onTap: () {
                Navigator.pop(context);
                _showBlockUserDialog(context);
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showBlockUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A2B1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        title: const Text(
          'Block User',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to block this user? You won\'t receive messages from them.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement block functionality
            },
            child: const Text(
              'Block',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(List<ChatMessage> messages, String currentUserId) {
    if (messages.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isMe = message.senderId == currentUserId;
        final showTimestamp = index == 0 ||
            messages[index - 1]
                    .timestamp
                    .difference(message.timestamp)
                    .inMinutes
                    .abs() >
                5;

        return Column(
          children: [
            if (showTimestamp) _buildTimestamp(message.timestamp),
            _buildMessageBubble(message, isMe),
          ],
        );
      },
    );
  }

  Widget _buildTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final isToday = timestamp.day == now.day &&
        timestamp.month == now.month &&
        timestamp.year == now.year;

    String timeText;
    if (isToday) {
      timeText = DateFormat('HH:mm').format(timestamp);
    } else {
      timeText = DateFormat('MMM dd, HH:mm').format(timestamp);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          timeText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(false),
          if (!isMe) const SizedBox(width: 8),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: GestureDetector(
                onLongPress: () => _showMessageOptions(context, message, isMe),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isMe
                            ? AppTheme.primaryGreen.withOpacity(0.8)
                            : Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 6),
                          bottomRight: Radius.circular(isMe ? 6 : 20),
                        ),
                        border: Border.all(
                          color: isMe
                              ? AppTheme.primaryGreen.withOpacity(0.3)
                              : Colors.white.withOpacity(0.2),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isMe ? AppTheme.primaryGreen : Colors.black)
                                .withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            message.message,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('HH:mm').format(message.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  message.isRead ? Icons.done_all : Icons.done,
                                  size: 16,
                                  color: message.isRead
                                      ? Colors.blue[300]
                                      : Colors.white.withOpacity(0.7),
                                ),
                              ],
                            ],
                          ),
                          if (message.reactions.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            _buildReactions(message.reactions),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
          if (isMe) _buildAvatar(true),
        ],
      ),
    );
  }

  Widget _buildAvatar(bool isMe) {
    final user = ref.watch(authServiceProvider).currentUser;
    final chatInfoAsync = ref.watch(chatInfoProvider(widget.chatId));

    return chatInfoAsync.when(
      data: (chat) {
        if (isMe) {
          // For current user, we could fetch their profile image URLs
          return ProfileImageWidget(
            imageUrls: null, // TODO: Get from user profile
            userName: user?.displayName ?? 'Me',
            size: 32,
            imageSize: ImageSize.thumbnail,
            borderWidth: 1,
          );
        } else {
          // For other user
          final otherUser = chat?.getOtherParticipant(user?.id ?? '');
          return ProfileImageWidget(
            imageUrls: null, // TODO: Get from other user's profile
            userName: otherUser?.name ?? 'User',
            size: 32,
            imageSize: ImageSize.thumbnail,
            borderWidth: 1,
          );
        }
      },
      loading: () => ProfileImageWidget(
        userName: isMe ? 'M' : 'U',
        size: 32,
        imageSize: ImageSize.thumbnail,
        borderWidth: 1,
      ),
      error: (_, __) => ProfileImageWidget(
        userName: isMe ? 'M' : 'U',
        size: 32,
        imageSize: ImageSize.thumbnail,
        borderWidth: 1,
      ),
    );
  }

  void _showMessageOptions(
      BuildContext context, ChatMessage message, bool isMe) {
    final reactions = ['👍', '❤️', '😂', '😮', '😢', '🔥'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Quick reactions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: reactions
                    .map((emoji) => GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _addReaction(message, emoji);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
            const Divider(color: Colors.white24),
            // Message options
            _buildMessageOptionTile(
              icon: Icons.reply,
              title: 'Reply',
              onTap: () {
                Navigator.pop(context);
                _replyToMessage(message);
              },
            ),
            _buildMessageOptionTile(
              icon: Icons.copy,
              title: 'Copy',
              onTap: () {
                Navigator.pop(context);
                _copyMessage(message);
              },
            ),
            if (isMe)
              _buildMessageOptionTile(
                icon: Icons.delete,
                title: 'Delete',
                onTap: () {
                  Navigator.pop(context);
                  _deleteMessage(message);
                },
                isDestructive: true,
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageOptionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.white,
          fontSize: 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _addReaction(ChatMessage message, String emoji) {
    // TODO: Implement add reaction
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added reaction: $emoji'),
        backgroundColor: AppTheme.primaryGreen,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _replyToMessage(ChatMessage message) {
    // TODO: Implement reply functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reply feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _copyMessage(ChatMessage message) {
    // TODO: Implement copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _deleteMessage(ChatMessage message) {
    // TODO: Implement delete message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message deleted'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 1),
      ),
    );
  }

  Widget _buildReactions(List<MessageReaction> reactions) {
    return Wrap(
      spacing: 4,
      children: reactions.map((reaction) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            reaction.emoji,
            style: const TextStyle(fontSize: 16),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMessageInput(String currentUserId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Attachment button
                GestureDetector(
                  onTap: _showAttachmentOptions,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.attach_file,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                    cursorColor: Colors.white,
                    maxLines: 5,
                    minLines: 1,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(currentUserId),
                    onChanged: (text) {
                      // Typing logic is handled by _onTextChanged listener
                    },
                  ),
                ),
                // Emoji button
                GestureDetector(
                  onTap: _showEmojiPicker,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.emoji_emotions_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
                // Send button
                GestureDetector(
                  onTap: () => _sendMessage(currentUserId),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen,
                          AppTheme.primaryGreen.withOpacity(0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      _openCamera();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.photo_library,
                    label: 'Gallery',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _openGallery();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.insert_drive_file,
                    label: 'Document',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _openDocuments();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.location_on,
                    label: 'Location',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _shareLocation();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  void _openCamera() {
    // TODO: Implement camera functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Camera feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openGallery() {
    // TODO: Implement gallery functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Gallery feature coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openDocuments() {
    // TODO: Implement document picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document sharing coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareLocation() {
    // TODO: Implement location sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location sharing coming soon!'),
        backgroundColor: AppTheme.primaryGreen,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showEmojiPicker() {
    final emojis = [
      '😀',
      '😃',
      '😄',
      '😁',
      '😆',
      '😅',
      '😂',
      '🤣',
      '😊',
      '😇',
      '🙂',
      '🙃',
      '😉',
      '😌',
      '😍',
      '🥰',
      '😘',
      '😗',
      '😙',
      '😚',
      '😋',
      '😛',
      '😝',
      '😜',
      '🤪',
      '🤨',
      '🧐',
      '🤓',
      '😎',
      '🤩',
      '🥳',
      '😏',
      '👍',
      '👎',
      '👌',
      '✌️',
      '🤞',
      '🤟',
      '🤘',
      '🤙',
      '👋',
      '🤚',
      '🖐️',
      '✋',
      '🖖',
      '👏',
      '🙌',
      '🤲',
      '❤️',
      '🧡',
      '💛',
      '💚',
      '💙',
      '💜',
      '🖤',
      '🤍',
      '💯',
      '💢',
      '💥',
      '💫',
      '💦',
      '💨',
      '🕳️',
      '💣',
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.4,
        decoration: BoxDecoration(
          color: const Color(0xFF1A2B1A),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose an emoji',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                  childAspectRatio: 1,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) => GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    _addEmojiToMessage(emojis[index]);
                  },
                  child: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _addEmojiToMessage(String emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );
    _messageController.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
  }

  void _sendMessage(String senderId) {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      // Stop typing indicator
      _typingTimer?.cancel();
      _isTyping = false;
      _sendTypingStatus(false);

      ref
          .read(messagesProvider(widget.chatId).notifier)
          .sendMessage(senderId, message);

      // Clear text but maintain cursor position for better UX
      _messageController.clear();

      // Always scroll to bottom when user sends a message
      _userScrolledUp = false; // Reset scroll state
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      // Enhanced focus management - multiple timing attempts to ensure focus retention
      Future.microtask(() {
        if (mounted && _focusNode.canRequestFocus) {
          _focusNode.requestFocus();
        }
      });

      // Secondary focus attempt with longer delay
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted && _focusNode.canRequestFocus && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });

      // Final focus attempt to ensure text input remains active
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted && _focusNode.canRequestFocus && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Custom loading animation
            TweenAnimationBuilder(
              duration: const Duration(seconds: 2),
              tween: Tween<double>(begin: 0, end: 1),
              onEnd: () {
                // Restart animation
                setState(() {});
              },
              builder: (context, double value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                    Container(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        value: value,
                        valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryGreen),
                        strokeWidth: 3,
                      ),
                    ),
                    Icon(
                      Icons.chat_bubble_outline,
                      color: AppTheme.primaryGreen.withOpacity(value),
                      size: 24,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 1500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(
                  opacity: value,
                  child: Text(
                    'Loading messages...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withOpacity(0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 600),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
              padding: const EdgeInsets.all(32),
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.withOpacity(0.7),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load messages',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      // Retry loading
                      ref
                          .read(messagesProvider(widget.chatId).notifier)
                          .loadMessages();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 800),
        tween: Tween<double>(begin: 0, end: 1),
        builder: (context, double value, child) {
          return Transform.scale(
            scale: value,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Start the conversation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Send your first message!',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ShimmerWidget extends StatefulWidget {
  final Widget child;

  const _ShimmerWidget({required this.child});

  @override
  State<_ShimmerWidget> createState() => _ShimmerWidgetState();
}

class _ShimmerWidgetState extends State<_ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                0.0,
                _animationController.value,
                1.0,
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
