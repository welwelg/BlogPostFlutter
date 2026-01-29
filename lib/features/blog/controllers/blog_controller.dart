import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../models/blog_model.dart';
import '../repository/blog_repository.dart';

final blogRepositoryProvider = Provider((ref) {
  return BlogRepository(Supabase.instance.client);
});

final getAllBlogsProvider = StreamProvider<List<Blog>>((ref) {
  final repository = ref.watch(blogRepositoryProvider);
  return repository.getAllBlogs();
});

final blogControllerProvider =
    StateNotifierProvider<BlogController, bool>((ref) {
  final repo = ref.watch(blogRepositoryProvider);
  return BlogController(ref, repo);
});

class BlogController extends StateNotifier<bool> {
  final Ref _ref;
  final BlogRepository _blogRepository;

  BlogController(this._ref, this._blogRepository) : super(false);

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
      _ref.invalidate(getAllBlogsProvider);
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      if (mounted) state = false;
    }
  }

  // EDIT BLOG
  Future<void> editBlog({
    required String blogId,
    required String title,
    required String content,
    XFile? image,
    bool isImageRemoved = false, // New Parameter
  }) async {
    state = true;
    try {
      await _blogRepository.updateBlog(
        blogId: blogId,
        title: title,
        content: content,
        image: image,
        isImageRemoved: isImageRemoved,
      );
      _ref.invalidate(getAllBlogsProvider);
    } catch (e) {
      state = false;
      rethrow;
    } finally {
      if (mounted) state = false;
    }
  }

  Future<void> deleteBlog(String blogId) async {
    try {
      await _blogRepository.deleteBlog(blogId);
      _ref.invalidate(getAllBlogsProvider);
    } catch (e) {
      rethrow;
    }
  }
}
