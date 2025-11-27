import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wishlist.dart';

class WishlistService {
  static const String baseUrl = 'http://localhost:5000/api';

  // Get user's wishlists
  static Future<List<Wishlist>> getUserWishlists(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/wishlists/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Wishlist.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load wishlists');
      }
    } catch (e) {
      print('Error fetching wishlists: $e');
      return [];
    }
  }

  // Create a new wishlist
  static Future<Wishlist?> createWishlist({
    required String name,
    required String userId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlists'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'userId': userId,
          'venueIds': [],
        }),
      );

      if (response.statusCode == 201) {
        return Wishlist.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create wishlist');
      }
    } catch (e) {
      print('Error creating wishlist: $e');
      return null;
    }
  }

  // Add venue to wishlist
  static Future<bool> addVenueToWishlist({
    required String wishlistId,
    required String venueId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/wishlists/$wishlistId/venues'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'venueId': venueId}),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error adding venue to wishlist: $e');
      return false;
    }
  }

  // Remove venue from wishlist
  static Future<bool> removeVenueFromWishlist({
    required String wishlistId,
    required String venueId,
  }) async {
    try {
      print('REMOVE: Removing venue $venueId from wishlist $wishlistId');

      final response = await http.delete(
        Uri.parse('$baseUrl/wishlists/$wishlistId/venues/$venueId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('REMOVE: Response status: ${response.statusCode}');
      print('REMOVE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            'REMOVE: Failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error removing venue from wishlist: $e');
      return false;
    }
  }

  // Delete wishlist
  static Future<bool> deleteWishlist(String wishlistId) async {
    try {
      print('DELETE: Deleting wishlist with ID: $wishlistId');

      final response = await http.delete(
        Uri.parse('$baseUrl/wishlists/$wishlistId'),
        headers: {'Content-Type': 'application/json'},
      );

      print('DELETE: Response status: ${response.statusCode}');
      print('DELETE: Response body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      } else {
        print(
            'DELETE: Failed with status ${response.statusCode}: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error deleting wishlist: $e');
      return false;
    }
  }

  // Check if venue is in any wishlist
  static Future<List<String>> getWishlistsContainingVenue({
    required String userId,
    required String venueId,
  }) async {
    try {
      final wishlists = await getUserWishlists(userId);
      return wishlists
          .where((wishlist) => wishlist.venueIds.contains(venueId))
          .map((wishlist) => wishlist.id)
          .toList();
    } catch (e) {
      print('Error checking venue in wishlists: $e');
      return [];
    }
  }
}
