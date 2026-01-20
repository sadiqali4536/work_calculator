import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:working_hour_time_calculator/data_store.dart';
import 'package:working_hour_time_calculator/models/break_snapshort.dart';
import 'package:working_hour_time_calculator/pages/settings.dart';
import 'dart:async';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TimeOfDay? morningEntry;
  TimeOfDay? eveningOut;
  Duration breakHours = const Duration(hours: 1);
  Duration workingHours = const Duration(hours: 7);
  TimeOfDay presetMorningEntry = const TimeOfDay(hour: 9, minute: 30);
  Timer? _breakTimer;
  bool _alerted = false;

  List<BreakSession> breaks = [];
  BreakSession? activeBreak;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    DataStore.instance.addListener(_onDataStoreChanged);
    DataStore.instance.load().then((_) => _loadTodayFromStore());
  }

  @override
  void dispose() {
    _breakTimer?.cancel();
    DataStore.instance.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  void _onDataStoreChanged() => _loadTodayFromStore();

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final breakMinutes = prefs.getInt('break_hours') ?? 60;
      breakHours = Duration(minutes: breakMinutes);

      final workMinutes = prefs.getInt('working_hours') ?? 420;
      workingHours = Duration(minutes: workMinutes);

      final presetHour = prefs.getInt('preset_morning_hour') ?? 9;
      final presetMinute = prefs.getInt('preset_morning_minute') ?? 30;
      presetMorningEntry = TimeOfDay(hour: presetHour, minute: presetMinute);
    });
  }

  void _loadTodayFromStore() {
    final today = DataStore.instance.getTodayEntry();
    if (today != null) {
      setState(() {
        morningEntry = today.morningEntry;
        eveningOut = today.eveningOut;
        workingHours = today.workingHours;
        breakHours = today.breakHours;

        breaks = today.breaks
            .map(
              (bs) =>
                  BreakSession(title: bs.title, start: bs.start, end: bs.end),
            )
            .toList();

        activeBreak = breaks.firstWhere(
          (b) => b.start != null && b.end == null,
          orElse: () => BreakSession(title: ''),
        );
        if (activeBreak?.start == null) activeBreak = null;
      });
    }
  }

  // Total break used (only finished breaks)
  Duration get totalBreakUsed {
    return breaks.fold(Duration.zero, (sum, b) {
      if (b.start != null && b.end != null) {
        final start = DateTime(2000, 1, 1, b.start!.hour, b.start!.minute);
        final end = DateTime(2000, 1, 1, b.end!.hour, b.end!.minute);
        return sum + end.difference(start);
      }
      return sum;
    });
  }

  // Actual break used including active (running) break
  Duration get actualBreakUsed {
    return breaks.fold(Duration.zero, (sum, b) => sum + b.duration);
  }

  // Calculate remaining break time (from allowed break hours)
  Duration get remainingBreak {
    final remaining = breakHours - actualBreakUsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  // Check if break time is fully used or exceeded
  bool get isBreakCovered => actualBreakUsed >= breakHours;

  // Calculate the standard office end time (preset arrival + work + allowed break)
  TimeOfDay get standardOfficeEnd {
    final now = DateTime.now();
    final standardEndDT = DateTime(
      now.year,
      now.month,
      now.day,
      presetMorningEntry.hour,
      presetMorningEntry.minute,
    ).add(workingHours).add(breakHours);

    return TimeOfDay(hour: standardEndDT.hour, minute: standardEndDT.minute);
  }

  // Calculate when you actually complete your work (arrival + 7h + breaks taken)
  TimeOfDay? get workCompletionTime {
    if (morningEntry == null) return null;

    final now = DateTime.now();
    final arrivalDT = DateTime(
      now.year,
      now.month,
      now.day,
      morningEntry!.hour,
      morningEntry!.minute,
    );

    // Work completion = Arrival + Required Work Hours + Actual Break Used
    final completionDT = arrivalDT.add(workingHours).add(actualBreakUsed);
    return TimeOfDay(hour: completionDT.hour % 24, minute: completionDT.minute);
  }

  // FIXED EXIT TIME WITH OVERTIME:
  // - If you finish work BEFORE standard end (5:30 PM): Exit at 5:30 PM (must wait)
  // - If you finish work AFTER standard end: Exit when work is done (overtime)
  TimeOfDay? get calculatedEveningOut {
    if (morningEntry == null || workCompletionTime == null) return null;

    final now = DateTime.now();

    final completionDT = DateTime(
      now.year,
      now.month,
      now.day,
      workCompletionTime!.hour,
      workCompletionTime!.minute,
    );

    final standardEndDT = DateTime(
      now.year,
      now.month,
      now.day,
      standardOfficeEnd.hour,
      standardOfficeEnd.minute,
    );

    // If work completion is after standard end time, must stay until work is done
    if (completionDT.isAfter(standardEndDT)) {
      return workCompletionTime; // Exit when work completes (overtime)
    }

    // Otherwise, exit at standard time
    return standardOfficeEnd; // Exit at 5:30 PM (fixed time)
  }

  // Calculate idle time (time spent waiting at office after work is done)
  Duration get idleTime {
    if (morningEntry == null || workCompletionTime == null)
      return Duration.zero;

    final now = DateTime.now();
    final completionDT = DateTime(
      now.year,
      now.month,
      now.day,
      workCompletionTime!.hour,
      workCompletionTime!.minute,
    );

    final officialEndDT = DateTime(
      now.year,
      now.month,
      now.day,
      standardOfficeEnd.hour,
      standardOfficeEnd.minute,
    );

    final difference = officialEndDT.difference(completionDT);
    return difference.isNegative ? Duration.zero : difference;
  }

  // Calculate overtime (working past standard office end time)
  Duration get overtimeHours {
    if (morningEntry == null || workCompletionTime == null)
      return Duration.zero;

    final now = DateTime.now();
    final completionDT = DateTime(
      now.year,
      now.month,
      now.day,
      workCompletionTime!.hour,
      workCompletionTime!.minute,
    );

    final standardEndDT = DateTime(
      now.year,
      now.month,
      now.day,
      standardOfficeEnd.hour,
      standardOfficeEnd.minute,
    );

    final difference = completionDT.difference(standardEndDT);
    return difference.isNegative ? Duration.zero : difference;
  }

  // Check if working overtime
  bool get hasOvertime => overtimeHours.inSeconds > 0;

  // Calculate actual free time available (remaining slack before overtime)
  Duration _calculateActualFreeTime() {
    return idleTime;
  }

  Future<void> _saveHistory() async {
    final snaps = breaks
        .map(
          (b) => BreakSnapshot(
            title: b.title,
            start: b.start,
            end: b.end,
            duration: b.duration,
            note: '',
          ),
        )
        .toList();

    await DataStore.instance.updateToday(
      morningEntry: morningEntry,
      eveningOut: calculatedEveningOut,
      workingHours: workingHours,
      breakHours: breakHours,
      breaks: snaps,
    );
  }

  void _recordEntry() async {
    final now = TimeOfDay.now();
    setState(() => morningEntry = now);
    await _saveHistory();
  }

  Future<void> _editMorningEntry() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: morningEntry ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => morningEntry = picked);
      await _saveHistory();
    }
  }

  void _startBreak() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildConfirmSheet(ctx, 'Start Break?', 'Start'),
    );

    if (result == true) {
      final now = TimeOfDay.now();
      setState(() {
        activeBreak = BreakSession(
          title: 'Break ${breaks.length + 1}',
          start: now,
        );
        breaks.add(activeBreak!);
        _alerted = false;
      });
      _startBreakTimer();
      await _saveHistory();
    }
  }

  void _endBreak() async {
    _breakTimer?.cancel();
    if (activeBreak != null) {
      final now = TimeOfDay.now();
      setState(() {
        activeBreak!.end = now;
        activeBreak = null;
      });
      await _saveHistory();
    }
  }

  void _startBreakTimer() {
    _breakTimer?.cancel();
    _alerted = false;

    _breakTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && activeBreak != null) {
        setState(() {
          // Trigger rebuild to update real-time getters
        });

        // Check if break time is exhausted
        final remainingBreak = breakHours - actualBreakUsed;
        final safeRemainingBreak = remainingBreak.isNegative
            ? Duration.zero
            : remainingBreak;

        // Fire alert ONLY once when break time runs out
        if (safeRemainingBreak.inSeconds == 0 && !_alerted) {
          _alerted = true;
          _showOverBreakAlert();
          HapticFeedback.vibrate();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _showOverBreakAlert() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Break Time Over!',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'You have used all your available break time (${formatDuration(breakHours)}).\n\nAny additional break will extend your exit time.',
          style: const TextStyle(color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK', style: TextStyle(color: Color(0xFF0A84FF))),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmSheet(BuildContext ctx, String title, String actionText) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Color(0xFFE5E5EA)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A1A),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    actionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _nextDay() async {
    await _saveHistory();
    setState(() {
      morningEntry = null;
      eveningOut = null;
      breaks = [];
      activeBreak = null;
    });
    await DataStore.instance.updateToday(
      morningEntry: null,
      eveningOut: null,
      workingHours: workingHours,
      breakHours: breakHours,
      breaks: [],
    );
  }

  String formatDuration(Duration d) =>
      "${d.inHours.toString().padLeft(2, '0')}:${(d.inMinutes % 60).toString().padLeft(2, '0')}";
  String formatTime(TimeOfDay? t) => t == null ? "--:--" : t.format(context);

  @override
  Widget build(BuildContext context) {
    final showEveningOut = morningEntry != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Work Tracker",
          style: TextStyle(
            color: const Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
            color: Colors.white,
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SettingsPage()),
                ).then((result) {
                  if (result == true) {
                    _loadSettings();
                  }
                });
              } else if (value == 'next_day') {
                _showNextDayDialog();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'next_day',
                child: Row(
                  children: [
                    Icon(Icons.today, color: Color(0xFF0A84FF), size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Next Day',
                      style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings, color: Color(0xFF0A84FF), size: 22),
                    SizedBox(width: 12),
                    Text(
                      'Settings',
                      style: TextStyle(fontSize: 16, color: Color(0xFF1A1A1A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Container(height: 0.5, color: const Color(0xFFE5E5EA)),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 15,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Morning Entry',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                formatTime(morningEntry),
                                style: TextStyle(
                                  fontSize: 17,
                                  color: morningEntry != null
                                      ? const Color(0xFF0A84FF)
                                      : Colors.grey[400],
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (morningEntry != null) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: _editMorningEntry,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF0A84FF,
                                      ).withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.edit,
                                      size: 18,
                                      color: Color(0xFF0A84FF),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (activeBreak != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF453A).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Color(0xFFFF453A),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Break Timer: ${formatDuration(activeBreak?.duration ?? Duration.zero)}",
                              style: const TextStyle(
                                color: Color(0xFFFF453A),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    if (showEveningOut)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              'Work end Time',
                              formatTime(calculatedEveningOut),
                              hasOvertime
                                  ? const Color(0xFFFF453A)
                                  : const Color(0xFF0A84FF),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: Color(0xFFF2F2F7),
                                height: 1,
                              ),
                            ),
                            _buildStatRow(
                              'Break Used',
                              formatDuration(actualBreakUsed),
                              const Color(0xFF1A1A1A),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Divider(
                                color: Color(0xFFF2F2F7),
                                height: 1,
                              ),
                            ),
                            _buildStatRow(
                              idleTime.inSeconds > 0
                                  ? 'Free Time '
                                  : 'Remaining Break',
                              idleTime.inSeconds > 0
                                  ? formatDuration(_calculateActualFreeTime())
                                  : formatDuration(remainingBreak),
                              isBreakCovered && idleTime.inSeconds == 0
                                  ? const Color(0xFFFF453A)
                                  : const Color(0xFF30D158),
                            ),
                            if (hasOvertime) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(
                                  color: Color(0xFFF2F2F7),
                                  height: 1,
                                ),
                              ),
                              _buildStatRow(
                                'Overtime',
                                formatDuration(overtimeHours),
                                const Color(0xFFFF453A),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            decoration: BoxDecoration(
              color: const Color.fromARGB(0, 255, 255, 255),
              border: Border(
                top: BorderSide(color: const Color(0xFFF2F2F7), width: 1),
              ),
            ),
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: morningEntry == null
                      ? _recordEntry
                      : (activeBreak == null ? _startBreak : _endBreak),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: morningEntry == null
                          ? const Color(0xFF1A1A1A)
                          : (activeBreak == null
                                ? const Color(0xFF0A84FF)
                                : const Color(0xFFFF453A)),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (morningEntry == null
                                      ? const Color(0xFF1A1A1A)
                                      : (activeBreak == null
                                            ? const Color(0xFF0A84FF)
                                            : const Color(0xFFFF453A)))
                                  .withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Icon(
                      morningEntry == null
                          ? Icons.power_settings_new
                          : (activeBreak == null
                                ? Icons.coffee
                                : Icons.stop_circle_outlined),
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF666666),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  void _showNextDayDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Proceed to Next Day?',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: const Text(
          'This will reset your current day data and start a new day.',
          style: TextStyle(fontSize: 15, color: Color(0xFF666666)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _nextDay();
            },
            child: const Text(
              'Continue',
              style: TextStyle(
                color: Color(0xFF0A84FF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BreakSession {
  String title;
  TimeOfDay? start;
  TimeOfDay? end;

  BreakSession({required this.title, this.start, this.end});

  Duration get duration {
    if (start == null) return Duration.zero;
    if (end != null) {
      final startDT = DateTime(2000, 1, 1, start!.hour, start!.minute);
      final endDT = DateTime(2000, 1, 1, end!.hour, end!.minute);
      return endDT.difference(startDT);
    } else {
      final now = DateTime.now();
      final startDT = DateTime(
        now.year,
        now.month,
        now.day,
        start!.hour,
        start!.minute,
      );
      final diff = now.difference(startDT);
      return diff.isNegative ? Duration.zero : diff;
    }
  }
}
