import 'package:flutter/material.dart';
import 'package:working_hour_time_calculator/data_store.dart';
import 'package:working_hour_time_calculator/pages/note_pad.dart';
import 'pages/home_page.dart';
import 'pages/history_page.dart';

void main() {
  runApp(const WorkBreakApp());
}

class WorkBreakApp extends StatelessWidget {
  const WorkBreakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Work & Break Tracker",
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: const Color(0xFF1A1A1A),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF1A1A1A),
          secondary: Color(0xFF0A84FF),
          surface: Colors.white,
          background: Color(0xFFF5F5F5),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      home: const MainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int selectedIndex = 0;
  late final List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = const [HomePage(), HistoryPage(), NotepadPage()];
    DataStore.instance.load();
  }

  void onNavTap(int index) => setState(() => selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: IndexedStack(index: selectedIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: BottomNavigationBar(
            currentIndex: selectedIndex,
            selectedItemColor: const Color(0xFF1A1A1A),
            unselectedItemColor: const Color(0xFFC7C7CC),
            backgroundColor: Colors.white,
            elevation: 0,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            onTap: onNavTap,
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.timer_rounded, size: 26),
                ),
                label: "Tracker",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.history_rounded, size: 26),
                ),
                label: "History",
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Icon(Icons.note_alt_rounded, size: 26),
                ),
                label: "Work Pad",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
