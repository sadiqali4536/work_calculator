

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
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _deleteSession(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Session?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'This will permanently delete this work session.',
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
              setState(() {
                _sessions.removeAt(index);
              });
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

  Future<void> _addEndTime(int index) async {
    final session = _sessions[index];
    final picked = await showTimePicker(
      context: context,
      initialTime: session.endTime ?? TimeOfDay.now(),
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

    if (picked != null) {
      setState(() {
        _sessions[index] = WorkSession(
          startTime: session.startTime,
          endTime: picked,
          note: session.note,
          createdAt: session.createdAt,
        );
      });
      _saveSessions();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
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

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return '--:--';
    return time.format(context);
  }

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
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF000000),
        leading: _isEditing
            ? IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _cancelEditing,
              )
            : null,
        title: Text(
          _isEditing ? 'New Session' : 'Work Sessions',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.check, color: Color(0xFF0A84FF)),
                  onPressed: _saveSession,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Container(
            height: 0.5,
            color: const Color(0xFF3A3A3C),
          ),
          Expanded(
            child: _isEditing ? _buildEditView() : _buildListView(),
          ),
        ],
      ),
      floatingActionButton: !_isEditing
          ? FloatingActionButton(
              onPressed: _startNewSession,
              backgroundColor: const Color(0xFF0A84FF),
              child: const Icon(Icons.add, color: Colors.white),
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
          // Time Selection
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _pickTime(true),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.login, color: Color(0xFF0A84FF), size: 22),
                            SizedBox(width: 12),
                            Text(
                              'Start Time',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatTime(_startTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _startTime != null
                                ? const Color(0xFF0A84FF)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => _pickTime(false),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.logout, color: Color(0xFFFF453A), size: 22),
                            SizedBox(width: 12),
                            Text(
                              'End Time (Optional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          _formatTime(_endTime),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _endTime != null
                                ? const Color(0xFFFF453A)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Note Input
          const Text(
            'Work Notes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _noteController,
              maxLines: 10,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              decoration: const InputDecoration(
                hintText: 'What did you work on?',
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_sessions.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.note_add, size: 64, color: Colors.white24),
            SizedBox(height: 16),
            Text(
              'No work sessions yet',
              style: TextStyle(fontSize: 18, color: Colors.white38),
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
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A84FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _formatTime(session.startTime),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                        ),
                        const Icon(Icons.arrow_forward, color: Colors.white38, size: 16),
                        if (session.endTime != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF453A).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(session.endTime),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFFF453A),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: () => _addEndTime(index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3A3A3C),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFF0A84FF).withOpacity(0.3),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, color: Color(0xFF0A84FF), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Add End',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF0A84FF),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFF0A84FF)),
                        onPressed: () => _editSession(index),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFFF453A)),
                        onPressed: () => _deleteSession(index),
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
              
              if (duration != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF30D158).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Duration: ${_formatDuration(duration)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF30D158),
                    ),
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFF3A3A3C)),
              const SizedBox(height: 16),
              
              Text(
                session.note,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  height: 1.5,
                ),
              ),
            ],
          ),
        );
      },
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
        startTime: TimeOfDay(
          hour: json['startHour'],
          minute: json['startMinute'],
        ),
        endTime: json['endHour'] != null
            ? TimeOfDay(
                hour: json['endHour'],
                minute: json['endMinute'],
              )
            : null,
        note: json['note'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}