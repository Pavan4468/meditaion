import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212), // Deep black
              Color(0xFF2A2A2A), // Slightly lighter black for depth
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Header
                    Text(
                      'Prayer Time',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFF5F5F5),
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(2, 2),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Embark on a spiritual journey with Sahaj Marg, nurturing inner peace through heartfelt practice and divine connection.',
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        color: Colors.white70,
                        height: 1.6,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Today's Practice Section
                    Text(
                      "Today's Practice",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildPracticeCard(
                      icon: Icons.wb_sunny,
                      title: 'Morning Meditation',
                      subtitle: 'Embrace serenity at dawn',
                      context: context,
                      gradientColors: const [Color(0xFFFFA726), Color(0xFFFF7043)],
                    ),
                    const SizedBox(height: 16),
                    _buildPracticeCard(
                      icon: Icons.cleaning_services,
                      title: 'Evening Cleaning',
                      subtitle: 'Purify your soul at dusk',
                      context: context,
                      gradientColors: const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                    ),
                    const SizedBox(height: 16),
                    _buildPracticeCard(
                      icon: Icons.access_time,
                      title: '9 PM Prayer',
                      subtitle: 'Connect universally',
                      context: context,
                      gradientColors: const [Color(0xFFAB47BC), Color(0xFF7B1FA2)],
                    ),
                    const SizedBox(height: 16),
                    _buildPracticeCard(
                      icon: Icons.nightlight_round,
                      title: 'Night Meditation',
                      subtitle: 'Point A tranquility',
                      context: context,
                      gradientColors: const [Color(0xFF26A69A), Color(0xFF00897B)],
                    ),
                    const SizedBox(height: 32),
                    // Today's Divine Thought Section
                    Text(
                      "Today's Divine Thought",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildQuoteCard(
                      quote:
                          '"True prayer is the soul’s yearning for the Divine, answered when it flows from a pure heart."',
                      author: '- Babuji Maharaj',
                      context: context,
                      gradientColors: const [Color(0xFFF06292), Color(0xFFEC407A)],
                    ),
                    const SizedBox(height: 16),
                    _buildQuoteCard(
                      quote:
                          '"Life’s ultimate purpose is to realize the Divine Reality within us."',
                      author: '- Lalaji Maharaj',
                      context: context,
                      gradientColors: const [Color(0xFFEF5350), Color(0xFFE53935)],
                    ),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPracticeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required BuildContext context,
    required List<Color> gradientColors,
  }) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title tapped')),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard({
    required String quote,
    required String author,
    required BuildContext context,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '“$quote”',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            author,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }
}