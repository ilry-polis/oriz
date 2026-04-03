import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/team_repository.dart';
import '../domain/professional_model.dart';

sealed class TeamState {
  const TeamState();
}

class TeamLoading extends TeamState {
  const TeamLoading();
}

class TeamLoaded extends TeamState {
  final List<ProfessionalModel> professionals;
  const TeamLoaded(this.professionals);
}

class TeamError extends TeamState {
  final String message;
  const TeamError(this.message);
}

class TeamNotifier extends Notifier<TeamState> {
  @override
  TeamState build() {
    _load();
    return const TeamLoading();
  }

  Future<void> _load() async {
    try {
      final repo = ref.read(teamRepositoryProvider);
      final professionals = await repo.listProfessionals();
      state = TeamLoaded(professionals);
    } catch (e) {
      state = TeamError(e.toString());
    }
  }

  Future<void> refresh() async {
    state = const TeamLoading();
    await _load();
  }
}

final teamProvider =
    NotifierProvider<TeamNotifier, TeamState>(TeamNotifier.new);
