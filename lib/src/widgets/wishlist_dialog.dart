import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/wishlist_provider.dart';

class WishlistDialog extends ConsumerStatefulWidget {
  final String venueId;
  final String venueName;
  final String userId;
  final bool createOnlyMode; // New parameter for create-only mode

  const WishlistDialog({
    Key? key,
    required this.venueId,
    required this.venueName,
    required this.userId,
    this.createOnlyMode = false, // Default to false for existing behavior
  }) : super(key: key);

  @override
  ConsumerState<WishlistDialog> createState() => _WishlistDialogState();
}

class _WishlistDialogState extends ConsumerState<WishlistDialog> {
  bool _isCreatingNew = false;
  final TextEditingController _nameController = TextEditingController();
  final FocusNode _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    print(
        'DEBUG: WishlistDialog initState called - venueId: ${widget.venueId}, venueName: ${widget.venueName}');
    if (widget.createOnlyMode) {
      _isCreatingNew = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _nameFocus.requestFocus();
      });
    } else {
      // Load user's wishlists when dialog opens (only in normal mode)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(wishlistsProvider.notifier).loadWishlists(widget.userId);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _showCreateForm() {
    setState(() {
      _isCreatingNew = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _nameFocus.requestFocus();
    });
  }

  void _hideCreateForm() {
    setState(() {
      _isCreatingNew = false;
      _nameController.clear();
    });
  }

  Future<void> _createWishlist() async {
    if (_nameController.text.trim().isEmpty) return;

    final wishlist = await ref.read(wishlistsProvider.notifier).createWishlist(
          name: _nameController.text.trim(),
          userId: widget.userId,
        );

    if (wishlist != null) {
      _hideCreateForm();
      // Add venue to the newly created wishlist
      await _addToWishlist(wishlist.id);
    }
  }

  Future<void> _addToWishlist(String wishlistId) async {
    final success =
        await ref.read(wishlistsProvider.notifier).addVenueToWishlist(
              wishlistId: wishlistId,
              venueId: widget.venueId,
              userId: widget.userId,
            );

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${widget.venueName}" to wishlist'),
          backgroundColor: const Color(0xFF28A745),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wishlistsAsync = ref.watch(wishlistsProvider);

    return Align(
      alignment: Alignment.bottomCenter,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: MediaQuery.of(context).size.width - 32, // Wide from both sides
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 40),
          constraints: const BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.createOnlyMode
                            ? 'Create New Wishlist'
                            : 'Save to Wishlist',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.close,
                          color: Colors.grey,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              if (widget.createOnlyMode)
                _buildCreateOnlyContent()
              else
                _buildNormalContent(wishlistsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateOnlyContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Wishlist Name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            focusNode: _nameFocus,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: 'Enter wishlist name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFF28A745)),
              ),
              counterText: '',
            ),
            onSubmitted: (_) => _createWishlist(),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _nameController.text.trim().isEmpty
                      ? null
                      : _createWishlist,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Create & Add'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNormalContent(AsyncValue wishlistsAsync) {
    return Flexible(
      child: wishlistsAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(
              color: Color(0xFF28A745),
            ),
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Error loading wishlists',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
        data: (wishlists) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create new wishlist form
            if (_isCreatingNew) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE5E5E5))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Wishlist',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      maxLength: 50,
                      decoration: InputDecoration(
                        hintText: 'Wishlist name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E5E5)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide:
                              const BorderSide(color: Color(0xFF28A745)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        counterText: '',
                      ),
                      onSubmitted: (_) => _createWishlist(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _hideCreateForm,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createWishlist,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF28A745),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Create'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // Existing wishlists
            if (wishlists.isNotEmpty) ...[
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: wishlists.length,
                  itemBuilder: (context, index) {
                    final wishlist = wishlists[index];
                    final isVenueInWishlist =
                        wishlist.venueIds.contains(widget.venueId);

                    return ListTile(
                      title: Text(
                        wishlist.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        '${wishlist.venueIds.length} venues',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      trailing: isVenueInWishlist
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF28A745),
                            )
                          : const Icon(
                              Icons.add_circle_outline,
                              color: Colors.grey,
                            ),
                      onTap: isVenueInWishlist
                          ? null
                          : () => _addToWishlist(wishlist.id),
                    );
                  },
                ),
              ),
            ],

            // No wishlists message
            if (wishlists.isEmpty && !_isCreatingNew) ...[
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No wishlists yet',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create your first wishlist to save venues',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],

            // Create new wishlist button
            if (!_isCreatingNew) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE5E5E5))),
                ),
                child: ElevatedButton.icon(
                  onPressed: _showCreateForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Wishlist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF28A745),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
