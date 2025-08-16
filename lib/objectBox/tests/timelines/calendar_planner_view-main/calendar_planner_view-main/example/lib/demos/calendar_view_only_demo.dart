import 'package:flutter/material.dart';
import 'package:calendar_planner_view/calendar_planner_view.dart';
import '../mock_events.dart';

/// A demo showcasing calendar view only with custom list builder.
///
/// Features:
/// - Calendar date picker only (no timeline view)
/// - Custom list builder for displaying events
/// - Clean, focused design
/// - Event filtering by selected date
/// - Card-based event display
/// - Responsive layout
class CalendarViewOnlyDemo extends StatefulWidget {
  const CalendarViewOnlyDemo({super.key});

  @override
  State<CalendarViewOnlyDemo> createState() => _CalendarViewOnlyDemoState();
}

class _CalendarViewOnlyDemoState extends State<CalendarViewOnlyDemo> {
  DateTime _selectedDate = DateTime.now();
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

  /// Custom list builder for event display
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
                Icons.event_available,
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
              'Select a different date to view events',
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: CustomScrollView(
        key: ValueKey(selectedDate.toString()),
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header section with improved styling
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 8,
                shadowColor: theme.colorScheme.primary.withAlpha(30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.primaryContainer.withAlpha(150),
                        theme.colorScheme.surfaceVariant.withAlpha(100),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'calendar_icon',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(20),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withAlpha(20),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.event_note,
                            color: theme.colorScheme.primary,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDate(selectedDate),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${events.length} event${events.length == 1 ? '' : 's'} scheduled',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Events list with animations
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final event = sortedEvents[index];
                  return TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    tween: Tween(begin: 0.0, end: 1.0),
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: Opacity(
                          opacity: value,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildEventCard(context, event),
                    ),
                  );
                },
                childCount: sortedEvents.length,
              ),
            ),
          ),
          // Bottom spacing
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    final theme = Theme.of(context);
    final duration = event.endTime.difference(event.startTime);
    final durationText = duration.inHours > 0
        ? '${duration.inHours}h ${duration.inMinutes % 60}m'
        : '${duration.inMinutes}m';

    return Hero(
      tag: 'event_${event.id ?? event.title}_${event.startTime}',
      child: Card(
        elevation: 4,
        shadowColor: event.color.withAlpha(80),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onEventTap(context, event),
            borderRadius: BorderRadius.circular(16),
            splashColor: event.color.withAlpha(30),
            highlightColor: event.color.withAlpha(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: event.color.withAlpha(60),
                  width: 1.5,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    event.color.withAlpha(8),
                    event.color.withAlpha(15),
                  ],
                ),
              ),
              child: Column(
                children: [
                  // Color header
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          event.color,
                          event.color.withAlpha(180),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title and category with better spacing
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (event.columnId != null) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: event.color.withAlpha(40),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: event.color.withAlpha(100),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  event.columnId!.toUpperCase(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: event.color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Time and duration section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.surfaceVariant.withAlpha(50),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 18,
                                color: event.color,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - '
                                '${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event.color.withAlpha(30),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  durationText,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: event.color,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (event.description != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(50),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Description',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  event.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    height: 1.4,
                                  ),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
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
      ),
    );
  }

  String _formatDate(DateTime date) {
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
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December'
      ];
      return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar View Only'),
        backgroundColor: theme.colorScheme.surfaceVariant.withAlpha(100),
        elevation: 0,
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

        // Modal settings (not used but good to have)
        modalTitle: "Select Date",
        modalBackgroundColor: theme.colorScheme.surface,
        modalShowCloseButton: true,

        // Loading
        isLoading: _loading,
        loadingBuilder: (context) => Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),

        showListView: true,
        listBuilder: _customListBuilder,

        // These won't be used since we have listBuilder, but required for completeness
        startHour: 0,
        endHour: 24,
      ),
    );
  }
}
