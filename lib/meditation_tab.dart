import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class MeditationTab extends StatefulWidget {
  const MeditationTab({super.key});

  @override
  _MeditationTabState createState() => _MeditationTabState();
}

class _MeditationTabState extends State<MeditationTab> with TickerProviderStateMixin {
  String selectedMeditation = 'Meditation';
  int selectedDuration = 30;
  bool isTimerRunning = false;
  int remainingSeconds = 30 * 60;
  AnimationController? _timerController;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  AnimationController? _blinkController;
  Animation<double>? _blinkAnimation;
  bool _isLoading = true;
  bool _showIntroScreen = true;
  String? _userName;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _blinkAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _blinkController!, curve: Curves.easeInOut),
    );
    _timerController = AnimationController(
      vsync: this,
      duration: Duration(seconds: remainingSeconds),
    )..addListener(() {
        if (mounted) {
          setState(() {
            remainingSeconds = (_timerController!.duration!.inSeconds * (1 - _timerController!.value)).round();
            if (remainingSeconds <= 0) {
              _stopTimer(saveSession: true);
              _showCongratulationsPopup();
            }
          });
        }
      });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseController!,
        curve: Curves.easeInOutSine,
      ),
    );
    // Start 30-second intro timer
    Future.delayed(const Duration(seconds: 30), () {
      if (mounted) {
        setState(() {
          _showIntroScreen = false;
        });
        _blinkController?.stop();
      }
    });
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meditation_settings')
          .doc('current')
          .get();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          selectedMeditation = data['selectedMeditation'] ?? 'Meditation';
          selectedDuration = data['selectedDuration'] ?? 30;
          remainingSeconds = selectedDuration * 60;
          _timerController?.duration = Duration(seconds: remainingSeconds);
        });
      }
      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? user.displayName ?? 'User';
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('meditation_settings')
          .doc('current')
          .set({
        'selectedMeditation': selectedMeditation,
        'selectedDuration': selectedDuration,
      });
    }
  }

  Future<void> _saveSessionData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .add({
        'meditationType': selectedMeditation,
        'duration': selectedDuration,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showCongratulationsPopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Congratulations!',
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF5F5F5),
          ),
        ),
        content: Text(
          'You have completed your $selectedMeditation session!',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startStopTimer() {
    if (mounted) {
      setState(() {
        if (isTimerRunning) {
          _stopTimer();
        } else {
          _timerController?.forward();
          _pulseController?.forward();
          isTimerRunning = true;
        }
      });
    }
  }

  void _stopTimer({bool saveSession = false}) {
    _timerController?.stop();
    _pulseController?.stop();
    if (mounted) {
      setState(() {
        isTimerRunning = false;
        remainingSeconds = selectedDuration * 60;
        _timerController?.duration = Duration(seconds: remainingSeconds);
        _timerController?.reset();
      });
    }
    if (saveSession) {
      _saveSessionData();
    }
  }

  void _selectMeditation(String meditation) {
    if (mounted) {
      setState(() {
        selectedMeditation = meditation;
        remainingSeconds = selectedDuration * 60;
        _timerController?.duration = Duration(seconds: remainingSeconds);
        if (isTimerRunning) {
          _stopTimer();
        }
        _saveUserData();
      });
    }
  }

  void _selectDuration(int duration) {
    if (mounted) {
      setState(() {
        selectedDuration = duration;
        remainingSeconds = duration * 60;
        _timerController?.duration = Duration(seconds: remainingSeconds);
        if (isTimerRunning) {
          _stopTimer();
        }
        _saveUserData();
      });
    }
  }

  @override
  void dispose() {
    _timerController?.dispose();
    _pulseController?.dispose();
    _blinkController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_showIntroScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: AnimatedBuilder(
            animation: _blinkAnimation!,
            builder: (context, child) {
              return Transform.scale(
                scale: _blinkAnimation!.value,
                child: Icon(
                  Icons.local_fire_department,
                  color: Colors.red,
                  size: 100,
                ),
              );
            },
          ),
        ),
      );
    }
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
                      'Meditation Session',
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
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 160,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildMeditationTypeCard(
                              title: 'Meditation',
                              icon: Icons.favorite,
                              color: const Color(0xFF10B981),
                              isSelected: selectedMeditation == 'Meditation',
                              onTap: () => _selectMeditation('Meditation'),
                            ),
                            const SizedBox(width: 16),
                            _buildMeditationTypeCard(
                              title: 'Point B Meditation',
                              icon: Icons.favorite_border,
                              color: const Color(0xFF10B981),
                              isSelected: selectedMeditation == 'Point B Meditation',
                              onTap: () => _selectMeditation('Point B Meditation'),
                            ),
                            const SizedBox(width: 16),
                            _buildMeditationTypeCard(
                              title: 'Heart Cleaning',
                              icon: Icons.cleaning_services,
                              color: const Color(0xFF10B981),
                              isSelected: selectedMeditation == 'Heart Cleaning',
                              onTap: () => _selectMeditation('Heart Cleaning'),
                            ),
                            const SizedBox(width: 16),
                            _buildMeditationTypeCard(
                              title: '9 PM Universal',
                              icon: Icons.lightbulb,
                              color: const Color(0xFFF97316),
                              isSelected: selectedMeditation == '9 PM Universal Prayer',
                              onTap: () => _selectMeditation('9 PM Universal Prayer'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildMeditationTimer(context),
                    const SizedBox(height: 32),
                    Align(
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FeedbackPage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: const Color(0xFFF5F5F5),
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 8,
                          shadowColor: const Color(0xFF8B5CF6).withOpacity(0.6),
                        ),
                        child: Text(
                          'View Feedback',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Guidance',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildQuoteCard(
                      quote: selectedMeditation == 'Meditation'
                          ? '"Sit comfortably, close your eyes gently, and suppose that the divine light is present in your heart. Feel the divine presence and allow yourself to be absorbed in it."'
                          : selectedMeditation == 'Point B Meditation'
                              ? '"Focus on Point B in the heart, imagining a divine light purifying and calming the mind. Let all thoughts dissolve into this light."'
                              : selectedMeditation == 'Heart Cleaning'
                                  ? '"Visualize all complexities and impurities being cleansed from your heart, leaving it pure and serene."'
                                  : '"At 9 PM, unite in prayer for the welfare of all beings, offering love and peace to the universe."',
                      author: selectedMeditation == 'Meditation' ? null : '- Heartfulness Practice',
                      context: context,
                      gradientColors: selectedMeditation == '9 PM Universal Prayer'
                          ? const [Color(0xFFF97316), Color(0xFFC2410C)]
                          : const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                    const SizedBox(height: 16),
                    _buildQuoteCard(
                      quote: '"Gather together to meditate and pray, creating a collective vibration of love and unity."',
                      author: '- Satsang Practice',
                      context: context,
                      gradientColors: const [Color(0xFFF97316), Color(0xFFC2410C)],
                    ),
                    const SizedBox(height: 16),
                    _buildQuoteCard(
                      quote: '"Make meditation a daily habit to align your heart with the divine purpose."',
                      author: '- Daily Practice Guide',
                      context: context,
                      gradientColors: const [Color(0xFF3B82F6), Color(0xFF1E3A8A)],
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

  Widget _buildMeditationTimer(BuildContext context) {
    return Container(
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
      child: AnimatedBuilder(
        animation: _pulseAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: isTimerRunning ? _pulseAnimation!.value : 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.7,
                    colors: [
                      const Color(0xFF10B981),
                      const Color(0xFF047857),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF10B981),
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 4,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      selectedMeditation,
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF5F5F5),
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 110,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${(remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(remainingSeconds % 60).toString().padLeft(2, '0')}',
                              style: GoogleFonts.poppins(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFF5F5F5),
                                shadows: [
                                  Shadow(
                                    color: const Color(0xFF10B981).withOpacity(0.7),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [1, 10, 20, 30, 45, 60].map((duration) {
                        return GestureDetector(
                          onTap: () => _selectDuration(duration),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: selectedDuration == duration
                                  ? const Color(0xFF3B82F6)
                                  : Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selectedDuration == duration
                                    ? const Color(0xFFF5F5F5).withOpacity(0.8)
                                    : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              '$duration min',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: const Color(0xFFF5F5F5),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _startStopTimer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: const Color(0xFFF5F5F5),
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                        shadowColor: const Color(0xFF8B5CF6).withOpacity(0.6),
                      ),
                      child: Text(
                        isTimerRunning ? 'Stop' : 'Start',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF5F5F5),
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMeditationTypeCard({
    required String title,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color,
              color.withOpacity(0.7),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFF5F5F5).withOpacity(0.9) : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.6),
              blurRadius: 16,
              spreadRadius: 3,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: const Color(0xFFF5F5F5),
              size: 44,
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF5F5F5),
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteCard({
    required String quote,
    String? author,
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
              color: const Color(0xFFF5F5F5),
              height: 1.6,
            ),
          ),
          if (author != null)
            Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  author,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF5F5F5).withOpacity(0.9),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  List<Map<String, dynamic>> _feedbackList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('feedback')
          .orderBy('timestamp', descending: true)
          .get();
      setState(() {
        _feedbackList = querySnapshot.docs.map((doc) => doc.data()).toList();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveFeedback() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null &&
        _feedbackController.text.trim().isNotEmpty &&
        _nameController.text.trim().isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('feedback')
            .add({
          'name': _nameController.text.trim(),
          'text': _feedbackController.text.trim(),
          'timestamp': FieldValue.serverTimestamp(),
        });
        _feedbackController.clear();
        _nameController.clear();
        await _loadFeedback();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback saved successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving feedback: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both name and feedback')),
      );
    }
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: Text(
          'Feedback',
          style: GoogleFonts.playfairDisplay(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF5F5F5),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFF5F5F5)),
          onPressed: () => Navigator.pop(context),
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
              : SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
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
                                'Share Your Experience',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFF5F5F5),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xFF8B5CF6),
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      controller: _nameController,
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: const Color(0xFFF5F5F5),
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter your name (e.g., Pavan)',
                                        hintStyle: GoogleFonts.poppins(
                                          fontSize: 16,
                                          color: Colors.white70,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: const Color(0xFFF5F5F5).withOpacity(0.3),
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.black.withOpacity(0.2),
                                        contentPadding: const EdgeInsets.all(12),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _feedbackController,
                                maxLines: 4,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFFF5F5F5),
                                ),
                                decoration: InputDecoration(
                                  hintText: 'How did your meditation feel today? Any insights?',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: const Color(0xFFF5F5F5).withOpacity(0.3),
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.2),
                                  contentPadding: const EdgeInsets.all(12),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: _saveFeedback,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF8B5CF6),
                                    foregroundColor: const Color(0xFFF5F5F5),
                                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 8,
                                    shadowColor: const Color(0xFF8B5CF6).withOpacity(0.6),
                                  ),
                                  child: Text(
                                    'Submit Feedback',
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
                        Text(
                          'Your Feedback History',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F5F5),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _feedbackList.isEmpty
                            ? Center(
                                child: Text(
                                  'No feedback yet. Share your experience above!',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              )
                            : Column(
                                children: _feedbackList.map((feedback) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildFeedbackCard(
                                    name: feedback['name'] ?? 'User',
                                    text: feedback['text'] ?? '',
                                    timestamp: (feedback['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
                                    context: context,
                                  ),
                                )).toList(),
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

  Widget _buildFeedbackCard({
    required String name,
    required String text,
    required DateTime timestamp,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2A2A2A),
            Color(0xFF1F1F1F),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person,
                    color: Color(0xFF8B5CF6),
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Name: $name',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF5F5F5),
                    ),
                  ),
                ],
              ),
              Text(
                DateFormat('MMM d, yyyy - HH:mm').format(timestamp),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Feedback:',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFF5F5F5).withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}