import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../controllers/blog_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'add_blog_screen.dart';
import 'blog_detail_screen.dart';

class HomeBlogScreen extends ConsumerWidget {
  const HomeBlogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Listen to the Stream of Blogs
    final blogsAsync = ref.watch(getAllBlogsProvider);
    // Get current user ID to check ownership
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Blog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      // 2. Button to go to Add Page
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBlogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      // 3. Display the List based on State
      body: blogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (blogs) {
          if (blogs.isEmpty) {
            return const Center(
                child: Text('No blogs yet. Be the first to post!'));
          }
          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];
              final isMyBlog = blog.userId == currentUserId;

              // 👇 Navigation Function (Clean Version)
              void navigateToDetail() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlogDetailScreen(blog: blog),
                  ),
                );
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼️ PART 1: IMAGE CLICK
                    if (blog.imageUrl != null)
                      GestureDetector(
                        onTap: navigateToDetail, // Direct Tap sa Image
                        child: SizedBox(
                          height: 200,
                          width: double.infinity,
                          child: Image.network(
                            blog.imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image),
                          ),
                        ),
                      ),

                    // 📝 PART 2: TEXT/LISTTILE CLICK
                    ListTile(
                      onTap: navigateToDetail, // Direct Tap sa ListTile
                      title: Text(
                        blog.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 5),
                          Text(
                            blog.content,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Posted: ${blog.createdAt.toString().split(' ')[0]}',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      // Delete Button (Hindi maaapektuhan ang navigation)
                      trailing: isMyBlog
                          ? IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ref
                                    .read(blogControllerProvider.notifier)
                                    .deleteBlog(blog.id);
                              },
                            )
                          : null,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
