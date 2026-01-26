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

  // 🔹 ADDED: UPDATE Profile
  Future<void> updateProfile({
    required String userId,
    String? fullName,
    String? avatarUrl,
  }) async {
    // Gumawa ng map para sa updates
    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    // I-add lang sa map kung may bagong value (para hindi mabura ang luma)
    if (fullName != null) updates['full_name'] = fullName;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _supabase.from('profiles').update(updates).eq('id', userId);
  }
}
