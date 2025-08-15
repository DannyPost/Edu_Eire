import 'package:flutter/material.dart';
import '../calendar/calendar.dart'; // adjust the path to match your Event model
import '../calendar/add_event_dialog.dart'; // if you have calendar-related helpers
import 'package:intl/intl.dart';

class EventsPage extends StatefulWidget {
  final List<Event> allEvents;
  final List<Event> bookmarkedEvents;
  final Function(Event) onBookmarkToggle;

  const EventsPage({
    super.key,
    required this.allEvents,
    required this.bookmarkedEvents,
    required this.onBookmarkToggle,
  });

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  bool isBookmarked(Event event) {
    return widget.bookmarkedEvents.contains(event);
  }

  @override
  Widget build(BuildContext context) {
    widget.allEvents.sort((a, b) => a.date.compareTo(b.date)); // sort by date

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Events'),
        backgroundColor: Colors.indigo,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: widget.allEvents.length,
        itemBuilder: (context, index) {
          final event = widget.allEvents[index];
          final formattedDate = DateFormat.yMMMMd().add_jm().format(event.date);
          final isSaved = isBookmarked(event);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                event.title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Text(formattedDate, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  Text(getDescriptionForEvent(event.title)),
                ],
              ),
              trailing: IconButton(
                icon: Icon(
                  isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: isSaved ? Colors.indigo : Colors.grey,
                ),
                onPressed: () {
                  widget.onBookmarkToggle(event);
                  setState(() {});
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // Add a function to return event descriptions based on the title
  String getDescriptionForEvent(String title) {
    switch (title.toLowerCase()) {
      case 'school year starts':
        return 'First official day of the academic year for secondary schools.';
      case 'cao opens':
        return 'Start date for submitting CAO college applications.';
      case 'susi grant opens':
        return 'SUSI grant application portal opens for students.';
      case 'cao early bird deadline (€30)':
        return 'Apply to CAO by this date to get the discounted fee.';
      case 'cao final deadline (€45)':
        return 'Final date to submit CAO applications with the standard fee.';
      case 'hear/dare application deadline':
        return 'Deadline to apply for HEAR or DARE schemes on CAO.';
      case 'hear/dare docs submission deadline':
        return 'Deadline to upload supporting documents for HEAR/DARE.';
      case 'change of mind opens (cao)':
        return 'You can now update your CAO choices without penalty.';
      case 'change of mind closes (cao)':
        return 'Final deadline to revise your CAO choices.';
      case 'midterm break starts':
        return 'First day of October midterm break for secondary schools.';
      case 'midterm break ends':
        return 'Last day of the October midterm break.';
      case 'christmas holidays start':
        return 'Christmas break begins for secondary school students.';
      case 'christmas holidays end':
        return 'Classes resume after the Christmas break.';
      case 'february midterm':
        return 'One-week midterm break in February for schools.';
      case 'easter holidays start':
        return 'Easter break begins for secondary schools.';
      case 'easter holidays end':
        return 'Return to school after the Easter holidays.';
      case 'leaving & junior cert exams begin':
        return 'State exams officially begin for Junior and Leaving Cert students.';
      case 'college open day (ucd sample)':
        return 'Visit UCD, tour the campus, and attend course talks.';
      case 'college open day (tcd sample)':
        return 'Explore Trinity College Dublin’s campus and departments.';
      default:
        return 'Important date in the Irish academic calendar.';
    }
  }

}
