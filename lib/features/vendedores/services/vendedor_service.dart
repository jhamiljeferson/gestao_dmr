import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendedor_model.dart';
import '../../../core/services/supabase_service.dart';

class VendedorService {
  final SupabaseClient _client = SupabaseService().client;

  // Buscar todos os vendedores
  Future<List<Vendedor>> getAll() async {
    try {
      final response = await _client.from('vendedores').select().order('nome');

      return (response as List).map((json) => Vendedor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendedores: $e');
    }
  }

  // Buscar vendedor por ID
  Future<Vendedor?> getById(String id) async {
    try {
      final response = await _client.from('vendedores').select().eq('id', id);

      if (response.isEmpty) {
        return null;
      }

      return Vendedor.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao buscar vendedor: $e');
    }
  }

  // Criar novo vendedor
  Future<Vendedor> create(Vendedor vendedor) async {
    try {
      // Remover o ID vazio para deixar o Supabase gerar
      final dataToInsert = {'nome': vendedor.nome};

      final response = await _client
          .from('vendedores')
          .insert(dataToInsert)
          .select()
          .single();

      return Vendedor.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar vendedor: $e');
    }
  }

  // Atualizar vendedor
  Future<Vendedor> update(Vendedor vendedor) async {
    try {
      final response = await _client
          .from('vendedores')
          .update(vendedor.toJson())
          .eq('id', vendedor.id)
          .select()
          .single();

      return Vendedor.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar vendedor: $e');
    }
  }

  // Deletar vendedor
  Future<void> delete(String id) async {
    try {
      await _client.from('vendedores').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar vendedor: $e');
    }
  }

  // Buscar vendedores por nome (busca parcial)
  Future<List<Vendedor>> searchByName(String nome) async {
    try {
      final response = await _client
          .from('vendedores')
          .select()
          .ilike('nome', '%$nome%')
          .order('nome');

      return (response as List).map((json) => Vendedor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar vendedores: $e');
    }
  }
}
