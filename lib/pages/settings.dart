


import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay presetMorningEntry = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay presetEveningOut = const TimeOfDay(hour: 17, minute: 30);
  Duration breakHours = const Duration(hours: 1);
  Duration workingHours = const Duration(hours: 7, minutes: 30);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // Load preset morning entry
      final presetMorningHour = prefs.getInt('preset_morning_hour') ?? 9;
      final presetMorningMinute = prefs.getInt('preset_morning_minute') ?? 30;
      presetMorningEntry = TimeOfDay(hour: presetMorningHour, minute: presetMorningMinute);

      // Load preset evening out
      final presetEveningHour = prefs.getInt('preset_evening_hour') ?? 17;
      final presetEveningMinute = prefs.getInt('preset_evening_minute') ?? 30;
      presetEveningOut = TimeOfDay(hour: presetEveningHour, minute: presetEveningMinute);

      // Load break hours
      final breakMinutes = prefs.getInt('break_hours') ?? 60;
      breakHours = Duration(minutes: breakMinutes);

      // Load working hours
      final workingMinutes = prefs.getInt('working_hours') ?? 450; // 7.5 hours
      workingHours = Duration(minutes: workingMinutes);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save preset morning entry
    await prefs.setInt('preset_morning_hour', presetMorningEntry.hour);
    await prefs.setInt('preset_morning_minute', presetMorningEntry.minute);
    
    // Save preset evening out
    await prefs.setInt('preset_evening_hour', presetEveningOut.hour);
    await prefs.setInt('preset_evening_minute', presetEveningOut.minute);
    
    // Save break hours
    await prefs.setInt('break_hours', breakHours.inMinutes);
    
    // Save working hours
    await prefs.setInt('working_hours', workingHours.inMinutes);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Color(0xFF30D158),
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Pop with result to trigger reload in home page
      Navigator.pop(context, true);
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
                // Preset Morning Entry Time
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
                      'Preset Morning Entry',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatTime(presetMorningEntry),
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
                        initialTime: presetMorningEntry,
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
                        setState(() => presetMorningEntry = time);
                      }
                    },
                  ),
                ),

                // Preset Evening Out Time
                // Container(
                //   margin: const EdgeInsets.only(bottom: 16),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF1C1C1E),
                //     borderRadius: BorderRadius.circular(16),
                //   ),
                //   child: ListTile(
                //     contentPadding: const EdgeInsets.symmetric(
                //       horizontal: 20,
                //       vertical: 12,
                //     ),
                //     leading: Container(
                //       padding: const EdgeInsets.all(10),
                //       decoration: BoxDecoration(
                //         color: const Color(0xFFFF453A).withOpacity(0.2),
                //         borderRadius: BorderRadius.circular(10),
                //       ),
                //       child: const Icon(
                //         Icons.nightlight_round,
                //         color: Color(0xFFFF453A),
                //         size: 24,
                //       ),
                //     ),
                //     title: const Text(
                //       'Preset Evening Out',
                //       style: TextStyle(
                //         fontSize: 16,
                //         fontWeight: FontWeight.w600,
                //         color: Colors.white,
                //       ),
                //     ),
                //     subtitle: Padding(
                //       padding: const EdgeInsets.only(top: 4),
                //       child: Text(
                //         formatTime(presetEveningOut),
                //         style: const TextStyle(
                //           fontSize: 14,
                //           color: Colors.white54,
                //         ),
                //       ),
                //     ),
                //     trailing: const Icon(
                //       Icons.chevron_right,
                //       color: Colors.white38,
                //     ),
                //     onTap: () async {
                //       final time = await showTimePicker(
                //         context: context,
                //         initialTime: presetEveningOut,
                //         builder: (context, child) {
                //           return Theme(
                //             data: ThemeData.dark().copyWith(
                //               colorScheme: const ColorScheme.dark(
                //                 primary: Color(0xFF0A84FF),
                //                 onPrimary: Colors.white,
                //                 surface: Color(0xFF1C1C1E),
                //                 onSurface: Colors.white,
                //               ),
                //               dialogBackgroundColor: const Color(0xFF1C1C1E),
                //             ),
                //             child: child!,
                //           );
                //         },
                //       );
                //       if (time != null) {
                //         setState(() => presetEveningOut = time);
                //       }
                //     },
                //   ),
                // ),

                // Working Hours Duration
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
                        color: const Color(0xFFFF9F0A).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.work,
                        color: Color(0xFFFF9F0A),
                        size: 24,
                      ),
                    ),
                    title: const Text(
                      'Working Hours',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        formatDuration(workingHours),
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
                        text: workingHours.inMinutes.toString(),
                      );
                      final result = await showDialog<int>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF1C1C1E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: const Text(
                            'Set Working Hours',
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
                      if (result != null && result > 0) {
                        setState(() => workingHours = Duration(minutes: result));
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
                      if (result != null && result > 0) {
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