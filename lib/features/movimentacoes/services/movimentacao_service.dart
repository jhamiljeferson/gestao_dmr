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

  // Método para verificar se uma tabela existe e tratar erros
  Future<void> _verificarTabela(String nomeTabela) async {
    try {
      await _supabase.from(nomeTabela).select('count').limit(1);
    } catch (error) {
      print(
        'Aviso: Tabela $nomeTabela não existe ou não está acessível: $error',
      );
      // Não falha a operação, apenas registra o aviso
    }
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

  // Método para verificar se uma tabela existe
  Future<bool> _tabelaExiste(String nomeTabela) async {
    try {
      await _supabase.from(nomeTabela).select('count').limit(1);
      return true;
    } catch (error) {
      print('Tabela $nomeTabela não existe: $error');
      return false;
    }
  }

  // Deletar movimentação
  Future<void> delete(String id) async {
    try {
      // Primeiro, buscar a movimentação para obter os dados antes de deletar
      final movimentacao = await getById(id);
      if (movimentacao == null) {
        throw Exception('Movimentação não encontrada');
      }

      // Deletar a movimentação
      await _supabase.from('movimentacoes_estoque').delete().eq('id', id);

      // Reverter o estoque baseado no tipo de movimentação
      await _reverterEstoque(
        movimentacao.produtoId,
        movimentacao.tipo,
        movimentacao.quantidade,
      );

      // Registrar a reversão no banco de movimentação
      await _registrarReversao(movimentacao);
    } catch (error) {
      print('Erro ao deletar movimentação: $error');
      rethrow;
    }
  }

  // Método para reverter estoque quando uma movimentação é deletada
  Future<void> _reverterEstoque(
    String produtoId,
    String tipo,
    int quantidade,
  ) async {
    try {
      // Verificar se existe registro de estoque
      final estoqueExistente = await _supabase
          .from('estoque')
          .select('quantidade')
          .eq('produto_id', produtoId)
          .maybeSingle();

      if (estoqueExistente != null) {
        // Reverter o estoque baseado no tipo
        int novaQuantidade = estoqueExistente['quantidade'] as int;

        if (tipo == 'entrada') {
          // Se era uma entrada, subtrair a quantidade
          novaQuantidade -= quantidade;
        } else if (tipo == 'saida') {
          // Se era uma saída, adicionar a quantidade de volta
          novaQuantidade += quantidade;
        }

        await _supabase
            .from('estoque')
            .update({'quantidade': novaQuantidade})
            .eq('produto_id', produtoId);
      }
    } catch (error) {
      print('Erro ao reverter estoque: $error');
      rethrow;
    }
  }

  // Método para registrar a reversão no banco de movimentação
  Future<void> _registrarReversao(
    MovimentacaoEstoque movimentacaoOriginal,
  ) async {
    try {
      final observacao =
          'REVERSÃO: ${movimentacaoOriginal.tipo.toUpperCase()} deletada - ${movimentacaoOriginal.quantidade} unidades';

      final movimentacaoReversao = MovimentacaoEstoque(
        id: '',
        data: DateTime.now(),
        produtoId: movimentacaoOriginal.produtoId,
        tipo: movimentacaoOriginal.tipo == 'entrada' ? 'saida' : 'entrada',
        quantidade: movimentacaoOriginal.quantidade,
        observacao: observacao,
      );

      final data = movimentacaoReversao.toJson();
      data.remove('id'); // Remove o ID para o Supabase gerar

      await _supabase
          .from('movimentacoes_estoque')
          .insert(data)
          .select()
          .single();
    } catch (error) {
      print('Erro ao registrar reversão: $error');
      // Não falha a operação principal se a reversão falhar
    }
  }

  // Atualizar movimentação com ajuste de estoque
  Future<MovimentacaoEstoque> update(MovimentacaoEstoque movimentacao) async {
    try {
      // Buscar a movimentação original para calcular a diferença
      final movimentacaoOriginal = await getById(movimentacao.id);
      if (movimentacaoOriginal == null) {
        throw Exception('Movimentação original não encontrada');
      }

      // Calcular a diferença na quantidade
      final diferencaQuantidade =
          movimentacao.quantidade - movimentacaoOriginal.quantidade;

      // Atualizar a movimentação
      final response = await _supabase
          .from('movimentacoes_estoque')
          .update(movimentacao.toJson())
          .eq('id', movimentacao.id)
          .select()
          .single();

      // Ajustar o estoque baseado na diferença
      if (diferencaQuantidade != 0) {
        await _ajustarEstoque(
          movimentacao.produtoId,
          movimentacao.tipo,
          diferencaQuantidade,
        );

        // Registrar o ajuste no banco de movimentação
        await _registrarAjuste(movimentacao, diferencaQuantidade);
      }

      return MovimentacaoEstoque.fromJson(response);
    } catch (error) {
      print('Erro ao atualizar movimentação: $error');
      rethrow;
    }
  }

  // Método para ajustar estoque quando uma movimentação é editada
  Future<void> _ajustarEstoque(
    String produtoId,
    String tipo,
    int diferencaQuantidade,
  ) async {
    try {
      // Verificar se existe registro de estoque
      final estoqueExistente = await _supabase
          .from('estoque')
          .select('quantidade')
          .eq('produto_id', produtoId)
          .maybeSingle();

      if (estoqueExistente != null) {
        // Ajustar o estoque baseado no tipo e diferença
        int novaQuantidade = estoqueExistente['quantidade'] as int;

        if (tipo == 'entrada') {
          novaQuantidade += diferencaQuantidade;
        } else if (tipo == 'saida') {
          novaQuantidade -= diferencaQuantidade;
        }

        await _supabase
            .from('estoque')
            .update({'quantidade': novaQuantidade})
            .eq('produto_id', produtoId);
      }
    } catch (error) {
      print('Erro ao ajustar estoque: $error');
      rethrow;
    }
  }

  // Método para registrar o ajuste no banco de movimentação
  Future<void> _registrarAjuste(
    MovimentacaoEstoque movimentacao,
    int diferencaQuantidade,
  ) async {
    try {
      final observacao =
          'AJUSTE: ${movimentacao.tipo.toUpperCase()} editada - diferença de $diferencaQuantidade unidades';

      final movimentacaoAjuste = MovimentacaoEstoque(
        id: '',
        data: DateTime.now(),
        produtoId: movimentacao.produtoId,
        tipo: diferencaQuantidade > 0
            ? movimentacao.tipo
            : (movimentacao.tipo == 'entrada' ? 'saida' : 'entrada'),
        quantidade: diferencaQuantidade.abs(),
        observacao: observacao,
      );

      final data = movimentacaoAjuste.toJson();
      data.remove('id'); // Remove o ID para o Supabase gerar

      await _supabase
          .from('movimentacoes_estoque')
          .insert(data)
          .select()
          .single();
    } catch (error) {
      print('Erro ao registrar ajuste: $error');
      // Não falha a operação principal se o ajuste falhar
    }
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
