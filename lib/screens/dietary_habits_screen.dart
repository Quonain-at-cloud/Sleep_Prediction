import 'package:flutter/material.dart';
import 'environmental_factors_screen.dart';
import '../utils/app_constants.dart';
import '../widgets/custom_bottom_navigation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:intl/intl.dart'; // Added for date formatting

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

class DietaryHabitsScreen extends StatefulWidget {
  final bool onSaveOnly;
  final Map<String, dynamic> sleepData;
  final Map<String, dynamic>? profileInfo; // Added profileInfo
  
  const DietaryHabitsScreen({
    Key? key, 
    this.onSaveOnly = false,
    required this.sleepData,
    this.profileInfo, // Added profileInfo
  }) : super(key: key);

  @override
  State<DietaryHabitsScreen> createState() => _DietaryHabitsScreenState();
}

class _DietaryHabitsScreenState extends State<DietaryHabitsScreen> {
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

  // Add selected food type for each meal
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

  final GlobalKey mealsKey = GlobalKey();
  List<GlobalKey> _portionKeys = List.generate(8, (_) => GlobalKey());
  
  // Helper method to build dietary data object
  Map<String, dynamic> _buildDietaryData() {
    // Always include all required fields, using current UI values
    String _formatTimeForData(TimeOfDay time) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    int _parsePortionSize(String portion) {
      final match = RegExp(r'(\d+)').firstMatch(portion);
      return match != null ? int.parse(match.group(1)!) : 400;
    }
    final meals = [
      {
        'Type': 'Breakfast',
        'Is Regular': _isBreakfastRegular,
        'Time': _formatTimeForData(_breakfastTime),
        'Portion Size': _parsePortionSize(_breakfastPortionSize),
        'Food Types': _selectedBreakfastFoodTypes.toList(),
      },
      {
        'Type': 'Lunch',
        'Is Regular': _isLunchRegular,
        'Time': _formatTimeForData(_lunchTime),
        'Portion Size': _parsePortionSize(_lunchPortionSize),
        'Food Types': _selectedLunchFoodTypes.toList(),
      },
      {
        'Type': 'Dinner',
        'Is Regular': _isDinnerRegular,
        'Time': _formatTimeForData(_dinnerTime),
        'Portion Size': _parsePortionSize(_dinnerPortionSize),
        'Food Types': _selectedDinnerFoodTypes.toList(),
      },
    ];
    // Validate required fields
    for (final meal in meals) {
      if (meal['Time'] == null || meal['Portion Size'] == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter all meal times and portion sizes.')),
        );
        return {};
      }
    }
    return {
      'Meals Per Day': _mealsPerDay,
      'Meals': meals,
      'Caffeine After Noon': _caffeineAfterNoon,
      'Alcohol Before Bed': _alcoholBeforeBed,
      'Heavy Meal Before Bed': _heavyMealBeforeBed,
      'Water Intake': _waterIntake,
      'Meal Timing Consistent': _mealTimingConsistent,
      'Balanced Meals': _balancedMeals,
      'Late Night Snacking': _lateNightSnacking,
    };
  }

  Widget _buildFoodTypeCheckboxList(String meal) {
    Set<String> selected;
    void Function(String, bool) onChanged;
    if (meal == 'Take Breakfast') {
      selected = _selectedBreakfastFoodTypes;
      onChanged = (val, checked) => setState(() {
        if (checked) {
          _selectedBreakfastFoodTypes.add(val);
        } else {
          _selectedBreakfastFoodTypes.remove(val);
        }
      });
    } else if (meal == 'Do Lunch') {
      selected = _selectedLunchFoodTypes;
      onChanged = (val, checked) => setState(() {
        if (checked) {
          _selectedLunchFoodTypes.add(val);
        } else {
          _selectedLunchFoodTypes.remove(val);
        }
      });
    } else {
      selected = _selectedDinnerFoodTypes;
      onChanged = (val, checked) => setState(() {
        if (checked) {
          _selectedDinnerFoodTypes.add(val);
        } else {
          _selectedDinnerFoodTypes.remove(val);
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _foodTypes.map((type) {
        final bool isChecked = selected.contains(type);
        return GestureDetector(
          onTap: () => onChanged(type, !isChecked),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Icon(
                  Icons.circle,
                  size: 16,
                  color: isChecked ? Color(0xFF2D2041) : Colors.grey[350],
                ),
                const SizedBox(width: 8),
                Text(
                  type,
                  style: GoogleFonts.montaga(
                    fontSize: 16,
                    color: Color(0xFF2D2041),
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
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    // Using 'en_US' locale to ensure AM/PM format regardless of device locale
    return DateFormat('h:mm a', 'en_US').format(dt);
  }

  Widget _buildBulletPoint(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.circle,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.montaga(
              fontSize: 16,
              color: Color(0xFF2D2041),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectMealTime(BuildContext context, String meal) async {
    TimeOfDay initialTime;
    if (meal == 'Take Breakfast') {
      initialTime = _breakfastTime;
    } else if (meal == 'Do Lunch') {
      initialTime = _lunchTime;
    } else {
      initialTime = _dinnerTime;
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
        if (meal == 'Take Breakfast') {
          _breakfastTime = picked;
        } else if (meal == 'Do Lunch') {
          _lunchTime = picked;
        } else {
          _dinnerTime = picked;
        }
      });
    }
  }

  Widget _buildMealTimeField(String meal, TimeOfDay mealTime) {
    return InkWell(
      onTap: () => _selectMealTime(context, meal),
      child: Container(
        width: 135,
        height: 35,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF31244C), width: 2),
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatTime(mealTime), // _formatTime now includes AM/PM
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
    );
  }

  Widget _buildMealSection(int index, String title, bool isRegular, TimeOfDay mealTime, String portionSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 120,
              child: Text(
                title,
                style: GoogleFonts.montaga(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (title == 'Take Breakfast') {
                        _isBreakfastRegular = true;
                      } else if (title == 'Do Lunch') {
                        _isLunchRegular = true;
                      } else {
                        _isDinnerRegular = true;
                      }
                    });
                  },
                  child: Row(
                    children: [
                      SquareCheckbox(
                        selected: isRegular,
                        fillColor: const Color(0xFF2D2041),
                        onTap: () {
                          setState(() {
                            if (title == 'Take Breakfast') {
                              _isBreakfastRegular = true;
                            } else if (title == 'Do Lunch') {
                              _isLunchRegular = true;
                            } else {
                              _isDinnerRegular = true;
                            }
                          });
                        },
                      ),
                      SizedBox(
                        width: 60,
                        child: Text(
                          'Regular',
                          style: GoogleFonts.montaga(
                            fontSize: 16,
                            color: Color(0xFF2D2041),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      if (title == 'Take Breakfast') {
                        _isBreakfastRegular = false;
                      } else if (title == 'Do Lunch') {
                        _isLunchRegular = false;
                      } else {
                        _isDinnerRegular = false;
                      }
                    });
                  },
                  child: Row(
                    children: [
                      SquareCheckbox(
                        selected: !isRegular,
                        fillColor: const Color(0xFF2D2041),
                        onTap: () {
                          setState(() {
                            if (title == 'Take Breakfast') {
                              _isBreakfastRegular = false;
                            } else if (title == 'Do Lunch') {
                              _isLunchRegular = false;
                            } else {
                              _isDinnerRegular = false;
                            }
                          });
                        },
                      ),
                      SizedBox(
                        width: 80,
                        child: Text(
                          'Not Regular',
                          style: GoogleFonts.montaga(
                            fontSize: 16,
                            color: Color(0xFF2D2041),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'Time',
                style: GoogleFonts.montaga(
                  fontSize: 16,
                  color: Color(0xFF2D2041),
                ),
              ),
            ),
            SizedBox(width: 16),
            _buildMealTimeField(title, mealTime),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'Food Type',
                style: GoogleFonts.montaga(
                  fontSize: 16,
                  color: Color(0xFF2D2041),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(child: _buildFoodTypeCheckboxList(title)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                'Portion size',
                style: GoogleFonts.montaga(
                  fontSize: 16,
                  color: Color(0xFF2D2041),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Container(
                key: _portionKeys[index],
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Color(0xFF2D2041), width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: TextEditingController(text: portionSize),
                        style: GoogleFonts.montaga(
                          fontSize: 16,
                          color: Color(0xFF2D2041),
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (title == 'Take Breakfast') {
                              _breakfastPortionSize = val;
                            } else if (title == 'Do Lunch') {
                              _lunchPortionSize = val;
                            } else {
                              _dinnerPortionSize = val;
                            }
                          });
                        },
                      ),
                    ),
                    GestureDetector(
                      onTap: () async {
                        final List<String> portionOptions = List.generate(20, (i) => '${(i + 1) * 100}g');
                        await showCustomDropdown<String>(
                          context: context,
                          key: _portionKeys[index],
                          items: portionOptions,
                          itemBuilder: (item) => Text(item, style: GoogleFonts.montaga(fontSize: 16)),
                          onSelected: (val) {
                            setState(() {
                              if (title == 'Take Breakfast') {
                                _breakfastPortionSize = val;
                              } else if (title == 'Do Lunch') {
                                _lunchPortionSize = val;
                              } else {
                                _dinnerPortionSize = val;
                              }
                            });
                          },
                          minHeight: 100,
                          maxHeight: 250,
                        );
                      },
                      child: Icon(
                        Icons.expand_more,
                        color: Color(0xFF2D2041),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Add helper for showing a custom dropdown menu below a widget
  Future<T?> showCustomDropdown<T>({
    required BuildContext context,
    required GlobalKey key,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required void Function(T) onSelected,
    double minHeight = 100,
    double maxHeight = 250,
  }) async {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;
    final selected = await showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        offset.dx,
        offset.dy + size.height,
        offset.dx + size.width,
        offset.dy + size.height + maxHeight,
      ),
      constraints: BoxConstraints(
        minHeight: minHeight,
        maxHeight: maxHeight,
        minWidth: size.width,
        maxWidth: size.width,
      ),
      items: items.map((item) {
        return PopupMenuItem<T>(
          value: item,
          child: itemBuilder(item),
        );
      }).toList(),
    );
    if (selected != null) {
      onSelected(selected);
    }
    return selected;
  }

  // Save dietary data and navigate to next screen
  void _saveAndContinue() {
    final dietaryData = _buildDietaryData();
    // Robust: Central allData map for all screens
    Map<String, dynamic> allData = {};
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    if (routeArgs != null && routeArgs is Map) {
      allData = Map<String, dynamic>.from(routeArgs);
    } else {
      // Fallback to data provided via constructor
      allData = {
        'sleepData': widget.sleepData,
        'profileInfo': widget.profileInfo ?? {},
      };
    }
    allData['dietaryData'] = dietaryData;
    if (widget.onSaveOnly) {
      Navigator.of(context).pop(dietaryData);
      return;
    }
    // Defensive: Ensure all keys have minimum default values (not null, not 0)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EnvironmentalFactorsScreen(
          sleepData: allData['sleepData'] as Map<String, dynamic>?,
          dietaryData: dietaryData,
          profileInfo: allData['profileInfo'] as Map<String, dynamic>?,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      endDrawer: const CustomProfileDrawer(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2041),
              ),
              child: const Text(
                'Dietary Habits',
                 textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildMealSection(0, 'Take Breakfast', _isBreakfastRegular, _breakfastTime, _breakfastPortionSize),
                    _buildMealSection(1, 'Do Lunch', _isLunchRegular, _lunchTime, _lunchPortionSize),
                    _buildMealSection(2, 'Have Dinner', _isDinnerRegular, _dinnerTime, _dinnerPortionSize),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          width: 120,
                          child: const Text(
                            'No. of meals per day',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          key: mealsKey,
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Color(0xFF2D2041), width: 2),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 30,
                                child: TextField(
                                  controller: TextEditingController(text: _mealsPerDay.toString()),
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  onChanged: (val) {
                                    final int? newValue = int.tryParse(val);
                                    if (newValue != null && newValue >= 1 && newValue <= 8) {
                                      setState(() {
                                        _mealsPerDay = newValue;
                                      });
                                    }
                                  },
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  final List<int> mealOptions = List.generate(8, (i) => i + 1);
                                  await showCustomDropdown<int>(
                                    context: context,
                                    key: mealsKey,
                                    items: mealOptions,
                                    itemBuilder: (item) => Text(item.toString(), style: GoogleFonts.montaga(fontSize: 16)),
                                    onSelected: (val) {
                                      setState(() {
                                        _mealsPerDay = val;
                                      });
                                    },
                                    minHeight: 100,
                                    maxHeight: 250,
                                  );
                                },
                                child: Icon(
                                  Icons.expand_more,
                                  color: Color(0xFF2D2041),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.only(top: 16, left: 24, right: 24),
                child: ElevatedButton(
                  onPressed: _saveAndContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF65558F),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Next',
                    style: GoogleFonts.montaga(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
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
                      color: Colors.grey[350],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        screenColor: Colors.white,
        currentIndex: 0,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
    );
  }
} 
