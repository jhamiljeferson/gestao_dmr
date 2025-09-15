import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/produto_model.dart';
import '../services/produto_service.dart';
import '../../estoque/controllers/estoque_controller.dart';

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
      return ProdutoController(service, ref);
    });

class ProdutoController extends StateNotifier<AsyncValue<List<Produto>>> {
  final ProdutoService _service;
  final Ref _ref;

  ProdutoController(this._service, this._ref)
    : super(const AsyncValue.loading()) {
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
        // Adicionar produto ordenado por código para manter consistência
        final updatedProdutos = [...produtos, newProduto];
        updatedProdutos.sort((a, b) => a.codigo.compareTo(b.codigo));
        state = AsyncValue.data(updatedProdutos);
      });
      // Invalidar estoque quando um produto for criado (assíncrono para não bloquear)
      _ref.invalidate(estoqueProvider);
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
