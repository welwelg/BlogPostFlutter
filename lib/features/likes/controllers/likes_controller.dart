import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// STATE MODEL
class LikeState {
  final bool isLiked;
  final int count;

  LikeState({required this.isLiked, required this.count});
}

// PROVIDER
final likesControllerProvider = StateNotifierProvider.autoDispose
    .family<LikesController, AsyncValue<LikeState>, String>((ref, blogId) {
  return LikesController(blogId);
});

// CONTROLLER
class LikesController extends StateNotifier<AsyncValue<LikeState>> {
  final String blogId;
  final SupabaseClient _supabase = Supabase.instance.client;

  //  ADD THIS FLAG
  bool _mounted = true;

  LikesController(this.blogId) : super(const AsyncValue.loading()) {
    _loadInitialData();
  }

  //  OVERRIDE DISPOSE PARA ALAM NATING PATAY NA
  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // LOAD DATA
  Future<void> _loadInitialData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      final count = await _supabase
          .from('likes')
          .count(CountOption.exact)
          .eq('blog_id', blogId);

      bool isLiked = false;
      if (userId != null) {
        final userLike = await _supabase
            .from('likes')
            .select()
            .eq('blog_id', blogId)
            .eq('user_id', userId)
            .maybeSingle();
        isLiked = userLike != null;
      }

      // CHECK MO MUNA KUNG BUHAY PA BAGO MAG-UPDATE
      if (_mounted) {
        state = AsyncValue.data(LikeState(isLiked: isLiked, count: count));
      }
    } catch (e, st) {
      if (_mounted) {
        // Check here too
        state = AsyncValue.error(e, st);
      }
    }
  }

  // TOGGLE LIKE
  Future<void> toggleLike() async {
    final currentState = state.value;
    if (currentState == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final oldIsLiked = currentState.isLiked;
    final oldCount = currentState.count;

    // Optimistic Update
    final newIsLiked = !oldIsLiked;
    final newCount = newIsLiked ? oldCount + 1 : oldCount - 1;

    // Safe to update here kasi user interaction to (buhay pa screen)
    state = AsyncValue.data(LikeState(isLiked: newIsLiked, count: newCount));

    try {
      if (newIsLiked) {
        await _supabase.from('likes').insert({
          'user_id': userId,
          'blog_id': blogId,
        });
      } else {
        await _supabase
            .from('likes')
            .delete()
            .eq('user_id', userId)
            .eq('blog_id', blogId);
      }
    } catch (e) {
      // Revert if error
      if (_mounted) {
        // Check bago mag-revert
        state =
            AsyncValue.data(LikeState(isLiked: oldIsLiked, count: oldCount));
      }
    }
  }
}
