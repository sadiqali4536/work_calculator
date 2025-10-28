
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

  Future<void> _editBreakTime(int historyIndex, int breakIndex, bool isStart) async {
    final history = DataStore.instance.history;
    final breakData = history[historyIndex].breaks[breakIndex];
    final currentTime = isStart ? breakData.start : breakData.end;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: currentTime ?? TimeOfDay.now(),
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
      // Calculate new duration
      final startTime = isStart ? picked : breakData.start;
      final endTime = isStart ? breakData.end : picked;
      
      Duration newDuration = Duration.zero;
      if (startTime != null && endTime != null) {
        final start = DateTime(2000, 1, 1, startTime.hour, startTime.minute);
        final end = DateTime(2000, 1, 1, endTime.hour, endTime.minute);
        newDuration = end.difference(start);
      }
      
      // Create updated break with new time and recalculated duration
      final updatedBreak = BreakSnapshot(
        title: breakData.title,
        start: startTime,
        end: endTime,
        duration: newDuration,
        note: breakData.note,
      );
      
      // Update the break in the history entry directly
      history[historyIndex].breaks[breakIndex] = updatedBreak;
      
      // Save to persist changes
      await DataStore.instance.save();
      
      // CRITICAL: Notify listeners so HomePage updates immediately
      DataStore.instance.notifyListeners();
      
      // Trigger UI update
      setState(() {});
    }
  }

  void _showDeleteDialog(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Entry?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'This will permanently delete this history entry.',
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
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Delete Break?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: const Text(
          'This will permanently delete this break from history.',
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
            onPressed: () async {
              final history = DataStore.instance.history;
              history[historyIndex].breaks.removeAt(breakIndex);
              await DataStore.instance.save();
              
              // CRITICAL: Notify listeners so HomePage updates immediately
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
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF000000),
        
        title: const Text(
          "History",
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
            child: history.isEmpty
                ? const Center(
                    child: Text(
                      "No history yet.",
                      style: TextStyle(fontSize: 18, color: Colors.white38),
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
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(16),
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
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0A84FF),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Color(0xFFFF453A),
                                  ),
                                  onPressed: () => _showDeleteDialog(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (h.morningEntry != null)
                              _buildInfoRow(
                                'Morning Entry',
                                formatTime(h.morningEntry, context),
                              ),
                            const SizedBox(height: 12),
                            if (h.breaks.isNotEmpty) ...[
                              const Text(
                                'Breaks',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.white,
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
                                    color: const Color(0xFF2C2C2E),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            b.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: Colors.white,
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
                                                    color: const Color(0xFF0A84FF).withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    formatDuration(b.duration),
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF0A84FF),
                                                    ),
                                                  ),
                                                ),
                                              const SizedBox(width: 8),
                                              GestureDetector(
                                                onTap: () => _showDeleteBreakDialog(index, breakIndex),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFF453A).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(
                                                    Icons.delete_outline,
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
                                            child: GestureDetector(
                                              onTap: () => _editBreakTime(index, breakIndex, true),
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3A3A3C),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'Start',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          formatTime(b.start, context),
                                                          style: const TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.white,
                                                          ),
                                                        ),
                                                        const Icon(
                                                          Icons.edit,
                                                          size: 16,
                                                          color: Color(0xFF0A84FF),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: b.end != null 
                                                  ? () => _editBreakTime(index, breakIndex, false)
                                                  : null,
                                              child: Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF3A3A3C),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    const Text(
                                                      'End',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white54,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text(
                                                          formatTime(b.end, context),
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight: FontWeight.w600,
                                                            color: b.end != null ? Colors.white : Colors.white38,
                                                          ),
                                                        ),
                                                        if (b.end != null)
                                                          const Icon(
                                                            Icons.edit,
                                                            size: 16,
                                                            color: Color(0xFF0A84FF),
                                                          ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
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
          ),
        ],
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
            color: Colors.white70,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
