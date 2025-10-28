// import 'package:flutter/material.dart';

// class BreakSnapshot {
//   final String title;
//   final TimeOfDay? start;
//   final TimeOfDay? end;
//   final Duration duration;
//   final String note;

//   BreakSnapshot({
//     required this.title,
//     this.start,
//     this.end,
//     required this.duration,
//     required this.note,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'title': title,
//       'startHour': start?.hour,
//       'startMinute': start?.minute,
//       'endHour': end?.hour,
//       'endMinute': end?.minute,
//       'durationMinutes': duration.inMinutes,
//       'note': note,
//     };
//   }

//   factory BreakSnapshot.fromMap(Map<String, dynamic> m) {
//     return BreakSnapshot(
//       title: m['title'] as String? ?? '',
//       start: m['startHour'] != null ? TimeOfDay(hour: m['startHour'], minute: m['startMinute']) : null,
//       end: m['endHour'] != null ? TimeOfDay(hour: m['endHour'], minute: m['endMinute']) : null,
//       duration: Duration(minutes: (m['durationMinutes'] as int?) ?? 0),
//       note: m['note'] as String? ?? '',
//     );
//   }
// }


import 'package:flutter/material.dart';

class BreakSnapshot {
  final String title;
  final TimeOfDay? start;
  final TimeOfDay? end;
  final Duration duration;
  final String note;

  BreakSnapshot({
    required this.title,
    this.start,
    this.end,
    required this.duration,
    this.note = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'start': start != null ? '${start!.hour}:${start!.minute}' : null,
      'end': end != null ? '${end!.hour}:${end!.minute}' : null,
      'duration': duration.inMinutes,
      'note': note,
    };
  }

  factory BreakSnapshot.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? str) {
      if (str == null) return null;
      final parts = str.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return BreakSnapshot(
      title: map['title'] ?? '',
      start: parseTime(map['start']),
      end: parseTime(map['end']),
      duration: Duration(minutes: map['duration'] ?? 0),
      note: map['note'] ?? '',
    );
  }
}