import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class KnowledgePage extends StatelessWidget {
  const KnowledgePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Knowledge Hub',
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF5F5F5),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF121212),
              Color(0xFF2A2A2A),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Knowledge Hub',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 34,
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
                  const SizedBox(height: 8),
                  Text(
                    'Sacred wisdom from the Masters',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Search Bar
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search teachings, practices, or insights...',
                      hintStyle: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF10B981),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Today's Thought
                  Text(
                    'Today\'s Thought',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF047857),
                        ],
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
                    child: Text(
                      'When the heart becomes the center of your being, the mind naturally follows. This is the beginning of true spiritual transformation.',
                      style: GoogleFonts.lora(
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFFF5F5F5),
                        height: 1.6,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Navigation Tiles (Teachings, Practices, Commandments)
                  Text(
                    'Explore',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.0,
                    children: [
                      _buildNavigationTile(
                        context,
                        'Teachings',
                        Icons.book,
                        () {
                          // Navigate to Teachings page (placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigating to Teachings...')),
                          );
                        },
                      ),
                      _buildNavigationTile(
                        context,
                        'Practices',
                        Icons.self_improvement,
                        () {
                          // Navigate to Practices page (placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigating to Practices...')),
                          );
                        },
                      ),
                      _buildNavigationTile(
                        context,
                        'Commandments',
                        Icons.rule,
                        () {
                          // Navigate to Commandments page (placeholder)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Navigating to Commandments...')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Daily Inspiration
                  Text(
                    'Daily Inspiration',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981),
                          Color(0xFF047857),
                        ],
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
                          'The Nature of Divine Love',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                        Text(
                          'by Babuji Maharaj',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Divine love is not an emotion but a state of being. When we surrender completely, we merge with this eternal flow of love.',
                          style: GoogleFonts.lora(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: const Color(0xFFF5F5F5),
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to full text (placeholder)
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Opening full text...')),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFF5F5F5),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              backgroundColor: const Color(0xFF10B981).withOpacity(0.2),
                            ),
                            child: Text(
                              'Read full text',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF5F5F5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF10B981),
              Color(0xFF047857),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: const Color(0xFFF5F5F5),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF5F5F5),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}