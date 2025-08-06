import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estoque_model.dart';

class EstoqueService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Buscar todo o estoque com dados do produto
  Future<List<Map<String, dynamic>>> getAllWithProduto() async {
    try {
      final response = await _supabase
          .from('estoque')
          .select('''
            *,
            produtos:produto_id (
              id,
              codigo,
              nome
            )
          ''')
          .order('quantidade', ascending: false);

      return response.cast<Map<String, dynamic>>();
    } catch (error) {
      print('Erro ao buscar estoque: $error');
      rethrow;
    }
  }

  // Buscar estoque de um produto específico
  Future<Estoque?> getByProdutoId(String produtoId) async {
    try {
      final response = await _supabase
          .from('estoque')
          .select('*')
          .eq('produto_id', produtoId)
          .single();

      return Estoque.fromJson(response);
    } catch (error) {
      if (error.toString().contains('No rows found')) {
        return null;
      }
      print('Erro ao buscar estoque do produto: $error');
      rethrow;
    }
  }

  // Atualizar quantidade de estoque manualmente
  Future<Estoque> updateQuantidade(String produtoId, int novaQuantidade) async {
    try {
      final response = await _supabase
          .from('estoque')
          .update({'quantidade': novaQuantidade})
          .eq('produto_id', produtoId)
          .select()
          .single();

      return Estoque.fromJson(response);
    } catch (error) {
      print('Erro ao atualizar estoque: $error');
      rethrow;
    }
  }

  // Criar registro de estoque para produto
  Future<Estoque> create(String produtoId, int quantidade) async {
    try {
      final data = {'produto_id': produtoId, 'quantidade': quantidade};

      final response = await _supabase
          .from('estoque')
          .insert(data)
          .select()
          .single();

      return Estoque.fromJson(response);
    } catch (error) {
      print('Erro ao criar estoque: $error');
      rethrow;
    }
  }

  // Buscar produtos com estoque baixo (menos de 10 unidades)
  Future<List<Map<String, dynamic>>> getEstoqueBaixo() async {
    try {
      final response = await _supabase
          .from('estoque')
          .select('''
            *,
            produtos:produto_id (
              id,
              codigo,
              nome
            )
          ''')
          .lt('quantidade', 10)
          .order('quantidade', ascending: true);

      return response.cast<Map<String, dynamic>>();
    } catch (error) {
      print('Erro ao buscar estoque baixo: $error');
      rethrow;
    }
  }

  // Buscar produtos sem estoque
  Future<List<Map<String, dynamic>>> getSemEstoque() async {
    try {
      final response = await _supabase
          .from('estoque')
          .select('''
            *,
            produtos:produto_id (
              id,
              codigo,
              nome
            )
          ''')
          .eq('quantidade', 0)
          .order('produto_id');

      return response.cast<Map<String, dynamic>>();
    } catch (error) {
      print('Erro ao buscar produtos sem estoque: $error');
      rethrow;
    }
  }

  // Método para testar se a tabela estoque existe
  Future<bool> testarTabelaEstoque() async {
    try {
      final response = await _supabase.from('estoque').select('count').limit(1);

      print('Tabela estoque existe e está acessível');
      return true;
    } catch (error) {
      print('Erro ao acessar tabela estoque: $error');
      return false;
    }
  }

  // Método para criar estoque manualmente para um produto
  Future<void> criarEstoqueManual(String produtoId) async {
    try {
      print('Criando estoque manual para produto: $produtoId');
      await _supabase.from('estoque').insert({
        'produto_id': produtoId,
        'quantidade': 0,
      });
      print('Estoque criado manualmente com sucesso');
    } catch (error) {
      print('Erro ao criar estoque manual: $error');
      rethrow;
    }
  }
}
