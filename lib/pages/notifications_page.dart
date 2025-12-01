import 'package:flutter/material.dart';
import '../services/database_service.dart';
import 'activity_page.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _db = DatabaseService();
  List<Map<String, Object?>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final rows = await _db.queryNotifications();
    setState(() {
      _items = rows;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              // Clear all read notifications
              final removed = await NotificationService.instance.clearReadNotifications();
              await _load();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cleared $removed read notifications')));
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
      body: _items.isEmpty
          ? const Center(child: Text('No notifications yet'))
          : ListView.builder(
              itemCount: _items.length,
              itemBuilder: (ctx, i) {
                final row = _items[i];
                final id = row['id'] as int?;
                final msg = row['message'] as String? ?? '';
                final ts = row['ts'] as String? ?? '';
                final isRead = (row['read'] as int?) == 1;
                final tsDate = ts.isNotEmpty ? DateTime.parse(ts) : null;
                return ListTile(
                  title: Text(msg, style: TextStyle(color: isRead ? Colors.grey : null)),
                  subtitle: tsDate != null ? Text(tsDate.toLocal().toString(), style: TextStyle(color: isRead ? Colors.grey : null)) : null,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ActivityPage(notification: row)));
                    // reload after activity page (activity page will mark read if saved)
                    await _load();
                  },
                  trailing: isRead
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.mark_email_read),
                          onPressed: id == null
                              ? null
                              : () async {
                                  // mark this notification read
                                  await NotificationService.instance.markRead(id);
                                  await _load();
                                },
                        ),
                );
              },
            ),
    );
  }
}
