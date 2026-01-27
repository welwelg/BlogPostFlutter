import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../controllers/profile_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  XFile? _imageFile; // Local image (habang hindi pa saved)
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  // Load existing data
  Future<void> _loadCurrentProfile() async {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    // .read is okay inside initState / functions
    final profile = await ref.read(profileProvider(userId).future);

    if (profile != null && mounted) {
      _nameController.text = profile.fullName ?? '';
    }
  }

  // Pick Image Logic
  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _imageFile = picked; // Show local image immediately
      });
    }
  }

  // Save Logic
  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      String? avatarUrl;

      //  Upload Image (Kung may pinili)
      if (_imageFile != null) {
        // Gumagamit tayo ng Timestamp sa filename para iwas Cache issue
        final fileName =
            'avatars/$userId/${DateTime.now().millisecondsSinceEpoch}';
        final supabase = Supabase.instance.client;

        if (kIsWeb) {
          final bytes = await _imageFile!.readAsBytes();
          await supabase.storage.from('blog_images').uploadBinary(
                fileName,
                bytes,
                fileOptions: const FileOptions(upsert: true),
              );
        } else {
          await supabase.storage.from('blog_images').upload(
                fileName,
                File(_imageFile!.path),
                fileOptions: const FileOptions(upsert: true),
              );
        }
        avatarUrl = supabase.storage.from('blog_images').getPublicUrl(fileName);
      }

      // Update Database & Trigger Auto-Reload
      await ref.read(profileControllerProvider.notifier).updateProfile(
            fullName: _nameController.text.trim(),
            avatarUrl: avatarUrl,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profile updated!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser!.id;
    // Ito ang nagbabantay ng changes. Kapag nag-invalidate ang controller,
    // Automatic magre-rebuild ang widget na 'to.
    final profileAsync = ref.watch(profileProvider(userId));

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // PROFILE AVATAR
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    // Logic:
                    // Kung may piniling local file, yun ang ipakita (Preview).
                    // Kung wala, ipakita ang galing sa database (URL).
                    backgroundImage: _imageFile != null
                        ? (kIsWeb
                                ? NetworkImage(_imageFile!.path)
                                : FileImage(File(_imageFile!.path)))
                            as ImageProvider
                        : null,
                    child: _imageFile == null
                        ? profileAsync.when(
                            data: (profile) => profile?.avatarUrl != null
                                ? ClipOval(
                                    child: Image.network(
                                      profile!.avatarUrl!,
                                      width: 120,
                                      height: 120,
                                      fit: BoxFit.cover,
                                      // Iwasan ang flicker gamit ang key
                                      key: ValueKey(profile.avatarUrl),
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 60, color: Colors.grey),
                            loading: () => const CircularProgressIndicator(),
                            error: (_, __) => const Icon(Icons.error),
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // DISPLAY NAME
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: "Display Name",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),

            const SizedBox(height: 30),

            // SAVE BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Save Changes",
                        style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),

            // LOGOUT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.red),
                label:
                    const Text("Logout", style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
