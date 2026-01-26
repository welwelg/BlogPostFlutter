import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart'; // 👈 Import XFile
import '../models/blog_model.dart';
import '../repository/blog_repository.dart';

// 1. Provide Repository
final blogRepositoryProvider = Provider((ref) {
  return BlogRepository(Supabase.instance.client);
});

// 2. Provide List of Blogs (Stream)
final getAllBlogsProvider = StreamProvider<List<Blog>>((ref) {
  final repository = ref.watch(blogRepositoryProvider);
  return repository.getAllBlogs();
});

// 3. Controller for Actions
final blogControllerProvider =
    StateNotifierProvider<BlogController, bool>((ref) {
  return BlogController(ref.watch(blogRepositoryProvider));
});

class BlogController extends StateNotifier<bool> {
  final BlogRepository _blogRepository;

  BlogController(this._blogRepository) : super(false);

  Future<void> uploadBlog({
    required String title,
    required String content,
    required XFile? image,
  }) async {
    state = true;
    try {
      final uid = Supabase.instance.client.auth.currentUser!.id;
      await _blogRepository.uploadBlog(
        uid: uid,
        title: title,
        content: content,
        image: image,
      );
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false;
    }
  }

  Future<void> deleteBlog(String blogId) async {
    try {
      await _blogRepository.deleteBlog(blogId);
    } catch (e) {
      rethrow;
    }
  }
}
