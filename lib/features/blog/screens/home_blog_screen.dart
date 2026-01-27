import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Imports
import '../controllers/blog_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import 'add_blog_screen.dart';
import 'blog_detail_screen.dart';
import 'edit_blog_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/controllers/profile_controller.dart';

// Import Likes Controller
import '../../likes/controllers/likes_controller.dart';

// Search Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// 🔹 REALTIME COMMENT COUNT PROVIDER
final commentCountProvider = StreamProvider.family<int, String>((ref, blogId) {
  return Supabase.instance.client
      .from('comments')
      .stream(primaryKey: ['id'])
      .eq('blog_id', blogId)
      .map((data) => data.length); // Bilangin ang rows
});

class HomeBlogScreen extends ConsumerWidget {
  const HomeBlogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogsAsync = ref.watch(getAllBlogsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Blog'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            onPressed: () {
              ref.read(authControllerProvider.notifier).signOut();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddBlogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // SEARCH BAR
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
              decoration: InputDecoration(
                hintText: 'Search blogs...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),

          // BLOG LIST
          Expanded(
            child: blogsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (blogs) {
                // Filtering Logic
                final filteredBlogs = blogs.where((blog) {
                  final query = searchQuery.toLowerCase();
                  final title = blog.title.toLowerCase();
                  final content = blog.content.toLowerCase();
                  return title.contains(query) || content.contains(query);
                }).toList();

                if (filteredBlogs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 50, color: Colors.grey),
                        const SizedBox(height: 10),
                        Text(
                          searchQuery.isEmpty
                              ? 'No blogs yet. Be the first to post!'
                              : 'No results found for "$searchQuery"',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredBlogs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    final blog = filteredBlogs[index];
                    return BlogCard(blog: blog);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 👇 BLOG CARD (With Hybrid Refresh Logic)
// ==========================================
class BlogCard extends ConsumerWidget {
  final dynamic blog;

  const BlogCard({super.key, required this.blog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMyBlog = blog.userId == currentUserId;
    final authorProfileAsync = ref.watch(profileProvider(blog.userId));

    // Watch Comment Count
    final commentCountAsync = ref.watch(commentCountProvider(blog.id));

    void navigateToDetail() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => BlogDetailScreen(blog: blog)),
      ).then((_) {
        // ⚡ FIX: FORCE REFRESH PAGBALIK
        // Kahit naka-off ang Realtime, mag-uupdate ito.
        ref.invalidate(commentCountProvider(blog.id));
      });
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AUTHOR HEADER
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                authorProfileAsync.when(
                  data: (profile) => CircleAvatar(
                    radius: 18,
                    backgroundImage: profile?.avatarUrl != null
                        ? NetworkImage(profile!.avatarUrl!)
                        : null,
                    child: profile?.avatarUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  loading: () => const CircleAvatar(
                      radius: 18, child: Icon(Icons.more_horiz)),
                  error: (_, __) =>
                      const CircleAvatar(radius: 18, child: Icon(Icons.error)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      authorProfileAsync.when(
                        data: (profile) => Text(
                          profile?.fullName ?? 'Unknown Author',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        loading: () => Container(
                            width: 80, height: 10, color: Colors.grey[200]),
                        error: (_, __) => const Text("Unknown"),
                      ),
                      Text(
                        _formatDateTime(blog.createdAt),
                        style:
                            const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (isMyBlog)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EditBlogScreen(blog: blog),
                          ),
                        );
                      } else if (value == 'delete') {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Blog?"),
                            content: const Text(
                                "Are you sure you want to remove this post?"),
                            actions: [
                              TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text("Cancel")),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    try {
                                      await ref
                                          .read(blogControllerProvider.notifier)
                                          .deleteBlog(blog.id);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Row(
                                              children: [
                                                Icon(Icons.delete,
                                                    color: Colors.white),
                                                SizedBox(width: 10),
                                                Text(
                                                    "Blog deleted successfully!"),
                                              ],
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content:
                                                  Text("Delete failed: $e"),
                                              backgroundColor: Colors.red),
                                        );
                                      }
                                    }
                                  },
                                  child: const Text("Delete",
                                      style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Edit')
                        ]),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete')
                        ]),
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // BLOG IMAGE
          if (blog.imageUrl != null)
            GestureDetector(
              onTap: navigateToDetail,
              child: SizedBox(
                height: 250,
                width: double.infinity,
                child: Image.network(
                  blog.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image)),
                ),
              ),
            ),

          // TITLE & CONTENT
          InkWell(
            onTap: navigateToDetail,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    blog.content,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[800], height: 1.4),
                  ),
                ],
              ),
            ),
          ),

          // ACTION BAR
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _LikeButton(blogId: blog.id),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: navigateToDetail,
                  icon: const Icon(Icons.chat_bubble_outline,
                      size: 20, color: Colors.grey),
                  label: commentCountAsync.when(
                    data: (count) => Text(
                      count > 0 ? "$count Comments" : "Comment",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    loading: () => const Text("Comment",
                        style: TextStyle(color: Colors.grey)),
                    error: (_, __) => const Text("Comment",
                        style: TextStyle(color: Colors.grey)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 👇 PRIVATE WIDGET: LIKE BUTTON
// ==========================================
class _LikeButton extends ConsumerWidget {
  final String blogId;

  const _LikeButton({required this.blogId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeStateAsync = ref.watch(likesControllerProvider(blogId));

    return likeStateAsync.when(
      data: (likeState) {
        return TextButton.icon(
          onPressed: () {
            ref.read(likesControllerProvider(blogId).notifier).toggleLike();
          },
          icon: Icon(
            likeState.isLiked ? Icons.favorite : Icons.favorite_border,
            color: likeState.isLiked ? Colors.red : Colors.grey,
            size: 20,
          ),
          label: Text(
            likeState.count > 0 ? "${likeState.count} Likes" : "Like",
            style: TextStyle(
              color: likeState.isLiked ? Colors.red : Colors.grey,
              fontWeight:
                  likeState.isLiked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        );
      },
      loading: () => const SizedBox(
          width: 60,
          height: 30,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
      error: (err, stack) => const Icon(Icons.error, color: Colors.grey),
    );
  }
}

// ==========================================
// 👇 HELPER FUNCTION: DATE FORMATTER
// ==========================================
String _formatDateTime(DateTime date) {
  final localDate = date.toLocal();
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec"
  ];
  final year = localDate.year;
  final month = months[localDate.month - 1];
  final day = localDate.day;
  var hour = localDate.hour;
  final minute = localDate.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  if (hour > 12) hour -= 12;
  if (hour == 0) hour = 12;
  return "$month $day, $year • $hour:$minute $period";
}
