import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_model.dart';

class EditBlogScreen extends ConsumerStatefulWidget {
  final Blog blog; //  Need natin ipasa ang lumang data

  const EditBlogScreen({super.key, required this.blog});

  @override
  ConsumerState<EditBlogScreen> createState() => _EditBlogScreenState();
}

class _EditBlogScreenState extends ConsumerState<EditBlogScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();
  XFile? _newImage;

  @override
  void initState() {
    super.initState();
    // Pre-fill data
    _titleController = TextEditingController(text: widget.blog.title);
    _contentController = TextEditingController(text: widget.blog.content);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImage = picked);
    }
  }

  void _updateBlog() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show Loading (Optional: You can use a loading dialog here)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Updating blog...'),
              duration: Duration(seconds: 1)),
        );

        await ref.read(blogControllerProvider.notifier).editBlog(
              blogId: widget.blog.id,
              title: _titleController.text,
              content: _contentController.text,
              image: _newImage,
            );

        if (!mounted) return;

        // Success Toast
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Blog updated!'), backgroundColor: Colors.green),
        );

        Navigator.pop(context); // Close Screen
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(blogControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Blog")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // IMAGE PREVIEW
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _newImage != null
                      //  New Image Selected
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(_newImage!.path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_newImage!.path),
                                  fit: BoxFit.cover),
                        )
                      : widget.blog.imageUrl != null
                          //  Existing Image from DB
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(widget.blog.imageUrl!,
                                      fit: BoxFit.cover),
                                ),
                                Container(
                                    color: Colors.black38,
                                    child: const Icon(Icons.edit,
                                        color: Colors.white, size: 40)),
                              ],
                            )
                          // C. No Image
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo,
                                    size: 40, color: Colors.grey),
                                Text("Add Cover Image"),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 16),

              // TITLE
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
                validator: (val) => val!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // CONTENT
              TextFormField(
                controller: _contentController,
                maxLines: 8,
                decoration: const InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true),
                validator: (val) => val!.isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 24),

              // SAVE BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _updateBlog,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
