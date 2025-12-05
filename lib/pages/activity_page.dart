// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/notification_service.dart';

class ActivityPage extends StatefulWidget {
  final Map<String, Object?> notification;
  const ActivityPage({super.key, required this.notification});

  @override
  State<ActivityPage> createState() => _ActivityPageState();
}

class _ActivityPageState extends State<ActivityPage> {
  final _controller = TextEditingController();
  final _db = DatabaseService();
  bool _saving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    // Update last 5 minutes of readings
    await _db.updateReadingsActivityForLast(const Duration(minutes: 5), text);
    // Mark notification read for this item (if id is available)
    final id = widget.notification['id'];
    if (id is int) {
      try {
        await NotificationService.instance.markRead(id);
      } catch (_) {}
    }
    setState(() => _saving = false);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity saved to last 5 minutes of readings')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = widget.notification['message'] as String? ?? '';
    final ts = widget.notification['ts'] as String? ?? '';
    final tsDate = ts.isNotEmpty ? DateTime.parse(ts) : null;
    final dateStr = tsDate != null
      ? '${tsDate.toLocal().year.toString().padLeft(4, '0')}-${tsDate.toLocal().month.toString().padLeft(2, '0')}-${tsDate.toLocal().day.toString().padLeft(2, '0')}'
      : '';
    return Scaffold(
      appBar: AppBar(title: const Text('Activity capture')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Notification: $msg'),
            const SizedBox(height: 8),
            Text('Received: ${dateStr.isNotEmpty ? dateStr : 'unknown'}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            const Text('What are you doing right now?'),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(hintText: 'Type activity here (e.g. driving, working, exercising)'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _saving ? null : _save, child: _saving ? const CircularProgressIndicator() : const Text('Save'))
          ],
        ),
      ),
    );
  }
}
