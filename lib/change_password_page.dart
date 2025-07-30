import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString('userData');
    final token = prefs.getString('token');

    if (userData == null || token == null || token.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("User not logged in")));
      return;
    }

    final user = json.decode(userData);
    final userId = user['id'];

    final url = Uri.parse(
      "http://192.168.200.110:5000/user/change_password/$userId",
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'oldPassword': _oldPassController.text,
        'newPassword': _newPassController.text,
      }),
    );

    final data = json.decode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? "Password updated successfully"),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(data['message'] ?? "Failed to update password")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _oldPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Old Password'),
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter old password' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _newPassController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (val) => val != null && val.length < 6
                    ? 'Minimum 6 characters'
                    : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmPassController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                ),
                validator: (val) => val != _newPassController.text
                    ? 'Passwords do not match'
                    : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _changePassword,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                child: const Text(
                  "Update Password",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
