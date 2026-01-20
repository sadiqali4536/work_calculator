import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotepadPage extends StatefulWidget {
  const NotepadPage({super.key});

  @override
  State<NotepadPage> createState() => _NotepadPageState();
}

class _NotepadPageState extends State<NotepadPage> {
  List<WorkSession> _sessions = [];
  bool _isEditing = false;
  int? _editingIndex;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("work_sessions");
    if (saved != null) {
      final List<dynamic> decoded = json.decode(saved);
      setState(() {
        _sessions = decoded.map((e) => WorkSession.fromJson(e)).toList();
      });
    }
  }

  Future<void> _saveSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = json.encode(_sessions.map((e) => e.toJson()).toList());
    await prefs.setString("work_sessions", encoded);
  }

  void _startNewSession() {
    setState(() {
      _isEditing = true;
      _editingIndex = null;
      _startTime = null;
      _endTime = null;
      _noteController.clear();
    });
  }

  void _editSession(int index) {
    final session = _sessions[index];
    setState(() {
      _isEditing = true;
      _editingIndex = index;
      _startTime = session.startTime;
      _endTime = session.endTime;
      _noteController.text = session.note;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _editingIndex = null;
      _startTime = null;
      _endTime = null;
      _noteController.clear();
    });
  }

  void _saveSession() {
    if (_startTime == null || _noteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add start time and note!'),
          backgroundColor: Color(0xFFFF453A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final session = WorkSession(
      startTime: _startTime!,
      endTime: _endTime,
      note: _noteController.text.trim(),
      createdAt: DateTime.now(),
    );

    setState(() {
      if (_editingIndex != null) {
        _sessions[_editingIndex!] = session;
      } else {
        _sessions.insert(0, session);
      }
      _isEditing = false;
      _editingIndex = null;
    });

    _saveSessions();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session saved!'),
        backgroundColor: Color(0xFF30D158),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _deleteSession(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Session?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'This will permanently delete this work session.',
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
              setState(() => _sessions.removeAt(index));
              _saveSessions();
              Navigator.pop(ctx);
            },
            child: const Text(
              'Delete',
              style: TextStyle(
                color: Color(0xFFFF453A),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
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

    if (picked != null) {
      setState(() {
        if (isStart)
          _startTime = picked;
        else
          _endTime = picked;
      });
    }
  }

  String _formatTime(TimeOfDay? time) =>
      time == null ? '--:--' : time.format(context);

  Duration? _calculateDuration(TimeOfDay start, TimeOfDay? end) {
    if (end == null) return null;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    final diff = endMinutes - startMinutes;
    return Duration(minutes: diff > 0 ? diff : diff + 1440);
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF1A1A1A)),
                onPressed: _cancelEditing,
              )
            : IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Color(0xFF1A1A1A),
                  size: 20,
                ),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _isEditing ? 'New Session' : 'Work Sessions',
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(
                    Icons.check_rounded,
                    color: Color(0xFF0A84FF),
                    size: 28,
                  ),
                  onPressed: _saveSession,
                ),
              ]
            : null,
      ),
      body: _isEditing ? _buildEditView() : _buildListView(),
      floatingActionButton: !_isEditing
          ? FloatingActionButton.extended(
              onPressed: _startNewSession,
              backgroundColor: const Color(0xFF1A1A1A),
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                'Add Session',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEditView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildTimeSelector(
                  'Start Time',
                  _startTime,
                  const Color(0xFF0A84FF),
                  Icons.login_rounded,
                  () => _pickTime(true),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(color: Color(0xFFF2F2F7), height: 1),
                ),
                _buildTimeSelector(
                  'End Time (Optional)',
                  _endTime,
                  const Color(0xFFFF453A),
                  Icons.logout_rounded,
                  () => _pickTime(false),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Work Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 8,
              style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'What did you work on?',
                hintStyle: TextStyle(color: Color(0xFFC7C7CC)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSelector(
    String label,
    TimeOfDay? time,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        color: Colors.transparent,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
            Text(
              _formatTime(time),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: time != null ? color : const Color(0xFFC7C7CC),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView() {
    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.note_add_rounded,
              size: 72,
              color: const Color(0xFFC7C7CC).withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No work sessions yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFC7C7CC),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sessions.length,
      itemBuilder: (context, index) {
        final session = _sessions[index];
        final duration = _calculateDuration(session.startTime, session.endTime);

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildTimeChip(
                          _formatTime(session.startTime),
                          const Color(0xFF0A84FF),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: Color(0xFFC7C7CC),
                            size: 16,
                          ),
                        ),
                        if (session.endTime != null)
                          _buildTimeChip(
                            _formatTime(session.endTime),
                            const Color(0xFFFF453A),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: Color(0xFF0A84FF),
                          size: 26,
                        ),
                        onPressed: () => _editSession(index),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFFF453A),
                          size: 24,
                        ),
                        onPressed: () => _deleteSession(index),
                      ),
                    ],
                  ),
                ],
              ),
              if (duration != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Duration: ${_formatDuration(duration)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF30D158),
                    ),
                  ),
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(color: Color(0xFFF2F2F7), height: 1),
              ),
              Text(
                session.note,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF1A1A1A),
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimeChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class WorkSession {
  final TimeOfDay startTime;
  final TimeOfDay? endTime;
  final String note;
  final DateTime createdAt;

  WorkSession({
    required this.startTime,
    this.endTime,
    required this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'startHour': startTime.hour,
    'startMinute': startTime.minute,
    'endHour': endTime?.hour,
    'endMinute': endTime?.minute,
    'note': note,
    'createdAt': createdAt.toIso8601String(),
  };

  factory WorkSession.fromJson(Map<String, dynamic> json) => WorkSession(
    startTime: TimeOfDay(hour: json['startHour'], minute: json['startMinute']),
    endTime: json['endHour'] != null
        ? TimeOfDay(hour: json['endHour'], minute: json['endMinute'])
        : null,
    note: json['note'],
    createdAt: DateTime.parse(json['createdAt']),
  );
}
