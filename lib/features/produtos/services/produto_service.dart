import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produto_model.dart';
import '../../../core/services/supabase_service.dart';

class ProdutoService {
  final SupabaseClient _client = SupabaseService().client;

  // Buscar todos os produtos
  Future<List<Produto>> getAll() async {
    try {
      final response = await _client.from('produtos').select().order('nome');
      return (response as List).map((json) => Produto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }

  // Buscar produto por ID
  Future<Produto?> getById(String id) async {
    try {
      final response = await _client.from('produtos').select().eq('id', id);

      if (response.isEmpty) {
        return null;
      }

      return Produto.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao buscar produto: $e');
    }
  }

  // Buscar produto por código
  Future<Produto?> getByCodigo(int codigo) async {
    try {
      final response = await _client
          .from('produtos')
          .select()
          .eq('codigo', codigo);

      if (response.isEmpty) {
        return null;
      }

      return Produto.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao buscar produto por código: $e');
    }
  }

  // Criar novo produto
  Future<Produto> create(Produto produto) async {
    try {
      // Verificar se o código já existe
      final existing = await getByCodigo(produto.codigo);
      if (existing != null) {
        throw Exception('Já existe um produto com o código ${produto.codigo}');
      }

      // Remover o ID vazio para deixar o Supabase gerar
      final dataToInsert = {'codigo': produto.codigo, 'nome': produto.nome};

      final response = await _client
          .from('produtos')
          .insert(dataToInsert)
          .select()
          .single();

      return Produto.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar produto: $e');
    }
  }

  // Atualizar produto
  Future<Produto> update(Produto produto) async {
    try {
      // Verificar se o código já existe em outro produto
      final existing = await getByCodigo(produto.codigo);
      if (existing != null && existing.id != produto.id) {
        throw Exception('Já existe um produto com o código ${produto.codigo}');
      }

      final response = await _client
          .from('produtos')
          .update(produto.toJson())
          .eq('id', produto.id)
          .select()
          .single();

      return Produto.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  // Deletar produto
  Future<void> delete(String id) async {
    try {
      await _client.from('produtos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar produto: $e');
    }
  }

  // Buscar produtos por nome (busca parcial)
  Future<List<Produto>> searchByName(String nome) async {
    try {
      final response = await _client
          .from('produtos')
          .select()
          .ilike('nome', '%$nome%')
          .order('nome');

      return (response as List).map((json) => Produto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }
}
