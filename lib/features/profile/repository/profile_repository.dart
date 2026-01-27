import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // GET Profile
  Future<Profile?> getProfile(String userId) async {
    try {
      final data =
          await _supabase.from('profiles').select().eq('id', userId).single();
      return Profile.fromJson(data);
    } catch (e) {
      return null;
    }
  }

  // UPDATE Profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      // MAP TO 'display_name'
      if (fullName != null) {
        updates['display_name'] = fullName;
      }

      // MAP TO 'profile_image'
      if (avatarUrl != null) {
        updates['profile_image'] = avatarUrl;
      }

      await _supabase.from('profiles').update(updates).eq('id', userId);
    } catch (e) {
      throw Exception('Update failed: $e');
    }
  }
}
