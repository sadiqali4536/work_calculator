import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final TimeOfDay? eveningOut;
  final Duration totalBreakUsed;
  final Duration remainingBreak;
  final Duration currentWorkedHour;
  final bool breakOverUsed;

  const SummaryCard({
    super.key,
    required this.eveningOut,
    required this.totalBreakUsed,
    required this.remainingBreak,
    required this.currentWorkedHour,
    required this.breakOverUsed, required Duration overtimeUsed,
  });

  String formatDuration(Duration d) => "${d.inHours.toString().padLeft(2,'0')}:${(d.inMinutes % 60).toString().padLeft(2,'0')}";

  String formatTime(TimeOfDay? t, BuildContext context) => t?.format(context) ?? "--:--";

  // @override
  // Widget build(BuildContext context) {
  //   return Card(
      
  //     elevation: 3,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  //     child: Padding(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text("Evening Out: ${formatTime(eveningOut, context)}", style: const TextStyle(fontSize: 16)),
  //           const SizedBox(height: 8),
  //           Text("Total Break Used: ${formatDuration(totalBreakUsed)}", style: const TextStyle(fontSize: 16)),
  //           const SizedBox(height: 8),
  //           Text("Remaining Break: ${formatDuration(remainingBreak)}", style: TextStyle(fontSize: 16, color: breakOverUsed ? Colors.red : Colors.black)),
  //           const SizedBox(height: 8),
  //           Text("Worked Hours: ${formatDuration(currentWorkedHour)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  //         ],
  //       ),
  //     ),
  //   );
  // }
  @override
Widget build(BuildContext context) {
  return Center( // Center it on the screen
    child: SizedBox(
      width: MediaQuery.of(context).size.width * 0.9, // 90% of screen width
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Evening Out: ",
                    style: const TextStyle(fontSize: 16),
                  ),
                   Text(
                    "${formatTime(eveningOut, context)}",
                    style: const TextStyle(fontSize: 16,),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Break Used:",
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    " ${formatDuration(totalBreakUsed)}",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Remaining Break: ",
                    style: TextStyle(
                      fontSize: 16,
                      color: breakOverUsed ? Colors.red : const Color.fromARGB(255, 7, 7, 7),
                    ),
                  ),
                  Text(
                    " ${formatDuration(remainingBreak)}",
                    style: TextStyle(
                      fontSize: 16,
                      color: breakOverUsed ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Work Hours:",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    "${formatDuration(currentWorkedHour)}",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}
