import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/blog/screens/home_blog_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // REPLACE with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://cslcsnywmypngwdqwzpw.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNzbGNzbnl3bXlwbmd3ZHF3enB3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njk0MTcyMDcsImV4cCI6MjA4NDk5MzIwN30.lTnEEqVYiBhD5_gNxDCzDBHECZXQQ3Lg1TJmTsyc3AM',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the auth state
    final authStateAsync = ref.watch(authStateProvider);

    return MaterialApp(
      title: 'Flutter Blog',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: authStateAsync.when(
        data: (state) {
          // If session exists, user is logged in
          if (state.session != null) {
            return const HomeBlogScreen();
          }
          // Otherwise show login
          return const AuthScreen();
        },
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text("Error: $err"))),
      ),
    );
  }
}