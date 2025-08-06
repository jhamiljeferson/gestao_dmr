import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/venda_model.dart';
import '../models/item_venda_model.dart';
import '../../../core/services/supabase_service.dart';

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

  // Atualizar venda
  Future<Venda> update(Venda venda) async {
    try {
      final response = await _client
          .from('vendas')
          .update(venda.toJson())
          .eq('id', venda.id)
          .select()
          .single();

      return Venda.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar venda: $e');
    }
  }

  // Deletar venda
  Future<void> delete(String id) async {
    try {
      await _client.from('vendas').delete().eq('id', id);
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
