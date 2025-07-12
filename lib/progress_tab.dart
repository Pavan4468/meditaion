import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class ProgressTab extends StatefulWidget {
  const ProgressTab({super.key});

  @override
  _ProgressTabState createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> with SingleTickerProviderStateMixin {
  final TextEditingController _reflectionController = TextEditingController();
  List<int> weeklySessions = [0, 0, 0, 0, 0, 0, 0];
  int dayStreak = 0;
  int totalSessions = 0;
  String avgSession = '0m';
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _animationController.forward();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final now = DateTime.now();
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .get();

      List<int> tempSessions = [0, 0, 0, 0, 0, 0, 0];
      int totalDuration = 0;
      int sessionCount = 0;
      Set<String> uniqueDays = {};

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dayIndex = timestamp.weekday - 1;
        tempSessions[dayIndex]++;
        uniqueDays.add(DateFormat('yyyy-MM-dd').format(timestamp));
        totalDuration += data['duration'] as int;
        sessionCount++;
      }

      final allSessions = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .get();
      int streak = 0;
      DateTime? lastDate;
      for (var doc in allSessions.docs) {
        final date = (doc['timestamp'] as Timestamp).toDate();
        final formattedDate = DateFormat('yyyy-MM-dd').format(date);
        if (lastDate == null) {
          lastDate = date;
          streak = 1;
          continue;
        }
        final lastFormatted = DateFormat('yyyy-MM-dd').format(lastDate);
        if (formattedDate ==
            DateFormat('yyyy-MM-dd')
                .format(lastDate.subtract(const Duration(days: 1)))) {
          streak++;
          lastDate = date;
        } else {
          break;
        }
      }

      setState(() {
        weeklySessions = tempSessions;
        dayStreak = streak;
        totalSessions = allSessions.size;
        avgSession =
            sessionCount > 0 ? '${(totalDuration / sessionCount).round()}m' : '0m';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveReflection() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && _reflectionController.text.trim().isNotEmpty) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('reflections')
          .add({
        'text': _reflectionController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });
      _reflectionController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reflection saved successfully')),
      );
    }
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)));
    }
    return Scaffold(
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
                    Text(
                      'Your Journey',
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
                    const SizedBox(height: 8),
                    Text(
                      'Gentle progress tracking with love and humility',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildStatCard('$dayStreak', 'Day Streak', const Color(0xFF8B5CF6)),
                        _buildStatCard('$totalSessions', 'Total Sessions', const Color(0xFF8B5CF6)),
                        _buildStatCard(
                            '${weeklySessions.reduce((a, b) => a + b)}/14', 'This Week', const Color(0xFF8B5CF6)),
                        _buildStatCard(avgSession, 'Avg. Session', const Color(0xFF8B5CF6)),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'This Week\'s Practice',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      height: 230,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: WeeklyProgressPainter(weeklySessions, _animation.value),
                              child: Container(),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Today\'s Reflection',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
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
                          TextField(
                            controller: _reflectionController,
                            maxLines: 4,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: const Color(0xFFF5F5F5),
                            ),
                            decoration: InputDecoration(
                              hintText: 'How did your practice feel today? Any insights or experiences to note...',
                              hintStyle: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                              border: InputBorder.none,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: _saveReflection,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: const Color(0xFFF5F5F5),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 8,
                                shadowColor: const Color(0xFF8B5CF6).withOpacity(0.6),
                              ),
                              child: Text(
                                'Save Reflection',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFF5F5F5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6),
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
                            '“Progress is not measured by distance traveled, but by the depth of surrender in each moment.”',
                            style: GoogleFonts.lora(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              color: const Color(0xFFF5F5F5),
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Remember: Every session is a gift to yourself and the divine',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF5F5F5).withOpacity(0.9),
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
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF5F5F5),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class WeeklyProgressPainter extends CustomPainter {
  final List<int> sessions;
  final double animationValue;

  WeeklyProgressPainter(this.sessions, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final barPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFFF5F5F5)
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFF5F5F5),
          const Color(0xFFD1D5DB),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final labelBackgroundPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF8B5CF6).withOpacity(0.3);

    final barWidth = size.width / 9;
    const maxSessions = 5; // Increased to make bars shorter
    final barHeightUnit = (size.height - 50) / maxSessions;

    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    for (int i = 0; i < sessions.length; i++) {
      final barHeight = sessions[i] * barHeightUnit * animationValue;
      final x = i * barWidth + barWidth * 0.5;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - 40 - barHeight, barWidth * 0.6, barHeight),
        const Radius.circular(6),
      );
      canvas.drawShadow(Path()..addRRect(rect), Colors.black.withOpacity(0.2), 4, true);

      canvas.drawRRect(rect, barPaint);

      final sessionParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textAlign: TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(
          color: const Color(0xFFF5F5F5),
          shadows: [
            ui.Shadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 2,
              offset: const Offset(1, 1),
            ),
          ],
        ))
        ..addText('${sessions[i]}');
      final sessionParagraphBuilt = sessionParagraph.build()
        ..layout(ui.ParagraphConstraints(width: barWidth * 0.6));
      canvas.drawParagraph(
        sessionParagraphBuilt,
        Offset(x + (barWidth * 0.6 - sessionParagraphBuilt.width) / 2, size.height - 40 - barHeight - 18),
      );

      final labelOval = Rect.fromLTWH(
        x - barWidth * 0.45,
        size.height - 30,
        barWidth * 0.9,
        20,
      );
      canvas.drawOval(labelOval, labelBackgroundPaint);

      final dayParagraph = ui.ParagraphBuilder(ui.ParagraphStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        fontFamily: GoogleFonts.poppins().fontFamily,
        textAlign: TextAlign.center,
      ))
        ..pushStyle(ui.TextStyle(
          color: const Color(0xFFF5F5F5),
        ))
        ..addText(['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][i]);
      final dayParagraphBuilt = dayParagraph.build()
        ..layout(ui.ParagraphConstraints(width: barWidth * 0.9));
      canvas.drawParagraph(
        dayParagraphBuilt,
        Offset(x + (barWidth * 0.9 - dayParagraphBuilt.width) / 2, size.height - 28),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}