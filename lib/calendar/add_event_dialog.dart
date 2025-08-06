import 'package:flutter/material.dart';
import 'calendar.dart'; // Make sure this path matches your project structure

Future<void> showAddOrEditEventDialog({
  required BuildContext context,
  DateTime? selectedDate,
  Event? existingEvent,
  required void Function(Event) onSave,
}) async {
  final titleController = TextEditingController(text: existingEvent?.title ?? '');
  final noteController = TextEditingController(text: existingEvent?.note ?? '');
  String selectedCategory = existingEvent?.category ?? 'General';
  DateTime selectedEventDate = existingEvent?.date ?? selectedDate ?? DateTime.now();

  await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(existingEvent == null ? 'Add Event' : 'Edit Event'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Title'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: <String>[
                  'General', 'Exam', 'Holiday', 'Deadline', 'Personal'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    selectedCategory = value;
                  }
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text("Date: "),
                  TextButton(
                    child: Text(
                      "${selectedEventDate.toLocal()}".split(' ')[0],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedEventDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        selectedEventDate = picked;
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          ElevatedButton(
            child: Text(existingEvent == null ? 'Add' : 'Update'),
            onPressed: () {
              final newEvent = Event(
                title: titleController.text,
                date: selectedEventDate,
                category: selectedCategory,
                note: noteController.text.isEmpty ? null : noteController.text,
              );
              onSave(newEvent);
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
