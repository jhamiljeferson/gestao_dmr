import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';
import '../services/venda_service.dart';

final vendaServiceProvider = Provider<VendaService>((ref) {
  return VendaService();
});

final vendasProvider = FutureProvider<List<Venda>>((ref) async {
  final service = ref.read(vendaServiceProvider);
  return await service.getAll();
});

final vendaControllerProvider =
    StateNotifierProvider<VendaController, AsyncValue<List<Venda>>>((ref) {
      final service = ref.read(vendaServiceProvider);
      return VendaController(service);
    });

final itensVendaProvider = FutureProvider.family<List<ItemVenda>, String>((
  ref,
  vendaId,
) async {
  final service = ref.read(vendaServiceProvider);
  return await service.getItensByVenda(vendaId);
});

class VendaController extends StateNotifier<AsyncValue<List<Venda>>> {
  final VendaService _service;

  VendaController(this._service) : super(const AsyncValue.loading()) {
    loadVendas();
  }

  Future<void> loadVendas() async {
    state = const AsyncValue.loading();
    try {
      final vendas = await _service.getAll();
      state = AsyncValue.data(vendas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<Venda> createVenda(Venda venda) async {
    try {
      final newVenda = await _service.create(venda);
      state.whenData((vendas) {
        state = AsyncValue.data([newVenda, ...vendas]);
      });
      return newVenda;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      throw error;
    }
  }

  Future<void> updateVenda(Venda venda) async {
    try {
      final updatedVenda = await _service.update(venda);
      state.whenData((vendas) {
        final updatedList = vendas
            .map((v) => v.id == venda.id ? updatedVenda : v)
            .toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteVenda(String id) async {
    try {
      await _service.delete(id);
      state.whenData((vendas) {
        final filteredList = vendas.where((v) => v.id != id).toList();
        state = AsyncValue.data(filteredList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadVendasByDate(DateTime data) async {
    state = const AsyncValue.loading();
    try {
      final vendas = await _service.getByDate(data);
      state = AsyncValue.data(vendas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadVendasByPonto(String pontoId) async {
    state = const AsyncValue.loading();
    try {
      final vendas = await _service.getByPonto(pontoId);
      state = AsyncValue.data(vendas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> loadVendasByVendedor(String vendedorId) async {
    state = const AsyncValue.loading();
    try {
      final vendas = await _service.getByVendedor(vendedorId);
      state = AsyncValue.data(vendas);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Métodos para itens de venda
  Future<List<ItemVenda>> getItensVenda(String vendaId) async {
    try {
      return await _service.getItensByVenda(vendaId);
    } catch (error, stackTrace) {
      throw error;
    }
  }

  Future<void> createItemVenda(ItemVenda item) async {
    try {
      await _service.createItem(item);
      // Não recarregar toda a lista aqui, apenas invalidar o provider específico
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateItemVenda(ItemVenda item) async {
    try {
      await _service.updateItem(item);
      // Não recarregar toda a lista aqui, apenas invalidar o provider específico
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteItemVenda(String id) async {
    try {
      await _service.deleteItem(id);
      // Não recarregar toda a lista aqui, apenas invalidar o provider específico
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Método para invalidar o provider de itens de uma venda específica
  void invalidateItensVenda(WidgetRef ref, String vendaId) {
    ref.invalidate(itensVendaProvider(vendaId));
  }
}
