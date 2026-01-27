import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../repository/profile_repository.dart';

// Repository Provider
final profileRepositoryProvider = Provider((ref) {
  return ProfileRepository(Supabase.instance.client);
});

// Profile Provider (GET Data)
// Ito ang pinakikinggan ng UI. Kapag in-invalidate ito, automatic mag-uupdate ang screen.
final profileProvider =
    FutureProvider.family<Profile?, String>((ref, userId) async {
  return ref.read(profileRepositoryProvider).getProfile(userId);
});

// Controller Provider (UPDATE Data)
final profileControllerProvider =
    StateNotifierProvider<ProfileController, bool>((ref) {
  // Pass 'ref' para makapag-utos tayo mag-refresh
  return ProfileController(ref);
});

class ProfileController extends StateNotifier<bool> {
  final Ref _ref;

  ProfileController(this._ref) : super(false);

  // UPDATE LOGIC
  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    state = true; // Loading start
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      //  Update sa Database
      await _ref.read(profileRepositoryProvider).updateProfile(
            userId: userId,
            fullName: fullName,
            avatarUrl: avatarUrl,
          );

      //  MAGIC TRIGGER: Force Refresh!
      // Sasabihan nito ang lahat ng nakikinig sa profileProvider na kumuha ng bagong data.
      // Dahil dito, hindi na kailangan mag-refresh ng browser.
      _ref.invalidate(profileProvider(userId));
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false; // Loading stop
    }
  }
}
