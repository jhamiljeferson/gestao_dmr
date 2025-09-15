import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;
  SupabaseClient get client => _client!;

  Future<void> init() async {
    await Supabase.initialize(url: 'https://draqreupzpwjisvumfzr.supabase.co', 
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRyYXFyZXVwenB3amlzdnVtZnpyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQxNzIzNzYsImV4cCI6MjA2OTc0ODM3Nn0.c6z9jDT_DTWWb4gqdnNyyoNEDCekdehRa_Rx_K9ljL8');
    _client = Supabase.instance.client;
  }
}
