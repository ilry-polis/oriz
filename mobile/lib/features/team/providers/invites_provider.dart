import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/team_repository.dart';
import '../domain/professional_model.dart';

sealed class InvitesState {
  const InvitesState();
}

class InvitesLoading extends InvitesState {
  const InvitesLoading();
}

class InvitesLoaded extends InvitesState {
  final List<PendingInvite> invites;
  const InvitesLoaded(this.invites);
}

class InvitesError extends InvitesState {
  final String message;
  const InvitesError(this.message);
}

class InvitesNotifier extends Notifier<InvitesState> {
  @override
  InvitesState build() {
    _load();
    return const InvitesLoading();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(teamRepositoryProvider);
      final invites = await repo.listPendingInvites();
      state = InvitesLoaded(invites);
    } catch (e) {
      state = InvitesError(e.toString());
    }
  }

  Future<void> refresh() async {
    state = const InvitesLoading();
    await _load();
  }
}

final invitesProvider =
    NotifierProvider<InvitesNotifier, InvitesState>(InvitesNotifier.new);
