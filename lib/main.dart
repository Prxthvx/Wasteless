import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://bpenozctewzutdmiggkk.supabase.co', // 🔑 Replace with your Supabase project URL
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJwZW5vemN0ZXd6dXRkbWlnZ2trIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTUzMzcxMTQsImV4cCI6MjA3MDkxMzExNH0.6BkfmaEOpj-CyWNn4f0PuPK654LQSJ5HnfEWJaRrnLU', // 🔑 Replace with your Supabase anon/public key
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WasteLess',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WasteLess')),
      body: const Center(
        child: Text('Supabase connected ✅'),
      ),
    );
  }
}
