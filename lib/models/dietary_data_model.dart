class DietaryData {
  final bool? isBreakfastRegular;
  final bool? isLunchRegular;
  final bool? isDinnerRegular;
  final List<String>? selectedBreakfastFoodTypes;
  final List<String>? selectedLunchFoodTypes;
  final List<String>? selectedDinnerFoodTypes;
  final double? waterIntake;
  final int? alcoholConsumption;
  final DateTime? eveningMealTime;
  final bool? hasCaffeineBefore;
  final DateTime? caffeineTime;
  final String? notes;

  DietaryData({
    this.isBreakfastRegular,
    this.isLunchRegular,
    this.isDinnerRegular,
    this.selectedBreakfastFoodTypes,
    this.selectedLunchFoodTypes,
    this.selectedDinnerFoodTypes,
    this.waterIntake,
    this.alcoholConsumption,
    this.eveningMealTime,
    this.hasCaffeineBefore,
    this.caffeineTime,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'isBreakfastRegular': isBreakfastRegular,
      'isLunchRegular': isLunchRegular,
      'isDinnerRegular': isDinnerRegular,
      'selectedBreakfastFoodTypes': selectedBreakfastFoodTypes,
      'selectedLunchFoodTypes': selectedLunchFoodTypes,
      'selectedDinnerFoodTypes': selectedDinnerFoodTypes,
      'waterIntake': waterIntake,
      'alcoholConsumption': alcoholConsumption,
      'eveningMealTime': eveningMealTime?.toIso8601String(),
      'hasCaffeineBefore': hasCaffeineBefore,
      'caffeineTime': caffeineTime?.toIso8601String(),
      'notes': notes,
    };
  }

  factory DietaryData.fromJson(Map<String, dynamic> json) {
    return DietaryData(
      isBreakfastRegular: json['isBreakfastRegular'],
      isLunchRegular: json['isLunchRegular'],
      isDinnerRegular: json['isDinnerRegular'],
      selectedBreakfastFoodTypes: List<String>.from(json['selectedBreakfastFoodTypes'] ?? []),
      selectedLunchFoodTypes: List<String>.from(json['selectedLunchFoodTypes'] ?? []),
      selectedDinnerFoodTypes: List<String>.from(json['selectedDinnerFoodTypes'] ?? []),
      waterIntake: json['waterIntake']?.toDouble(),
      alcoholConsumption: json['alcoholConsumption'],
      eveningMealTime: json['eveningMealTime'] != null 
          ? DateTime.parse(json['eveningMealTime']) 
          : null,
      hasCaffeineBefore: json['hasCaffeineBefore'],
      caffeineTime: json['caffeineTime'] != null 
          ? DateTime.parse(json['caffeineTime']) 
          : null,
      notes: json['notes'],
    );
  }

  static List<String> get foodTypeOptions => [
    'Carbohydrates',
    'Proteins',
    'Fruits',
    'Vegetables',
    'Dairy',
    'Fats',
    'Sweets'
  ];
}
