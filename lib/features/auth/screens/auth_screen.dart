import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  bool _isLogin = true; // Toggle between Login and Register

  @override
  void dispose() {
    // Good practice: Dispose controllers to free memory
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch loading state
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _isLogin ? 'Welcome Back' : 'Create Account',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Only show Name field if registering
                if (!_isLogin)
                  TextFormField(
                    controller: _nameController,
                    decoration:
                        const InputDecoration(labelText: 'Display Name'),
                    validator: (value) =>
                        value!.isEmpty ? 'Enter a name' : null,
                  ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) =>
                      !value!.contains('@') ? 'Invalid email' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) =>
                      value!.length < 6 ? 'Min 6 chars' : null,
                ),
                const SizedBox(height: 24),

                // Use a standard Flutter Button, but show Spinner if loading
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (_formKey.currentState!.validate()) {
                              try {
                                if (_isLogin) {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signIn(
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                } else {
                                  await ref
                                      .read(authControllerProvider.notifier)
                                      .signUp(
                                        _emailController.text,
                                        _passwordController.text,
                                        _nameController.text,
                                      );
                                }
                              } catch (e) {
                                // 🛑 FIX: Check if the screen is still alive before showing error
                                if (!mounted) return;

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          },
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_isLogin ? 'Login' : 'Sign Up'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(_isLogin
                      ? "Don't have an account? Sign Up"
                      : "Already have an account? Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
