import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/blog_controller.dart';
import '../models/blog_model.dart';

class EditBlogScreen extends ConsumerStatefulWidget {
  final Blog blog;

  const EditBlogScreen({super.key, required this.blog});

  @override
  ConsumerState<EditBlogScreen> createState() => _EditBlogScreenState();
}

class _EditBlogScreenState extends ConsumerState<EditBlogScreen> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final _formKey = GlobalKey<FormState>();

  XFile? _newImage;
  bool _isImageDeleted = false; //  Flag para sa delete logic

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.blog.title);
    _contentController = TextEditingController(text: widget.blog.content);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _newImage = picked;
        _isImageDeleted = false;
      });
    }
  }

  void _updateBlog() async {
    if (_formKey.currentState!.validate()) {
      try {
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
              isImageRemoved: _isImageDeleted,
            );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Blog updated!'), backgroundColor: Colors.green),
        );

        Navigator.pop(context);
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
              // --- IMAGE PREVIEW LOGIC ---
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
                      //  NEW IMAGE SELECTED
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: kIsWeb
                              ? Image.network(_newImage!.path,
                                  fit: BoxFit.cover)
                              : Image.file(File(_newImage!.path),
                                  fit: BoxFit.cover),
                        )
                      : (widget.blog.imageUrl != null && !_isImageDeleted)
                          //  EXISTING IMAGE (NOT DELETED)
                          ? Stack(
                              fit: StackFit.expand,
                              children: [
                                // The Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(widget.blog.imageUrl!,
                                      fit: BoxFit.cover),
                                ),
                                // The EDIT Overlay
                                Container(
                                  color: Colors.black12,
                                  alignment: Alignment.center,
                                  child: const Icon(Icons.edit,
                                      color: Colors.white70, size: 30),
                                ),
                                // The REMOVE Button
                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _isImageDeleted = true; // Hide image UI
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                                blurRadius: 2,
                                                color: Colors.black26)
                                          ]),
                                      child: const Icon(Icons.close,
                                          color: Colors.white, size: 18),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          //  NO IMAGE / DELETED
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
