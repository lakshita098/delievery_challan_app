import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class PersonalDetailScreen extends StatefulWidget {
  const PersonalDetailScreen({super.key});

  @override
  State<PersonalDetailScreen> createState() => _PersonalDetailScreenState();
}

class _PersonalDetailScreenState extends State<PersonalDetailScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();

  // Hidden fields
  final TextEditingController _roleIdController = TextEditingController();
  final TextEditingController _statusIdController = TextEditingController();
  final TextEditingController _departmentIdController = TextEditingController();

  Map<String, dynamic>? editableUser;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');

    if (userDataString != null) {
      final user = jsonDecode(userDataString);
      setState(() {
        editableUser = user;
        _firstNameController.text = user['firstName'] ?? '';
        _lastNameController.text = user['lastname'] ?? '';
        _emailController.text = user['email'] ?? '';
        _contactController.text = user['contact'] ?? '';
        _employeeIdController.text = user['employeeId'] ?? '';
        _roleIdController.text = user['roleId']?.toString() ?? '';
        _statusIdController.text = user['statusId']?.toString() ?? '';
        _departmentIdController.text = user['departmentId']?.toString() ?? '';
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
    }
  }

  Future<void> saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');
    final userId = editableUser?['id'];

    if (token == null || userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authorization token missing")),
      );
      return;
    }

    final updatedUser = {
      "employeeId": _employeeIdController.text,
      "firstName": _firstNameController.text,
      "lastname": _lastNameController.text,
      "email": _emailController.text,
      "contact": _contactController.text,
      "role": int.tryParse(_roleIdController.text),
      "status": int.tryParse(_statusIdController.text),
      "department": int.tryParse(_departmentIdController.text),
    };

    final url = Uri.parse('$updateUserEndpoint/$userId');

    final response = await http.put(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(updatedUser),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: ${response.body}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Personal Details"),
        backgroundColor: Colors.black,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _firstNameController,
                      decoration: const InputDecoration(
                        labelText: 'First Name',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter First Name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: const InputDecoration(labelText: 'Last Name'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Last Name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Email' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _contactController,
                      decoration: const InputDecoration(
                        labelText: 'Contact Number',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Enter Contact Number' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        labelText: 'Employee ID',
                      ),
                      enabled: false,
                    ),

                    // Hidden TextFormFields - not shown but still functional
                    Offstage(
                      offstage: true,
                      child: Column(
                        children: [
                          TextFormField(controller: _roleIdController),
                          TextFormField(controller: _statusIdController),
                          TextFormField(controller: _departmentIdController),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                        ),
                        onPressed: saveChanges,
                        child: const Text(
                          "Save",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
