// import 'package:flutter/material.dart';
// import 'package:working_hour_time_calculator/models/break_snapshort.dart';

// class HistoryEntry {
//   DateTime date;
//   TimeOfDay? morningEntry;
//   TimeOfDay? eveningOut;
//   Duration workingHours;
//   Duration breakHours;
//   List<BreakSnapshot> breaks;

//   HistoryEntry({
//     required this.date,
//     required this.morningEntry,
//     required this.eveningOut,
//     required this.workingHours,
//     required this.breakHours,
//     required this.breaks,
//   });

//   Map<String, dynamic> toMap() {
//     return {
//       'date': date.toIso8601String(),
//       'morningHour': morningEntry?.hour,
//       'morningMinute': morningEntry?.minute,
//       'eveningHour': eveningOut?.hour,
//       'eveningMinute': eveningOut?.minute,
//       'workingHoursMinutes': workingHours.inMinutes,
//       'breakHoursMinutes': breakHours.inMinutes,
//       'breaks': breaks.map((b) => b.toMap()).toList(),
//     };
//   }

//   factory HistoryEntry.fromMap(Map<String, dynamic> m) {
//     return HistoryEntry(
//       date: DateTime.parse(m['date'] as String),
//       morningEntry:
//           m['morningHour'] != null ? TimeOfDay(hour: m['morningHour'], minute: m['morningMinute']) : null,
//       eveningOut:
//           m['eveningHour'] != null ? TimeOfDay(hour: m['eveningHour'], minute: m['eveningMinute']) : null,
//       workingHours: Duration(minutes: (m['workingHoursMinutes'] as int?) ?? 0),
//       breakHours: Duration(minutes: (m['breakHoursMinutes'] as int?) ?? 0),
//       breaks: m['breaks'] != null
//           ? List<BreakSnapshot>.from((m['breaks'] as List).map((x) => BreakSnapshot.fromMap(Map<String, dynamic>.from(x))))
//           : [],
//     );
//   }
// }



import 'package:flutter/material.dart';
import 'break_snapshort.dart';

class HistoryEntry {
  DateTime date;
  TimeOfDay? morningEntry;
  TimeOfDay? eveningOut;
  Duration workingHours;
  Duration breakHours;
  List<BreakSnapshot> breaks;

  HistoryEntry({
    required this.date,
    this.morningEntry,
    this.eveningOut,
    required this.workingHours,
    required this.breakHours,
    required this.breaks,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'morningEntry': morningEntry != null
          ? '${morningEntry!.hour}:${morningEntry!.minute}'
          : null,
      'eveningOut': eveningOut != null
          ? '${eveningOut!.hour}:${eveningOut!.minute}'
          : null,
      'workingHours': workingHours.inMinutes,
      'breakHours': breakHours.inMinutes,
      'breaks': breaks.map((b) => b.toMap()).toList(),
    };
  }

  factory HistoryEntry.fromMap(Map<String, dynamic> map) {
    TimeOfDay? parseTime(String? str) {
      if (str == null) return null;
      final parts = str.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }

    return HistoryEntry(
      date: DateTime.parse(map['date']),
      morningEntry: parseTime(map['morningEntry']),
      eveningOut: parseTime(map['eveningOut']),
      workingHours: Duration(minutes: map['workingHours'] ?? 420),
      breakHours: Duration(minutes: map['breakHours'] ?? 60),
      breaks: (map['breaks'] as List?)
              ?.map((b) => BreakSnapshot.fromMap(b))
              .toList() ??
          [],
    );
  }
}