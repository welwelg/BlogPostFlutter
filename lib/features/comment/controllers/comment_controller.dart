import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment_model.dart';
import '../repository/comment_repository.dart';
import 'package:image_picker/image_picker.dart';

// 1. Repository Provider
final commentRepositoryProvider = Provider((ref) {
  return CommentRepository(Supabase.instance.client);
});

// 2. Stream Provider (Family)
final commentsStreamProvider =
    StreamProvider.family<List<Comment>, String>((ref, blogId) {
  final repository = ref.watch(commentRepositoryProvider);
  return repository.getComments(blogId);
});

// 3. Controller Provider
final commentControllerProvider =
    StateNotifierProvider<CommentController, bool>((ref) {
  // 👈 IMPORTANTE: Ipasa ang 'ref' dito para magamit sa loob
  return CommentController(ref, ref.watch(commentRepositoryProvider));
});

class CommentController extends StateNotifier<bool> {
  final Ref _ref; // 👈 Added Ref here
  final CommentRepository _repository;

  CommentController(this._ref, this._repository) : super(false);

  // 🔹 ADD COMMENT
  Future<void> addComment(String blogId, String content, XFile? image) async {
    state = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await _repository.addComment(
        blogId: blogId,
        image: image,
        userId: userId,
        content: content,
      );
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false;
    }
  }

  // 🔹 DELETE COMMENT (Fixed)
  Future<void> deleteComment(String commentId, String blogId) async {
    state = true;
    try {
      await _repository
          .deleteComment(commentId); // Gamitin ang _repository direkta

      // Refresh the list
      _ref.invalidate(commentsStreamProvider(blogId));
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false;
    }
  }

  // 🔹 NEW: EDIT COMMENT
  Future<void> editComment(
      {required String commentId,
      required String newContent,
      required String blogId}) async {
    state = true; // Start loading
    try {
      await _repository.updateComment(
          commentId: commentId, content: newContent);

      // Refresh the list para makita agad ang pagbabago
      _ref.invalidate(commentsStreamProvider(blogId));
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false;
    }
  }
}
