import 'package:flutter/material.dart';
import 'calendar.dart'; // For the Event class

class AddEventDialog extends StatefulWidget {
  const AddEventDialog({super.key});

  @override
  State<AddEventDialog> createState() => _AddEventDialogState();
}

class _AddEventDialogState extends State<AddEventDialog> {
  final _titleController = TextEditingController();
  DateTime _selectedDate = DateTime(
  DateTime.now().year,
  DateTime.now().month,
  DateTime.now().day,
);

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
            onChanged: (value) => _note = value,
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
                  _selectedDate = DateTime(date.year, date.month, date.day); // <- clean date
                });
              }
            },
            child: const Text('Select Date'),
          ),
          Text(
            'Selected Date: ${_selectedDate.day.toString().padLeft(2, '0')}/'
            '${_selectedDate.month.toString().padLeft(2, '0')}/'
            '${_selectedDate.year}',
            style: const TextStyle(fontSize: 13),
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
                title: _titleController.text,
                date: _selectedDate,
                category: 'personal',
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
