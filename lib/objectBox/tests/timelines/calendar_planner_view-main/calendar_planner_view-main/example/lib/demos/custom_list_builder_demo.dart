import 'package:flutter/material.dart';
import 'package:calendar_planner_view/calendar_planner_view.dart';
import '../mock_events.dart';

/// A demo showcasing custom list builder functionality while keeping the top calendar selection.
///
/// Features:
/// - Top calendar date picker for date selection
/// - Custom list builder for displaying events in a custom format
/// - Based on the Japanese demo UI styling
/// - Custom event cards with enhanced styling
/// - Event filtering by selected date
/// - Custom time formatting
/// - Interactive event cards with tap handling
class CustomListBuilderDemo extends StatefulWidget {
  const CustomListBuilderDemo({super.key});

  @override
  State<CustomListBuilderDemo> createState() => _CustomListBuilderDemoState();
}

class _CustomListBuilderDemoState extends State<CustomListBuilderDemo> {
  DateTime _selectedDate = DateTime.now();
  bool _loading = true;

  /// Japanese weekday names (月, 火, 水, 木, 金, 土, 日)
  static const List<String> japaneseWeekdays = [
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
    '日'
  ];

  /// Japanese month names
  static const List<String> japaneseMonths = [
    '1月',
    '2月',
    '3月',
    '4月',
    '5月',
    '6月',
    '7月',
    '8月',
    '9月',
    '10月',
    '11月',
    '12月'
  ];

