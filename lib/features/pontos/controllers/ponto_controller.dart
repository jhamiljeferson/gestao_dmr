import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ponto_model.dart';
import '../services/ponto_service.dart';

final pontoServiceProvider = Provider<PontoService>((ref) {
  return PontoService();
});

final pontosProvider = FutureProvider<List<Ponto>>((ref) async {
  final service = ref.read(pontoServiceProvider);
  return await service.getAll();
});

final pontoControllerProvider =
    StateNotifierProvider<PontoController, AsyncValue<List<Ponto>>>((ref) {
      final service = ref.read(pontoServiceProvider);
      return PontoController(service);
    });

class PontoController extends StateNotifier<AsyncValue<List<Ponto>>> {
  final PontoService _service;

  PontoController(this._service) : super(const AsyncValue.loading()) {
    loadPontos();
  }

  Future<void> loadPontos() async {
    state = const AsyncValue.loading();
    try {
      final pontos = await _service.getAll();
      state = AsyncValue.data(pontos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createPonto(Ponto ponto) async {
    try {
      final newPonto = await _service.create(ponto);
      state.whenData((pontos) {
        state = AsyncValue.data([...pontos, newPonto]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updatePonto(Ponto ponto) async {
    try {
      final updatedPonto = await _service.update(ponto);
      state.whenData((pontos) {
        final updatedList = pontos
            .map((p) => p.id == ponto.id ? updatedPonto : p)
            .toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deletePonto(String id) async {
    try {
      await _service.delete(id);
      state.whenData((pontos) {
        final filteredList = pontos.where((p) => p.id != id).toList();
        state = AsyncValue.data(filteredList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchPontos(String query) async {
    if (query.isEmpty) {
      await loadPontos();
      return;
    }

    try {
      final pontos = await _service.searchByName(query);
      state = AsyncValue.data(pontos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
