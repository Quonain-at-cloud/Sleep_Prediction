class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    // Simple email regex pattern
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    
    return null;
  }
  
  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    
    // Check for at least one number
    if (!value.contains(RegExp(r'\d'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for at least one special character
    if (!value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }
  
  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters long';
    }
    
    return null;
  }
  
  // Date of birth validation
  static String? validateDateOfBirth(DateTime? value) {
    if (value == null) {
      return 'Date of birth is required';
    }
    
    final now = DateTime.now();
    final age = now.year - value.year - 
        (now.month < value.month || 
        (now.month == value.month && now.day < value.day) ? 1 : 0);
    
    if (age < 13) {
      return 'You must be at least 13 years old';
    }
    
    if (age > 120) {
      return 'Enter a valid date of birth';
    }
    
    return null;
  }
  
  // Height validation (in cm)
  static String? validateHeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Height is required';
    }
    
    final height = double.tryParse(value);
    if (height == null) {
      return 'Enter a valid number';
    }
    
    if (height < 50 || height > 250) {
      return 'Enter a valid height (50-250 cm)';
    }
    
    return null;
  }
  
  // Weight validation (in kg)
  static String? validateWeight(String? value) {
    if (value == null || value.isEmpty) {
      return 'Weight is required';
    }
    
    final weight = double.tryParse(value);
    if (weight == null) {
      return 'Enter a valid number';
    }
    
    if (weight < 20 || weight > 500) {
      return 'Enter a valid weight (20-500 kg)';
    }
    
    return null;
  }
  
  // Sleep duration validation (in minutes)
  static String? validateSleepDuration(int? value) {
    if (value == null) {
      return 'Sleep duration is required';
    }
    
    if (value < 60) { // Less than 1 hour
      return 'Sleep duration must be at least 1 hour';
    }
    
    if (value > 24 * 60) { // More than 24 hours
      return 'Sleep duration must be less than 24 hours';
    }
    
    return null;
  }
  
  // Sleep quality validation (0-10)
  static String? validateSleepQuality(double? value) {
    if (value == null) {
      return 'Sleep quality is required';
    }
    
    if (value < 0 || value > 10) {
      return 'Sleep quality must be between 0 and 10';
    }
    
    return null;
  }
} 