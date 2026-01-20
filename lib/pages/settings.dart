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
      final presetMorningHour = prefs.getInt('preset_morning_hour') ?? 9;
      final presetMorningMinute = prefs.getInt('preset_morning_minute') ?? 30;
      presetMorningEntry = TimeOfDay(
        hour: presetMorningHour,
        minute: presetMorningMinute,
      );

      final presetEveningHour = prefs.getInt('preset_evening_hour') ?? 17;
      final presetEveningMinute = prefs.getInt('preset_evening_minute') ?? 30;
      presetEveningOut = TimeOfDay(
        hour: presetEveningHour,
        minute: presetEveningMinute,
      );

      final breakMinutes = prefs.getInt('break_hours') ?? 60;
      breakHours = Duration(minutes: breakMinutes);

      final workingMinutes = prefs.getInt('working_hours') ?? 450;
      workingHours = Duration(minutes: workingMinutes);
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('preset_morning_hour', presetMorningEntry.hour);
    await prefs.setInt('preset_morning_minute', presetMorningEntry.minute);
    await prefs.setInt('preset_evening_hour', presetEveningOut.hour);
    await prefs.setInt('preset_evening_minute', presetEveningOut.minute);
    await prefs.setInt('break_hours', breakHours.inMinutes);
    await prefs.setInt('working_hours', workingHours.inMinutes);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: Color(0xFF30D158),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1A1A1A),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSettingTile(
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFF0A84FF),
                  title: 'Preset Morning Entry',
                  subtitle: formatTime(presetMorningEntry),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: presetMorningEntry,
                      builder: (context, child) {
                        return Theme(
                          data: ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1A1A1A),
                              onPrimary: Colors.white,
                              surface: Colors.white,
                              onSurface: Color(0xFF1A1A1A),
                            ),
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (time != null) setState(() => presetMorningEntry = time);
                  },
                ),
                _buildSettingTile(
                  icon: Icons.work_rounded,
                  iconColor: const Color(0xFFFF9F0A),
                  title: 'Working Hours',
                  subtitle: formatDuration(workingHours),
                  onTap: () => _showMinutesDialog(
                    'Set Working Hours',
                    workingHours.inMinutes,
                    (val) {
                      setState(() => workingHours = Duration(minutes: val));
                    },
                  ),
                ),
                _buildSettingTile(
                  icon: Icons.coffee_rounded,
                  iconColor: const Color(0xFF30D158),
                  title: 'Break Duration',
                  subtitle: formatDuration(breakHours),
                  onTap: () => _showMinutesDialog(
                    'Set Break Duration',
                    breakHours.inMinutes,
                    (val) {
                      setState(() => breakHours = Duration(minutes: val));
                    },
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
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

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFC7C7CC)),
        onTap: onTap,
      ),
    );
  }

  Future<void> _showMinutesDialog(
    String title,
    int initialValue,
    Function(int) onSave,
  ) async {
    final controller = TextEditingController(text: initialValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFF1A1A1A)),
          decoration: const InputDecoration(
            hintText: 'Enter minutes',
            suffix: Text('min', style: TextStyle(color: Color(0xFF666666))),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFF2F2F7)),
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
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) Navigator.pop(ctx, val);
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
    if (result != null && result > 0) onSave(result);
  }
}
