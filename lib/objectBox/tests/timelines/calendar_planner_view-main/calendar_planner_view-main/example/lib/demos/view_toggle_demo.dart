import 'package:flutter/material.dart';
import 'package:calendar_planner_view/calendar_planner_view.dart';
import '../mock_events.dart';

/// A demo showcasing the toggle between timeline and list view modes.
///
/// Features:
/// - Toggle switch to change between timeline and list views
/// - Default timeline view (original functionality)
/// - Enhanced list view with custom styling
/// - Maintains all calendar functionality in both modes
/// - Shows how to implement view switching in your app
class ViewToggleDemo extends StatefulWidget {
  const ViewToggleDemo({super.key});

  @override
  State<ViewToggleDemo> createState() => _ViewToggleDemoState();
}

class _ViewToggleDemoState extends State<ViewToggleDemo> {
  DateTime _selectedDate = DateTime.now();
  bool _showListView = true;
  final bool _loading = false;

  @override
  void initState() {
    super.initState();
  }

  /// Shows event details in a dialog when an event is tapped
  void _onEventTap(BuildContext context, CalendarEvent event) {
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

  /// Custom list builder for list view mode
  Widget _customListBuilder(
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
                color: theme.colorScheme.surfaceVariant.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_available_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant.withAlpha(150),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No events scheduled',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Switch to a different date to view events',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
                theme.colorScheme.primaryContainer,
                theme.colorScheme.primaryContainer.withAlpha(100),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withAlpha(20),
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
                  color: theme.colorScheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.view_list,
                  color: theme.colorScheme.primary,
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
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${events.length} event${events.length == 1 ? '' : 's'} • List View',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                            theme.colorScheme.onPrimaryContainer.withAlpha(180),
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
                    onTap: () => _onEventTap(context, event),
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
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - '
                                      '${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.surfaceVariant
                                            .withAlpha(100),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        durationText,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
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
                                      color: theme.colorScheme.onSurfaceVariant,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Toggle Demo'),
        backgroundColor: theme.colorScheme.surfaceVariant.withAlpha(100),
        elevation: 0,
        actions: [
          // View toggle switch
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withAlpha(100),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _showListView ? Icons.view_timeline : Icons.view_list,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  _showListView ? 'List' : 'Timeline',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: _showListView,
                  onChanged: (value) {
                    setState(() {
                      _showListView = value;
                    });
                  },
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
      body: CalendarPlannerView(
        events: _loading ? [] : mockEvents,
        selectedDate: _selectedDate,
        onEventTap: (event) => _onEventTap(context, event),
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
        },

        // Calendar settings
        datePickerPosition: DatePickerPosition.top,
        enableViewToggle: true,
        initialView: CalendarViewType.month,
        showDayTitle: false,

        // Styling
        calendarTitle: 'Select Date',
        calendarTitleStyle: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface,
        ),
        todayContainerColor: theme.colorScheme.primary.withAlpha(30),
        selectedContainerColor: theme.colorScheme.primary,
        calendarBackgroundColor: Colors.transparent,

        // Labels
        monthLabelText: 'Month',
        weekLabelText: 'Week',
        todayLabel: 'Today',

        // Timeline settings (used when showListView is false)
        startHour: 8,
        endHour: 20,
        showCurrentTimeIndicator: true,
        timeLabelWidth: 60,

        // Multi-column support
        columns: const [
          (id: 'work', title: 'Work'),
          (id: 'personal', title: 'Personal'),
          (id: 'meetings', title: 'Meetings'),
        ],

        // Loading
        isLoading: _loading,
        loadingBuilder: (context) => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),

        // Toggle between list view and timeline view
        showListView: _showListView,
        listBuilder: _showListView ? _customListBuilder : null,
      ),
    );
  }
}
