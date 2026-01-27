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

  //  Add Comment with Image
  Future<void> addComment({
    required String blogId,
    required String userId,
    required String content,
    required XFile? image,
  }) async {
    String? imageUrl;

    //  Upload Logic (Same as Blog Upload)
    if (image != null) {
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

    //  Save to Database
    await _supabase.from('comments').insert({
      'blog_id': blogId,
      'user_id': userId,
      'comment_text': content,
      'image_url': imageUrl,
    });
  }

  // Edit/Update Comment
  Future<void> updateComment({
    required String commentId,
    required String content,
    XFile? newImage,
  }) async {
    try {
      String? imageUrl;

      //  Kapag may bagong image, i-upload muna
      if (newImage != null) {
        final userId = _supabase.auth.currentUser!.id;
        final fileName = 'comments/$userId/${DateTime.now().toIso8601String()}';

        // Upload logic (Same as addComment)
        if (kIsWeb) {
          final bytes = await newImage.readAsBytes();
          await _supabase.storage.from('blog_images').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
        } else {
          await _supabase.storage.from('blog_images').upload(
                fileName,
                File(newImage.path),
                fileOptions: const FileOptions(upsert: true),
              );
        }
        imageUrl = _supabase.storage.from('blog_images').getPublicUrl(fileName);
      }

      // Prepare Data to Update
      final Map<String, dynamic> updates = {
        'comment_text': content,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Isama lang ang image_url sa update KUNG may bagong in-upload
      if (imageUrl != null) {
        updates['image_url'] = imageUrl;
      }

      // Update Database
      await _supabase.from('comments').update(updates).eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to update comment: $e');
    }
  }

  // Delete Comment
  Future<void> deleteComment(String commentId) async {
    try {
      await _supabase.from('comments').delete().eq('id', commentId);
    } catch (e) {
      throw Exception('Failed to delete comment: $e');
    }
  }
}
