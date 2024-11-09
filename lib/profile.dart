// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:feedforge/services/auth_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  ProfileState createState() => ProfileState();
}

class ProfileState extends State<Profile> {
  bool _obscurePassword = true;
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF708291),
      appBar: AppBar(
        backgroundColor: const Color(0xFF708291),
        title: const Text('User Profile', style: TextStyle(color: Color(0xFFFF8700))),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFFFF8700)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Color(0xFFFF8700),
                child: Icon(Icons.person, size: 50, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? 'User',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 32),
              _buildInfoTile('Email', user?.email ?? 'N/A'),
              const SizedBox(height: 16),
              _buildPasswordTile(),
              const SizedBox(height: 32),

              // Align buttons in a single Column with Expanded for equal width
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: _buildButton(
                      icon: Icons.lock,
                      label: 'Change Password',
                      onPressed: () {
                        _showPasswordResetDialog();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildButton(
                icon: Icons.logout,
                label: 'Logout',
                onPressed: () async {
                  final authService = AuthService();
                  await authService.signout(context); // Pass the context here for navigation
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF011935),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Color(0xFFFF8700))),
          Text(value, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPasswordTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF708291),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Password', style: TextStyle(color: Color(0xFFFF8700))),
          Row(
            children: [
              Text(
                _obscurePassword ? '•••••••••••••••' : 'password hidden',
                style: const TextStyle(color: Colors.black),
              ),
              IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFFFF8700),
                ),
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.black),
      label: Text(label, style: const TextStyle(color: Colors.black)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF8700),
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 50), // Set button to take full available width
      ),
    );
  }

  void _showPasswordResetDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: const Text('Are you sure you want to reset your password?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () async {
                if (user?.email != null) {
                  await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password reset email sent!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No email found!')),
                  );
                }
                Navigator.of(context).pop(); // Close the dialog
              },
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }
}
