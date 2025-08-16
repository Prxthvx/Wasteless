import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/user_profile.dart';
import '../dashboard/restaurant_dashboard.dart';
import '../dashboard/ngo_dashboard.dart';
import '../welcome_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  User? _user;
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? user = data.session?.user;

      if (event == AuthChangeEvent.signedIn && user != null) {
        _fetchUserProfile(user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        setState(() {
          _user = null;
          _profile = null;
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session?.user != null) {
        _user = session!.user;
        await _fetchUserProfile(_user!.id);
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final response = await SupabaseService.client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      final profile = UserProfile.fromJson(response);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (e) {
      // Profile not found, user needs to complete signup
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              ),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // User is authenticated and has a profile
    if (_user != null && _profile != null) {
      if (_profile!.role == 'restaurant') {
        return RestaurantDashboard(profile: _profile!);
      } else if (_profile!.role == 'ngo') {
        return NGODashboard(profile: _profile!);
      }
    }

    // User is not authenticated or doesn't have a profile
    return const WelcomeScreen();
  }
}
