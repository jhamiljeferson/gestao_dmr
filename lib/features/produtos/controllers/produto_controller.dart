import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/produto_model.dart';
import '../services/produto_service.dart';

final produtoServiceProvider = Provider<ProdutoService>((ref) {
  return ProdutoService();
});

final produtosProvider = FutureProvider<List<Produto>>((ref) async {
  final service = ref.read(produtoServiceProvider);
  return await service.getAll();
});

final produtoControllerProvider =
    StateNotifierProvider<ProdutoController, AsyncValue<List<Produto>>>((ref) {
      final service = ref.read(produtoServiceProvider);
      return ProdutoController(service);
    });

class ProdutoController extends StateNotifier<AsyncValue<List<Produto>>> {
  final ProdutoService _service;

  ProdutoController(this._service) : super(const AsyncValue.loading()) {
    loadProdutos();
  }

  Future<void> loadProdutos() async {
    state = const AsyncValue.loading();
    try {
      final produtos = await _service.getAll();
      state = AsyncValue.data(produtos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createProduto(Produto produto) async {
    try {
      final newProduto = await _service.create(produto);
      state.whenData((produtos) {
        state = AsyncValue.data([...produtos, newProduto]);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> updateProduto(Produto produto) async {
    try {
      final updatedProduto = await _service.update(produto);
      state.whenData((produtos) {
        final updatedList = produtos
            .map((p) => p.id == produto.id ? updatedProduto : p)
            .toList();
        state = AsyncValue.data(updatedList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> deleteProduto(String id) async {
    try {
      await _service.delete(id);
      state.whenData((produtos) {
        final filteredList = produtos.where((p) => p.id != id).toList();
        state = AsyncValue.data(filteredList);
      });
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> searchProdutos(String query) async {
    if (query.isEmpty) {
      await loadProdutos();
      return;
    }

    try {
      final produtos = await _service.searchByName(query);
      state = AsyncValue.data(produtos);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
