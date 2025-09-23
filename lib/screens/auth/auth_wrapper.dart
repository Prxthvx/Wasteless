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
        if (mounted) {
          setState(() {
            _user = null;
            _profile = null;
            _isLoading = false;
          });
        }
      }
    });
  }

  Future<void> _checkAuthState() async {
    try {
      final session = SupabaseService.client.auth.currentSession;
      final user = session?.user;
      if (user != null) {
        _user = user;
        await _fetchUserProfile(user.id);
      } else {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
      if (mounted) {
        setState(() {
          _profile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Profile not found, create one automatically
      try {
        final user = SupabaseService.client.auth.currentUser;
        if (user != null) {
          await SupabaseService.client
              .from('profiles')
              .insert({
                'id': user.id,
                'name': user.email?.split('@')[0] ?? 'User',
                'role': 'restaurant', // Default to restaurant
                'location': 'Unknown',
                'email': user.email ?? '',
              });

          // Fetch the newly created profile
          final newResponse = await SupabaseService.client
              .from('profiles')
              .select()
              .eq('id', userId)
              .single();

          final newProfile = UserProfile.fromJson(newResponse);
          if (mounted) {
            setState(() {
              _profile = newProfile;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } catch (profileError) {
        // If profile creation fails, still show welcome screen
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
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
      if (_profile?.role == 'restaurant' && _profile != null) {
        return RestaurantDashboard(profile: _profile!);
      } else if (_profile?.role == 'ngo' && _profile != null) {
        return NGODashboard(profile: _profile!);
      }
    }

    // User is not authenticated or doesn't have a profile
    return const WelcomeScreen();
  }
}
