import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/movimentacao_estoque_model.dart';
import '../services/movimentacao_service.dart';

final movimentacaoServiceProvider = Provider<MovimentacaoService>((ref) {
  return MovimentacaoService();
});

// Provider para entradas
final entradasProvider = FutureProvider<List<Map<String, dynamic>>>((
  ref,
) async {
  try {
    print('Provider entradasProvider executando...');
    final service = ref.read(movimentacaoServiceProvider);
    final result = await service.getWithProduto('entrada');
    print('Provider entradasProvider resultado: ${result.length} entradas');
    return result;
  } catch (error) {
    print('Erro no provider entradasProvider: $error');
    rethrow;
  }
});

// Provider para saídas
final saidasProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  try {
    print('Provider saidasProvider executando...');
    final service = ref.read(movimentacaoServiceProvider);
    final result = await service.getWithProduto('saida');
    print('Provider saidasProvider resultado: ${result.length} saídas');
    return result;
  } catch (error) {
    print('Erro no provider saidasProvider: $error');
    rethrow;
  }
});

// Provider para todas as movimentações com filtros
final movimentacoesFiltradasProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((
      ref,
      filtros,
    ) async {
      try {
        print('Provider movimentacoesFiltradasProvider executando...');
        final service = ref.read(movimentacaoServiceProvider);
        final result = await service.getAllWithProduto(
          tipo: filtros['tipo'],
          produtoId: filtros['produtoId'],
          dataInicio: filtros['dataInicio'],
          dataFim: filtros['dataFim'],
        );
        print(
          'Provider movimentacoesFiltradasProvider resultado: ${result.length} movimentações',
        );
        return result;
      } catch (error) {
        print('Erro no provider movimentacoesFiltradasProvider: $error');
        rethrow;
      }
    });

class MovimentacaoController extends StateNotifier<AsyncValue<void>> {
  final MovimentacaoService _service;

  MovimentacaoController(this._service) : super(const AsyncValue.data(null));

  // Criar entrada
  Future<void> createEntrada({
    required String produtoId,
    required int quantidade,
    String? observacao,
  }) async {
    state = const AsyncValue.loading();

    try {
      final movimentacao = MovimentacaoEstoque(
        id: '',
        data: DateTime.now(),
        produtoId: produtoId,
        tipo: 'entrada',
        quantidade: quantidade,
        observacao: observacao,
      );

      await _service.create(movimentacao);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Criar saída
  Future<void> createSaida({
    required String produtoId,
    required int quantidade,
    String? observacao,
  }) async {
    state = const AsyncValue.loading();

    try {
      final movimentacao = MovimentacaoEstoque(
        id: '',
        data: DateTime.now(),
        produtoId: produtoId,
        tipo: 'saida',
        quantidade: quantidade,
        observacao: observacao,
      );

      await _service.create(movimentacao);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Deletar movimentação
  Future<void> deleteMovimentacao(String id) async {
    state = const AsyncValue.loading();

    try {
      await _service.delete(id);
      state = const AsyncValue.data(null);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  // Método de teste para verificar conexão
  Future<void> testConnection() async {
    try {
      print('Testando conexão com movimentações...');
      final result = await _service.getByTipo('saida');
      print('Teste de conexão - Saídas encontradas: ${result.length}');
    } catch (error) {
      print('Erro no teste de conexão: $error');
      rethrow;
    }
  }
}

final movimentacaoControllerProvider =
    StateNotifierProvider<MovimentacaoController, AsyncValue<void>>((ref) {
      final service = ref.read(movimentacaoServiceProvider);
      return MovimentacaoController(service);
    });
