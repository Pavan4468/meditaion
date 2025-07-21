import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_tab.dart';
import 'daily_practice_tab.dart';
import 'meditation_tab.dart';
import 'stripepayment.dart';
import 'progress_tab.dart';
import 'guide_page.dart';
import 'knowledge_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  final List<Widget> _pages = [
    const HomeTab(),
    const DailyPracticeTab(),
     PaymentScreen(),
    const MeditationTab(),
    const ProgressTab(),
  ];

  final List<Color> _iconColors = [
    const Color(0xFFF97316), // Orange for Home
    const Color(0xFF3B82F6), // Blue for Daily Practice
    const Color(0xFFEAB308), // Yellow for Payment
    const Color(0xFF10B981), // Green for Meditation
    const Color(0xFF8B5CF6), // Purple for Progress
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _animationController.forward().then((_) => _animationController.reverse());
  }

  void _onDrawerItemSelected(String value) {
    Navigator.pop(context); // Close the drawer
    if (value == 'Guide') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const GuidePage()),
      );
    } else if (value == 'Knowledge') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const KnowledgePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Color(0xFFF5F5F5)),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'Pranahuti',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF5F5F5),
          ),
        ),
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1F1F1F),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0D0D),
                Color(0xFF1F1F1F),
              ],
            ),
          ),
          child: Column(
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6),
                      Color(0xFF6D28D9),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    'Pranahuti Menu',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.book, color: Color(0xFFF5F5F5)),
                title: Text(
                  'Guide',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF5F5F5),
                  ),
                ),
                onTap: () => _onDrawerItemSelected('Guide'),
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb, color: Color(0xFFF5F5F5)),
                title: Text(
                  'Knowledge',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF5F5F5),
                  ),
                ),
                onTap: () => _onDrawerItemSelected('Knowledge'),
              ),
            ],
          ),
        ),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0D0D0D), // Deep black
                Color(0xFF1F1F1F), // Softer dark gray
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return BottomNavigationBar(
                currentIndex: _currentIndex,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFFF97316), // Orange for selected
                unselectedItemColor: Colors.white70,
                backgroundColor: Colors.transparent, // Use container's gradient
                elevation: 0,
                selectedLabelStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pacifico',
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                items: [
                  BottomNavigationBarItem(
                    icon: Transform.scale(
                      scale: _currentIndex == 0 ? _scaleAnimation.value : 1.0,
                      child: Icon(
                        Icons.home,
                        size: 32,
                        color: _currentIndex == 0 ? _iconColors[0] : Colors.white70,
                      ),
                    ),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Transform.scale(
                      scale: _currentIndex == 1 ? _scaleAnimation.value : 1.0,
                      child: Icon(
                        Icons.calendar_today,
                        size: 32,
                        color: _currentIndex == 1 ? _iconColors[1] : Colors.white70,
                      ),
                    ),
                    label: 'Daily',
                  ),
                  BottomNavigationBarItem(
                    icon: Transform.scale(
                      scale: _currentIndex == 2 ? _scaleAnimation.value : 1.0,
                      child: Icon(
                        Icons.payment,
                        size: 32,
                        color: _currentIndex == 2 ? _iconColors[2] : Colors.white70,
                      ),
                    ),
                    label: 'Pay',
                  ),
                  BottomNavigationBarItem(
                    icon: Transform.scale(
                      scale: _currentIndex == 3 ? _scaleAnimation.value : 1.0,
                      child: Icon(
                        Icons.self_improvement,
                        size: 32,
                        color: _currentIndex == 3 ? _iconColors[3] : Colors.white70,
                      ),
                    ),
                    label: 'Meditation',
                  ),
                  BottomNavigationBarItem(
                    icon: Transform.scale(
                      scale: _currentIndex == 4 ? _scaleAnimation.value : 1.0,
                      child: Icon(
                        Icons.bar_chart,
                        size: 32,
                        color: _currentIndex == 4 ? _iconColors[4] : Colors.white70,
                      ),
                    ),
                    label: 'Progress',
                  ),
                ],
                onTap: _onTabTapped,
              );
            },
          ),
        ),
      ),
    );
  }
}