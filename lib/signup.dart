import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'services/auth_service.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  SignupState createState() => SignupState();
}

class SignupState extends State<Signup> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false; // Variable to track password visibility

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      // Navigate to home screen or perform any other action after successful registration
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to sign in with Google: $e')),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          _buildBackgroundImage(),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    _buildLogo(),
                    const SizedBox(height: 30), // Increased vertical spacing
                    const Text(
                      'REGISTER',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8700),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // Username field
                    CustomTextField(
                      controller: _usernameController,
                      hintText: 'Username',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 25), // Increased vertical spacing
                    // Email field
                    CustomTextField(
                      controller: _emailController,
                      hintText: 'Email',
                      icon: Icons.email,
                    ),
                    const SizedBox(height: 25), // Increased vertical spacing
                    // Password field with visibility toggle
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock,
                      obscureText: !_isPasswordVisible, // Control visibility
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          color: const Color(0xFFFF8700),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 45), // Increased vertical spacing
                    // Sign Up button
                    _buildSignupButton(context),
                    const SizedBox(height: 25), // Increased vertical spacing
                    // Google Register button
                    _buildGoogleSignupButton(context),
                    const SizedBox(height: 30), // Increased vertical spacing
                    // Sign In link
                    _buildSignInLink(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widget methods

  Widget _buildBackgroundImage() {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/background.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/images/logo.png',
      width: 150,
      height: 150,
    );
  }

  Widget _buildSignupButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await AuthService().signup(
            userName: _usernameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            context: context,
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF708291),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: const Text(
          'SIGN UP',
          style: TextStyle(fontSize: 18, color: Color(0xFFFF8700)),
        ),
      ),
    );
  }

  Widget _buildGoogleSignupButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _handleGoogleSignIn(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        icon: Image.asset(
          'assets/images/google_logo.png',
          height: 24,
        ),
        label: const Text(
          'Register with Google',
          style: TextStyle(fontSize: 18, color: Colors.black87),
        ),
      ),
    );
  }

  Widget _buildSignInLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Already have an account? ",
          style: TextStyle(fontSize: 16,color: Colors.black),
          ),
        GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Text(
            'SIGN IN',
            style: TextStyle(fontSize: 18,color: Color(0xFFFF8700)),
          ),
        ),
      ],
    );
  }
}

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon; // Optional suffix icon parameter

  const CustomTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon, // Add suffix icon parameter
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFFFF8700)),
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.black.withOpacity(0.5)),
        contentPadding: const EdgeInsets.symmetric(vertical: 15), // Added vertical padding
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFF8700)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Color(0xFFFF8700)),
        ),
        suffixIcon: suffixIcon, // Include the suffix icon in the decoration
      ),
      keyboardAppearance: Brightness.dark,
      cursorColor: const Color(0xFFFF8700),
    );
  }
}
