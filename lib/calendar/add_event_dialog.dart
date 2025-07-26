import 'package:flutter/material.dart';
import 'calendar.dart'; // For the Event class

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _note;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Personal Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Event Title'),
          ),
          TextField(
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            onChanged: (value) {
              _note = value;
            },
          ),
          TextButton(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2025, 1, 1),
                lastDate: DateTime(2026, 12, 31),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                });
              }
            },
            child: const Text('Select Date'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              final newEvent = Event(
                _titleController.text,
                _selectedDate,
                'personal',
                note: _note,
              );
              Navigator.pop(context, newEvent);
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
