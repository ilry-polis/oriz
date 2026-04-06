import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/http/api_client.dart';
import '../models/package_model.dart';
import '../models/package_subscription_model.dart';

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return PackageRepository(apiClient);
});

class PackageRepository {
  final ApiClient _api;

  PackageRepository(this._api);

  /// List packages, optionally filtered by [serviceId].
  /// Returns cursor-based paginated list.
  Future<({List<PackageModel> items, bool hasMore, String? cursor})> list({
    String? serviceId,
    String? cursor,
    int limit = 30,
  }) async {
    final params = StringBuffer('?limit=$limit');
    if (serviceId != null && serviceId.isNotEmpty) {
      params.write('&service_id=$serviceId');
    }
    if (cursor != null && cursor.isNotEmpty) {
      params.write('&cursor=$cursor');
    }

    final response = await _api.get('/api/v1/packages$params');
    final data = response['data'] as List;
    final meta = response['meta'] as Map<String, dynamic>? ?? {};

    return (
      items: data
          .map((e) => PackageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: meta['hasMore'] as bool? ?? false,
      cursor: meta['cursor'] as String?,
    );
  }

  /// Create a new package.
  Future<PackageModel> create({
    required List<String> serviceIds,
    required String name,
    required int totalSessions,
    required int price,
    required int validityDays,
  }) async {
    final response = await _api.post('/api/v1/packages', body: {
      'service_ids': serviceIds,
      'name': name,
      'total_sessions': totalSessions,
      'price': price,
      'validity_days': validityDays,
    });
    return PackageModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Update an existing package.
  Future<PackageModel> update(
    String packageId, {
    String? name,
    int? totalSessions,
    int? price,
    int? validityDays,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (totalSessions != null) body['total_sessions'] = totalSessions;
    if (price != null) body['price'] = price;
    if (validityDays != null) body['validity_days'] = validityDays;

    final response =
        await _api.patch('/api/v1/packages/$packageId', body: body);
    return PackageModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Delete a package.
  Future<void> delete(String packageId) async {
    await _api.delete('/api/v1/packages/$packageId');
  }

  /// Sell a package to a client (create subscription).
  Future<PackageSubscriptionModel> createSubscription({
    required String packageId,
    required String clientId,
  }) async {
    final response = await _api.post(
      '/api/v1/packages/$packageId/subscriptions',
      body: {'client_id': clientId},
    );
    return PackageSubscriptionModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }

  /// List subscriptions for a package or client.
  Future<
      ({
        List<PackageSubscriptionModel> items,
        bool hasMore,
        String? cursor
      })> listSubscriptions({
    String? packageId,
    String? clientId,
    String? status,
    String? cursor,
    int limit = 20,
  }) async {
    if (packageId != null && packageId.isNotEmpty) {
      // Use package-specific endpoint
      final params = StringBuffer('?limit=$limit');
      if (status != null && status.isNotEmpty) params.write('&status=$status');
      if (cursor != null && cursor.isNotEmpty) params.write('&cursor=$cursor');

      final response = await _api
          .get('/api/v1/packages/$packageId/subscriptions$params');
      final data = response['data'] as List;
      final meta = response['meta'] as Map<String, dynamic>? ?? {};

      return (
        items: data
            .map((e) =>
                PackageSubscriptionModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        hasMore: meta['hasMore'] as bool? ?? false,
        cursor: meta['cursor'] as String?,
      );
    }

    // Use client-scoped listing via active endpoint
    final params = StringBuffer('?limit=$limit');
    if (clientId != null && clientId.isNotEmpty) {
      params.write('&client_id=$clientId');
    }
    if (status != null && status.isNotEmpty) params.write('&status=$status');
    if (cursor != null && cursor.isNotEmpty) params.write('&cursor=$cursor');

    final response =
        await _api.get('/api/v1/package-subscriptions$params');
    final data = response['data'] as List;
    final meta = response['meta'] as Map<String, dynamic>? ?? {};

    return (
      items: data
          .map((e) =>
              PackageSubscriptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasMore: meta['hasMore'] as bool? ?? false,
      cursor: meta['cursor'] as String?,
    );
  }

  /// Get the active subscription for a client+service combination.
  Future<PackageSubscriptionModel?> getActiveForClientService({
    required String clientId,
    required String serviceId,
  }) async {
    final response = await _api.get(
      '/api/v1/package-subscriptions/active?client_id=$clientId&service_id=$serviceId',
    );
    final data = response['data'];
    if (data == null) return null;
    return PackageSubscriptionModel.fromJson(data as Map<String, dynamic>);
  }

  /// Extend subscription expiry.
  Future<PackageSubscriptionModel> extendExpiry({
    required String subscriptionId,
    required DateTime newExpiresAt,
  }) async {
    final response = await _api.patch(
      '/api/v1/package-subscriptions/$subscriptionId',
      body: {'expires_at': newExpiresAt.toIso8601String()},
    );
    return PackageSubscriptionModel.fromJson(
        response['data'] as Map<String, dynamic>);
  }
}
