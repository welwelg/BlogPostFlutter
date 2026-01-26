import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/blog_model.dart';
import 'package:flutter/foundation.dart'; // Needed for kIsWeb
import 'package:image_picker/image_picker.dart'; // Needed for XFile

class BlogRepository {
  final SupabaseClient _supabase;

  BlogRepository(this._supabase);

  // 🔹 READ: Get all blogs
  Stream<List<Blog>> getAllBlogs() {
    return _supabase
        .from('blogs')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) => data.map((blogMap) => Blog.fromJson(blogMap)).toList());
  }

  // 🔹 CREATE: Upload new blog
  Future<void> uploadBlog({
    required String uid,
    required String title,
    required String content,
    required XFile? image, // 👈 Changed to XFile to support Web
  }) async {
    String? imageUrl;

    // 1. If an image is selected, upload it first
    if (image != null) {
      final fileName = '$uid/${DateTime.now().toIso8601String()}';
      
      if (kIsWeb) {
        // 🌐 WEB: Upload Raw Bytes
        final bytes = await image.readAsBytes(); // 👈 Fix: Read bytes here
        await _supabase.storage.from('blog_images').uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
      } else {
        // 📱 MOBILE: Upload File Object
        await _supabase.storage.from('blog_images').upload(
          fileName,
          File(image.path),
          fileOptions: const FileOptions(upsert: true),
        );
      }

      // Get the public link (Works for both Web and Mobile)
      imageUrl = _supabase.storage.from('blog_images').getPublicUrl(fileName);
    }

    // 2. Save blog details to Database
    await _supabase.from('blogs').insert({
      'user_id': uid,
      'title': title,
      'content': content,
      'image_url': imageUrl,
    });
  }
  
  // 🔹 DELETE: Delete blog
  Future<void> deleteBlog(String blogId) async {
    await _supabase.from('blogs').delete().eq('id', blogId);
  }
}