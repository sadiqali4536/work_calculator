import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:working_hour_time_calculator/data_store.dart';
import 'package:working_hour_time_calculator/models/break_snapshort.dart';
import 'package:working_hour_time_calculator/pages/settings.dart';

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
    DataStore.instance.removeListener(_onDataStoreChanged);
    super.dispose();
  }

  void _onDataStoreChanged() => _loadTodayFromStore();

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final breakMinutes = prefs.getInt('break_hours') ?? 60;
      breakHours = Duration(minutes: breakMinutes);
      
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
        
        breaks = today.breaks.map((bs) => BreakSession(
          title: bs.title,
          start: bs.start,
          end: bs.end,
        )).toList();
        
        activeBreak = breaks.firstWhere(
          (b) => b.start != null && b.end == null,
          orElse: () => BreakSession(title: ''),
        );
        if (activeBreak?.start == null) activeBreak = null;
      });
    }
  }

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

  Duration get earlyArrivalBonus {
    if (morningEntry == null) return Duration.zero;
    
    final presetDT = DateTime(2000, 1, 1, presetMorningEntry.hour, presetMorningEntry.minute);
    final actualDT = DateTime(2000, 1, 1, morningEntry!.hour, morningEntry!.minute);
    
    final difference = presetDT.difference(actualDT);
    return difference.isNegative ? Duration.zero : difference;
  }

  Duration get totalAvailableBreak {
    return breakHours + earlyArrivalBonus;
  }

  Duration get remainingBreak {
    final remaining = totalAvailableBreak - totalBreakUsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  Duration get overtimeUsed {
    final overtime = totalBreakUsed - totalAvailableBreak;
    return overtime.isNegative ? Duration.zero : overtime;
  }

  bool get isBreakCovered {
    return totalBreakUsed >= totalAvailableBreak;
  }

  TimeOfDay? get calculatedEveningOut {
    if (morningEntry == null) return null;

    final now = DateTime.now();

    // Base preset evening time = preset morning + working hours + preset break
    final presetEveningDT = DateTime(
      now.year,
      now.month,
      now.day,
      presetMorningEntry.hour,
      presetMorningEntry.minute,
    ).add(workingHours).add(breakHours);

    // Calculate if user exceeded available break (preset + early bonus)
    final overtime = totalBreakUsed - totalAvailableBreak;

    // If break used <= total available (preset + bonus), always show preset evening time
    // This means early arrival converts to extra break, not early leave
    if (overtime.isNegative || overtime == Duration.zero) {
      return TimeOfDay(hour: presetEveningDT.hour, minute: presetEveningDT.minute);
    }

    // If exceeded → extend preset evening by overtime duration
    final adjustedEveningDT = presetEveningDT.add(overtime);
    return TimeOfDay(hour: adjustedEveningDT.hour, minute: adjustedEveningDT.minute);
  }

  String get breakStatus {
    if (breaks.isEmpty || totalBreakUsed == Duration.zero) {
      return 'No breaks taken yet';
    }
    
    if (totalBreakUsed < breakHours) {
      return 'Break time not covered';
    } else if (totalBreakUsed == breakHours) {
      return 'Break time covered';
    } else {
      return 'Break time exceeded';
    }
  }

  Future<void> _saveHistory() async {
    final snaps = breaks.map((b) => BreakSnapshot(
      title: b.title,
      start: b.start,
      end: b.end,
      duration: b.duration,
      note: '',
    )).toList();

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

  void _startBreak() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            const Text(
              'Start Break?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[400]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        color: Colors.black,
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
                      backgroundColor: const Color(0xFF0095F6),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
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
      ),
    );

    if (result == true) {
      final now = TimeOfDay.now();
      setState(() {
        activeBreak = BreakSession(
          title: 'Break ${breaks.length + 1}',
          start: now,
        );
        breaks.add(activeBreak!);
      });
      await _saveHistory();
    }
  }

  void _endBreak() async {
    if (activeBreak != null) {
      final now = TimeOfDay.now();
      setState(() {
        activeBreak!.end = now;
        activeBreak = null;
      });
      await _saveHistory();
    }
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

  String formatTime(TimeOfDay? t) {
    if (t == null) return "--:--";
    return t.format(context);
  }

  @override
  Widget build(BuildContext context) {
    final hasBreaks = breaks.isNotEmpty && totalBreakUsed > Duration.zero;
    final showEveningOut = morningEntry != null;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF000000),
        title: const Text(
          "Work Tracker",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1C1C1E),
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            onSelected: (value) {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => SettingsPage()),
                ).then((_) => _loadSettings());
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                      ),
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
          // Divider
          Container(
            height: 0.5,
            color: const Color(0xFF3A3A3C),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Morning Entry Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Morning Entry',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            formatTime(morningEntry),
                            style: TextStyle(
                              fontSize: 17,
                              color: morningEntry != null ? const Color(0xFF0A84FF) : Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Break Button
                    if (morningEntry != null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: activeBreak == null ? _startBreak : _endBreak,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeBreak == null
                                ? const Color(0xFF0A84FF)
                                : const Color(0xFFFF453A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            activeBreak == null ? "Add Break" : "End Break",
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Summary Section
                    if (showEveningOut) ...[
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            // Evening Out Time - Always Show
                            _buildStatRow(
                              'Evening Out',
                              formatTime(calculatedEveningOut),
                              const Color(0xFF0A84FF),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, color: const Color(0xFF3A3A3C)),
                            ),
                            
                            // Break Status
                            if (hasBreaks) ...[
                              _buildStatRow(
                                'Break Status',
                                breakStatus,
                                isBreakCovered ? const Color(0xFF30D158) : const Color(0xFFFFCC00),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, color: const Color(0xFF3A3A3C)),
                              ),
                            ],
                            
                            // Early Arrival Bonus
                            if (earlyArrivalBonus > Duration.zero) ...[
                              _buildStatRow(
                                'Early Arrival Bonus',
                                formatDuration(earlyArrivalBonus),
                                const Color(0xFF30D158),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, color: const Color(0xFF3A3A3C)),
                              ),
                            ],
                            
                            // Total Break Used
                            _buildStatRow(
                              'Total Break Used',
                              formatDuration(totalBreakUsed),
                              Colors.white,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Divider(height: 1, color: const Color(0xFF3A3A3C)),
                            ),
                            
                            // Available Break Time (Preset + Bonus)
                            _buildStatRow(
                              'Available Break',
                              formatDuration(totalAvailableBreak),
                              const Color(0xFF0A84FF),
                            ),
                            
                            // Show remaining or overtime
                            if (hasBreaks) ...[
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Divider(height: 1, color: const Color(0xFF3A3A3C)),
                              ),
                              _buildStatRow(
                                isBreakCovered ? 'Overtime Used' : 'Remaining Break',
                                formatDuration(isBreakCovered ? overtimeUsed : remainingBreak),
                                isBreakCovered ? const Color(0xFFFF453A) : const Color(0xFF30D158),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          
          // Power Button at Bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFF3A3A3C).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Center(
                child: GestureDetector(
                  onTap: morningEntry == null ? _recordEntry : null,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: morningEntry == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0A84FF),
                                Color(0xFF0066FF),
                              ],
                            )
                          : LinearGradient(
                              colors: [
                                const Color(0xFF3A3A3C).withOpacity(0.5),
                                const Color(0xFF3A3A3C).withOpacity(0.3),
                              ],
                            ),
                      boxShadow: morningEntry == null
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0A84FF).withOpacity(0.5),
                                blurRadius: 40,
                                spreadRadius: 5,
                              ),
                            ]
                          : [],
                    ),
                    child: const Icon(
                      Icons.power_settings_new,
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

  Widget _buildStatRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  void _showNextDayDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Start Next Day?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'This will reset your current day data and start a new day.',
          style: TextStyle(
            fontSize: 15,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Colors.white70,
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

  BreakSession({
    required this.title,
    this.start,
    this.end,
  });

  Duration get duration {
    if (start == null || end == null) return Duration.zero;
    final startDT = DateTime(2000, 1, 1, start!.hour, start!.minute);
    final endDT = DateTime(2000, 1, 1, end!.hour, end!.minute);
    return endDT.difference(startDT);
  }
}


