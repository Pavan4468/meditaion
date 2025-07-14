import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DailyPracticeTab extends StatefulWidget {
  const DailyPracticeTab({super.key});

  @override
  _DailyPracticeTabState createState() => _DailyPracticeTabState();
}

class _DailyPracticeTabState extends State<DailyPracticeTab> with SingleTickerProviderStateMixin {
  final TextEditingController _reflectionController = TextEditingController();
  List<bool> isBlinking = [false, false, false, false];
  List<bool> isReminderActive = [false, false, false, false];
  List<bool> hasSelectedTime = [false, false, false, false];
  List<TimeOfDay> practiceTimes = [
    const TimeOfDay(hour: 6, minute: 0),
    const TimeOfDay(hour: 19, minute: 0),
    const TimeOfDay(hour: 21, minute: 0),
    const TimeOfDay(hour: 22, minute: 30),
  ];
  bool _isLoading = true;
  late AnimationController _blinkController;
  late Animation<Color?> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _blinkAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.2),
      end: const Color(0xFF10B981),
    ).animate(_blinkController);
    _loadUserData().then((_) {
      setState(() => _isLoading = false);
      _showTimeSelectionPopup();
      _startTimeCheck();
    });
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('practices')
          .doc('settings')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          isReminderActive = List<bool>.from(data['reminders'] ?? [false, false, false, false]);
          hasSelectedTime = List<bool>.from(data['hasSelectedTime'] ?? [false, false, false, false]);
          practiceTimes = (data['times'] as List<dynamic>?)
                  ?.asMap()
                  .map((i, time) => MapEntry(
                        i,
                        TimeOfDay(
                          hour: time['hour'] ?? practiceTimes[i].hour,
                          minute: time['minute'] ?? practiceTimes[i].minute,
                        ),
                      ))
                  .values
                  .toList() ??
              practiceTimes;
        });
      }
    }
    _updateBlinkingStatus();
  }

  Future<void> _saveUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('practices')
          .doc('settings')
          .set({
        'reminders': isReminderActive,
        'hasSelectedTime': hasSelectedTime,
        'times': practiceTimes
            .map((time) => {'hour': time.hour, 'minute': time.minute})
            .toList(),
      });
    }
  }

  Future<void> _saveCompletedPractice(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .add({
        'meditationType': ['Morning Meditation', 'Evening Cleaning', '9 PM Prayer', 'Night Meditation'][index],
        'duration': [60, 30, 15, 20][index],
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
  }

  void _showTimeSelectionPopup() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1F1F1F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Set Practice Times',
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF5F5F5),
            ),
          ),
          content: Text(
            'Please set times for your spiritual practices to enable reminders.',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF8B5CF6),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _selectTime(context, 0);
              },
              child: Text(
                'Set Times',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  void _startTimeCheck() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 60));
      if (!mounted) return false;
      _checkPracticeCompletion();
      _updateBlinkingStatus();
      return true;
    });
  }

  void _checkPracticeCompletion() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    for (int i = 0; i < 4; i++) {
      if (isReminderActive[i] && hasSelectedTime[i] && !isWeekend) {
        final practiceTime = practiceTimes[i].hour * 60 + practiceTimes[i].minute;
        final practiceDuration = [60, 30, 15, 20][i];
        if (currentTime == practiceTime + practiceDuration) {
          _saveCompletedPractice(i);
          _showCongratulationsPopup(i);
        }
      }
    }
  }

  void _showCongratulationsPopup(int index) {
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
          'You have completed your ${['Morning Meditation', 'Evening Cleaning', '9 PM Prayer', 'Night Meditation'][index]} practice!',
          style: GoogleFonts.poppins(
            fontSize: 16,
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FeedbackPage()),
              );
            },
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

  void _updateBlinkingStatus() {
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    setState(() {
      for (int i = 0; i < 4; i++) {
        if (isReminderActive[i] && hasSelectedTime[i] && !isWeekend) {
          final practiceTime = practiceTimes[i].hour * 60 + practiceTimes[i].minute;
          isBlinking[i] = currentTime >= practiceTime - 30 && currentTime < practiceTime + 60;
        } else {
          isBlinking[i] = false;
        }
      }
      if (!isBlinking.contains(true)) {
        _blinkController.stop();
      } else if (_blinkController.isDismissed) {
        _blinkController.repeat(reverse: true);
      }
    });
  }

  Future<void> _selectTime(BuildContext context, int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: practiceTimes[index],
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Color(0xFF2A2A2A),
              onSurface: Colors.white,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != practiceTimes[index]) {
      setState(() {
        practiceTimes[index] = picked;
        hasSelectedTime[index] = true;
        isReminderActive[index] = true;
        _updateBlinkingStatus();
        _saveUserData();
      });
      if (index < 3 && !hasSelectedTime[index + 1]) {
        _selectTime(context, index + 1);
      }
    }
  }

  void _handleDoneButton(int index) {
    _saveCompletedPractice(index);
    _showCongratulationsPopup(index);
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    _blinkController.dispose();
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
                      'Daily Practice Schedule',
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
                      'Set gentle reminders for your spiritual practices',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Reminders',
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
                      description: 'Point B Meditation before sunrise',
                      time: practiceTimes[0].format(context),
                      duration: '30-60 min',
                      status: _getStatus(0),
                      context: context,
                      isBlinking: isBlinking[0],
                      isReminderActive: isReminderActive[0],
                      hasSelectedTime: hasSelectedTime[0],
                      onToggleReminder: (value) {
                        if (hasSelectedTime[0]) {
                          setState(() {
                            isReminderActive[0] = value;
                            _updateBlinkingStatus();
                            _saveUserData();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a time first')),
                          );
                          _selectTime(context, 0);
                        }
                      },
                      onSelectTime: () => _selectTime(context, 0),
                      onDone: () => _handleDoneButton(0),
                      blinkAnimation: _blinkAnimation,
                      gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                    const SizedBox(height: 16),
                    _buildPracticeCard(
                      icon: Icons.cleaning_services,
                      title: 'Evening Cleaning',
                      description: 'Heart cleaning after sunset',
                      time: practiceTimes[1].format(context),
                      duration: '20-30 min',
                      status: _getStatus(1),
                      context: context,
                      isBlinking: isBlinking[1],
                      isReminderActive: isReminderActive[1],
                      hasSelectedTime: hasSelectedTime[1],
                      onToggleReminder: (value) {
                        if (hasSelectedTime[1]) {
                          setState(() {
                            isReminderActive[1] = value;
                            _updateBlinkingStatus();
                            _saveUserData();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a time first')),
                          );
                          _selectTime(context, 1);
                        }
                      },
                      onSelectTime: () => _selectTime(context, 1),
                      onDone: () => _handleDoneButton(1),
                      blinkAnimation: _blinkAnimation,
                      gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                    const SizedBox(height: 16),
                    _buildPracticeCard(
                      icon: Icons.access_time,
                      title: '9 PM Prayer',
                      description: 'Universal prayer for all',
                      time: practiceTimes[2].format(context),
                      duration: '10-15 min',
                      status: _getStatus(2),
                      context: context,
                      isBlinking: isBlinking[2],
                      isReminderActive: isReminderActive[2],
                      hasSelectedTime: hasSelectedTime[2],
                      onToggleReminder: (value) {
                        if (hasSelectedTime[2]) {
                          setState(() {
                            isReminderActive[2] = value;
                            _updateBlinkingStatus();
                            _saveUserData();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a time first')),
                          );
                          _selectTime(context, 2);
                        }
                      },
                      onSelectTime: () => _selectTime(context, 2),
                      onDone: () => _handleDoneButton(2),
                      blinkAnimation: _blinkAnimation,
                      gradientColors: const [Color(0xFFF97316), Color(0xFFEA580C)],
                    ),
                    const SizedBox(height: 16),
                    _buildPracticeCard(
                      icon: Icons.nightlight_round,
                      title: 'Night Meditation',
                      description: 'Point A Meditation before sleep',
                      time: practiceTimes[3].format(context),
                      duration: '15-20 min',
                      status: _getStatus(3),
                      context: context,
                      isBlinking: isBlinking[3],
                      isReminderActive: isReminderActive[3],
                      hasSelectedTime: hasSelectedTime[3],
                      onToggleReminder: (value) {
                        if (hasSelectedTime[3]) {
                          setState(() {
                            isReminderActive[3] = value;
                            _updateBlinkingStatus();
                            _saveUserData();
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select a time first')),
                          );
                          _selectTime(context, 3);
                        }
                      },
                      onSelectTime: () => _selectTime(context, 3),
                      onDone: () => _handleDoneButton(3),
                      blinkAnimation: _blinkAnimation,
                      gradientColors: const [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Notification Settings',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSettingsCard(
                      context: context,
                      gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Sahaj Marg Teaching',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildQuoteCard(
                      quote:
                          '"Regularity in practice is the key to progress. Even five minutes of sincere meditation is better than hours of mechanical sitting."',
                      context: context,
                      gradientColors: const [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
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

  String _getStatus(int index) {
    if (!hasSelectedTime[index]) {
      return 'Time Not Set';
    }
    if (!isReminderActive[index]) {
      return 'Disabled';
    }
    final now = DateTime.now();
    final currentTime = now.hour * 60 + now.minute;
    final practiceTime = practiceTimes[index].hour * 60 + practiceTimes[index].minute;

    if (currentTime >= practiceTime && currentTime < practiceTime + 60) {
      return 'Now';
    } else if (currentTime < practiceTime) {
      return 'Upcoming';
    } else {
      return 'Passed';
    }
  }

  Widget _buildPracticeCard({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required String duration,
    required String status,
    required BuildContext context,
    required bool isBlinking,
    required bool isReminderActive,
    required bool hasSelectedTime,
    required ValueChanged<bool> onToggleReminder,
    required VoidCallback onSelectTime,
    required VoidCallback onDone,
    Animation<Color?>? blinkAnimation,
    required List<Color> gradientColors,
  }) {
    return AnimatedBuilder(
      animation: isBlinking && blinkAnimation != null ? blinkAnimation : const AlwaysStoppedAnimation(Colors.white),
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isBlinking && blinkAnimation != null
                  ? [blinkAnimation.value!, blinkAnimation.value!.withOpacity(0.7)]
                  : gradientColors,
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
                    child: Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 64),
                child: Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 64),
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    GestureDetector(
                      onTap: onSelectTime,
                      child: Text(
                        hasSelectedTime ? '$time • $duration' : 'Set Time • $duration',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(hasSelectedTime ? 0.8 : 0.6),
                        ),
                      ),
                    ),
                    Text(
                      status,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: status == 'Now'
                            ? const Color(0xFF10B981)
                            : status == 'Disabled' || status == 'Time Not Set'
                                ? Colors.grey
                                : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    'Reminder',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white.withOpacity(hasSelectedTime ? 0.8 : 0.6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: isReminderActive,
                    onChanged: hasSelectedTime ? onToggleReminder : null,
                    activeColor: gradientColors[0],
                    activeTrackColor: Colors.white,
                    inactiveThumbColor: Colors.grey,
                    inactiveTrackColor: Colors.white.withOpacity(0.2),
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: onDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: const Color(0xFFF5F5F5),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                      shadowColor: const Color(0xFF8B5CF6).withOpacity(0.6),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFF5F5F5),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard({
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
            'Notification Settings',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '• Gentle notification tones\n• Vibration reminders\n• Silent mode (weekends)',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuoteCard({
    required String quote,
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
      child: Text(
        '“$quote”',
        style: GoogleFonts.lora(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          color: Colors.white,
          height: 1.6,
        ),
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
                                  hintText: 'How did your practice feel today? Any insights?',
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