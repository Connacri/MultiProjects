library calendar_planner_view;

// Extensions
export 'src/extensions/calendar_style_extension.dart';
// Models
export 'src/models/calendar_enums.dart';
export 'src/models/event_model.dart';
export 'src/models/event_utils.dart';
export 'src/models/time_label_eums.dart';
// Utils
export 'src/utils/date_utils.dart';
export 'src/utils/style_utils.dart';
// Widgets
export 'src/date_picker.dart';
export 'src/event_list.dart';
export 'src/planner_view.dart';
export 'src/time_labels.dart';

/// A customizable calendar planner view with advanced localization support.
///
/// This package provides a flexible and customizable calendar planner view that
/// displays events in a modern, card-based list format by default, with optional
/// timeline view for traditional hourly layouts. Key features include:
/// * Modern List View (Default): Beautiful card-based event display with enhanced UX
/// * Custom List Builder: Complete control over event layout and styling
/// * Optional Timeline View: Traditional hourly timeline available via toggle
/// * Time-based event management with customizable time ranges
/// * Month and week view support with smooth transitions
/// * Material 3 design support with theme awareness
/// * Flexible date picker (top or modal) with complete customization
/// * Multi-column layout support for event categorization
/// * Event indicators with customizable shapes and colors
/// * Responsive design for all screen sizes
/// * Enhanced localization support for various languages (including Turkish and Japanese)
/// * Event overlap handling and smart positioning
/// * Loading overlay with customizable appearance
/// * Advanced animation support for smooth transitions
///
/// ## Installation
/// Add this to your package's `pubspec.yaml` file:
///
/// dependencies:
///   calendar_planner_view: any
///
/// ## Usage
/// import 'package:calendar_planner_view/calendar_planner_view.dart';
///
/// Basic usage:
/// CalendarPlannerView(
///   events: myEvents,
///   onEventTap: (event) => print('Event tapped: $event'),
///   onDateChanged: (date) => print('Date changed: $date'),
///   datePickerPosition: DatePickerPosition.top,
///   startHour: 8,
///   endHour: 18,
///   showCurrentTimeIndicator: true,
/// )
///
/// Advanced usage with multi-column layout and loading overlay:
/// CalendarPlannerView(
///   events: myEvents,
///   onEventTap: (event) => print('Event tapped: $event'),
///   onDateChanged: (date) {
/// Update your app's state with the new date:
///     setState(() => selectedDate = date);
/// Optionally fetch events for the new date:
///     fetchEventsForDate(date);
///   },
///   datePickerPosition: DatePickerPosition.modal,
///   startHour: 8,
///   endHour: 20,
///   showDayTitle: true,
///   enableViewToggle: true,
///   initialView: CalendarViewType.week,
///   showCurrentTimeIndicator: true,
///   columns: [
///     (id: 'work', title: 'Work'),
///     (id: 'personal', title: 'Personal'),
///     (id: 'meetings', title: 'Meetings'),
///   ],
///   dotColor: Colors.blue,
///   dotSize: 5.0,
///   eventDotShape: EventDotShape.circle,
///   highlightCurrentHour: true,
///   modalBackgroundColor: Colors.white,
/// Dropdown styling:
///   dropdownBorder: OutlineInputBorder(
///     borderRadius: BorderRadius.circular(8),
///     borderSide: BorderSide(color: Colors.blue.withAlpha(50)),
///   ),
///   dropdownPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
/// Custom event builder for internationalized text:
///   eventBuilder: (context, event, ...) => LocalizedEventCard(...),
/// Loading overlay configuration:
///   isLoading: true,
///   loadingBuilder: (context) => Center(
///     child: CircularProgressIndicator(color: Colors.blue),
///   ),
///   loadingOverlayColor: Colors.black12,
///   showContentWhileLoading: false,
/// Toggle between list view (default) and timeline view:
///   showListView: false, // Switch to timeline view mode
/// Custom list builder for complete control over event display:
///   listBuilder: (context, events, selectedDate) => CustomScrollView(
///     slivers: [
///       SliverToBoxAdapter(
///         child: Text('Events for ${selectedDate.day}/${selectedDate.month}'),
///       ),
///       SliverList(
///         delegate: SliverChildBuilderDelegate(
///           (context, index) => CustomEventCard(events[index]),
///           childCount: events.length,
///         ),
///       ),
///     ],
///   ),
/// )
///
/// ## Features
/// * Time-based Events: Display events with specific start and end times
/// * Multiple Views: Switch between month and week views with smooth transitions
/// * Customizable Styling: Theme-aware design with Material 3 support
/// * Event Management: Add, edit, and delete events with overlap handling
/// * Date Navigation: Flexible date selection with top or modal picker
/// * Responsive Design: Adapts to different screen sizes
/// * Accessibility: Support for screen readers and keyboard navigation
/// * Multi-column Layout: Organize events into separate columns
/// * Event Overlap Handling: Smart positioning of overlapping events
/// * Custom Event Builders: Create custom event displays
/// * Time Range Control: Set custom start and end hours
/// * Event Indicators: Visual dots with customizable shapes and colors
/// * Date Change Callbacks: Respond to date selection changes
/// * Current Hour Highlighting: Visual indicator for current time
/// * Current Time Indicator: Shows current time line in the timeline
/// * Custom Time Labels: Format time labels with custom builder
/// * Localization: Enhanced support for different languages and date formats
/// * Loading Overlay: Customizable loading state with optional content visibility
/// * Dropdown Styling: Custom border and padding options for dropdown menus
/// * Custom List Builder: Complete control over event list display with custom layouts
/// * Calendar-Only Mode: Use only the calendar picker with custom event display layouts
/// * Modern List View: Enhanced card-based event display as the default experience
/// * View Mode Toggle: Easy switching between modern list layouts and traditional timeline
///
/// ## Multi-column Layout
/// The calendar planner supports organizing events into multiple columns:
/// * Timeline View: Events are positioned in visual columns with headers and dropdowns
/// * List View: Column information is shown as badges/tags on event cards
/// * Define columns with unique IDs and optional titles (supports localized text)
/// * Assign events to specific columns using `columnId`
/// * Timeline: Automatic column width calculation with visual dividers
/// * Timeline: Column headers and dropdown filtering available
/// * List: Column info displayed as category tags on events
/// * Minimum 2 columns, maximum 10 columns
/// * Events without columnId use default column
///
/// ## Date Picker
/// The widget offers two date picker modes:
/// * Top Position: Always visible above the timeline
/// * Modal Position: Appears in an animated dialog with:
///   - Smooth scale and fade animations
///   - Gradient header with calendar icon
///   - "Today" button with icon
///   - Customizable styling
///   - Responsive layout
///   - Complete customization options
///     - Week number styling and layout
///     - Chevron icon customization
///     - Calendar container styling
///     - Date range constraints
///     - Header styling
///
/// ## View Mode Toggle
/// The `showListView` parameter allows switching between list view and timeline display modes:
/// * List Mode (default): Modern card-based event list with chronological ordering
/// * Timeline Mode: Traditional hourly timeline with time labels and event positioning
/// * Custom List Builder: When `showListView: true` (default), optionally provide `listBuilder` for complete customization
/// * Default List View: If no `listBuilder` provided, shows a clean default list layout
/// * Seamless Integration: Both modes maintain full calendar picker functionality
///
/// ## Custom List Builder
/// The `listBuilder` parameter (when `showListView: true` - default) allows complete customization:
/// * Replaces Default List: Substitutes the default list with your custom widget
/// * Filtered Event Access: Receives pre-filtered events for the selected date
/// * Date Context: Provides the selected date for custom formatting and display
/// * Flexible Layouts: Supports any Flutter widget (ListView, GridView, CustomScrollView, Column, etc.)
/// * Calendar Integration: Maintains full calendar picker functionality at the top
/// * Creative Freedom: Perfect for card layouts, grouped displays, agenda views, or any custom visualization
/// * Event Interaction: Handle event taps and interactions within your custom builder
/// * Responsive Design: Build layouts that adapt to different screen sizes
/// * Theme Awareness: Access theme data for consistent styling
///
/// Example use cases:
/// * Card-based event lists with custom styling
/// * Grouped events by time or category
/// * Agenda-style layouts with enhanced typography
/// * Grid views for visual event browsing
/// * Alternative list representations with enhanced UX
///
/// ## Callbacks
/// The widget provides several callbacks for handling user interactions:
/// * `onEventTap`: Triggered when an event is tapped
/// * `onDateChanged`: Triggered when the selected date changes
/// * `onColumnChanged`: Triggered when a different column is selected
///
/// ## Dependencies
/// * Flutter SDK
/// * intl: ^0.20.2
/// * table_calendar: ^3.2.0
/// * flutter_hooks: ^0.20.0
///
/// ## Contributing
/// Contributions are welcome! Please feel free to submit a Pull Request.
/// For major changes, please open an issue first to discuss what you would like to change.
///
/// ## License
/// This project is licensed under the MIT License - see the LICENSE file for details.
