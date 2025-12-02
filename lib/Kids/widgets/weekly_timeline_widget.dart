import 'package:flutter/material.dart';

import '../models/child_model_complete.dart';
import '../models/course_model_complete.dart';
import '../models/session_schedule_model.dart';

class WeeklyTimeline extends StatefulWidget {
  final Map<DateTime, List<SessionSchedule>> schedulesByDate;
  final Map<String, CourseModel> coursesById;
  final Map<String, ChildModel> childrenById;
  final Function(SessionSchedule)? onSessionTap;

  const WeeklyTimeline({
    super.key,
    required this.schedulesByDate,
    required this.coursesById,
    required this.childrenById,
    this.onSessionTap,
  });

  @override
  State<WeeklyTimeline> createState() => _WeeklyTimelineState();
}

class _WeeklyTimelineState extends State<WeeklyTimeline> {
  late DateTime _currentWeekStart;
  late ScrollController _scrollController;
  final double _dayColumnWidth = 140;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  void _scrollToToday() {
    final today = DateTime.now();
    final todayIndex = today.weekday - 1;
    final scrollPosition = todayIndex * _dayColumnWidth -
        (MediaQuery.of(context).size.width / 2) +
        (_dayColumnWidth / 2);

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _currentWeekStart = _getWeekStart(DateTime.now());
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToToday();
    });
  }

  List<DateTime> _getWeekDays() {
    return List.generate(7, (index) {
      return _currentWeekStart.add(Duration(days: index));
    });
  }

  bool _isToday(DateTime date) {
    final today = DateTime.now();
    return date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
  }

  @override
  Widget build(BuildContext context) {
    final weekDays = _getWeekDays();

    return Column(
      children: [
        _buildHeader(weekDays),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTimelineContent(weekDays),
        ),
      ],
    );
  }

  Widget _buildHeader(List<DateTime> weekDays) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton.filled(
            onPressed: _previousWeek,
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semaine précédente',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                Text(
                  _getMonthYearText(weekDays.first, weekDays.last),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${weekDays.first.day} - ${weekDays.last.day}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FilledButton.tonalIcon(
            onPressed: _goToToday,
            icon: const Icon(Icons.today),
            label: const Text('Aujourd\'hui'),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            onPressed: _nextWeek,
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semaine suivante',
          ),
        ],
      ),
    );
  }

  String _getMonthYearText(DateTime start, DateTime end) {
    final months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre'
    ];

    if (start.month == end.month) {
      return '${months[start.month - 1]} ${start.year}';
    } else {
      return '${months[start.month - 1]} - ${months[end.month - 1]} ${start.year}';
    }
  }

  Widget _buildTimelineContent(List<DateTime> weekDays) {
    return ListView.builder(
      controller: _scrollController,
      scrollDirection: Axis.horizontal,
      itemCount: weekDays.length,
      itemBuilder: (context, index) {
        final date = weekDays[index];
        final isToday = _isToday(date);
        final dateKey = DateTime(date.year, date.month, date.day);
        final sessions = widget.schedulesByDate[dateKey] ?? [];

        return _buildDayColumn(date, sessions, isToday);
      },
    );
  }

  Widget _buildDayColumn(
      DateTime date, List<SessionSchedule> sessions, bool isToday) {
    return Container(
      width: _dayColumnWidth,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: isToday ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          _buildDayHeader(date, isToday),
          Expanded(
            child: sessions.isEmpty
                ? _buildEmptyDay()
                : _buildSessionsList(sessions),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader(DateTime date, bool isToday) {
    final dayOfWeek = DayOfWeek.fromDateTime(date);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isToday
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          Text(
            dayOfWeek.shortName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: isToday
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isToday
                  ? Theme.of(context).colorScheme.onPrimary
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${date.day}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 32,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Aucun cours',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionsList(List<SessionSchedule> sessions) {
    sessions.sort((a, b) =>
        a.timeSlot.startTime.hour * 60 +
        a.timeSlot.startTime.minute -
        b.timeSlot.startTime.hour * 60 -
        b.timeSlot.startTime.minute);

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        return _buildSessionCard(sessions[index]);
      },
    );
  }

  Widget _buildSessionCard(SessionSchedule session) {
    final course = widget.coursesById[session.courseId];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => widget.onSessionTap?.call(session),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                session.timeSlot.displayTime,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                course?.title ?? 'Cours',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (course?.category != null) ...[
                const SizedBox(height: 4),
                Chip(
                  label: Text(
                    course!.category.displayName,
                    style: const TextStyle(fontSize: 10),
                  ),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${session.currentEnrollment}/${session.maxCapacity}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