  @override
  void initState() {
    super.initState();
    // Simulate loading delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _loading = false;
      });
    });
  }

  /// Shows event details in a dialog when an event is tapped
  void _onEventTap(BuildContext context, CalendarEvent event) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                event.title,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onSurface,
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
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom list builder for events display
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
            Icon(
              Icons.event_busy,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
            ),
            const SizedBox(height: 16),
            Text(
              'No events for this date',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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

    // Group events by time
    final Map<String, List<CalendarEvent>> eventsByTime = {};
    for (final event in events) {
      final timeKey =
          '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
      eventsByTime[timeKey] = (eventsByTime[timeKey] ?? [])..add(event);
    }

    final sortedTimes = eventsByTime.keys.toList()
      ..sort((a, b) {
        final aParts = a.split(':');
        final bParts = b.split(':');
        final aMinutes = int.parse(aParts[0]) * 60 + int.parse(aParts[1]);
        final bMinutes = int.parse(bParts[0]) * 60 + int.parse(bParts[1]);
        return aMinutes.compareTo(bMinutes);
      });

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.3),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      child: CustomScrollView(
        key: ValueKey(
            '${selectedDate.day}-${selectedDate.month}-${selectedDate.year}'),
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header section
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 8,
                shadowColor: Colors.red[300]?.withAlpha(50),
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
                        Colors.red[50]!,
                        Colors.red[100]!.withAlpha(150),
                        Colors.orange[50]!.withAlpha(100),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'date_icon',
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.red[300]?.withAlpha(30),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red[300]?.withAlpha(40) ??
                                    Colors.transparent,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.today_rounded,
                            color: Colors.red[700],
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
                              _formatDateHeader(selectedDate),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red[300]?.withAlpha(30),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${events.length} event${events.length == 1 ? '' : 's'} scheduled',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.red[700],
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
          // Animated time groups
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final timeKey = sortedTimes[index];
                final timeEvents = eventsByTime[timeKey]!;

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 400 + (index * 100)),
                  curve: Curves.easeOutCubic,
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: Opacity(
                        opacity: value,
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Card(
                      elevation: 6,
                      shadowColor: Colors.red[300]?.withAlpha(30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white,
                              Colors.red[50]!.withAlpha(30),
                            ],
                          ),
                        ),
                        child: Column(
                          children: [
                            // Time header
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.red[300]?.withAlpha(15),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.red[300]!,
                                          Colors.red[400]!,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              Colors.red[300]?.withAlpha(50) ??
                                                  Colors.transparent,
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      timeKey,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      '${timeEvents.length} event${timeEvents.length == 1 ? '' : 's'}',
                                      style:
                                          theme.textTheme.bodyMedium?.copyWith(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.schedule_rounded,
                                    color: Colors.red[400],
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            // Events for this time
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                children: timeEvents
                                    .map((event) => Container(
                                          margin:
                                              const EdgeInsets.only(bottom: 12),
                                          child:
                                              _buildEventCard(context, event),
                                        ))
                                    .toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
              childCount: sortedTimes.length,
            ),
          ),
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
        elevation: 3,
        shadowColor: event.color.withAlpha(60),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _onEventTap(context, event),
            borderRadius: BorderRadius.circular(12),
            splashColor: event.color.withAlpha(30),
            highlightColor: event.color.withAlpha(20),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    event.color.withAlpha(10),
                    event.color.withAlpha(25),
                  ],
                ),
                border: Border.all(
                  color: event.color.withAlpha(80),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  // Color indicator strip
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          event.color,
                          event.color.withAlpha(180),
                        ],
                      ),
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
                        // Title and category row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: theme.textTheme.titleMedium?.copyWith(
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
                        const SizedBox(height: 12),
                        // Time and duration section
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                theme.colorScheme.surfaceVariant.withAlpha(40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
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
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: event.color.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
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
                          const SizedBox(height: 12),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outline.withAlpha(30),
                              ),
                            ),
                            child: Text(
                              event.description!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today\'s Schedule';
    } else if (difference == 1) {
      return 'Tomorrow\'s Schedule';
    } else if (difference == -1) {
      return 'Yesterday\'s Schedule';
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
    final scrollController = ScrollController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom List Builder Demo'),
        backgroundColor: Colors.red[300]?.withAlpha(30),
      ),
      body: CalendarPlannerView(
        events: _loading ? [] : mockEvents,
        onEventTap: (event) => _onEventTap(context, event),
        onDateChanged: (date) {
          setState(() {
            _selectedDate = date;
          });
        },
        selectedDate: _selectedDate,
        datePickerPosition: DatePickerPosition.top,
        startHour: 8,
        endHour: 20,
        showDayTitle: false,
        enableViewToggle: true,
        calendarTitle: 'カスタムリスト',
        initialView: CalendarViewType.week,
        modalTitle: "日付を選択",
        dropdownLabel: "選択",
        dropdownAllLabel: "すべて",
        monthLabelText: '月',
        weekLabelText: '週',
        todayLabel: '日',
        tomorrowLabel: '明日',
        yesterdayLabel: '昨日',
        weekdayNames: japaneseWeekdays,
        monthNames: japaneseMonths,
        dotColor: Colors.pink[300],
        dotSize: 5.0,
        showColumnHeadersInDropdownAllOption: true,
        toggleColorBackground: Colors.red[300],
        showCurrentTimeIndicator: true,
        toggleColor: Colors.black87,
        calendarBackgroundColor: Colors.transparent,
        todayContainerColor: Colors.red[300]?.withAlpha(15),
        selectedContainerColor: Colors.red[400]?.withAlpha(70),
        modalHeaderGradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.redAccent.withAlpha(75),
            Colors.white,
          ],
        ),
        timeLabelWidth: 55,
        timeLabelType: TimeLabelType.hourAndHalf,
        modalTitleStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
        modalTodayButtonTextStyle:
            Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
        calendarTitleStyle: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
        dayTitleStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
        timeLabelBuilder: (DateTime time) {
          return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        },
        dayNumberStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.black87,
            ),
        weekdayLabelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
        monthLabelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
            ),
        titleTextStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
        timeTextStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black87,
            ),
        timeLabelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
        columnTitleStyle: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
        modalShowCloseButton: false,
        modalBackgroundColor: Colors.white,
        columns: const [
          (id: 'work', title: 'Work'),
          (id: 'personal', title: 'Personal'),
          (id: 'meetings', title: 'Meetings'),
        ],
        columnLabelType: ColumnLabelType.dropdown,
        loadingBuilder: (context) =>
            Center(child: CircularProgressIndicator(color: Colors.pink[300])),
        scrollController: scrollController,
        isLoading: _loading,
        loadingOverlayColor: Colors.black12,
        showListView: true,
        listBuilder: _customListBuilder,
      ),
    );
  }
}
