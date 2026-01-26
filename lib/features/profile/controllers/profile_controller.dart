import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../repository/profile_repository.dart';

// 1. Repository Provider
final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// 2. Profile Provider (GET)
final profileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  return ref.read(profileRepositoryProvider).getProfile(userId);
});

// 3. 🔹 ADDED: Profile Controller (UPDATE)
final profileControllerProvider =
    StateNotifierProvider<ProfileController, bool>((ref) {
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<bool> {
  final Ref _ref;

  ProfileController(this._ref) : super(false); // false = not loading

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    state = true; // Start loading
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      await _ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            fullName: fullName,
            avatarUrl: avatarUrl,
          );

      // 🔄 Force refresh the profile data para makita agad ang bago
      _ref.invalidate(profileProvider(userId));
    } catch (e) {
      state = false;
      rethrow; // Ipasa ang error sa UI para makita ang Snackbar
    } finally {
      state = false; // Stop loading
    }
  }
}
