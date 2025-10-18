import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../events/event_service.dart';
import '../events/event_model.dart';
import 'create_edit_event_page.dart';

class OrganiserDashboardPage extends StatelessWidget {
  final User user;
  const OrganiserDashboardPage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final svc = EventService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organiser Events'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => CreateEditEventPage(user: user)),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<GlobalEvent>>(
        stream: svc.streamMine(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? const [];
          if (items.isEmpty) return const Center(child: Text('No events yet.'));
          final df = DateFormat('EEE, d MMM h:mm a');
          return ListView.separated(
            itemBuilder: (_, i) {
              final e = items[i];
              return ListTile(
                title: Text(e.title),
                subtitle: Text('${df.format(e.start)} → ${df.format(e.end)} • ${e.location}'
                    '\n${e.approved ? 'Approved' : 'Pending'} • ${e.isGlobal ? 'Global' : 'Private'}'),
                isThreeLine: true,
                trailing: PopupMenuButton<String>(
                  onSelected: (v) async {
                    if (v == 'edit') {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => CreateEditEventPage(user: user, existing: e)),
                      );
                    } else if (v == 'delete') {
                      await EventService().deleteEvent(e.id);
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemCount: items.length,
          );
        },
      ),
    );
  }
}
