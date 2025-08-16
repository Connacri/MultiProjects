import 'package:flutter/material.dart';
import 'package:calendar_planner_view/calendar_planner_view.dart';
import '../mock_events.dart';

/// A minimal demo showcasing just the calendar picker with custom list view.
///
/// This example demonstrates:
/// - Calendar date selection only (no timeline)
/// - Simple event list display
/// - Clean, minimal design
/// - Focus on the listBuilder functionality
class MinimalCalendarListDemo extends StatefulWidget {
  const MinimalCalendarListDemo({super.key});

  @override
  State<MinimalCalendarListDemo> createState() =>
      _MinimalCalendarListDemoState();
}

class _MinimalCalendarListDemoState extends State<MinimalCalendarListDemo> {
  DateTime _selectedDate = DateTime.now();

  /// Simple event list builder
  Widget _buildEventList(
    BuildContext context,
    List<CalendarEvent> events,
    DateTime selectedDate,
  ) {
    final theme = Theme.of(context);
    if (events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_outlined,
                size: 48,
                color: Colors.blue.shade300,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No events scheduled',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a different date to view events',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // Sort events by start time
    final sortedEvents = List<CalendarEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    return Column(
      children: [
        // Header section
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.blue.shade100.withAlpha(100),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade100.withAlpha(100),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.calendar_today,
                  color: Colors.blue.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatSelectedDate(selectedDate),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      '${events.length} event${events.length == 1 ? '' : 's'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Events list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: sortedEvents.length,
            itemBuilder: (context, index) {
              final event = sortedEvents[index];
              final duration = event.endTime.difference(event.startTime);
              final durationText = duration.inHours > 0
                  ? '${duration.inHours}h ${duration.inMinutes % 60}m'
                  : '${duration.inMinutes}m';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: Card(
                  elevation: 2,
                  shadowColor: event.color.withAlpha(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _showEventDetails(context, event);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: event.color.withAlpha(80),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          // Color strip
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: event.color,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title and category
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        event.title,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (event.columnId != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: event.color.withAlpha(30),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          event.columnId!.toUpperCase(),
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: event.color,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Time and duration
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - '
                                      '${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        durationText,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (event.description != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    event.description!,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatSelectedDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else {
      final weekdays = [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ];
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  void _showEventDetails(BuildContext context, CalendarEvent event) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: event.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                event.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - '
                  '${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (event.description != null) ...[
              const SizedBox(height: 12),
              Text(
                event.description!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (event.columnId != null) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: event.color.withAlpha(30),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Category: ${event.columnId!.toUpperCase()}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: event.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minimal Calendar List'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: CalendarPlannerView(
        events: mockEvents,
        selectedDate: _selectedDate,
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
        },

        // Calendar settings
        datePickerPosition: DatePickerPosition.top,
        enableViewToggle: true,
        showDayTitle: false,

        // Simple styling
        calendarTitle: 'Select Date',
        todayContainerColor: Colors.blue.withAlpha(50),
        selectedContainerColor: Colors.blue,

        showListView: true,
        listBuilder: _buildEventList,

        // Required but not used parameters
        startHour: 0,
        endHour: 24,
      ),
    );
  }
}
