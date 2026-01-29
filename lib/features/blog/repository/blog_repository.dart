import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_model.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:image_picker/image_picker.dart';

class BlogRepository {
  final SupabaseClient _supabase;

  BlogRepository(this._supabase);

  // READ: Get all blogs
  Stream<List<Blog>> getAllBlogs() {
    return _supabase
        .from('blogs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((blogMap) => Blog.fromJson(blogMap)).toList());
  }

  // CREATE: Upload new blog
  Future<void> uploadBlog({
    required String uid,
    required String title,
    required String content,
    required XFile? image,
  }) async {
    String? imageUrl;

    if (image != null) {
      final fileName = '$uid/${DateTime.now().toIso8601String()}';
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

    await _supabase.from('blogs').insert({
      'user_id': uid,
      'title': title,
      'content': content,
      'image_url': imageUrl,
    });
  }

  // UPDATE BLOG
  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String content,
    XFile? image,
    bool isImageRemoved = false,
  }) async {
    //  Prepare Base Updates
    final Map<String, dynamic> updates = {
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    };

    //  LOGIC PARA SA IMAGE
    if (isImageRemoved) {
      // Gusto burahin ang image -> Set to NULL
      updates['image_url'] = null;
    } else if (image != null) {
      //  May bagong image -> Upload muna
      final fileName = 'blogs/$blogId/${DateTime.now().millisecondsSinceEpoch}';

      if (kIsWeb) {
        await _supabase.storage.from('blog_images').uploadBinary(
              fileName,
              await image.readAsBytes(),
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        await _supabase.storage.from('blog_images').upload(
              fileName,
              File(image.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }
      // Set new URL
      final newImageUrl =
          _supabase.storage.from('blog_images').getPublicUrl(fileName);
      updates['image_url'] = newImageUrl;
    }
    // SCENARIO C: Walang ginalaw -> Wala tayong babaguhin sa image_url

    // Execute Update
    await _supabase.from('blogs').update(updates).eq('id', blogId);
  }

  // Delete blog
  Future<void> deleteBlog(String blogId) async {
    await _supabase.from('blogs').delete().eq('id', blogId);
  }
}
