import 'package:flutter/material.dart';
import 'event.dart';

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String _category = 'personal'; // personal|deadline|open_day
  String? _college; // optional

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 3),
    );
    if (picked != null) {
      // keep as local date-only here; we will normalize to UTC when saving
      setState(() => _date = DateTime(picked.year, picked.month, picked.day));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Personal Event'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/'
                      '${_date.year}',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick date'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: const [
                  DropdownMenuItem(value: 'personal', child: Text('Personal')),
                  DropdownMenuItem(value: 'deadline', child: Text('Deadline')),
                  DropdownMenuItem(value: 'open_day', child: Text('Open Day')),
                ],
                onChanged: (v) => setState(() => _category = v ?? 'personal'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _college,
                decoration: const InputDecoration(labelText: 'College (optional)'),
                items: const [
                  DropdownMenuItem(value: 'NCI', child: Text('NCI')),
                  DropdownMenuItem(value: 'UCD', child: Text('UCD')),
                  DropdownMenuItem(value: 'TCD', child: Text('TCD')),
                  DropdownMenuItem(value: 'DCU', child: Text('DCU')),
                  DropdownMenuItem(value: 'UL', child: Text('UL')),
                  DropdownMenuItem(value: 'UCC', child: Text('UCC')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (v) => setState(() => _college = v),
              ),
              if (_college == 'Other')
                TextFormField(
                  decoration: const InputDecoration(labelText: 'College name'),
                  onChanged: (v) => _college = v,
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          child: const Text('Add'),
          onPressed: () {
            if (_formKey.currentState?.validate() != true) return;

            // ✅ Normalize to UTC midnight so it matches calendar grouping
            final utcDate = DateTime.utc(_date.year, _date.month, _date.day);

            final event = Event(
              title: _titleCtrl.text.trim(),
              date: utcDate,
              category: _category,
              note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
              college: (_college?.trim().isEmpty ?? true) ? null : _college!.trim(),
            );
            Navigator.pop(context, event);
          },
        ),
      ],
    );
  }
}
