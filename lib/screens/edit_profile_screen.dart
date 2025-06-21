import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../utils/app_theme.dart';
import '../services/service_locator.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  String? _selectedGender;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _ageController = TextEditingController(text: widget.user.dateOfBirth != null ? _calculateAge(widget.user.dateOfBirth).toString() : '');
    if (widget.user.gender != null && widget.user.gender.isNotEmpty) {
      _selectedGender = widget.user.gender[0].toUpperCase() + widget.user.gender.substring(1).toLowerCase();
    } else {
      _selectedGender = null;
    }
  }

  int _calculateAge(DateTime birthDate) {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }

  DateTime _getDateOfBirthFromAge(int age) {
    final now = DateTime.now();
    return DateTime(now.year - age, now.month, now.day);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    final name = _nameController.text.trim();
    final ageStr = _ageController.text.trim();
    final gender = _selectedGender?.toLowerCase();
    if (name.isEmpty || ageStr.isEmpty || gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields'), backgroundColor: Colors.red),
      );
      return;
    }
    final age = int.tryParse(ageStr);
    if (age == null || age < 1 || age > 120) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid age'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final dateOfBirth = _getDateOfBirthFromAge(age);
      await serviceLocator.auth.updateUserProfile({
        'name': name,
        'gender': gender,
        'dateOfBirth': dateOfBirth.toIso8601String(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width * 0.07;
    final fieldWidth = size.width > 400 ? 340.0 : size.width * 0.86;
    final buttonWidth = size.width > 400 ? 260.0 : size.width * 0.7;
    final buttonHeight = 56.0;
    final deepPurple = const Color(0xFF1B1530); // Deeper, more vibrant purple

    return Scaffold(
      backgroundColor: const Color(0xFF211A36), // Even deeper background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Custom Back Button
                    Padding(
                      padding: EdgeInsets.only(top: size.height * 0.025, bottom: size.height * 0.01),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          SizedBox(width: size.width * 0.04),
                          Text('Edit Profile', style: AppTheme.titleMedium),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                    // Name label left aligned with input box
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Name', style: AppTheme.labelLarge),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: _nameController,
                          style: AppTheme.bodyLarge,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Enter your name',
                            hintStyle: AppTheme.bodyMedium.copyWith(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),
                    // Email label left aligned with input box
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Email', style: AppTheme.labelLarge),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: TextEditingController(text: widget.user.email),
                          style: AppTheme.bodyLarge,
                          readOnly: true,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),
                    // Age label left aligned with input box
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Age', style: AppTheme.labelLarge),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.012),
                    Center(
                      child: SizedBox(
                        width: fieldWidth,
                        child: TextField(
                          controller: _ageController,
                          style: AppTheme.bodyLarge,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintText: 'Enter your age',
                            hintStyle: AppTheme.bodyMedium.copyWith(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.025),
                    Center(child: Text('Gender', style: AppTheme.labelLarge)),
                    SizedBox(height: size.height * 0.012),
                    Center(
                      child: Container(
                        height: 55,
                        width: 170,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            dropdownColor: deepPurple,
                            icon: const SizedBox.shrink(),
                            hint: Center(
                              child: Text(
                                'Gender',
                                style: AppTheme.bodyLarge.copyWith(color: Colors.white.withOpacity(0.5)),
                              ),
                            ),
                            items: ['Male', 'Female', 'Other']
                                .map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Center(
                                  child: Text(
                                    value,
                                    style: AppTheme.bodyLarge.copyWith(color: Colors.white),
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
                    ),
                    const Spacer(),
                    // Update Button styled responsively
                    Center(
                      child: SizedBox(
                        width: buttonWidth,
                        height: buttonHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          onPressed: _isLoading ? null : _updateProfile,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : Text(
                                  'Update',
                                  style: AppTheme.bodyLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: size.height * 0.04),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 