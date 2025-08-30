import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _status = 'Checking...';
  List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _checkDatabase();
  }

  Future<void> _checkDatabase() async {
    _addLog('Starting database check...');
    
    try {
      // Check if we can connect to Supabase
      _addLog('Testing Supabase connection...');
      final session = SupabaseService.client.auth.currentSession;
      _addLog('Current session: ${session != null ? 'Active' : 'None'}');
      
      // Check if profiles table exists
      _addLog('Checking profiles table...');
      try {
        final response = await SupabaseService.client
            .from('profiles')
            .select('count')
            .limit(1);
        _addLog('✅ Profiles table exists and is accessible');
      } catch (e) {
        _addLog('❌ Profiles table error: $e');
        setState(() {
          _status = 'Database setup incomplete';
        });
        return;
      }
      
      // Check if inventory_items table exists
      _addLog('Checking inventory_items table...');
      try {
        final response = await SupabaseService.client
            .from('inventory_items')
            .select('count')
            .limit(1);
        _addLog('✅ Inventory_items table exists and is accessible');
      } catch (e) {
        _addLog('❌ Inventory_items table error: $e');
      }
      
      // Check if donations table exists
      _addLog('Checking donations table...');
      try {
        final response = await SupabaseService.client
            .from('donations')
            .select('count')
            .limit(1);
        _addLog('✅ Donations table exists and is accessible');
      } catch (e) {
        _addLog('❌ Donations table error: $e');
      }
      
      // Check if donation_claims table exists
      _addLog('Checking donation_claims table...');
      try {
        final response = await SupabaseService.client
            .from('donation_claims')
            .select('count')
            .limit(1);
        _addLog('✅ Donation_claims table exists and is accessible');
      } catch (e) {
        _addLog('❌ Donation_claims table error: $e');
      }
      
      setState(() {
        _status = 'Database check complete';
      });
      _addLog('✅ Database check completed successfully');
      
    } catch (e) {
      _addLog('❌ Database check failed: $e');
      setState(() {
        _status = 'Database check failed';
      });
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.add('${DateTime.now().toString().substring(11, 19)}: $message');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status: $_status',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _checkDatabase,
                      child: const Text('Recheck Database'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Logs:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        _logs[index],
                        style: const TextStyle(fontFamily: 'monospace'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '1. If tables show errors, upload database_setup.sql to Supabase\n'
                      '2. Go to Supabase Dashboard → SQL Editor → New Query\n'
                      '3. Copy the entire database_setup.sql content\n'
                      '4. Paste and click "Run"\n'
                      '5. Come back and recheck the database',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
