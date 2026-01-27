import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/blog_model.dart';
import '../repository/blog_repository.dart';

//  Provide Repository
final blogRepositoryProvider = Provider((ref) {
  return BlogRepository(Supabase.instance.client);
});

//  Provide List of Blogs (STREAM Provider ang dapat dito)
final getAllBlogsProvider = StreamProvider<List<Blog>>((ref) {
  final repository = ref.watch(blogRepositoryProvider);
  return repository.getAllBlogs();
});

// Controller for Actions
final blogControllerProvider =
    StateNotifierProvider<BlogController, bool>((ref) {
  final repo = ref.watch(blogRepositoryProvider);
  // Pass 'ref' para makapag-utos tayo mag-refresh
  return BlogController(ref, repo);
});

class BlogController extends StateNotifier<bool> {
  final Ref _ref; // Need this for refresh
  final BlogRepository _blogRepository;

  BlogController(this._ref, this._blogRepository) : super(false);

  // UPLOAD BLOG
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

      // REFRESH LOGIC:
      // Gumagana ito kahit StreamProvider. Irereset niya ang stream connection.
      _ref.invalidate(getAllBlogsProvider);
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false;
    }
  }

  // EDIT BLOG ACTION
  Future<void> editBlog({
    required String blogId,
    required String title,
    required String content,
    XFile? image,
  }) async {
    state = true;
    try {
      await _blogRepository.updateBlog(
        blogId: blogId,
        title: title,
        content: content,
        image: image,
      );

      // Force Refresh Home Screen
      _ref.invalidate(getAllBlogsProvider);
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      state = false;
    }
  }

  // DELETE BLOG
  Future<void> deleteBlog(String blogId) async {
    try {
      await _blogRepository.deleteBlog(blogId);

      // REFRESH LOGIC
      _ref.invalidate(getAllBlogsProvider);
    } catch (e) {
      rethrow;
    }
  }
}
