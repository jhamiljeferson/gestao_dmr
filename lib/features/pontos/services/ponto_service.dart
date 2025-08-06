import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ponto_model.dart';
import '../../../core/services/supabase_service.dart';

class PontoService {
  final SupabaseClient _client = SupabaseService().client;

  // Buscar todos os pontos
  Future<List<Ponto>> getAll() async {
    try {
      final response = await _client.from('pontos').select().order('nome');

      return (response as List).map((json) => Ponto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar pontos: $e');
    }
  }

  // Buscar ponto por ID
  Future<Ponto?> getById(String id) async {
    try {
      final response = await _client.from('pontos').select().eq('id', id);

      if (response.isEmpty) {
        return null;
      }

      return Ponto.fromJson(response.first);
    } catch (e) {
      throw Exception('Erro ao buscar ponto: $e');
    }
  }

  // Criar novo ponto
  Future<Ponto> create(Ponto ponto) async {
    try {
      // Remover o ID vazio para deixar o Supabase gerar
      final dataToInsert = {'nome': ponto.nome};

      final response = await _client
          .from('pontos')
          .insert(dataToInsert)
          .select()
          .single();

      return Ponto.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao criar ponto: $e');
    }
  }

  // Atualizar ponto
  Future<Ponto> update(Ponto ponto) async {
    try {
      final response = await _client
          .from('pontos')
          .update(ponto.toJson())
          .eq('id', ponto.id)
          .select()
          .single();

      return Ponto.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao atualizar ponto: $e');
    }
  }

  // Deletar ponto
  Future<void> delete(String id) async {
    try {
      await _client.from('pontos').delete().eq('id', id);
    } catch (e) {
      throw Exception('Erro ao deletar ponto: $e');
    }
  }

  // Buscar pontos por nome (busca parcial)
  Future<List<Ponto>> searchByName(String nome) async {
    try {
      final response = await _client
          .from('pontos')
          .select()
          .ilike('nome', '%$nome%')
          .order('nome');

      return (response as List).map((json) => Ponto.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar pontos: $e');
    }
  }
}
