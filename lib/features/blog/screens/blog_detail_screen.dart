import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; // Image Picker
import 'package:supabase_flutter/supabase_flutter.dart'; // For Auth check

import '../models/blog_model.dart';
import '../../comment/controllers/comment_controller.dart';
import '../../comment/models/comment_model.dart';
import '../../profile/controllers/profile_controller.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  final _commentController = TextEditingController();
  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = picked;
      });
    }
  }

  // SUBMIT LOGIC (ADD COMMENT)
  void _submitComment() async {
    if (_commentController.text.isEmpty && _selectedImage == null) return;

    try {
      await ref.read(commentControllerProvider.notifier).addComment(
            widget.blog.id,
            _commentController.text,
            _selectedImage,
          );

      if (!mounted) return;

      _commentController.clear();
      setState(() {
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Comment posted successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Force refresh logic
      ref.invalidate(commentsStreamProvider(widget.blog.id));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(commentsStreamProvider(widget.blog.id));
    final isPosting = ref.watch(commentControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blog Details')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blog Image
                  if (widget.blog.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        widget.blog.imageUrl!,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Blog Title
                  Text(widget.blog.title,
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 8),

                  // Blog Content
                  Text(widget.blog.content),
                  const Divider(height: 40, thickness: 2),

                  // Comments Header
                  const Text("Comments",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),

                  // COMMENT LIST
                  commentsAsync.when(
                    data: (comments) {
                      if (comments.isEmpty) {
                        return const Text("No comments yet.");
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: comments.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final Comment comment = comments[index];
                          return CommentItem(comment: comment);
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ),

          // Input Area (Bottom)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black12)]),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Container(
                    height: 100,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        kIsWeb
                            ? Image.network(_selectedImage!.path)
                            : Image.file(File(_selectedImage!.path)),
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () =>
                                setState(() => _selectedImage = null),
                          ),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo_camera, color: Colors.blue),
                      onPressed: _pickImage,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: const InputDecoration(
                          hintText: 'Write a comment...',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: isPosting ? null : _submitComment,
                      icon: isPosting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send, color: Colors.blue),
                    ),
                  ],
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
//  SMART WIDGET: Comment Item (Display)
// ==========================================
class CommentItem extends ConsumerWidget {
  final Comment comment;

  const CommentItem({super.key, required this.comment});

  // EDIT FUNCTION: Opens the Dialog
  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => EditCommentDialog(
        comment: comment,
        onSave: (newContent, newImage) async {
          // Logic to save (Text + Image)
          try {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Updating comment..."),
                duration: Duration(milliseconds: 500),
              ),
            );

            await ref.read(commentControllerProvider.notifier).editComment(
                  commentId: comment.id,
                  newContent: newContent,
                  blogId: comment.blogId,
                  newImage: newImage,
                );

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.check, color: Colors.white),
                      SizedBox(width: 10),
                      Text("Comment updated successfully!"),
                    ],
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text("Failed to update: $e"),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Fetch Profile & Check Ownership
    final profileAsync = ref.watch(profileProvider(comment.userId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;
    final isMyComment = currentUserId == comment.userId;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER (Avatar + Name + Buttons)
            Row(
              children: [
                // AVATAR
                profileAsync.when(
                  data: (profile) => CircleAvatar(
                    radius: 16,
                    backgroundImage: profile?.avatarUrl != null
                        ? NetworkImage(profile!.avatarUrl!)
                        : null,
                    child: profile?.avatarUrl == null
                        ? const Icon(Icons.person, size: 20)
                        : null,
                  ),
                  loading: () => const CircleAvatar(
                      radius: 16, child: Icon(Icons.more_horiz)),
                  error: (_, __) =>
                      const CircleAvatar(radius: 16, child: Icon(Icons.error)),
                ),
                const SizedBox(width: 10),

                // NAME
                Expanded(
                  child: profileAsync.when(
                    data: (profile) => Text(
                      profile?.fullName ?? 'Anonymous User',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    loading: () => Container(
                        width: 100, height: 10, color: Colors.grey[300]),
                    error: (_, __) => const Text("Unknown User"),
                  ),
                ),

                // ACTION BUTTONS (Only if I own it)
                if (isMyComment) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                    onPressed: () => _showEditDialog(context, ref),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete Comment?"),
                          content: const Text(
                              "Are you sure you want to remove this?"),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancel")),
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Delete",
                                    style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        try {
                          await ref
                              .read(commentControllerProvider.notifier)
                              .deleteComment(comment.id, comment.blogId);

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text("Comment deleted!"),
                                  backgroundColor: Colors.grey),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text("Error deleting: $e"),
                                  backgroundColor: Colors.red),
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ],
            ),

            const SizedBox(height: 8),

            // CONTENT TEXT
            Text(comment.content),

            // EDITED LABEL
            if (comment.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(Icons.edit, size: 10, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      "Edited",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

            // COMMENT IMAGE
            if (comment.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    comment.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// NEW WIDGET: EDIT DIALOG (Fixed Overflow)
// ==========================================
class EditCommentDialog extends StatefulWidget {
  final Comment comment;
  final Function(String content, XFile? newImage) onSave;

  const EditCommentDialog({
    super.key,
    required this.comment,
    required this.onSave,
  });

  @override
  State<EditCommentDialog> createState() => _EditCommentDialogState();
}

class _EditCommentDialogState extends State<EditCommentDialog> {
  late TextEditingController _controller;
  XFile? _newImage;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.content);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImage = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Edit Comment"),
      // 🔹 IMPORTANT FIX: Wrapped in SingleChildScrollView
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Text Input
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: "Update your comment",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 15),

            // Image Preview Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: _newImage != null
                    // New Image
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.network(_newImage!.path, fit: BoxFit.cover)
                            : Image.file(File(_newImage!.path),
                                fit: BoxFit.cover),
                      )
                    : widget.comment.imageUrl != null
                        // Existing Image
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(widget.comment.imageUrl!,
                                    fit: BoxFit.cover),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.black38,
                                ),
                                child: const Center(
                                  child: Icon(Icons.edit,
                                      color: Colors.white, size: 30),
                                ),
                              ),
                            ],
                          )
                        // No Image
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: Colors.grey, size: 30),
                              SizedBox(height: 5),
                              Text("Change Photo",
                                  style: TextStyle(color: Colors.grey)),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_controller.text.trim(), _newImage);
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
