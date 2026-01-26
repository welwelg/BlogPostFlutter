import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // 🔹 Get current user session
  Session? get currentSession => _supabase.auth.currentSession;

  // 🔹 Sign Up
  Future<AuthResponse> signUp(String email, String password, String displayName) async {
    try {
      // 1. Create the user in Supabase Auth
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      // 2. Create the entry in the 'profiles' table
      // We manually insert this because Supabase Auth and Public Tables are separate
      if (response.user != null) {
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'display_name': displayName,
          'profile_image': '', // Empty initially
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
      return response;
    } catch (e) {
      rethrow; // Pass error to UI
    }
  }

  // 🔹 Sign In
  Future<AuthResponse> signIn(String email, String password) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // 🔹 Sign Out
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  // 🔹 Upload Profile Image
  Future<String> uploadProfileImage(String userId, File imageFile) async {
    final fileExt = imageFile.path.split('.').last;
    final fileName = '$userId/avatar.$fileExt'; // e.g., user123/avatar.jpg

    // Upload to Supabase Storage bucket 'avatars'
    await _supabase.storage.from('avatars').upload(
          fileName,
          imageFile,
          fileOptions: const FileOptions(upsert: true), // Overwrite if exists
        );

    // Get Public URL to save in database
    final imageUrl = _supabase.storage.from('avatars').getPublicUrl(fileName);
    
    // Update profile table
    await _supabase.from('profiles').update({
      'profile_image': imageUrl
    }).eq('id', userId);

    return imageUrl;
  }
}