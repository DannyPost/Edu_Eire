import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../events/event_service.dart';
import '../events/event_model.dart';

class CreateEditEventPage extends StatefulWidget {
  final User user;
  final GlobalEvent? existing;
  const CreateEditEventPage({super.key, required this.user, this.existing});

  @override
  State<CreateEditEventPage> createState() => _CreateEditEventPageState();
}

class _CreateEditEventPageState extends State<CreateEditEventPage> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _category = TextEditingController(text: 'Academic');
  final _location = TextEditingController();
  final _orgId = TextEditingController(); // 👈 NEW: college/org code like NCI/UCD

  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  DateTime _end   = DateTime.now().add(const Duration(hours: 2));
  bool _isGlobal = true;
  bool _approved = true; // flip to false if you want moderation by default
  bool _busy = false;
  String _err = '';

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _title.text = e.title;
      _desc.text = e.description;
      _category.text = e.category;
      _location.text = e.location;
      _orgId.text = e.orgId;
      _start = e.start;
      _end = e.end;
      _isGlobal = e.isGlobal;
      _approved = e.approved;
    }
  }

  Future<void> _pickDateTime(bool isStart) async {
    final base = isStart ? _start : _end;
    final d = await showDatePicker(
      context: context,
      initialDate: base,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
    );
    if (t == null) return;
    final dt = DateTime(d.year, d.month, d.day, t.hour, t.minute);
    setState(() {
      if (isStart) {
        _start = dt;
      } else {
        _end = dt.isBefore(_start) ? _start.add(const Duration(hours: 1)) : dt;
      }
    });
  }

  Future<void> _save() async {
    setState(() { _busy = true; _err = ''; });
    try {
      if (_title.text.trim().isEmpty) throw Exception('Title is required.');
      if (_orgId.text.trim().isEmpty) throw Exception('College / Org ID is required (e.g., NCI).');

      final svc = EventService();
      final payload = GlobalEvent(
        id: widget.existing?.id ?? '',
        title: _title.text.trim(),
        description: _desc.text.trim(),
        category: _category.text.trim().isEmpty ? 'Academic' : _category.text.trim(),
        location: _location.text.trim(),
        start: _start,
        end: _end,
        organiserId: widget.user.uid,
        organiserName: widget.user.displayName ?? '',
        orgId: _orgId.text.trim(),       // 👈 crucial for college filtering
        isGlobal: _isGlobal,
        approved: _approved,
      );

      if (widget.existing == null) {
        await svc.addEvent(payload);
      } else {
        await svc.updateEvent(payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.existing == null ? 'Create Event' : 'Save Changes';
    final brand = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: _desc, decoration: const InputDecoration(labelText: 'Description'), maxLines: 3),
            TextField(controller: _category, decoration: const InputDecoration(labelText: 'Category (e.g., Academic)')),
            TextField(controller: _location, decoration: const InputDecoration(labelText: 'Location')),
            TextField(
              controller: _orgId,
              decoration: const InputDecoration(
                labelText: 'College / Org ID (e.g., NCI, UCD, TCD)',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: ListTile(
                  title: const Text('Start'),
                  subtitle: Text(_start.toString()),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _pickDateTime(true),
                )),
              ],
            ),
            Row(
              children: [
                Expanded(child: ListTile(
                  title: const Text('End'),
                  subtitle: Text(_end.toString()),
                  trailing: const Icon(Icons.edit_calendar),
                  onTap: () => _pickDateTime(false),
                )),
              ],
            ),
            SwitchListTile(
              title: const Text('Global (visible to all students)'),
              value: _isGlobal,
              onChanged: (v) => setState(() => _isGlobal = v),
            ),
            SwitchListTile(
              title: const Text('Approved'),
              subtitle: const Text('Uncheck to require admin approval later'),
              value: _approved,
              onChanged: (v) => setState(() => _approved = v),
            ),
            if (_err.isNotEmpty) Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_err, style: const TextStyle(color: Colors.red)),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _busy ? null : _save,
              child: _busy
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(label),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.info_outline, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Events will be created with fields: startsAt/endsAt (UTC), orgId, '
                    'allowedAudienceKeys=["all-students"], audience.colleges=[orgId], '
                    'published/status flags.\nThis matches the /events schema your calendar expects.',
                    style: TextStyle(color: brand.withOpacity(0.8), fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
