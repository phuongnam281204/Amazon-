import 'package:amazon_clone/features/product_details/services/product_details_service.dart';
import 'package:amazon_clone/models/product.dart';
import 'package:amazon_clone/models/rating.dart';
import 'package:amazon_clone/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';

class RatingProvider extends ChangeNotifier {
  final ProductDetailsService _productDetailsService = ProductDetailsService();

  // Cache for product ratings to avoid frequent API calls
  final Map<String, List<Rating>> _productRatingsCache = {};
  final Map<String, double> _averageRatingsCache = {};
  Timer? _refreshTimer;

  // Get cached average rating for a product
  double getAverageRating(String productId, List<Rating>? ratings) {
    if (_averageRatingsCache.containsKey(productId)) {
      return _averageRatingsCache[productId]!;
    }

    if (ratings == null || ratings.isEmpty) {
      _averageRatingsCache[productId] = 0.0;
      return 0.0;
    }

    double totalRating = 0;
    for (Rating rating in ratings) {
      totalRating += rating.rating;
    }
    double average = totalRating / ratings.length;
    _averageRatingsCache[productId] = average;
    return average;
  }

  // Get cached ratings for a product
  List<Rating>? getCachedRatings(String productId) {
    return _productRatingsCache[productId];
  }

  // Update rating and refresh cache immediately
  Future<void> updateRating({
    required BuildContext context,
    required Product product,
    required double rating,
    required VoidCallback? onSuccess,
  }) async {
    // Get user ID for the rating
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final userId = userProvider.user.id;

    // Update rating via service
    _productDetailsService.rateProduct(
      context: context,
      product: product,
      rating: rating,
    );

    // Update cache immediately for instant UI feedback
    if (product.id != null) {
      List<Rating> currentRatings = List.from(
        _productRatingsCache[product.id!] ?? product.rating ?? [],
      );

      // Find existing rating by current user and update, or add new rating
      bool foundExisting = false;
      for (int i = 0; i < currentRatings.length; i++) {
        if (currentRatings[i].userId == userId) {
          currentRatings[i] = Rating(userId: userId, rating: rating);
          foundExisting = true;
          break;
        }
      }

      if (!foundExisting) {
        currentRatings.add(Rating(userId: userId, rating: rating));
      }

      // Update cache
      _productRatingsCache[product.id!] = currentRatings;

      // Recalculate average rating
      double totalRating = 0;
      for (Rating r in currentRatings) {
        totalRating += r.rating;
      }
      _averageRatingsCache[product.id!] = currentRatings.isNotEmpty
          ? totalRating / currentRatings.length
          : 0.0;

      // Notify listeners for immediate UI update
      notifyListeners();

      // Call success callback
      onSuccess?.call();
    }
  }

  // Cache product ratings
  void cacheProductRatings(String productId, List<Rating> ratings) {
    _productRatingsCache[productId] = ratings;

    // Update average rating cache
    if (ratings.isNotEmpty) {
      double totalRating = 0;
      for (Rating rating in ratings) {
        totalRating += rating.rating;
      }
      _averageRatingsCache[productId] = totalRating / ratings.length;
    } else {
      _averageRatingsCache[productId] = 0.0;
    }

    notifyListeners();
  }

  // Get rating count for a product
  int getRatingCount(String productId, List<Rating>? ratings) {
    if (_productRatingsCache.containsKey(productId)) {
      return _productRatingsCache[productId]!.length;
    }
    return ratings?.length ?? 0;
  }

  // Clear cache for a specific product
  void clearProductCache(String productId) {
    _productRatingsCache.remove(productId);
    _averageRatingsCache.remove(productId);
    notifyListeners();
  }

  // Clear all cache
  void clearAllCache() {
    _productRatingsCache.clear();
    _averageRatingsCache.clear();
    notifyListeners();
  }

  // Start periodic refresh for ratings (less frequent than notifications)
  void startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      // Refresh cached ratings periodically
      clearAllCache();
    });
  }

  // Stop periodic refresh
  void stopPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    stopPeriodicRefresh();
    super.dispose();
  }
}
