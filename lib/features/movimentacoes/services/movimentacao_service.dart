import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/movimentacao_estoque_model.dart';

class MovimentacaoService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Buscar todas as movimentações de um tipo específico
  Future<List<MovimentacaoEstoque>> getByTipo(String tipo) async {
    final response = await _supabase
        .from('movimentacoes_estoque')
        .select('*')
        .eq('tipo', tipo)
        .order('data', ascending: false);

    return response.map((json) => MovimentacaoEstoque.fromJson(json)).toList();
  }

  // Buscar movimentação por ID
  Future<MovimentacaoEstoque?> getById(String id) async {
    final response = await _supabase
        .from('movimentacoes_estoque')
        .select('*')
        .eq('id', id);

    if (response.isEmpty) return null;
    return MovimentacaoEstoque.fromJson(response.first);
  }

  // Criar nova movimentação
  Future<MovimentacaoEstoque> create(MovimentacaoEstoque movimentacao) async {
    final data = movimentacao.toJson();
    data.remove('id'); // Remove o ID para o Supabase gerar

    final response = await _supabase
        .from('movimentacoes_estoque')
        .insert(data)
        .select()
        .single();

    final novaMovimentacao = MovimentacaoEstoque.fromJson(response);

    // Atualizar estoque automaticamente
    await _atualizarEstoque(
      movimentacao.produtoId,
      movimentacao.tipo,
      movimentacao.quantidade,
    );

    return novaMovimentacao;
  }

  // Método para atualizar estoque
  Future<void> _atualizarEstoque(
    String produtoId,
    String tipo,
    int quantidade,
  ) async {
    try {
      // Verificar se já existe registro de estoque
      final estoqueExistente = await _supabase
          .from('estoque')
          .select('quantidade')
          .eq('produto_id', produtoId)
          .maybeSingle();

      if (estoqueExistente != null) {
        // Atualizar estoque existente
        int novaQuantidade = estoqueExistente['quantidade'] as int;

        if (tipo == 'entrada') {
          novaQuantidade += quantidade;
        } else if (tipo == 'saida') {
          novaQuantidade -= quantidade;
        }

        await _supabase
            .from('estoque')
            .update({'quantidade': novaQuantidade})
            .eq('produto_id', produtoId);
      } else {
        // Criar novo registro de estoque
        int quantidadeInicial = 0;
        if (tipo == 'entrada') {
          quantidadeInicial = quantidade;
        } else if (tipo == 'saida') {
          quantidadeInicial = -quantidade;
        }

        await _supabase.from('estoque').insert({
          'produto_id': produtoId,
          'quantidade': quantidadeInicial,
        });
      }
    } catch (error) {
      print('Erro ao atualizar estoque: $error');
      // Não falha a movimentação se o estoque falhar
    }
  }

  // Atualizar movimentação
  Future<MovimentacaoEstoque> update(MovimentacaoEstoque movimentacao) async {
    final response = await _supabase
        .from('movimentacoes_estoque')
        .update(movimentacao.toJson())
        .eq('id', movimentacao.id)
        .select()
        .single();

    return MovimentacaoEstoque.fromJson(response);
  }

  // Deletar movimentação
  Future<void> delete(String id) async {
    await _supabase.from('movimentacoes_estoque').delete().eq('id', id);
  }

  // Buscar movimentações com dados do produto
  Future<List<Map<String, dynamic>>> getWithProduto(String tipo) async {
    try {
      print('Buscando movimentações do tipo: $tipo');
      final response = await _supabase
          .from('movimentacoes_estoque')
          .select('''
            *,
            produtos:produto_id (
              id,
              codigo,
              nome
            )
          ''')
          .eq('tipo', tipo)
          .order('data', ascending: false);

      print('Resposta do Supabase para $tipo: ${response.length} registros');
      if (response.isNotEmpty) {
        print('Primeiro registro: ${response.first}');
      }

      // Converter explicitamente para List<Map<String, dynamic>>
      final List<Map<String, dynamic>> result = response
          .cast<Map<String, dynamic>>();
      return result;
    } catch (error) {
      print('Erro ao buscar movimentações do tipo $tipo: $error');
      rethrow;
    }
  }

  // Buscar todas as movimentações com dados do produto
  Future<List<Map<String, dynamic>>> getAllWithProduto({
    String? tipo,
    String? produtoId,
    DateTime? dataInicio,
    DateTime? dataFim,
  }) async {
    try {
      print('Buscando todas as movimentações com filtros');

      var query = _supabase.from('movimentacoes_estoque').select('''
            *,
            produtos:produto_id (
              id,
              codigo,
              nome
            )
          ''');

      // Aplicar filtros
      if (tipo != null && tipo.isNotEmpty) {
        query = query.eq('tipo', tipo);
      }

      if (produtoId != null && produtoId.isNotEmpty) {
        query = query.eq('produto_id', produtoId);
      }

      if (dataInicio != null) {
        query = query.gte('data', dataInicio.toIso8601String().split('T')[0]);
      }

      if (dataFim != null) {
        query = query.lte('data', dataFim.toIso8601String().split('T')[0]);
      }

      final response = await query.order('data', ascending: false);

      print('Resposta do Supabase: ${response.length} registros');

      // Converter explicitamente para List<Map<String, dynamic>>
      final List<Map<String, dynamic>> result = response
          .cast<Map<String, dynamic>>();
      return result;
    } catch (error) {
      print('Erro ao buscar movimentações: $error');
      rethrow;
    }
  }
}
