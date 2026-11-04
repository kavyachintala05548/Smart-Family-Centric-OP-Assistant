import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';
import '../auth/login_screen.dart';
import '../family/family_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? user;
  bool loading = true;
  String currentBackendUrl = ApiClient.baseUrl;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final response = await ApiClient.get('/auth/me');
      final url = await ApiClient.getBaseUrl();
      setState(() {
        user = UserModel.fromJson(response);
        currentBackendUrl = url;
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
    }
  }

  void _showBackendUrlDialog() {
    final urlController = TextEditingController(text: currentBackendUrl);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Configure Backend URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter FastAPI backend URL (e.g. http://10.0.2.2:8000 for Android emulator):'),
            const SizedBox(height: 12),
            TextField(
              controller: urlController,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final newUrl = urlController.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiClient.saveBaseUrl(newUrl);
                setState(() => currentBackendUrl = newUrl);
                if (!mounted) return;
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Backend URL updated to $newUrl')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Center(
                  child: CircleAvatar(
                    radius: 45,
                    backgroundColor: Color(0xFF1565C0),
                    child: Icon(Icons.person, size: 50, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    user?.fullName ?? 'User Name',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
                Center(
                  child: Text(
                    user?.email ?? 'email@example.com',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
                if (user?.phoneNumber != null && user!.phoneNumber!.isNotEmpty)
                  Center(
                    child: Text(
                      user!.phoneNumber!,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                const SizedBox(height: 24),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.family_restroom, color: Color(0xFF1565C0)),
                    title: const Text('Family Members'),
                    subtitle: const Text('Manage family health profiles'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FamilyScreen()),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.dns, color: Color(0xFF1565C0)),
                    title: const Text('Backend URL Settings'),
                    subtitle: Text(currentBackendUrl),
                    trailing: const Icon(Icons.edit),
                    onTap: _showBackendUrlDialog,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      await ApiClient.clearToken();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
