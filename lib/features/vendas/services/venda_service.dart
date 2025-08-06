import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../movimentacoes/models/movimentacao_estoque_model.dart';

class VendaService {
  final SupabaseClient _client = SupabaseService().client;

  // Buscar todas as vendas
  Future<List<Venda>> getAll() async {
    try {
      final response = await _client
          .from('vendas')
          .select()
          .order('data', ascending: false);
      return (response as List).map((json) => Venda.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas: $e');
    }
  }

  // Buscar venda por ID
  Future<Venda?> getById(String id) async {
    try {
      final response = await _client.from('vendas').select().eq('id', id);

      if (response.isEmpty) {
        return null;
      }

      return Venda.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao buscar venda: $e');
    }
  }

  // Buscar vendas por data
  Future<List<Venda>> getByDate(DateTime data) async {
    try {
      final dataStr = data.toIso8601String().split('T')[0];
      final response = await _client
          .from('vendas')
          .select()
          .eq('data', dataStr)
          .order('data', ascending: false);
      return (response as List).map((json) => Venda.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas por data: $e');
    }
  }

  // Buscar vendas por ponto
  Future<List<Venda>> getByPonto(String pontoId) async {
    try {
      final response = await _client
          .from('vendas')
          .select()
          .eq('ponto_id', pontoId)
          .order('data', ascending: false);
      return (response as List).map((json) => Venda.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas por ponto: $e');
    }
  }

  // Buscar vendas por vendedor
  Future<List<Venda>> getByVendedor(String vendedorId) async {
    try {
      final response = await _client
          .from('vendas')
          .select()
          .eq('vendedor_id', vendedorId)
          .order('data', ascending: false);
      return (response as List).map((json) => Venda.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendas por vendedor: $e');
    }
  }

  // Criar nova venda
  Future<Venda> create(Venda venda) async {
    try {
      // Remover o ID vazio para deixar o Supabase gerar
      final dataToInsert = {
        'data': venda.data.toIso8601String().split('T')[0],
        'ponto_id': venda.pontoId,
        'vendedor_id': venda.vendedorId,
        'troco': venda.troco,
        'valor_pix': venda.valorPix,
        'valor_dinheiro': venda.valorDinheiro,
      };

      final response = await _client
          .from('vendas')
          .insert(dataToInsert)
          .select()
          .single();

      final novaVenda = Venda.fromJson(response);

      // Registrar movimentação de criação da venda
      await _registrarMovimentacaoVendaDetalhada(
        '', // produtoId vazio para venda geral
        0, // quantidade 0 para venda geral
        'Venda criada',
        novaVenda.id,
      );

      // Nota: A atualização do estoque será feita quando os itens da venda forem criados
      // através do método createItemVenda

      return novaVenda;
    } catch (e) {
      throw Exception('Erro ao criar venda: $e');
    }
  }

  // Método para atualizar estoque quando uma venda é criada
  Future<void> _atualizarEstoqueVenda(String produtoId, int quantidade) async {
    try {
      // Verificar se já existe registro de estoque
      final estoqueExistente = await _client
          .from('estoque')
          .select('quantidade')
          .eq('produto_id', produtoId)
          .maybeSingle();

      if (estoqueExistente != null) {
        // Atualizar estoque existente (diminuir quantidade vendida)
        int novaQuantidade = estoqueExistente['quantidade'] as int;
        novaQuantidade -= quantidade;

        await _client
            .from('estoque')
            .update({'quantidade': novaQuantidade})
            .eq('produto_id', produtoId);
      } else {
        // Criar novo registro de estoque com quantidade negativa
        await _client.from('estoque').insert({
          'produto_id': produtoId,
          'quantidade': -quantidade,
        });
      }
    } catch (error) {
      print('Erro ao atualizar estoque da venda: $error');
      // Não falha a venda se o estoque falhar
    }
  }

  // Método para registrar movimentação de estoque da venda com detalhes
  Future<void> _registrarMovimentacaoVendaDetalhada(
    String produtoId,
    int quantidade,
    String operacao,
    String? vendaId,
  ) async {
    try {
      final observacao = 'VENDA: $operacao - $quantidade unidades';

      final movimentacao = MovimentacaoEstoque(
        id: '', // Será gerado pelo banco
        data: DateTime.now(),
        produtoId: produtoId.isEmpty ? 'VENDA_GERAL' : produtoId,
        tipo: 'venda',
        quantidade: quantidade,
        referenciaId: vendaId,
        observacao: observacao,
      );

      final dataToInsert = {
        'data': movimentacao.data.toIso8601String(),
        'produto_id': movimentacao.produtoId,
        'tipo': movimentacao.tipo,
        'quantidade': movimentacao.quantidade,
        'referencia_id': movimentacao.referenciaId,
        'observacao': movimentacao.observacao,
      };

      await _client.from('movimentacoes_estoque').insert(dataToInsert);
    } catch (error) {
      print('Erro ao registrar movimentação da venda: $error');
      // Não falha a venda se a movimentação falhar
    }
  }

  // Método para verificar se uma tabela existe
  Future<bool> _tabelaExiste(String nomeTabela) async {
    try {
      await _client.from(nomeTabela).select('count').limit(1);
      return true;
    } catch (error) {
      print('Tabela $nomeTabela não existe: $error');
      return false;
    }
  }

  // Atualizar venda
  Future<Venda> update(Venda venda) async {
    try {
      final response = await _client
          .from('vendas')
          .update(venda.toJson())
          .eq('id', venda.id)
          .select()
          .single();

      final vendaAtualizada = Venda.fromJson(response);

      // Registrar movimentação de edição da venda
      await _registrarMovimentacaoVendaDetalhada(
        '', // produtoId vazio para venda geral
        0, // quantidade 0 para venda geral
        'Venda editada',
        venda.id,
      );

      return vendaAtualizada;
    } catch (e) {
      throw Exception('Erro ao atualizar venda: $e');
    }
  }

  // Deletar venda
  Future<void> delete(String id) async {
    try {
      // Buscar todos os itens da venda antes de deletar
      final itens = await getItensByVenda(id);

      // Deletar a venda
      await _client.from('vendas').delete().eq('id', id);

      // Restaurar estoque de todos os itens da venda
      for (final item in itens) {
        if (item.vendidos > 0) {
          await _restaurarEstoqueVenda(item.produtoId, item.vendidos);
          // Registrar movimentação de restauração para cada item
          await _registrarMovimentacaoVendaDetalhada(
            item.produtoId,
            item.vendidos,
            'Venda excluída - Estoque restaurado',
            id,
          );
        }
      }

      // Registrar movimentação de exclusão da venda
      await _registrarMovimentacaoVendaDetalhada(
        '', // produtoId vazio para venda geral
        0, // quantidade 0 para venda geral
        'Venda excluída',
        id,
      );
    } catch (e) {
      throw Exception('Erro ao deletar venda: $e');
    }
  }

  // Buscar itens de uma venda
  Future<List<ItemVenda>> getItensByVenda(String vendaId) async {
    try {
      final response = await _client
          .from('itens_venda')
          .select()
          .eq('venda_id', vendaId)
          .order('id');
      return (response as List)
          .map((json) => ItemVenda.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar itens da venda: $e');
    }
  }

  // Criar item de venda
  Future<ItemVenda> createItem(ItemVenda item) async {
    try {
      // Calcular vendidos e subtotal
      final vendidos = ItemVenda.calcularVendidos(
        item.retirada,
        item.reposicao,
        item.retorno,
      );
      final subtotal = ItemVenda.calcularSubtotal(vendidos, item.precoUnitario);

      // Remover o ID vazio para deixar o Supabase gerar
      final dataToInsert = {
        'venda_id': item.vendaId,
        'produto_id': item.produtoId,
        'retirada': item.retirada,
        'reposicao': item.reposicao,
        'retorno': item.retorno,
        'preco_unitario': item.precoUnitario,
        'vendidos': vendidos,
        'subtotal': subtotal,
      };

      final response = await _client
          .from('itens_venda')
          .insert(dataToInsert)
          .select()
          .single();

      final novoItem = ItemVenda.fromJson(response);

      // Atualizar estoque (diminuir quantidade vendida)
      await _atualizarEstoqueVenda(item.produtoId, vendidos);
      // Registrar movimentação de criação
      await _registrarMovimentacaoVendaDetalhada(
        item.produtoId,
        vendidos,
        'Item criado',
        item.vendaId,
      );

      return novoItem;
    } catch (e) {
      throw Exception('Erro ao criar item de venda: $e');
    }
  }

  // Atualizar item de venda
  Future<ItemVenda> updateItem(ItemVenda item) async {
    try {
      // Buscar item atual para calcular diferença no estoque
      final itemAtual = await _client
          .from('itens_venda')
          .select('vendidos')
          .eq('id', item.id)
          .single();

      final vendidosAtual = itemAtual['vendidos'] as int;

      // Calcular vendidos e subtotal
      final vendidos = ItemVenda.calcularVendidos(
        item.retirada,
        item.reposicao,
        item.retorno,
      );
      final subtotal = ItemVenda.calcularSubtotal(vendidos, item.precoUnitario);

      final dataToUpdate = {
        'venda_id': item.vendaId,
        'produto_id': item.produtoId,
        'retirada': item.retirada,
        'reposicao': item.reposicao,
        'retorno': item.retorno,
        'preco_unitario': item.precoUnitario,
        'vendidos': vendidos,
        'subtotal': subtotal,
      };

      final response = await _client
          .from('itens_venda')
          .update(dataToUpdate)
          .eq('id', item.id)
          .select()
          .single();

      final itemAtualizado = ItemVenda.fromJson(response);

      // Atualizar estoque (diferença entre vendidos antigo e novo)
      final diferencaVendidos = vendidos - vendidosAtual;
      if (diferencaVendidos != 0) {
        await _atualizarEstoqueVenda(item.produtoId, diferencaVendidos);
        // Registrar movimentação de ajuste
        await _registrarMovimentacaoVendaDetalhada(
          item.produtoId,
          diferencaVendidos.abs(),
          diferencaVendidos > 0
              ? 'Item editado - Venda aumentada'
              : 'Item editado - Venda reduzida',
          item.vendaId,
        );
      }

      return itemAtualizado;
    } catch (e) {
      throw Exception('Erro ao atualizar item de venda: $e');
    }
  }

  // Deletar item de venda
  Future<void> deleteItem(String id) async {
    try {
      // Buscar item antes de deletar para restaurar estoque
      final item = await _client
          .from('itens_venda')
          .select('produto_id, vendidos')
          .eq('id', id)
          .single();

      await _client.from('itens_venda').delete().eq('id', id);

      // Restaurar estoque (adicionar quantidade vendida de volta)
      final produtoId = item['produto_id'] as String;
      final vendidos = item['vendidos'] as int;

      if (vendidos > 0) {
        await _restaurarEstoqueVenda(produtoId, vendidos);
        // Registrar movimentação de restauração
        await _registrarMovimentacaoVendaDetalhada(
          produtoId,
          vendidos,
          'Item removido - Estoque restaurado',
          null,
        );
      }
    } catch (e) {
      throw Exception('Erro ao deletar item de venda: $e');
    }
  }

  // Método para restaurar estoque quando um item de venda é deletado
  Future<void> _restaurarEstoqueVenda(String produtoId, int quantidade) async {
    try {
      // Verificar se já existe registro de estoque
      final estoqueExistente = await _client
          .from('estoque')
          .select('quantidade')
          .eq('produto_id', produtoId)
          .maybeSingle();

      if (estoqueExistente != null) {
        // Restaurar estoque existente (adicionar quantidade de volta)
        int novaQuantidade = estoqueExistente['quantidade'] as int;
        novaQuantidade += quantidade;

        await _client
            .from('estoque')
            .update({'quantidade': novaQuantidade})
            .eq('produto_id', produtoId);
      } else {
        // Criar novo registro de estoque com quantidade restaurada
        await _client.from('estoque').insert({
          'produto_id': produtoId,
          'quantidade': quantidade,
        });
      }
    } catch (error) {
      print('Erro ao restaurar estoque da venda: $error');
      // Não falha a deleção se o estoque falhar
    }
  }

  // Buscar venda com itens (join)
  Future<Map<String, dynamic>?> getVendaComItens(String vendaId) async {
    try {
      final vendaResponse = await _client
          .from('vendas')
          .select()
          .eq('id', vendaId)
          .single();

      final itensResponse = await _client
          .from('itens_venda')
          .select()
          .eq('venda_id', vendaId);

      return {
        'venda': Venda.fromJson(vendaResponse),
        'itens': (itensResponse as List)
            .map((json) => ItemVenda.fromJson(json))
            .toList(),
      };
    } catch (e) {
      throw Exception('Erro ao buscar venda com itens: $e');
    }
  }
}
