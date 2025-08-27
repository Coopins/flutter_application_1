// lib/screens/calendar_screen.dart

import 'package:flutter/material.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final PageController _pageController = PageController(initialPage: 0);

  // Example map of dates to activity details
  final Map<DateTime, String> _notes = {
    DateTime(2025, 2, 6): 'Practiced vocabulary: numbers 1–10',
    DateTime(2025, 2, 12): 'Missed session',
  };

  static const _monthNames = [
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
    'December',
  ];

  DateTime _monthForIndex(int index) {
    final base = DateTime(2025, 2);
    final yearOffset = (base.month - 1 + index) ~/ 12;
    final month = (base.month - 1 + index) % 12 + 1;
    return DateTime(base.year + yearOffset, month);
  }

  void _showDetails(BuildContext ctx, DateTime date) {
    final note = _notes[DateTime(date.year, date.month, date.day)];
    showDialog(
      context: ctx,
      builder:
          (_) => AlertDialog(
            title: Text('${date.toLocal()}'.split(' ')[0]),
            content: Text(note ?? 'No activity logged for this day.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _buildDayCell(DateTime date) {
    final dayNum = date.day;
    final hasNote = _notes.containsKey(
      DateTime(date.year, date.month, date.day),
    );

    return GestureDetector(
      onTap: () => _showDetails(context, date),
      child: Container(
        decoration:
            hasNote
                ? BoxDecoration(
                  color: Colors.green[300],
                  shape: BoxShape.circle,
                )
                : null,
        alignment: Alignment.center,
        child: Text(
          '$dayNum',
          style: TextStyle(
            color: Colors.black,
            fontWeight: hasNote ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthView(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final firstWeekday = firstDay.weekday; // 1=Mon,7=Sun
    final totalCells = ((firstWeekday - 1) + daysInMonth + 6) ~/ 7 * 7;

    final rows = <TableRow>[];
    for (int i = 0; i < totalCells; i += 7) {
      final days = <Widget>[];
      for (int j = 0; j < 7; j++) {
        final cellIndex = i + j;
        final dayNum = cellIndex - (firstWeekday - 2);
        final date = DateTime(month.year, month.month, dayNum);
        days.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _buildDayCell(date),
          ),
        );
      }
      rows.add(TableRow(children: days));
    }

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with month/year and quote
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_monthNames[month.month - 1]} ${month.year}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    '“The limits of my language mean the limits of my world.”',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Calendar grid
            Table(
              border: const TableBorder(
                horizontalInside: BorderSide(color: Colors.black, width: 1),
              ),
              children: rows,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Gab & Go',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Swipeable months
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemBuilder: (context, index) {
                  final month = _monthForIndex(index);
                  return _buildMonthView(month);
                },
              ),
            ),

            // Daily AI Prompt card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      "Today's AI Prompt: Describe your breakfast in Spanish",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.play_circle_fill,
                      size: 32,
                      color: Colors.black,
                    ),
                    onPressed: () {
                      // TODO: navigate to AI practice conversation
                    },
                  ),
                ],
              ),
            ),

            // Bottom nav bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  Icon(Icons.home, size: 28),
                  Icon(Icons.search, size: 28),
                  Icon(Icons.person, size: 28),
                  Icon(Icons.settings, size: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
