import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:image_picker/image_picker.dart'; // For XFile
import '../models/comment_model.dart';

class CommentRepository {
  final SupabaseClient _supabase;

  CommentRepository(this._supabase);

  // GET Comments (Walang pagbabago)
  Stream<List<Comment>> getComments(String blogId) {
    return _supabase
        .from('comments')
        .stream(primaryKey: ['id'])
        .eq('blog_id', blogId)
        .order('created_at', ascending: true)
        .map((data) => data.map((map) => Comment.fromJson(map)).toList());
  }

  // 🔹  Add Comment with Image
  Future<void> addComment({
    required String blogId,
    required String userId,
    required String content,
    required XFile? image, // 👈 Added Image Parameter
  }) async {
    String? imageUrl;

    // 1. Upload Logic (Same as Blog Upload)
    if (image != null) {
      // Note: We reuse 'blog_images' bucket for simplicity.
      // Pwede ka gumawa ng separate bucket like 'comment_images' if gusto mo organized.
      final fileName = 'comments/$userId/${DateTime.now().toIso8601String()}';

      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await _supabase.storage.from('blog_images').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        await _supabase.storage.from('blog_images').upload(
              fileName,
              File(image.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }
      imageUrl = _supabase.storage.from('blog_images').getPublicUrl(fileName);
    }

    // 2. Save to Database
    await _supabase.from('comments').insert({
      'blog_id': blogId,
      'user_id': userId,
      'comment_text': content,
      'image_url': imageUrl, // 👈 Save the URL
    });
  }

  // 🔹 NEW: Edit/Update Comment
  Future<void> updateComment({
    required String commentId,
    required String content,
  }) async {
    try {
      await _supabase.from('comments').update({
        'comment_text': content,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  // 🔹 NEW: Delete Comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}
