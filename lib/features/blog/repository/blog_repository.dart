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

    //  If an image is selected, upload it first
    if (image != null) {
      final fileName = '$uid/${DateTime.now().toIso8601String()}';

      if (kIsWeb) {
        //  Upload Raw Bytes
        final bytes = await image.readAsBytes();
        await _supabase.storage.from('blog_images').uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        // upload File Object
        await _supabase.storage.from('blog_images').upload(
              fileName,
              File(image.path),
              fileOptions: const FileOptions(upsert: true),
            );
      }

      // Get the public link (Works for both Web and Mobile)
      imageUrl = _supabase.storage.from('blog_images').getPublicUrl(fileName);
    }

    // Save blog details to Database
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
  }) async {
    String? imageUrl;

    //  Kung may bagong image, upload muna natin
    if (image != null) {
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
      imageUrl = _supabase.storage.from('blog_images').getPublicUrl(fileName);
    }

    //  Prepare Update Data
    final updates = {
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Isama lang ang image_url kung may bagong upload
    if (imageUrl != null) {
      updates['image_url'] = imageUrl;
    }

    // Update Supabase
    await _supabase.from('blogs').update(updates).eq('id', blogId);
  }

  // Delete blog
  Future<void> deleteBlog(String blogId) async {
    await _supabase.from('blogs').delete().eq('id', blogId);
  }
}
