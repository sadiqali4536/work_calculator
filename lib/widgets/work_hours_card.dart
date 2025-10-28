import 'package:flutter/material.dart';

/// WorkHoursCard (kept UI same)
class WorkHoursCard extends StatefulWidget {
  final TimeOfDay? morningEntry;
  final TextEditingController workingHourController;
  final TextEditingController breakHourController;
  final Function(TimeOfDay) onMorningEntryChanged;

  const WorkHoursCard({
    super.key,
    required this.morningEntry,
    required this.workingHourController,
    required this.breakHourController,
    required this.onMorningEntryChanged,
  });

  @override
  State<WorkHoursCard> createState() => _WorkHoursCardState();
}

class _WorkHoursCardState extends State<WorkHoursCard> {
  bool _showHours = false;

  String formatTime(TimeOfDay? t) {
    if (t == null) return "--:--";
    return t.format(context);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 5,
      shadowColor: Colors.purple.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text("Morning Entry:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple)),
            Text(formatTime(widget.morningEntry), style: const TextStyle(fontSize: 16)),
            IconButton(icon: const Icon(Icons.edit, size: 22, color: Colors.purple), onPressed: () async {
              final t = await showTimePicker(context: context, initialTime: widget.morningEntry ?? TimeOfDay.now());
              if (t != null) widget.onMorningEntryChanged(t);
            }),
            IconButton(icon: Icon(_showHours ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 26, color: Colors.purple), onPressed: () => setState(() => _showHours = !_showHours)),
          ]),
          if (_showHours) ...[
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Working Hours:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              Text("${widget.workingHourController.text.isEmpty ? '--' : widget.workingHourController.text} h", style: const TextStyle(fontSize: 15)),
              IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.black54), onPressed: () async {
                final controller = TextEditingController(text: widget.workingHourController.text);
                final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text("Set Working Hours"), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Enter hours")), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text("Save"))]));
                if (result != null) setState(() => widget.workingHourController.text = result);
              }),
            ]),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("Break Hours:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87)),
              Text("${widget.breakHourController.text.isEmpty ? '--' : widget.breakHourController.text} h", style: const TextStyle(fontSize: 15)),
              IconButton(icon: const Icon(Icons.edit, size: 20, color: Colors.black54), onPressed: () async {
                final controller = TextEditingController(text: widget.breakHourController.text);
                final result = await showDialog<String>(context: context, builder: (ctx) => AlertDialog(title: const Text("Set Break Hours"), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: "Enter hours")), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")), ElevatedButton(onPressed: () => Navigator.pop(ctx, controller.text), child: const Text("Save"))]));
                if (result != null) setState(() => widget.breakHourController.text = result);
              }),
            ]),
          ],
        ]),
      ),
    );
  }
}
