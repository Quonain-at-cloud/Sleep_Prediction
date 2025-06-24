import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dietary_habits_screen.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart'; // Added for date formatting

class SleepPatternsScreen extends StatefulWidget {
  const SleepPatternsScreen({Key? key}) : super(key: key);

  @override
  State<SleepPatternsScreen> createState() => _SleepPatternsScreenState();
}

class _SleepPatternsScreenState extends State<SleepPatternsScreen> {
  // Controllers for age input
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  bool _isFirstTimeUser = false;
  bool _isLoadingUserData = true;
  
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Check if user is first time user (missing gender or age)
    _checkIfFirstTimeUser();
    // Compute initial average based on default times
    _updateAverageSleepDuration();
  }
  
  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }
  
  Future<void> _checkIfFirstTimeUser() async {
    setState(() => _isLoadingUserData = true);
    
    try {
      final authBloc = BlocProvider.of<AuthBloc>(context);
      final currentState = authBloc.state;
      
      if (currentState is AuthAuthenticated && currentState.user != null) {
        final user = currentState.user;
        
        // Check if gender is empty or dateOfBirth is not set
        if (user == null || 
            user['gender'] == null || 
            user['gender']?.toString().isEmpty == true || 
            user['dateOfBirth'] == null || 
            user['dateOfBirth']?.toString().isEmpty == true) {
          setState(() => _isFirstTimeUser = true);
        } else {
          setState(() => _isFirstTimeUser = false);
        }
      }
    } catch (e) {
      print('Error checking user data: $e');
    } finally {
      setState(() => _isLoadingUserData = false);
    }
  }

  TimeOfDay _weekdayBedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _weekdayWakeup = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _weekendBedtime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _weekendWakeup = const TimeOfDay(hour: 10, minute: 0);
  double _sleepDuration = 6.0;
  int _awakenings = 3;
  int _rateSleepQuality = 1;
  int _relaxedBeforeSleep = 1;
  bool _useElectronics = true;
  double _stressLevel = 1.0;

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // Using 'en_US' locale to ensure AM/PM format regardless of device locale
    // 'h' for 12-hour format, 'mm' for minutes, 'a' for AM/PM marker
    return DateFormat('h:mm a', 'en_US').format(dt);
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    TimeOfDay initialTime;
    switch (type) {
      case 'weekdayBedtime':
        initialTime = _weekdayBedtime;
        break;
      case 'weekdayWakeup':
        initialTime = _weekdayWakeup;
        break;
      case 'weekendBedtime':
        initialTime = _weekendBedtime;
        break;
      case 'weekendWakeup':
        initialTime = _weekendWakeup;
        break;
      default:
        initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (type) {
          case 'weekdayBedtime':
            _weekdayBedtime = picked;
            break;
          case 'weekdayWakeup':
            _weekdayWakeup = picked;
            break;
          case 'weekendBedtime':
            _weekendBedtime = picked;
            break;
          case 'weekendWakeup':
            _weekendWakeup = picked;
            break;
        }
        _updateAverageSleepDuration();
      });
    }
  }

  Widget _buildTimeSelector(String label, String type) {
    TimeOfDay time;
    switch (type) {
      case 'weekdayBedtime':
        time = _weekdayBedtime;
        break;
      case 'weekdayWakeup':
        time = _weekdayWakeup;
        break;
      case 'weekendBedtime':
        time = _weekendBedtime;
        break;
      case 'weekendWakeup':
        time = _weekendWakeup;
        break;
      default:
        time = TimeOfDay.now();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montaga(
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        InkWell(
          onTap: () => _selectTime(context, type),
          child: Container(
            width: 135,
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF31244C), width: 1),
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTime(time), // _formatTime now includes AM/PM
                  style: GoogleFonts.montaga(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                Image.asset(
                  'assets/icons/timer.png',
                  width: 22,
                  height: 22,
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(String label, int value, void Function(int) onChanged, {String? subtitle, int min = 0, int max = 100, bool showIcons = true, String? hintText}) {
    // Create a controller that maintains the current value
    final TextEditingController controller = TextEditingController(text: value.toString());
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.montaga(
                    fontSize: 16,
                    color: const Color(0xFF31244C),
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.montaga(
                        fontSize: 13,
                        color: const Color(0xFF31244C),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                width: 100,
                height: 46,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF31244C), width: 1),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.only(left: 15, right: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.montaga(
                          fontSize: 22,
                          color: const Color(0xFF31244C),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: hintText,
                          hintStyle: GoogleFonts.montaga(
                            fontSize: 18,
                            color: const Color(0xFF31244C).withOpacity(0.5),
                          ),
                        ),
                        inputFormatters: showIcons ? null : [
                          FilteringTextInputFormatter.digitsOnly,
                          FilteringTextInputFormatter.allow(RegExp(r'^[1-5]?')),
                        ],
                        onChanged: (val) {
                          final int? newValue = int.tryParse(val);
                          if (newValue != null && newValue >= min && newValue <= max) {
                            onChanged(newValue);
                          }
                        },
                        onSubmitted: (val) {
                          final int? newValue = int.tryParse(val);
                          if (newValue != null && newValue >= min && newValue <= max) {
                            onChanged(newValue);
                          } else {
                            // Reset to current value if invalid
                            controller.text = value.toString();
                          }
                        },
                      ),
                    ),
                    if (showIcons) ...[
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: const Offset(0, 6),
                            child: GestureDetector(
                              onTap: () {
                                if (value < max) {
                                  onChanged(value + 1);
                                  controller.text = (value + 1).toString();
                                }
                              },
                              child: Icon(
                                Icons.expand_less,
                                size: 22,
                                color: const Color(0xFF31244C),
                              ),
                            ),
                          ),
                          Transform.translate(
                            offset: const Offset(0, -6),
                            child: GestureDetector(
                              onTap: () {
                                if (value > min) {
                                  onChanged(value - 1);
                                  controller.text = (value - 1).toString();
                                }
                              },
                              child: Icon(
                                Icons.expand_more,
                                size: 22,
                                color: const Color(0xFF31244C),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]  
                  ],
                ),
              ),
              const SizedBox(width: 30),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to calculate duration (in hours) between two TimeOfDay values
  double _calculateDurationHours(TimeOfDay start, TimeOfDay end) {
    final now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, start.hour, start.minute);
    DateTime endDate   = DateTime(now.year, now.month, now.day, end.hour, end.minute);

    // If wake-up happens the next day, add a day to endDate
    if (!endDate.isAfter(startDate)) {
      endDate = endDate.add(const Duration(days: 1));
    }
    return endDate.difference(startDate).inMinutes / 60.0;
  }

  // Re-calculate and update the average sleep duration
  // Formula: (weekdayHours * 5 + weekendHours * 2) / 7
  void _updateAverageSleepDuration() {
    final double weekdayHours = _calculateDurationHours(_weekdayBedtime, _weekdayWakeup);
    final double weekendHours = _calculateDurationHours(_weekendBedtime, _weekendWakeup);

    final double totalForWeek = (weekdayHours * 5) + (weekendHours * 2);
    final double average = totalForWeek / 7.0;

    setState(() {
      _sleepDuration = double.parse(average.toStringAsFixed(1)); // keep one decimal place
    });
  }

  // Read-only UI row that mirrors the existing input style
  Widget _buildAverageDurationDisplay(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.montaga(
            fontSize: 16,
            color: const Color(0xFF31244C),
          ),
        ),
        Container(
          width: 100,
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF31244C), width: 1),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Text(
            value.toStringAsFixed(1),
            style: GoogleFonts.montaga(
              fontSize: 22,
              color: const Color(0xFF31244C),
            ),
          ),
        ),
      ],
    );
  }

  // Build sleep data map from form inputs
  Map<String, dynamic> _buildSleepData() {
    // Debug log to check the values before creating the map
    print('--- Building Sleep Data ---');
    print('Weekday Bedtime: ${_weekdayBedtime.hour}:${_weekdayBedtime.minute}');
    print('Weekday Wake-up: ${_weekdayWakeup.hour}:${_weekdayWakeup.minute}');
    print('Weekend Bedtime: ${_weekendBedtime.hour}:${_weekendBedtime.minute}');
    print('Weekend Wake-up: ${_weekendWakeup.hour}:${_weekendWakeup.minute}');
    print('Sleep Duration: $_sleepDuration');
    print('Awakenings: $_awakenings');
    print('Rate Sleep Quality: $_rateSleepQuality');
    print('Relaxed Before Sleep: $_relaxedBeforeSleep');
    print('Use Electronics: $_useElectronics');
    print('Stress Level: $_stressLevel');
    print('--------------------------');

    return {
      'Sleep Duration': _sleepDuration,
      'Awakenings During Night': _awakenings,
      'Rate Sleep Quality': _rateSleepQuality,
      'Stress Level': _stressLevel,
      'Weekday Bedtime Hour': _weekdayBedtime.hour,
      'Weekday Bedtime Minute': _weekdayBedtime.minute,
      'Weekday Wake-up Hour': _weekdayWakeup.hour,
      'Weekday Wake-up Minute': _weekdayWakeup.minute,
      'Weekend Bedtime Hour': _weekendBedtime.hour,
      'Weekend Bedtime Minute': _weekendBedtime.minute,
      'Weekend Wake-up Hour': _weekendWakeup.hour,
      'Weekend Wake-up Minute': _weekendWakeup.minute,
      'How Relaxed Before Sleep': _relaxedBeforeSleep,
      'Use Electronic Devices Before Bed': _useElectronics,
    };
  }

  // Save sleep data and navigate to next screen
  void _saveAndContinue() {
    final sleepData = _buildSleepData();

    // Basic validation
    if (sleepData['Sleep Duration'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter sleep duration.')),
      );
      return;
    }

    if (_isFirstTimeUser) {
      if (_ageController.text.isEmpty || _selectedGender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter your age and select your gender.')),
        );
        return;
      }
      final age = int.tryParse(_ageController.text);
      if (age == null || age <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid age.')),
        );
        return;
      }

      // Update profile via BLoC
      final now = DateTime.now();
      final dateOfBirth = DateTime(now.year - age, now.month, now.day);

      BlocProvider.of<AuthBloc>(context).add(
        UpdateProfileEvent(dateOfBirth: dateOfBirth, gender: _selectedGender!.toLowerCase()),
      );

      // Prepare data for next screen
      final profileInfo = {'Age': age, 'Gender': _selectedGender};
      final combinedData = {...sleepData, ...profileInfo};

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DietaryHabitsScreen(
            sleepData: combinedData,
            profileInfo: profileInfo,
          ),
        ),
      );
    } else {
      // For existing users, just pass sleep data
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DietaryHabitsScreen(sleepData: sleepData),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated && state.user != null) {
            // Close loading indicator if showing
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
            
            // Check if this was a profile update for first-time user
            if (_isFirstTimeUser && 
                state.user != null &&
                state.user?['gender'] != null && 
                state.user?['dateOfBirth'] != null) {
              // Navigate to the dietary habits screen
              Navigator.pushReplacementNamed(
                context,
                AppConstants.dietaryHabitsRoute,
                arguments: {
                  'sleepData': _buildSleepData(),
                  'profileInfo': {
                    'age': int.tryParse(_ageController.text) ?? 0, // Age from current input
                    'gender': state.user?['gender'] ?? _selectedGender ?? '' // Gender from updated user state or current selection
                  }
                },
              );
            }
          } else if (state is AuthError) {
            // Close loading indicator if showing
            if (Navigator.of(context).canPop()) {
              Navigator.pop(context);
            }
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: SafeArea(
          child: _isLoadingUserData 
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
              child: Text(
                _isFirstTimeUser ? 'Complete Your Profile' : 'Sleep Patterns',
                textAlign: TextAlign.center,
                style: GoogleFonts.montaga(
                  fontSize: 25,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF3B1F52),
                ),
              ),
            ),
            // Show first-time user message if needed
            if (_isFirstTimeUser)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Please provide your age and gender to personalize your sleep predictions.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Age input
                    Text(
                      'Your Age',
                      style: GoogleFonts.montaga(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 55,
                      width: 170,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _ageController,
                        style: GoogleFonts.montaga(
                          fontSize: 18,
                          color: const Color(0xFF31244C),
                        ),
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Age',
                          hintStyle: GoogleFonts.montaga(
                            fontSize: 16,
                            color: const Color(0xFF31244C).withOpacity(0.5),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Gender dropdown
                    Text(
                      'Your Gender',
                      style: GoogleFonts.montaga(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 55,
                      width: 170,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGender,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF352F44),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF31244C),
                          ),
                          hint: Center(
                            child: Text(
                              'Select Gender',
                              style: GoogleFonts.montaga(
                                fontSize: 16,
                                color: const Color(0xFF31244C).withOpacity(0.5),
                              ),
                            ),
                          ),
                          items: ['Male', 'Female', 'Other']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Center(
                                child: Text(
                                  value,
                                  style: GoogleFonts.montaga(
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGender = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 24, right: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Only show sleep pattern inputs for returning users
                    if (!_isFirstTimeUser) ...[                    
                      _buildTimeSelector('Weekday Bedtime', 'weekdayBedtime'),
                      const SizedBox(height: 16),
                      _buildTimeSelector('Weekday Wake-up', 'weekdayWakeup'),
                      const SizedBox(height: 16),
                      _buildTimeSelector('Weekend Bedtime', 'weekendBedtime'),
                      const SizedBox(height: 16),
                      _buildTimeSelector('Weekend wake-up', 'weekendWakeup'),
                      const SizedBox(height: 16),
                      _buildAverageDurationDisplay('Average Sleep Duration', _sleepDuration),
                      const SizedBox(height: 16),
                      _buildStepper('Awakenings during night', _awakenings, (val) => setState(() => _awakenings = val)),
                      const SizedBox(height: 16),
                      _buildStepper('Rate sleep quality', _rateSleepQuality, (val) => setState(() => _rateSleepQuality = val),
                        subtitle: '(1 for worst and 5 for best)',
                        min: 1,
                        max: 5,
                        showIcons: false,
                        hintText: '1 - 5'),
                      const SizedBox(height: 16),
                      Text(
                        'Use electronic devices before bed?',
                        style: GoogleFonts.montaga(
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _useElectronics,
                                  onChanged: (value) {
                                    setState(() {
                                      _useElectronics = value ?? false;
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Yes',
                                style: GoogleFonts.montaga(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 64),
                          Row(
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: !_useElectronics,
                                  onChanged: (value) {
                                    setState(() {
                                      _useElectronics = !(value ?? true);
                                    });
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'No',
                                style: GoogleFonts.montaga(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 90),

                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildStepper(
                        'How relaxed do you feel before sleep?',
                        _relaxedBeforeSleep,
                        (val) => setState(() => _relaxedBeforeSleep = val),
                        subtitle: '(1 for not relaxed, 5 for very relaxed)',
                        min: 1,
                        max: 5,
                        showIcons: false,
                        hintText: '1 - 5',
                      ),
                      const SizedBox(height: 24),
                      _buildStepper(
                        'Stress Level',
                        _stressLevel.toInt(),
                        (val) => setState(() => _stressLevel = val.toDouble()),
                        subtitle: '(1 for low, 5 for high)',
                        min: 1,
                        max: 5,
                        showIcons: false,
                        hintText: '1 - 5',
                      ),
                    ],
                    const SizedBox(height: 32),
                    Center(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _saveAndContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF65558F),
                            padding: const EdgeInsets.symmetric(vertical: 16 ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 0,
                          ),
                        child: Text(
                          _isFirstTimeUser ? 'Next' : 'Next',
                          style: GoogleFonts.montserrat(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 18, bottom: 0),
              width: double.infinity,
              height: 10,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 65,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5C5470),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 65,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 65,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
      bottomNavigationBar: CustomBottomNavigation(
        screenColor: Colors.white,
        currentIndex: 1,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
      endDrawer: const CustomProfileDrawer(),
    ),
  );
}
}