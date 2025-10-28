import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:working_hour_time_calculator/models/break_snapshort.dart';
import 'package:working_hour_time_calculator/models/history_entry.dart';

class DataStore extends ChangeNotifier {
  DataStore._internal();
  static final DataStore instance = DataStore._internal();

  final String _prefsKey = 'work_break_history_v2';
  List<HistoryEntry> history = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_prefsKey);
    if (jsonString != null) {
      try {
        final List decoded = jsonDecode(jsonString);
        history = decoded.map((m) => HistoryEntry.fromMap(m)).toList();
      } catch (e) {
        history = [];
      }
    } else {
      history = [];
    }
    _pruneOlderThan24Hours();
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(history.map((h) => h.toMap()).toList()),
    );
  }

  void _pruneOlderThan24Hours() {
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    history.removeWhere((h) => h.date.isBefore(cutoff));
  }

  HistoryEntry? getTodayEntry() {
    final todayStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    for (final h in history) {
      if (DateFormat("yyyy-MM-dd").format(h.date) == todayStr) return h;
    }
    return null;
  }

  Future<void> updateToday({
    TimeOfDay? morningEntry,
    TimeOfDay? eveningOut,
    Duration? workingHours,
    Duration? breakHours,
    List<BreakSnapshot>? breaks,
    TimeOfDay? companyEntry,
  }) async {
    final todayStr = DateFormat("yyyy-MM-dd").format(DateTime.now());
    HistoryEntry? today;
    for (final h in history) {
      if (DateFormat("yyyy-MM-dd").format(h.date) == todayStr) {
        today = h;
        break;
      }
    }

    if (today == null) {
      today = HistoryEntry(
        date: DateTime.now(),
        morningEntry: morningEntry,
        eveningOut: eveningOut,
        workingHours: workingHours ?? const Duration(hours: 7),
        breakHours: breakHours ?? const Duration(hours: 1),
        breaks: breaks ?? [],
      );
      history.add(today);
    } else {
      today.morningEntry = morningEntry ?? today.morningEntry;
      today.eveningOut = eveningOut ?? today.eveningOut;
      today.workingHours = workingHours ?? today.workingHours;
      today.breakHours = breakHours ?? today.breakHours;
      if (breaks != null) today.breaks = breaks;
    }

    _pruneOlderThan24Hours();
    await save();
    notifyListeners();
  }

 Future<void> deleteEntryAt(int index) async {
    if (index >= 0 && index < history.length) {
      history.removeAt(index);
      await save();
      notifyListeners();
    }
  }
}