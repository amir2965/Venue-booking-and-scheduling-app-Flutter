import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wishlist.dart';
import '../services/wishlist_service.dart';

// Provider for user's wishlists
final wishlistsProvider =
    StateNotifierProvider<WishlistsNotifier, AsyncValue<List<Wishlist>>>((ref) {
  return WishlistsNotifier();
});

class WishlistsNotifier extends StateNotifier<AsyncValue<List<Wishlist>>> {
  WishlistsNotifier() : super(const AsyncValue.loading());

  // Load user's wishlists
  Future<void> loadWishlists(String userId) async {
    state = const AsyncValue.loading();
    try {
      final wishlists = await WishlistService.getUserWishlists(userId);
      state = AsyncValue.data(wishlists);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Create a new wishlist
  Future<Wishlist?> createWishlist({
    required String name,
    required String userId,
  }) async {
    try {
      final wishlist = await WishlistService.createWishlist(
        name: name,
        userId: userId,
      );

      if (wishlist != null) {
        // Refresh the wishlists
        await loadWishlists(userId);
      }

      return wishlist;
    } catch (error) {
      print('Error creating wishlist: $error');
      return null;
    }
  }

  // Add venue to wishlist
  Future<bool> addVenueToWishlist({
    required String wishlistId,
    required String venueId,
    required String userId,
  }) async {
    try {
      final success = await WishlistService.addVenueToWishlist(
        wishlistId: wishlistId,
        venueId: venueId,
      );

      if (success) {
        // Refresh the wishlists
        await loadWishlists(userId);
      }

      return success;
    } catch (error) {
      print('Error adding venue to wishlist: $error');
      return false;
    }
  }

  // Remove venue from wishlist
  Future<bool> removeVenueFromWishlist({
    required String wishlistId,
    required String venueId,
    required String userId,
  }) async {
    try {
      final success = await WishlistService.removeVenueFromWishlist(
        wishlistId: wishlistId,
        venueId: venueId,
      );

      if (success) {
        // Refresh the wishlists
        await loadWishlists(userId);
      }

      return success;
    } catch (error) {
      print('Error removing venue from wishlist: $error');
      return false;
    }
  }

  // Delete wishlist
  Future<bool> deleteWishlist({
    required String wishlistId,
    required String userId,
  }) async {
    try {
      print('PROVIDER: Attempting to delete wishlist $wishlistId');
      final success = await WishlistService.deleteWishlist(wishlistId);

      if (success) {
        print('PROVIDER: Wishlist deleted successfully, refreshing list');
        // Refresh the wishlists
        await loadWishlists(userId);
      } else {
        print('PROVIDER: Failed to delete wishlist $wishlistId');
      }

      return success;
    } catch (error) {
      print('PROVIDER: Error deleting wishlist: $error');
      return false;
    }
  }
}

// Provider to check if a venue is in user's wishlists
final venueInWishlistsProvider =
    FutureProvider.family<List<String>, Map<String, String>>(
        (ref, params) async {
  final userId = params['userId']!;
  final venueId = params['venueId']!;

  return await WishlistService.getWishlistsContainingVenue(
    userId: userId,
    venueId: venueId,
  );
});
