# WasteLess Authentication Setup Guide

This document outlines the authentication system implementation for the WasteLess app.

## 🎯 Features Implemented

### ✅ Authentication System
- **Login Screen**: Email + password authentication with Supabase
- **Signup Screen**: Collects email, password, name, role (Restaurant/NGO), and location
- **Profile Management**: User profiles stored in Supabase `profiles` table
- **Role-Based Navigation**: Automatic routing to appropriate dashboard based on user role

### ✅ Role-Based Dashboards
- **Restaurant Dashboard**: 
  - Tabs: Inventory | Donations | Notifications
  - Placeholder UI for future features
- **NGO Dashboard**:
  - Tabs: Nearby Restaurants | Donations Available | Donations Received
  - Placeholder UI for future features

### ✅ User Experience
- **Welcome Screen**: Beautiful onboarding with app introduction
- **Auth Wrapper**: Handles authentication state and routing
- **Logout Functionality**: Secure logout with proper state management

## 🗄️ Database Setup

### 1. Run the SQL Script
Execute the `database_setup.sql` script in your Supabase SQL editor:

```sql
-- This creates the profiles table with proper RLS policies
-- Run the entire script in Supabase SQL Editor
```

### 2. Verify Table Structure
The `profiles` table should have these columns:
- `id` (UUID, Primary Key, references auth.users)
- `email` (TEXT, NOT NULL)
- `name` (TEXT, NOT NULL)
- `role` (TEXT, NOT NULL, CHECK constraint for 'restaurant' or 'ngo')
- `location` (TEXT, NOT NULL)
- `created_at` (TIMESTAMP WITH TIME ZONE)
- `updated_at` (TIMESTAMP WITH TIME ZONE)

## 🚀 How to Test

### 1. Run the App
```bash
flutter pub get
flutter run
```

### 2. Test User Flow
1. **New User**: 
   - App opens to Welcome Screen
   - Click "Get Started" → Signup Screen
   - Fill form with role selection
   - Should redirect to appropriate dashboard

2. **Existing User**:
   - App opens to Welcome Screen
   - Click "I already have an account" → Login Screen
   - Enter credentials
   - Should redirect to appropriate dashboard

3. **Role-Based Routing**:
   - Restaurant users → Restaurant Dashboard
   - NGO users → NGO Dashboard

### 3. Test Logout
- Click logout button in dashboard
- Should return to Welcome Screen

## 📁 File Structure

```
lib/
├── main.dart                    # App entry point with routing
├── models/
│   └── user_profile.dart        # User profile data model
├── services/
│   └── supabase_service.dart    # Supabase client configuration
└── screens/
    ├── auth/
    │   ├── auth_wrapper.dart    # Authentication state management
    │   ├── login_screen.dart    # Login form
    │   └── signup_screen.dart   # Signup form
    ├── dashboard/
    │   ├── restaurant_dashboard.dart  # Restaurant user interface
    │   └── ngo_dashboard.dart         # NGO user interface
    └── welcome_screen.dart      # App introduction screen
```

## 🔧 Configuration

### Supabase Setup
1. Ensure Auth is enabled in your Supabase project
2. Update Supabase URL and anon key in `lib/services/supabase_service.dart`
3. Run the database setup script

### Environment Variables (Optional)
For production, consider moving Supabase credentials to environment variables:

```dart
// In supabase_service.dart
url: const String.fromEnvironment('SUPABASE_URL'),
anonKey: const String.fromEnvironment('SUPABASE_ANON_KEY'),
```

## 🎨 UI/UX Features

### Design System
- **Color Scheme**: Green theme (Colors.green)
- **Material 3**: Modern Material Design components
- **Responsive**: Works on mobile and web
- **Accessibility**: Proper form validation and error handling

### User Experience
- **Loading States**: Proper loading indicators during auth operations
- **Error Handling**: User-friendly error messages
- **Form Validation**: Real-time validation with helpful messages
- **Navigation**: Smooth transitions between screens

## 🔒 Security Features

### Row Level Security (RLS)
- Users can only access their own profile data
- Proper authentication checks
- Secure logout functionality

### Data Validation
- Email format validation
- Password strength requirements
- Role validation (restaurant/ngo only)

## 🚀 Next Steps

### For Dev 3 (UI/UX Engineer)
The authentication system provides:
- Form fields for name, role, location (as specified in requirements)
- Clean, modern UI ready for enhancement
- Proper state management for user data

### For Future Development
- Profile editing functionality
- Password reset
- Email verification
- Social authentication (Google, Facebook)
- Profile picture upload

## 🐛 Troubleshooting

### Common Issues
1. **"Profile not found" error**: Ensure database setup script was run
2. **Authentication fails**: Check Supabase URL and anon key
3. **Navigation issues**: Verify all routes are properly defined in main.dart

### Debug Mode
Enable debug logging in Supabase:
```dart
await Supabase.initialize(
  // ... other config
  debug: true, // Add this for debugging
);
```

---

**Status**: ✅ Complete and Ready for Testing
**Dependencies**: Supabase project with Auth enabled + profiles table
**Next Phase**: Ready for Dev 3 to enhance UI components
