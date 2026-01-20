import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:working_hour_time_calculator/data_store.dart';
import 'package:working_hour_time_calculator/models/break_snapshort.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    DataStore.instance.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    DataStore.instance.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() => setState(() {});

  String formatTime(TimeOfDay? t, BuildContext context) {
    if (t == null) return '--:--';
    return t.format(context);
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}";
  }

  Future<void> _editBreakTime(
    int historyIndex,
    int breakIndex,
    bool isStart,
  ) async {
    final history = DataStore.instance.history;
    final breakData = history[historyIndex].breaks[breakIndex];
    final currentTime = isStart ? breakData.start : breakData.end;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
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
      final startTime = isStart ? picked : breakData.start;
      final endTime = isStart ? breakData.end : picked;

      Duration newDuration = Duration.zero;
      if (startTime != null && endTime != null) {
        final start = DateTime(2000, 1, 1, startTime.hour, startTime.minute);
        final end = DateTime(2000, 1, 1, endTime.hour, endTime.minute);
        newDuration = end.difference(start);
      }

      final updatedBreak = BreakSnapshot(
        title: breakData.title,
        start: startTime,
        end: endTime,
        duration: newDuration,
        note: breakData.note,
      );

      history[historyIndex].breaks[breakIndex] = updatedBreak;
      await DataStore.instance.save();
      DataStore.instance.notifyListeners();
      setState(() {});
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Entry?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'This will permanently delete this history entry.',
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
              DataStore.instance.deleteEntryAt(index);
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

  void _showDeleteBreakDialog(int historyIndex, int breakIndex) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Delete Break?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        content: const Text(
          'This will permanently delete this break from history.',
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
            onPressed: () async {
              final history = DataStore.instance.history;
              history[historyIndex].breaks.removeAt(breakIndex);
              await DataStore.instance.save();
              DataStore.instance.notifyListeners();
              Navigator.pop(ctx);
              setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final history = DataStore.instance.history;
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
          "History",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontWeight: FontWeight.w700,
            fontSize: 28,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: history.isEmpty
          ? const Center(
              child: Text(
                "No history yet.",
                style: TextStyle(fontSize: 18, color: Color(0xFFC7C7CC)),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DateFormat("dd MMM yyyy").format(h.date),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFFF453A),
                            ),
                            onPressed: () => _showDeleteDialog(index),
                          ),
                        ],
                      ),
                      const Divider(color: Color(0xFFF2F2F7), height: 32),
                      if (h.morningEntry != null)
                        _buildInfoRow(
                          'Morning Entry',
                          formatTime(h.morningEntry, context),
                        ),
                      if (h.eveningOut != null) ...[
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          'Evening Out',
                          formatTime(h.eveningOut, context),
                        ),
                      ],
                      if (h.breaks.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Breaks',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...h.breaks.asMap().entries.map((entry) {
                          final breakIndex = entry.key;
                          final b = entry.value;
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F9F9),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFF2F2F7),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      b.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        color: Color(0xFF1A1A1A),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        if (b.duration != Duration.zero)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFF0A84FF,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              formatDuration(b.duration),
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF0A84FF),
                                              ),
                                            ),
                                          ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () => _showDeleteBreakDialog(
                                            index,
                                            breakIndex,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: const Color(
                                                0xFFFF453A,
                                              ).withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Icon(
                                              Icons.delete_outline_rounded,
                                              size: 18,
                                              color: Color(0xFFFF453A),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildTimeEditBox(
                                        'Start',
                                        formatTime(b.start, context),
                                        () => _editBreakTime(
                                          index,
                                          breakIndex,
                                          true,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildTimeEditBox(
                                        'End',
                                        formatTime(b.end, context),
                                        b.end != null
                                            ? () => _editBreakTime(
                                                index,
                                                breakIndex,
                                                false,
                                              )
                                            : null,
                                        isDimmed: b.end == null,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildTimeEditBox(
    String label,
    String value,
    VoidCallback? onTap, {
    bool isDimmed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF2F2F7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF666666),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDimmed ? Color(0xFFC7C7CC) : Color(0xFF1A1A1A),
                  ),
                ),
                if (onTap != null)
                  const Icon(
                    Icons.edit_rounded,
                    size: 14,
                    color: Color(0xFF0A84FF),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
}
