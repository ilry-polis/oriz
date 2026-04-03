import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/client_repository.dart';
import '../domain/client_model.dart';

// ─── Client List ─────────────────────────────────────────

sealed class ClientListState {
  const ClientListState();
}

class ClientListLoading extends ClientListState {
  const ClientListLoading();
}

class ClientListLoaded extends ClientListState {
  final List<ClientModel> clients;
  final bool hasMore;
  final String? nextCursor;
  final String? activeSearch;
  final String? activeTag;

  const ClientListLoaded({
    required this.clients,
    this.hasMore = false,
    this.nextCursor,
    this.activeSearch,
    this.activeTag,
  });
}

class ClientListError extends ClientListState {
  final String message;
  const ClientListError(this.message);
}

class ClientListNotifier extends Notifier<ClientListState> {
  Timer? _debounce;
  bool _isFetching = false;
  String? _activeSearch;
  String? _activeTag;

  @override
  ClientListState build() {
    ref.onDispose(() => _debounce?.cancel());
    _load();
    return const ClientListLoading();
  }

  Future<void> _load({String? search, String? tag, String? cursor}) async {
    if (_isFetching) return;
    _isFetching = true;

    try {
      final repo = ref.read(clientRepositoryProvider);
      final response =
          await repo.listClients(cursor: cursor, search: search, tag: tag);
      final data = (response['data'] as List)
          .map((e) => ClientModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = response['meta'] as Map<String, dynamic>?;

      final current = state;
      final existing =
          (cursor != null && current is ClientListLoaded) ? current.clients : <ClientModel>[];

      state = ClientListLoaded(
        clients: [...existing, ...data],
        hasMore: meta?['has_more'] as bool? ?? false,
        nextCursor: meta?['next_cursor'] as String?,
        activeSearch: search,
        activeTag: tag,
      );
    } catch (e) {
      state = ClientListError(e.toString());
    } finally {
      _isFetching = false;
    }
  }

  void search(String query) {
    _debounce?.cancel();
    // Capture current tag before debounce fires
    final tag = _activeTag;
    _activeSearch = query.isEmpty ? null : query;
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = const ClientListLoading();
      _load(search: _activeSearch, tag: tag);
    });
  }

  void filterByTag(String? tag) {
    _activeTag = tag;
    state = const ClientListLoading();
    _load(search: _activeSearch, tag: tag);
  }

  void loadMore() {
    final current = state;
    if (current is ClientListLoaded && current.hasMore && !_isFetching) {
      _load(
        search: current.activeSearch,
        tag: current.activeTag,
        cursor: current.nextCursor,
      );
    }
  }

  Future<void> refresh() async {
    _activeSearch = null;
    _activeTag = null;
    state = const ClientListLoading();
    await _load();
  }
}

final clientListProvider =
    NotifierProvider<ClientListNotifier, ClientListState>(
        ClientListNotifier.new);

// ─── Client Detail ───────────────────────────────────────

final clientDetailProvider =
    FutureProvider.family<ClientModel, String>((ref, clientId) async {
  final repo = ref.read(clientRepositoryProvider);
  return repo.getClientById(clientId);
});
