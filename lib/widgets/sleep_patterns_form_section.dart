import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_constants.dart';
import '../blocs/auth/auth_bloc.dart';
import '../blocs/auth/auth_event.dart';
import '../blocs/auth/auth_state.dart';
import '../utils/app_constants.dart'; // For potential route constants if any part still needs them, though likely not for navigation
import '../utils/app_theme.dart';

class SleepPatternsFormSection extends StatefulWidget {
  final Function(Map<String, dynamic> sleepData) onDataCollected;
  // This key will allow the parent to call methods on this state
  const SleepPatternsFormSection({Key? key, required this.onDataCollected}) : super(key: key);

  @override
  SleepPatternsFormSectionState createState() => SleepPatternsFormSectionState();
}

class SleepPatternsFormSectionState extends State<SleepPatternsFormSection> {
  // Controllers for age input
  final TextEditingController _ageController = TextEditingController();
  String? _selectedGender;
  bool _isFirstTimeUser = false;
  bool _isLoadingUserData = true;
  bool _profileUpdateInProgress = false;
  bool _wasAttemptingProfileUpdate = false;
  
  // Form state for sleep patterns
  TimeOfDay _weekdayBedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _weekdayWakeup = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _weekendBedtime = const TimeOfDay(hour: 0, minute: 0);
  TimeOfDay _weekendWakeup = const TimeOfDay(hour: 10, minute: 0);
  int _sleepDuration = 6;
  int _awakenings = 3;
  int _rateSleepQuality = 1;
  int _relaxedBeforeSleep = 1;
  bool _useElectronics = true;
  double _stressLevel = 1.0;

  final GlobalKey<FormState> _firstTimeFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _sleepPatternsFormKey = GlobalKey<FormState>(); // If needed for sleep data validation

  @override
  void initState() {
    super.initState();
    _checkIfFirstTimeUser();
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }
  
  Future<void> _checkIfFirstTimeUser() async {
    setState(() => _isLoadingUserData = true);
    try {
      // Ensure AuthBloc is available. If not, this indicates a setup issue.
      if (!mounted) return;
      final authBloc = BlocProvider.of<AuthBloc>(context);
      final currentState = authBloc.state;
      
      if (currentState is AuthAuthenticated && currentState.user != null) {
        final user = currentState.user!;
        if (user['gender'] == null || 
            user['gender']?.toString().isEmpty == true || 
            user['dateOfBirth'] == null || 
            user['dateOfBirth']?.toString().isEmpty == true) {
          setState(() => _isFirstTimeUser = true);
        } else {
          setState(() => _isFirstTimeUser = false);
        }
      } else {
        // Handle cases where user might not be authenticated as expected or user data is null
        // This might indicate a flow issue or that this screen was reached inappropriately.
        print('User not authenticated or user data is null in SleepPatternsFormSection');
        setState(() => _isFirstTimeUser = false); // Default to not being first time to avoid blocking
      }
    } catch (e) {
      print('Error checking user data in SleepPatternsFormSection: $e');
      if(mounted) setState(() => _isFirstTimeUser = false); // Default on error
    } finally {
      if(mounted) setState(() => _isLoadingUserData = false);
    }
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    // Create DateTime from TimeOfDay
    final dtFromTimeOfDay = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    print('--- Debug _formatTime (SleepPatterns) ---');
    print('Input TimeOfDay: hour=${time.hour}, minute=${time.minute}');
    print('Created DateTime: $dtFromTimeOfDay');

    // Test DateFormat with the created DateTime
    String formattedFromDt = DateFormat('h:mm a', 'en_US').format(dtFromTimeOfDay);
    print('Formatted from dtFromTimeOfDay (h:mm a, en_US): $formattedFromDt');

    // Forcing lowercase 'h' - sometimes 'hh' (two digits) vs 'h' (one or two) can matter, though 'h' is usually correct for 1-12.
    String formattedWithSingleH = DateFormat('h:mm a', 'en_US').format(dtFromTimeOfDay);
    print('Formatted with single h (h:mm a, en_US): $formattedWithSingleH');
    
    // Test with a known DateTime value, e.g., 11 PM
    final testDateTime = DateTime(now.year, now.month, now.day, 23, 0); // 11:00 PM
    String formattedTest = DateFormat('h:mm a', 'en_US').format(testDateTime);
    print('Formatted from testDateTime (23:00) (h:mm a, en_US): $formattedTest');

    // Test with another known DateTime value, e.g., 3:30 PM
    final testDateTime2 = DateTime(now.year, now.month, now.day, 15, 30); // 3:30 PM
    String formattedTest2 = DateFormat('h:mm a', 'en_US').format(testDateTime2);
    print('Formatted from testDateTime2 (15:30) (h:mm a, en_US): $formattedTest2');
    print('--- End Debug _formatTime (SleepPatterns) ---');

    // Return the version we expect to work
    return formattedFromDt;
  }

