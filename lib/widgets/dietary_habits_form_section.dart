import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// TODO: Consider moving SquareCheckbox to a common widgets directory if used elsewhere.
class SquareCheckbox extends StatelessWidget {
  final bool selected;
  final Color fillColor;
  final VoidCallback onTap;

  const SquareCheckbox({
    Key? key,
    required this.selected,
    required this.fillColor,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: selected ? fillColor : Colors.transparent,
          borderRadius: BorderRadius.circular(2),
          border: Border.all(
            color: selected ? fillColor : Colors.grey,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class DietaryHabitsFormSection extends StatefulWidget {
  final Function(Map<String, dynamic> data) onDataCollected;

  const DietaryHabitsFormSection({Key? key, required this.onDataCollected}) : super(key: key);

  @override
  DietaryHabitsFormSectionState createState() => DietaryHabitsFormSectionState();
}

class DietaryHabitsFormSectionState extends State<DietaryHabitsFormSection> {
  // --- State Variables (copied from DietaryHabitsScreen) ---
  bool _isBreakfastRegular = true;
  bool _isLunchRegular = true;
  bool _isDinnerRegular = true;
  TimeOfDay _breakfastTime = const TimeOfDay(hour: 9, minute: 30);
  TimeOfDay _lunchTime = const TimeOfDay(hour: 2, minute: 30);
  TimeOfDay _dinnerTime = const TimeOfDay(hour: 8, minute: 30);
  String _breakfastPortionSize = '400g';
  String _lunchPortionSize = '400g';
  String _dinnerPortionSize = '400g';
  int _mealsPerDay = 3;
  bool _caffeineAfterNoon = false;
  bool _alcoholBeforeBed = false;
  bool _heavyMealBeforeBed = false;
  int _waterIntake = 8; // in glasses
  bool _mealTimingConsistent = true;
  bool _balancedMeals = true;
  bool _lateNightSnacking = false;

  Set<String> _selectedBreakfastFoodTypes = {'Carbohydrates'};
  Set<String> _selectedLunchFoodTypes = {'Carbohydrates'};
  Set<String> _selectedDinnerFoodTypes = {'Carbohydrates'};

  final List<String> _foodTypes = [
    'Carbohydrates',
    'Proteins',
    'Fats',
    'Beverage intake',
    'Fruits and Vegetables',
  ];

  final GlobalKey _mealsKey = GlobalKey(); // For custom dropdown positioning
  List<GlobalKey> _portionKeys = List.generate(8, (_) => GlobalKey()); // For portion dropdowns

  // --- Helper method to build dietary data object (copied from DietaryHabitsScreen) ---
  Map<String, dynamic> _buildDietaryData() {
    String formatTimeForData(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }

    int parsePortionSize(String portion) {
      // Corrected RegExp
      final match = RegExp(r'\d+').firstMatch(portion);
      return match != null ? int.parse(match.group(1)!) : 400;
    }

    return {
      'mealsPerDay': _mealsPerDay,
      'meals': [
        {
          'type': 'breakfast',
          'isRegular': _isBreakfastRegular,
          'time': formatTimeForData(_breakfastTime),
          'portionSize': parsePortionSize(_breakfastPortionSize),
          'foodTypes': _selectedBreakfastFoodTypes.toList(),
        },
        {
          'type': 'lunch',
          'isRegular': _isLunchRegular,
          'time': formatTimeForData(_lunchTime),
          'portionSize': parsePortionSize(_lunchPortionSize),
          'foodTypes': _selectedLunchFoodTypes.toList(),
        },
        {
          'type': 'dinner',
          'isRegular': _isDinnerRegular,
          'time': formatTimeForData(_dinnerTime),
          'portionSize': parsePortionSize(_dinnerPortionSize),
          'foodTypes': _selectedDinnerFoodTypes.toList(),
        },
      ],
      'caffeineAfterNoon': _caffeineAfterNoon,
      'alcoholBeforeBed': _alcoholBeforeBed,
      'heavyMealBeforeBed': _heavyMealBeforeBed,
      'waterIntake': _waterIntake,
      'mealTimingConsistent': _mealTimingConsistent,
      'balancedMeals': _balancedMeals,
      'lateNightSnacking': _lateNightSnacking,
    };
  }

  // Method to be called by MultiStepDataCollectionScreen to get data
  Future<Map<String, dynamic>?> prepareAndValidateCurrentStep() async {
    // TODO: Add any validation if necessary
    final data = _buildDietaryData();
    widget.onDataCollected(data);
    return data;
  }

  // --- UI Building Methods (Copied and adapted from DietaryHabitsScreen) ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Text(
        title,
        style: GoogleFonts.montaga(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF2D2041),
        ),
      ),
    );
  }

