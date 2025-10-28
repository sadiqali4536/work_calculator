import 'package:flutter/material.dart';

class BreakEntry {
  String title;
  TimeOfDay? start;
  TimeOfDay? end;
  final TextEditingController controller;

  BreakEntry( {
    required this.title,
    this.start,
    this.end,
    String? note,
  }) : controller = TextEditingController(text: note);

  Duration get duration {
    if (start == null || end == null) return Duration.zero;
    final now = DateTime.now();
    final s = DateTime(now.year, now.month, now.day, start!.hour, start!.minute);
    final e = DateTime(now.year, now.month, now.day, end!.hour, end!.minute);
    return e.isAfter(s) ? e.difference(s) : Duration.zero;
  }

  void dispose() => controller.dispose();
}
