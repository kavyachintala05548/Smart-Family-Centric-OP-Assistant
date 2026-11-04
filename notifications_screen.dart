import 'package:flutter/material.dart';
import '../../api/api_client.dart';
import '../../models/models.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationModel> notifications = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    setState(() => loading = true);
    try {
      final response = await ApiClient.get('/notifications');
      setState(() {
        notifications = (response as List).map((item) => NotificationModel.fromJson(item)).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications & Alerts')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadNotifications,
              child: error != null
                  ? ListView(children: [const SizedBox(height: 150), Center(child: Text(error!, style: const TextStyle(color: Colors.red)))])
                  : notifications.isEmpty
                      ? ListView(children: const [SizedBox(height: 200), Center(child: Text('No notifications yet.'))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: notifications.length,
                          itemBuilder: (context, index) {
                            final notification = notifications[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  notification.isRead ? Icons.notifications_none : Icons.notifications_active,
                                  color: notification.isRead ? Colors.grey : Colors.blue,
                                ),
                                title: Text(notification.title, style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(notification.message),
                                    const SizedBox(height: 4),
                                    Text(notification.createdAt, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
    );
  }
}
