import 'package:flutter/material.dart';
import '../widgets/custom_bottom_navigation.dart';
import '../utils/app_theme.dart';
import '../widgets/custom_profile_drawer.dart';
import 'package:flutter/services.dart';

class SleepQualityFeedbackScreen extends StatefulWidget {
  const SleepQualityFeedbackScreen({super.key});

  @override
  State<SleepQualityFeedbackScreen> createState() => _SleepQualityFeedbackScreenState();
}

class _SleepQualityFeedbackScreenState extends State<SleepQualityFeedbackScreen> {
  int _selectedRating = 0;
  final TextEditingController _suggestionController = TextEditingController();

  Widget _buildRatingButton(int rating) {
    final isSelected = _selectedRating >= rating;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedRating = rating;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          isSelected ? Icons.thumb_up : Icons.thumb_up_outlined,
          color: isSelected ? const Color(0xFF2D2041) : const Color(0xFF000000),
          size: 28,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));

    return Scaffold(
      drawer: const CustomProfileDrawer(),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: const BoxDecoration(
                color: Color(0xFF2D2041),
              ),
              child: Text(
                'Sleep Quality Feedback',
                textAlign: TextAlign.center,
                style: AppTheme.modifyStyle(
                  AppTheme.titleMedium,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 120),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Please give your feedback',
                      textAlign: TextAlign.center,
                      style: AppTheme.modifyStyle(
                        AppTheme.titleSmall,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(
                        5,
                        (index) {
                          int buttonValue = index + 1;
                          return _buildRatingButton(buttonValue);
                        },
                      ),
                    ),
                    const SizedBox(height: 50),
                    Text(
                      'Give any suggestion: (optional)',
                      style: AppTheme.modifyStyle(
                        AppTheme.titleExtraSmall,
                        color: const Color(0xFF000000),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      width: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF31244C)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: TextField(
                        controller: _suggestionController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          hintText: 'Write your suggestion here...',
                          hintStyle: AppTheme.modifyStyle(
                            AppTheme.bodyMedium,
                            color: Colors.grey.shade400,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    Center(
                    child: SizedBox(
                      width: 250,
                      child: ElevatedButton(
                        onPressed: () {
                          // Handle feedback submission
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C5470),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Submit',
                          style: AppTheme.modifyStyle(
                            AppTheme.buttonLarge,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigation(
        currentIndex: 1,
        onTap: (index) {
          // Handle tab changes if needed
        },
      ),
    );
  }

  @override
  void dispose() {
    _suggestionController.dispose();
    super.dispose();
  }
} 