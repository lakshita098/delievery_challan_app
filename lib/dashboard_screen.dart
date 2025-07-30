import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'challan_list_page.dart';
import 'profile_screen.dart'; // ✅ isko profile_page.dart rakho jo maine diya tha

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  Future<void> logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DASHBOARD'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const ProfileScreen(), // ✅ yaha bhi ProfilePage()
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'profile', child: Text('Profile')),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildCard(
              color: Colors.blue.shade100,
              title: "Today's Challan",
              value: "0",
              showArrow: false,
              onTap: () {},
            ),
            _buildCard(
              color: Colors.orange.shade100,
              title: "Pending Challan",
              value: "0",
              showArrow: false,
              onTap: () {},
            ),
            _buildCard(
              color: Colors.green.shade100,
              title: "Total Challan",
              value: "0",
              showArrow: true,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChallanListPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Image.asset('assets/images/background.png', fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Color color,
    required String title,
    required String value,
    required bool showArrow,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: color,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              if (showArrow)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: Colors.black87,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
