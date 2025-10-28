


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay morningEntry = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay eveningOut = const TimeOfDay(hour: 17, minute: 30);
  Duration breakHours = const Duration(hours: 1);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      final morningMinutes = prefs.getInt('morning_entry') ?? 540; // 9:00 AM
      morningEntry = TimeOfDay(
        hour: morningMinutes ~/ 60,
        minute: morningMinutes % 60,
      );

      final eveningMinutes = prefs.getInt('evening_out') ?? 1050; // 5:30 PM
      eveningOut = TimeOfDay(
        hour: eveningMinutes ~/ 60,
        minute: eveningMinutes % 60,
      );

      final breakMinutes = prefs.getInt('break_hours') ?? 60; // 1 hour
      breakHours = Duration(minutes: breakMinutes);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('morning_entry', morningEntry.hour * 60 + morningEntry.minute);
    await prefs.setInt('evening_out', eveningOut.hour * 60 + eveningOut.minute);
    await prefs.setInt('break_hours', breakHours.inMinutes);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Color(0xFF30D158),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String formatTime(TimeOfDay time) => time.format(context);

  String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF000000),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 0.5,
            color: const Color(0xFF3A3A3C),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Morning Entry
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A84FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.wb_sunny,
                        color: Color(0xFF0A84FF),
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Morning Entry Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatTime(morningEntry),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: morningEntry,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF0A84FF),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1C1C1E),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF1C1C1E),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => morningEntry = time);
                      }
                    },
                  ),
                ),

                // Evening Out
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF453A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.nightlight_round,
                        color: Color(0xFFFF453A),
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Evening Out Time',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatTime(eveningOut),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: eveningOut,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF0A84FF),
                                onPrimary: Colors.white,
                                surface: Color(0xFF1C1C1E),
                                onSurface: Colors.white,
                              ),
                              dialogBackgroundColor: const Color(0xFF1C1C1E),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => eveningOut = time);
                      }
                    },
                  ),
                ),

                // Break Duration
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF30D158).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.coffee,
                        color: Color(0xFF30D158),
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Break Duration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatDuration(breakHours),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right,
                      color: Colors.white38,
                    ),
                    onTap: () async {
                      final controller = TextEditingController(
                        text: breakHours.inMinutes.toString(),
                      );
                      final result = await showDialog<int>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1C1C1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Set Break Duration',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          content: TextField(
                            controller: controller,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: 'Enter minutes',
                              hintStyle: TextStyle(color: Colors.white38),
                              suffix: Text(
                                'minutes',
                                style: TextStyle(color: Colors.white54),
                              ),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF3A3A3C)),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF0A84FF)),
                              ),
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
                                final minutes = int.tryParse(controller.text);
                                Navigator.pop(ctx, minutes);
                              },
                              child: const Text(
                                'Save',
                                style: TextStyle(
                                  color: Color(0xFF0A84FF),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (result != null) {
                        setState(() => breakHours = Duration(minutes: result));
                      }
                    },
                  ),
                ),

                const SizedBox(height: 8),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0A84FF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}