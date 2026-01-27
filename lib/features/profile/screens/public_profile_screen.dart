import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../blog/controllers/blog_controller.dart';
import '../../blog/screens/home_blog_screen.dart';
import '../controllers/profile_controller.dart';

class PublicProfileScreen extends ConsumerWidget {
  final String userId;

  const PublicProfileScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    //  Get Profile Info
    final profileAsync = ref.watch(profileProvider(userId));

    //  Get All Blogs & Filter by this User
    final allBlogsAsync = ref.watch(getAllBlogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Author Profile")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),

            //  USER HEADER (Avatar & Name)
            profileAsync.when(
              data: (profile) => Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: profile?.avatarUrl != null
                        ? NetworkImage(profile!.avatarUrl!)
                        : null,
                    child: profile?.avatarUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 15),
                  Text(
                    profile?.fullName ?? 'Unknown User',
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  // const SizedBox(height: 5),
                  // const Text("Community Member",
                  //     style: TextStyle(color: Colors.grey)),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const Text("Could not load profile"),
            ),

            const SizedBox(height: 20),
            const Divider(),

            //  USER'S BLOG POSTS
            Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: const Text(
                "Published Posts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            allBlogsAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(20.0),
                child: CircularProgressIndicator(),
              )),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (blogs) {
                // Kunin lang ang blogs ni userId
                final userBlogs =
                    blogs.where((b) => b.userId == userId).toList();

                if (userBlogs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Text("This user hasn't posted anything yet.",
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                // Show List (Using Column + Map para nasa loob ng SingleScrollView)
                return ListView.builder(
                  shrinkWrap: true, // Importante ito sa loob ng ScrollView
                  physics:
                      const NeverScrollableScrollPhysics(), // ScrollView na ang bahala mag-scroll
                  itemCount: userBlogs.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (context, index) {
                    return BlogCard(blog: userBlogs[index]);
                  },
                );
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
