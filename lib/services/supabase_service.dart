import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static Future<void> init() async {
    await Supabase.initialize(
      url: 'https://bpenozctewzutdmiggkk.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwZW5vemN0ZXd6dXRkbWlnZ2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzMzcxMTQsImV4cCI6MjA3MDkxMzExNH0.6BkfmaEOpj-CyWNn4f0PuPK654LQSJ5HnfEWJaRrnLU',
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
