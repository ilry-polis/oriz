import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/package_model.dart';
import '../repositories/package_repository.dart';

// ─── State ────────────────────────────────────────────────────

sealed class PackageListState {
  const PackageListState();
}

class PackageListLoading extends PackageListState {
  const PackageListLoading();
}

class PackageListLoaded extends PackageListState {
  final List<PackageModel> items;
  final bool hasMore;
  final String? cursor;
  final String? serviceIdFilter;

  const PackageListLoaded({
    required this.items,
    required this.hasMore,
    this.cursor,
    this.serviceIdFilter,
  });

  PackageListLoaded copyWith({
    List<PackageModel>? items,
    bool? hasMore,
    String? cursor,
    String? serviceIdFilter,
  }) {
    return PackageListLoaded(
      items: items ?? this.items,
      hasMore: hasMore ?? this.hasMore,
      cursor: cursor ?? this.cursor,
      serviceIdFilter: serviceIdFilter ?? this.serviceIdFilter,
    );
  }
}

class PackageListError extends PackageListState {
  final String message;
  const PackageListError(this.message);
}

// ─── Notifier ─────────────────────────────────────────────────

class PackageNotifier extends AsyncNotifier<PackageListState> {
  @override
  Future<PackageListState> build() async {
    return await _fetchPackages();
  }

  Future<PackageListState> _fetchPackages({String? serviceId}) async {
    final repo = ref.read(packageRepositoryProvider);
    try {
      final result = await repo.list(serviceId: serviceId);
      return PackageListLoaded(
        items: result.items,
        hasMore: result.hasMore,
        cursor: result.cursor,
        serviceIdFilter: serviceId,
      );
    } catch (e) {
      return PackageListError(e.toString());
    }
  }

  Future<void> load({String? serviceId}) async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _fetchPackages(serviceId: serviceId));
  }

  Future<void> refresh() async {
    final current = state.value;
    final serviceId = current is PackageListLoaded ? current.serviceIdFilter : null;
    await load(serviceId: serviceId);
  }

  Future<void> create({
    required List<String> serviceIds,
    required String name,
    required int totalSessions,
    required int price,
    required int validityDays,
  }) async {
    final repo = ref.read(packageRepositoryProvider);
    final created = await repo.create(
      serviceIds: serviceIds,
      name: name,
      totalSessions: totalSessions,
      price: price,
      validityDays: validityDays,
    );

    final current = state.value;
    if (current is PackageListLoaded) {
      state = AsyncValue.data(
        current.copyWith(items: [created, ...current.items]),
      );
    } else {
      await refresh();
    }
  }

  Future<void> updatePackage(
    String packageId, {
    String? name,
    int? totalSessions,
    int? price,
    int? validityDays,
  }) async {
    final repo = ref.read(packageRepositoryProvider);
    final updated = await repo.update(
      packageId,
      name: name,
      totalSessions: totalSessions,
      price: price,
      validityDays: validityDays,
    );

    final current = state.value;
    if (current is PackageListLoaded) {
      final newItems = current.items
          .map((p) => p.id == packageId ? updated : p)
          .toList();
      state = AsyncValue.data(current.copyWith(items: newItems));
    }
  }

  Future<void> delete(String packageId) async {
    final repo = ref.read(packageRepositoryProvider);
    await repo.delete(packageId);

    final current = state.value;
    if (current is PackageListLoaded) {
      final newItems = current.items.where((p) => p.id != packageId).toList();
      state = AsyncValue.data(current.copyWith(items: newItems));
    }
  }
}

final packageProvider =
    AsyncNotifierProvider<PackageNotifier, PackageListState>(
  PackageNotifier.new,
);

// ─── Client subscriptions provider ────────────────────────────

/// Loads all subscriptions for a specific client (all statuses).
final clientSubscriptionsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>(
  (ref, clientId) async {
    final repo = ref.read(packageRepositoryProvider);
    final result =
        await repo.listSubscriptions(clientId: clientId, limit: 50);
    return result.items;
  },
);

/// Loads subscriptions for a specific package.
final packageSubscriptionsProvider =
    FutureProvider.autoDispose.family<List<dynamic>, String>(
  (ref, packageId) async {
    final repo = ref.read(packageRepositoryProvider);
    final result = await repo.listSubscriptions(packageId: packageId, limit: 50);
    return result.items;
  },
);