  Widget _buildFoodTypeCheckboxList(String meal) {
    Set<String> selectedSet;
    void Function(String, bool) onChangedHandler;

    switch (meal) {
      case 'Take Breakfast':
        selectedSet = _selectedBreakfastFoodTypes;
        onChangedHandler = (val, checked) => setState(() {
          if (checked) _selectedBreakfastFoodTypes.add(val); else _selectedBreakfastFoodTypes.remove(val);
        });
        break;
      case 'Do Lunch':
        selectedSet = _selectedLunchFoodTypes;
        onChangedHandler = (val, checked) => setState(() {
          if (checked) _selectedLunchFoodTypes.add(val); else _selectedLunchFoodTypes.remove(val);
        });
        break;
      default: // Dinner
        selectedSet = _selectedDinnerFoodTypes;
        onChangedHandler = (val, checked) => setState(() {
          if (checked) _selectedDinnerFoodTypes.add(val); else _selectedDinnerFoodTypes.remove(val);
        });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _foodTypes.map((type) {
        final bool isChecked = selectedSet.contains(type);
        return GestureDetector(
          onTap: () => onChangedHandler(type, !isChecked),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
            child: Row(
              children: [
                Icon(
                  isChecked ? Icons.check_circle : Icons.circle_outlined,
                  size: 20,
                  color: isChecked ? const Color(0xFF2D2041) : Colors.grey[600],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    type,
                    style: GoogleFonts.montaga(
                      fontSize: 16,
                      color: const Color(0xFF2D2041),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    // Create DateTime from TimeOfDay
    final dtFromTimeOfDay = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    print('--- Debug _formatTime (DietaryHabits) ---');
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
    print('--- End Debug _formatTime (DietaryHabits) ---');

    // Return the version we expect to work
    return formattedFromDt;
  }

  Future<void> _selectMealTime(BuildContext context, String mealType) async {
    TimeOfDay initialTime;
    switch (mealType) {
      case 'breakfast': initialTime = _breakfastTime; break;
      case 'lunch': initialTime = _lunchTime; break;
      case 'dinner': initialTime = _dinnerTime; break;
      default: initialTime = TimeOfDay.now();
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2D2041), // header background color
              onPrimary: Colors.white, // header text color
              onSurface: Color(0xFF2D2041), // body text color
            ),
            timePickerTheme: TimePickerThemeData(
              dialHandColor: const Color(0xFF2D2041),
              hourMinuteTextColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : const Color(0xFF2D2041)),
              hourMinuteColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF2D2041) : Colors.grey.shade200),
              dayPeriodTextColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? Colors.white : const Color(0xFF2D2041)),
              dayPeriodColor: MaterialStateColor.resolveWith((states) => states.contains(MaterialState.selected) ? const Color(0xFF2D2041) : Colors.grey.shade200),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D2041)),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        switch (mealType) {
          case 'breakfast': _breakfastTime = picked; break;
          case 'lunch': _lunchTime = picked; break;
          case 'dinner': _dinnerTime = picked; break;
        }
      });
    }
  }

  Widget _buildMealTimeField(String mealType, TimeOfDay mealTime) {
    String mealLabel;
    switch (mealType) {
      case 'breakfast': mealLabel = 'Breakfast Time'; break;
      case 'lunch': mealLabel = 'Lunch Time'; break;
      case 'dinner': mealLabel = 'Dinner Time'; break;
      default: mealLabel = 'Meal Time';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mealLabel, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _selectMealTime(context, mealType),
          child: Container(
            width: double.infinity, // Make it wider
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF31244C), width: 1.5),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                (){ String formattedTime = _formatTime(mealTime); print('DietaryHabits - Formatted time for $mealLabel: $formattedTime'); return Text(formattedTime, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87)); }(),
                Icon(Icons.access_time, color: Colors.grey.shade700),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPortionDropdown(BuildContext context, GlobalKey itemKey, String mealType) {
    final RenderBox renderBox = itemKey.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final List<String> portionSizes = List.generate(10, (i) => "${(i + 1) * 100}g");

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy + size.height, position.dx + size.width, position.dy + size.height * 2), // Adjust position as needed
      items: portionSizes.map((String value) {
        return PopupMenuItem<String>(
          value: value,
          child: Text(value, style: GoogleFonts.montaga()),
        );
      }).toList(),
      elevation: 8.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ).then<void>((String? newValue) {
      if (newValue != null) {
        setState(() {
          switch (mealType) {
            case 'breakfast': _breakfastPortionSize = newValue; break;
            case 'lunch': _lunchPortionSize = newValue; break;
            case 'dinner': _dinnerPortionSize = newValue; break;
          }
        });
      }
    });
  }

  Widget _buildPortionSizeField(String mealType, String currentPortionSize, GlobalKey itemKey) {
    String mealLabel;
    switch (mealType) {
      case 'breakfast': mealLabel = 'Breakfast Portion'; break;
      case 'lunch': mealLabel = 'Lunch Portion'; break;
      case 'dinner': mealLabel = 'Dinner Portion'; break;
      default: mealLabel = 'Portion Size';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mealLabel, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          key: itemKey, // Assign key here
          onTap: () => _showPortionDropdown(context, itemKey, mealType),
          child: Container(
            width: double.infinity, // Make it wider
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF31244C), width: 1.5),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentPortionSize,
                  style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.grey.shade700),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, String mealType, bool isRegular, TimeOfDay mealTime, String portionSize, Set<String> selectedFoodTypes, GlobalKey portionKey) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.montaga(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF2D2041))),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Regularity: ', style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87)),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() {
                    if (mealType == 'breakfast') _isBreakfastRegular = true;
                    else if (mealType == 'lunch') _isLunchRegular = true;
                    else _isDinnerRegular = true;
                  }),
                  child: Row(children: [SquareCheckbox(selected: isRegular, fillColor: const Color(0xFF2D2041), onTap: () => setState(() { if (mealType == 'breakfast') _isBreakfastRegular = true; else if (mealType == 'lunch') _isLunchRegular = true; else _isDinnerRegular = true; })), Text('Regular', style: GoogleFonts.montaga(fontSize: 16))]),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() {
                    if (mealType == 'breakfast') _isBreakfastRegular = false;
                    else if (mealType == 'lunch') _isLunchRegular = false;
                    else _isDinnerRegular = false;
                  }),
                  child: Row(children: [SquareCheckbox(selected: !isRegular, fillColor: const Color(0xFF2D2041), onTap: () => setState(() { if (mealType == 'breakfast') _isBreakfastRegular = false; else if (mealType == 'lunch') _isLunchRegular = false; else _isDinnerRegular = false; })), Text('Not Regular', style: GoogleFonts.montaga(fontSize: 16))]),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildMealTimeField(mealType, mealTime),
            const SizedBox(height: 16),
            _buildPortionSizeField(mealType, portionSize, portionKey),
            const SizedBox(height: 16),
            Text('Food Types:', style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            _buildFoodTypeCheckboxList(title), // title is 'Take Breakfast', 'Do Lunch', 'Have Dinner'
          ],
        ),
      ),
    );
  }

  Widget _buildStepperField(String label, int value, ValueChanged<int> onChanged, int minValue, int maxValue) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87))),
          Row(
            children: [
              IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: value > minValue ? () => onChanged(value - 1) : null, color: const Color(0xFF2D2041)),
              Text('$value', style: GoogleFonts.montaga(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.add_circle_outline), onPressed: value < maxValue ? () => onChanged(value + 1) : null, color: const Color(0xFF2D2041)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: GoogleFonts.montaga(fontSize: 16, color: Colors.black87))),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2D2041),
            inactiveThumbColor: Colors.grey.shade400,
            inactiveTrackColor: Colors.grey.shade200,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize keys here if they depend on context or need to be fresh
    // For now, assuming they are fine as member variables initialized once.
    // If issues arise with dropdown positioning, consider re-initializing keys in build or initState.
    if (_portionKeys.length != 3) { // Ensure we have 3 keys for 3 meals
        _portionKeys = List.generate(3, (_) => GlobalKey());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSectionTitle('Daily Meal Count & Water Intake'),
          _buildStepperField('Meals Per Day', _mealsPerDay, (val) => setState(() => _mealsPerDay = val), 1, 6),
          _buildStepperField('Water Intake (glasses)', _waterIntake, (val) => setState(() => _waterIntake = val), 1, 20),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300, thickness: 1),
          
          _buildSectionTitle('Meal Details'),
          _buildMealSection('Take Breakfast', 'breakfast', _isBreakfastRegular, _breakfastTime, _breakfastPortionSize, _selectedBreakfastFoodTypes, _portionKeys[0]),
          _buildMealSection('Do Lunch', 'lunch', _isLunchRegular, _lunchTime, _lunchPortionSize, _selectedLunchFoodTypes, _portionKeys[1]),
          _buildMealSection('Have Dinner', 'dinner', _isDinnerRegular, _dinnerTime, _dinnerPortionSize, _selectedDinnerFoodTypes, _portionKeys[2]),
          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300, thickness: 1),

          _buildSectionTitle('Other Dietary Habits'),
          _buildSwitchField('Caffeine After Noon?', _caffeineAfterNoon, (val) => setState(() => _caffeineAfterNoon = val)),
          _buildSwitchField('Alcohol Before Bed?', _alcoholBeforeBed, (val) => setState(() => _alcoholBeforeBed = val)),
          _buildSwitchField('Heavy Meal Before Bed?', _heavyMealBeforeBed, (val) => setState(() => _heavyMealBeforeBed = val)),
          _buildSwitchField('Consistent Meal Timing?', _mealTimingConsistent, (val) => setState(() => _mealTimingConsistent = val)),
          _buildSwitchField('Balanced Meals Usually?', _balancedMeals, (val) => setState(() => _balancedMeals = val)),
          _buildSwitchField('Late Night Snacking?', _lateNightSnacking, (val) => setState(() => _lateNightSnacking = val)),
        ],
      ),
    );
  }
}

