import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vendedor_model.dart';
import '../services/vendedor_service.dart';

final vendedorServiceProvider = Provider<VendedorService>((ref) {
  return VendedorService();
});

final vendedoresProvider = FutureProvider<List<Vendedor>>((ref) async {
  final service = ref.read(vendedorServiceProvider);
  return await service.getAll();
});

final vendedorControllerProvider =
    StateNotifierProvider<VendedorController, AsyncValue<List<Vendedor>>>((
      ref,
    ) {
      final service = ref.read(vendedorServiceProvider);
      return VendedorController(service);
    });

class VendedorController extends StateNotifier<AsyncValue<List<Vendedor>>> {
  final VendedorService _service;

  VendedorController(this._service) : super(const AsyncValue.loading()) {
    loadVendedores();
  }

  Future<void> loadVendedores() async {
    state = const AsyncValue.loading();
    try {
      final vendedores = await _service.getAll();
      state = AsyncValue.data(vendedores);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createVendedor(Vendedor vendedor) async {
    try {
      final newVendedor = await _service.create(vendedor);
      state.whenData((vendedores) {
        state = AsyncValue.data([...vendedores, newVendedor]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateVendedor(Vendedor vendedor) async {
    try {
      final updatedVendedor = await _service.update(vendedor);
      state.whenData((vendedores) {
        final updatedList = vendedores
            .map((v) => v.id == vendedor.id ? updatedVendedor : v)
            .toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteVendedor(String id) async {
    try {
      await _service.delete(id);
      state.whenData((vendedores) {
        final filteredList = vendedores.where((v) => v.id != id).toList();
        state = AsyncValue.data(filteredList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchVendedores(String query) async {
    if (query.isEmpty) {
      await loadVendedores();
      return;
    }

    try {
      final vendedores = await _service.searchByName(query);
      state = AsyncValue.data(vendedores);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
