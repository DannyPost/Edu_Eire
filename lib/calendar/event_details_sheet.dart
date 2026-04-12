import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'event.dart';

/// Single key for bookmark storage so titles match across Search and My Bookmarks.
String bookmarkTitleKey(String title) => title.trim();

String eventCategoryLabel(String category) {
  switch (category) {
    case 'deadline':
      return 'Deadline';
    case 'open_day':
      return 'Open Day';
    case 'personal':
      return 'Personal';
    default:
      return category;
  }
}

void showEventDetails(
  BuildContext context, {
  required Event event,
  required bool Function(Event) isBookmarked,
  required void Function(Event) onToggleBookmark,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final bookmarked = isBookmarked(event);
              final theme = Theme.of(context);
              final dateStr = DateFormat('EEEE, d MMMM y').format(event.date);
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        IconButton(
                          tooltip: bookmarked
                              ? 'Remove bookmark'
                              : 'Add bookmark',
                          icon: Icon(
                            bookmarked
                                ? Icons.bookmark
                                : Icons.bookmark_border,
                            color: bookmarked ? Colors.blue : null,
                          ),
                          onPressed: () {
                            onToggleBookmark(event);
                            setModalState(() {});
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Category: ${eventCategoryLabel(event.category)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (event.note != null && event.note!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Note',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.note!,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );
}