  Future<void> _selectTime(BuildContext context, String type) async {
    print('SleepPatternsFormSection: _selectTime called for type: "$type".');
    TimeOfDay initialTime;
    switch (type) {
      case 'weekdayBedtime': initialTime = _weekdayBedtime; break;
      case 'weekdayWakeup': initialTime = _weekdayWakeup; break;
      case 'weekendBedtime': initialTime = _weekendBedtime; break;
      case 'weekendWakeup': initialTime = _weekendWakeup; break;
      default: initialTime = TimeOfDay.now();
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
    print('SleepPatternsFormSection: _selectTime - picked time: $picked');
    if (picked != null) {
      setState(() {
        print('SleepPatternsFormSection: _selectTime - setState called with picked: $picked for type: "$type".');
        switch (type) {
          case 'weekdayBedtime': _weekdayBedtime = picked; break;
          case 'weekdayWakeup': _weekdayWakeup = picked; break;
          case 'weekendBedtime': _weekendBedtime = picked; break;
          case 'weekendWakeup': _weekendWakeup = picked; break;
        }
      });
    } else {
      print('SleepPatternsFormSection: _selectTime - picked was null (dialog cancelled).');
    }
  }

  Map<String, dynamic> _buildSleepData() {
    return {
      'weekdayBedtime': _formatTime(_weekdayBedtime),
      'weekdayWakeup': _formatTime(_weekdayWakeup),
      'weekendBedtime': _formatTime(_weekendBedtime),
      'weekendWakeup': _formatTime(_weekendWakeup),
      'sleepDuration': _sleepDuration,
      'awakenings': _awakenings,
      'sleepQuality': _rateSleepQuality,
      'relaxedBeforeSleep': _relaxedBeforeSleep,
      'useElectronics': _useElectronics,
      'stressLevel': _stressLevel,
    };
  }

  void _handleProfileUpdate() {
    if (_firstTimeFormKey.currentState?.validate() ?? false) {
      setState(() => _profileUpdateInProgress = true);
      final age = int.parse(_ageController.text);
      final DateTime now = DateTime.now();
      final DateTime dateOfBirth = DateTime(now.year - age, now.month, now.day); // Standardize to midnight local time
      BlocProvider.of<AuthBloc>(context).add(UpdateProfileEvent(
        dateOfBirth: dateOfBirth,
        gender: _selectedGender!.toLowerCase(),
      ));
    }
  }
  
  // This method will be called by the parent MultiStepDataCollectionScreen
  // It returns true if data collection can proceed to the next step, false otherwise.
  bool prepareAndValidateCurrentStep() {
    if (_isFirstTimeUser) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please save your profile information first.')),
        );
        return false; // User must save profile first using the internal button
    }
    // Add any validation for sleep patterns data if needed, e.g., using _sleepPatternsFormKey.currentState.validate()
    // For now, assume it's valid if not a first-time user who hasn't saved profile.
    widget.onDataCollected(_buildSleepData());
    return true;
  }

  // UI Building methods (to be moved from SleepPatternsScreen)
  Widget _buildTimeSelector(String label, String type) {
    print('SleepPatternsFormSection: _buildTimeSelector called for label: "$label", type: "$type".');
    TimeOfDay time;
    switch (type) {
      case 'weekdayBedtime': time = _weekdayBedtime; break;
      case 'weekdayWakeup': time = _weekdayWakeup; break;
      case 'weekendBedtime': time = _weekendBedtime; break;
      case 'weekendWakeup': time = _weekendWakeup; break;
      default: time = TimeOfDay.now();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87)),
          InkWell(
            onTap: () => _selectTime(context, type),
            child: Container(
              width: 135, height: 35, padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF31244C), width: 1), borderRadius: BorderRadius.circular(10), color: Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  (){ String formattedTime = _formatTime(time); print('SleepPatterns - Formatted time for $label: $formattedTime'); return Text(formattedTime, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87)); }(),
                  Image.asset('assets/icons/timer.png', width: 22, height: 22, color: Colors.grey.shade600),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper(String label, int value, void Function(int) onChanged, {String? subtitle, int min = 0, int max = 100, bool showIcons = true, String? hintText}) {
     return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: GoogleFonts.montaga(fontSize: 16, color: const Color(0xFF31244C))),
              if (subtitle != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(subtitle, style: GoogleFonts.montaga(fontSize: 13, color: const Color(0xFF31244C)))),
            ]),
          ),
          Container(
            width: 100, height: 46,
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF31244C), width: 1), borderRadius: BorderRadius.circular(12), color: Colors.white),
            padding: const EdgeInsets.only(left: 15, right: 10),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Expanded(child: TextField(
                controller: TextEditingController(text: value.toString())..selection = TextSelection.fromPosition(TextPosition(offset: value.toString().length)),
                keyboardType: TextInputType.number, textAlign: TextAlign.center, style: GoogleFonts.montaga(fontSize: 22, color: const Color(0xFF31244C)),
                decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: hintText, hintStyle: GoogleFonts.montaga(fontSize: 18, color: const Color(0xFF31244C).withOpacity(0.5))),
                inputFormatters: showIcons ? [FilteringTextInputFormatter.digitsOnly] : [FilteringTextInputFormatter.digitsOnly, FilteringTextInputFormatter.allow(RegExp(r'^[1-5]?'))],
                onChanged: (val) { final int? newValue = int.tryParse(val); if (newValue != null && newValue >= min && newValue <= max) { onChanged(newValue); } else if (val.isEmpty && min == 0) {onChanged(0); } else { /* Optionally revert to old value or show error */ } },
              )),
              if (showIcons) ...[
                Column(mainAxisAlignment: MainAxisAlignment.center, mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Transform.translate(offset: const Offset(0, 6), child: GestureDetector(onTap: () { if (value < max) onChanged(value + 1); }, child: Icon(Icons.expand_less, size: 22, color: const Color(0xFF31244C)))),
                  Transform.translate(offset: const Offset(0, -6), child: GestureDetector(onTap: () { if (value > min) onChanged(value - 1); }, child: Icon(Icons.expand_more, size: 22, color: const Color(0xFF31244C)))),
                ]),
              ]
            ]),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('SleepPatternsFormSection: build method called.');
    print('SleepPatternsFormSection: _isLoadingUserData = $_isLoadingUserData');
    print('SleepPatternsFormSection: _isFirstTimeUser = $_isFirstTimeUser');
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        setState(() => _profileUpdateInProgress = false);
        if (state is AuthAuthenticated) {
          // Assuming AuthAuthenticated is emitted after a successful profile update
          // if no AuthError was emitted during the process.
          // Show a generic success message if we were indeed trying to update.
          if (_wasAttemptingProfileUpdate) { // We need a flag to know if this AuthAuthenticated is due to profile update
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile saved successfully!'), backgroundColor: Colors.green));
            setState(() {
              _isFirstTimeUser = false; // Profile is updated, no longer first time for this section
              _isLoadingUserData = false;
              _wasAttemptingProfileUpdate = false; // Reset flag
            });
          }
        } else if (state is AuthError) { // Changed from AuthFailure
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('An error occurred: ${state.message}'), backgroundColor: Colors.red));
          _wasAttemptingProfileUpdate = false; // Reset flag on error too
        }
      },
      child: _isLoadingUserData
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isFirstTimeUser) ...[
                    print('SleepPatternsFormSection: Building _buildFirstTimeUserForm...'),
                    _buildFirstTimeUserForm()
                  ],
                  if (!_isFirstTimeUser) ...[
                    print('SleepPatternsFormSection: Building _buildSleepPatternsForm...'),
                    _buildSleepPatternsForm()
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildFirstTimeUserForm() {
    return Form(
      key: _firstTimeFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Please provide some basic information:', style: AppConstants.subheadingStyle),
          SizedBox(height: 20),
          TextFormField(
            controller: _ageController,
            decoration: InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter your age.';
              final age = int.tryParse(value);
              if (age == null || age < 1 || age > 120) return 'Please enter a valid age (1-120).';
              return null;
            },
          ),
          SizedBox(height: 20),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
            value: _selectedGender,
            hint: Text('Select Gender'),
            items: ['Male', 'Female', 'Other'].map((String value) {
              return DropdownMenuItem<String>(value: value, child: Text(value));
            }).toList(),
            onChanged: (String? newValue) => setState(() => _selectedGender = newValue),
            validator: (value) => value == null ? 'Please select your gender.' : null,
          ),
          SizedBox(height: 30),
          ElevatedButton(
            onPressed: _profileUpdateInProgress ? null : _handleProfileUpdate,
            child: _profileUpdateInProgress ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0,) : Text('Save Profile'),
            style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 50)),
          ),
          SizedBox(height: 20),
          Text('After saving, you can fill your sleep patterns.', style: AppConstants.bodyStyle)
        ],
      ),
    );
  }

  Widget _buildSleepPatternsForm() {
    print('SleepPatternsFormSection: _buildSleepPatternsForm method called.');
    // This will contain the actual sleep pattern input fields
    // For now, it's a placeholder
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Enter Your Sleep Patterns', style: AppConstants.headingStyle),
        _buildTimeSelector('Weekday Bedtime', 'weekdayBedtime'),
        _buildTimeSelector('Weekday Wake-up', 'weekdayWakeup'),
        _buildTimeSelector('Weekend Bedtime', 'weekendBedtime'),
        _buildTimeSelector('Weekend Wake-up', 'weekendWakeup'),
        _buildStepper('Sleep Duration (hours)', _sleepDuration, (val) => setState(() => _sleepDuration = val), min: 1, max: 16, subtitle: 'Average hours you sleep'),
        _buildStepper('Night Awakenings', _awakenings, (val) => setState(() => _awakenings = val), min: 0, max: 20, subtitle: 'Times you wake up during sleep'),
        _buildStepper('Rate Sleep Quality', _rateSleepQuality, (val) => setState(() => _rateSleepQuality = val), min: 1, max: 5, showIcons: false, hintText: '1-5', subtitle: '1 (Very Poor) to 5 (Excellent)'),
        _buildStepper('Relaxed Before Sleep', _relaxedBeforeSleep, (val) => setState(() => _relaxedBeforeSleep = val), min: 1, max: 5, showIcons: false, hintText: '1-5', subtitle: '1 (Not at all) to 5 (Very relaxed)'),
        SwitchListTile(
          title: Text('Use Electronics Before Bed?', style: GoogleFonts.montaga(fontSize: 16, color: const Color(0xFF31244C))),
          value: _useElectronics,
          onChanged: (bool value) => setState(() => _useElectronics = value),
          activeColor: AppConstants.primaryColor,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text('Stress Level Before Sleep: ${_stressLevel.toStringAsFixed(1)}', style: GoogleFonts.montaga(fontSize: 16, color: const Color(0xFF31244C))),
        ),
        Slider(
          value: _stressLevel,
          min: 1,
          max: 5,
          divisions: 4,
          label: _stressLevel.round().toString(),
          onChanged: (double value) => setState(() => _stressLevel = value),
          activeColor: AppConstants.primaryColor,
          inactiveColor: AppConstants.primaryColor.withOpacity(0.3),
        ),
        // Add other sleep pattern inputs here...
      ],
    );
  }
}
