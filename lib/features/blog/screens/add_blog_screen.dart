import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/blog_controller.dart';

class AddBlogScreen extends ConsumerStatefulWidget {
  const AddBlogScreen({super.key});

  @override
  ConsumerState<AddBlogScreen> createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends ConsumerState<AddBlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  XFile? _selectedImage;

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  // FIXED FUNCTION WITH TOAST
  void _uploadBlog() async {
    if (_formKey.currentState!.validate()) {
      try {
        await ref.read(blogControllerProvider.notifier).uploadBlog(
              title: _titleController.text,
              content: _contentController.text,
              image: _selectedImage,
            );

        if (!mounted) return;

        // 🔹 SUCCESS TOAST
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text("Blog posted successfully!"),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context); // Close Screen
      } catch (e) {
        if (!mounted) return;

        // 🔹 ERROR TOAST
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Upload failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(blogControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('New Blog Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _selectedImage != null
                      ? kIsWeb
                          ? Image.network(_selectedImage!.path,
                              fit: BoxFit.cover)
                          : Image.file(File(_selectedImage!.path),
                              fit: BoxFit.cover)
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
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) => val!.isEmpty ? 'Content is required' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _uploadBlog,
                  child: isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Publish Blog'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
