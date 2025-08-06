import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/estoque_model.dart';
import '../services/estoque_service.dart';

final estoqueServiceProvider = Provider<EstoqueService>((ref) {
  return EstoqueService();
});

// Provider para todo o estoque
final estoqueProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    final service = ref.read(estoqueServiceProvider);
    return await service.getAllWithProduto();
  } catch (error) {
    print('Erro no provider estoque: $error');
    rethrow;
  }
});

// Provider para estoque baixo
final estoqueBaixoProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final service = ref.read(estoqueServiceProvider);
    return await service.getEstoqueBaixo();
  } catch (error) {
    print('Erro no provider estoque baixo: $error');
    rethrow;
  }
});

// Provider para produtos sem estoque
final semEstoqueProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    final service = ref.read(estoqueServiceProvider);
    return await service.getSemEstoque();
  } catch (error) {
    print('Erro no provider sem estoque: $error');
    rethrow;
  }
});

class EstoqueController extends StateNotifier<AsyncValue<void>> {
  final EstoqueService _service;

  EstoqueController(this._service) : super(const AsyncValue.data(null));

  // Atualizar quantidade de estoque manualmente
  Future<void> updateQuantidade(String produtoId, int novaQuantidade) async {
    state = const AsyncValue.loading();

    try {
      await _service.updateQuantidade(produtoId, novaQuantidade);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Criar registro de estoque para produto
  Future<void> createEstoque(String produtoId, int quantidade) async {
    state = const AsyncValue.loading();

    try {
      await _service.create(produtoId, quantidade);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Buscar estoque de um produto específico
  Future<Estoque?> getEstoqueProduto(String produtoId) async {
    try {
      return await _service.getByProdutoId(produtoId);
    } catch (error) {
      print('Erro ao buscar estoque do produto: $error');
      return null;
    }
  }
}

final estoqueControllerProvider =
    StateNotifierProvider<EstoqueController, AsyncValue<void>>((ref) {
      final service = ref.read(estoqueServiceProvider);
      return EstoqueController(service);
    });
