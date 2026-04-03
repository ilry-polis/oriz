import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/service_mgmt_repository.dart';
import '../domain/service_model.dart';

sealed class ServiceMgmtState {
  const ServiceMgmtState();
}

class ServiceMgmtLoading extends ServiceMgmtState {
  const ServiceMgmtLoading();
}

class ServiceMgmtLoaded extends ServiceMgmtState {
  final Map<String, List<ServiceModel>> grouped;
  final List<ServiceModel> all;

  const ServiceMgmtLoaded({required this.grouped, required this.all});
}

class ServiceMgmtError extends ServiceMgmtState {
  final String message;
  const ServiceMgmtError(this.message);
}

class ServiceMgmtNotifier extends Notifier<ServiceMgmtState> {
  @override
  ServiceMgmtState build() {
    _load();
    return const ServiceMgmtLoading();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(serviceMgmtRepositoryProvider);
      // ignore: avoid_print
      print('[ServiceMgmt] Loading services...');
      final services = await repo.listServices();
      // ignore: avoid_print
      print('[ServiceMgmt] Loaded ${services.length} services');
      final grouped = <String, List<ServiceModel>>{};
      for (final s in services) {
        final cat = s.categoryName ?? 'Sem categoria';
        grouped.putIfAbsent(cat, () => []).add(s);
      }
      state = ServiceMgmtLoaded(grouped: grouped, all: services);
    } catch (e, stack) {
      // ignore: avoid_print
      print('[ServiceMgmt] ERROR: $e\n$stack');
      state = ServiceMgmtError(e.toString());
    }
  }

  Future<void> refresh() async {
    state = const ServiceMgmtLoading();
    await _load();
  }
}

final serviceMgmtProvider =
    NotifierProvider<ServiceMgmtNotifier, ServiceMgmtState>(
        ServiceMgmtNotifier.new);
