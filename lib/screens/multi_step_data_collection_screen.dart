import 'package:flutter/material.dart';
import '../widgets/sleep_patterns_form_section.dart';
import '../widgets/dietary_habits_form_section.dart';
import '../widgets/environmental_factors_form_section.dart';

enum DataCollectionStep {
  sleep,
  dietary,
  environmental,
  // Add more steps here if needed
}

class MultiStepDataCollectionScreen extends StatefulWidget {
  const MultiStepDataCollectionScreen({Key? key}) : super(key: key);

  static const String routeName = '/multi_step_data_collection'; // Optional: if direct navigation is needed

  @override
  _MultiStepDataCollectionScreenState createState() => _MultiStepDataCollectionScreenState();
}

class _MultiStepDataCollectionScreenState extends State<MultiStepDataCollectionScreen> {
  DataCollectionStep _currentStep = DataCollectionStep.sleep;
  final GlobalKey<SleepPatternsFormSectionState> _sleepPatternsFormKey = GlobalKey();
  final GlobalKey<DietaryHabitsFormSectionState> _dietaryHabitsFormKey = GlobalKey();
  final GlobalKey<EnvironmentalFactorsFormSectionState> _environmentalFactorsFormKey = GlobalKey();

  Map<String, dynamic>? _sleepData;
  Map<String, dynamic>? _dietaryData;
  Map<String, dynamic>? _environmentalData;

  // History for back navigation
  final List<DataCollectionStep> _stepHistory = [];

  Future<void> _nextStep() async {
    if (_currentStep == DataCollectionStep.sleep) {
      final data = await _sleepPatternsFormKey.currentState?.prepareAndValidateCurrentStep();
      if (data != null) {
        // _sleepData is already updated by the onDataCollected callback in SleepPatternsFormSection
        setState(() {
          _stepHistory.add(_currentStep);
          _currentStep = DataCollectionStep.dietary;
        });
      } else {
        _showErrorSnackBar('Please complete all sleep pattern fields correctly.');
      }
    } else if (_currentStep == DataCollectionStep.dietary) {
      final data = await _dietaryHabitsFormKey.currentState?.prepareAndValidateCurrentStep();
      if (data != null) {
        // _dietaryData is already updated by the onDataCollected callback in DietaryHabitsFormSection
        setState(() {
          _stepHistory.add(_currentStep);
          _currentStep = DataCollectionStep.environmental;
        });
      } else {
        _showErrorSnackBar('Please complete all dietary habit fields correctly.');
      }
    } else if (_currentStep == DataCollectionStep.environmental) {
      final data = await _environmentalFactorsFormKey.currentState?.prepareAndValidateCurrentStep();
      if (data != null) {
        // _environmentalData is already updated by the onDataCollected callback
        _submitAllData();
      } else {
        _showErrorSnackBar('Please complete all environmental factor fields correctly.');
      }
    }
  }

  void _previousStep() {
    if (_stepHistory.isNotEmpty) {
      setState(() {
        _currentStep = _stepHistory.removeLast();
      });
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submitAllData() {
    // Combine all data and process it
    final allData = {
      'sleepData': _sleepData,
      'dietaryData': _dietaryData, // This will be null until DietaryHabitsFormSection is integrated
      'environmentalData': _environmentalData, // This will be null until EnvironmentalFactorsFormSection is integrated
    };

    print('Submitting all data: $allData');

    // Check if all necessary data parts are collected (optional, depends on how robust you want this stage to be)
    // For now, we assume that if _submitAllData is called, the user has gone through the steps.

    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('All data collected! Processing...'), backgroundColor: Colors.green),
        );
        // Pop the screen and return the collected data
        Navigator.pop(context, allData);
    }
  }

  Widget _buildCurrentStepWidget() {
    switch (_currentStep) {
      case DataCollectionStep.sleep:
        return SleepPatternsFormSection(
          key: _sleepPatternsFormKey,
          onDataCollected: (data) {
            setState(() {
              _sleepData = data;
            });
          },
        );
      case DataCollectionStep.dietary:
        return DietaryHabitsFormSection(
          key: _dietaryHabitsFormKey,
          onDataCollected: (data) {
            setState(() {
              _dietaryData = data;
            });
          },
        );
      case DataCollectionStep.environmental:
        return EnvironmentalFactorsFormSection(key: _environmentalFactorsFormKey, onDataCollected: (data) => _environmentalData = data);
      default:
        return Center(child: Text('Unknown Step'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_stepHistory.isNotEmpty) {
          _previousStep();
          return false; // Prevent default back navigation
        }
        return true; // Allow default back navigation if at the first step
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Data Collection - ${_currentStep.toString().split('.').last}'),
          leading: _stepHistory.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: _previousStep,
                )
              : null, // No custom back button on the first step if system back is handled by WillPopScope
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: _buildCurrentStepWidget(),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_stepHistory.isNotEmpty) // Show 'Previous' only if not on the first step
                    ElevatedButton(
                      onPressed: _previousStep,
                      child: Text('Previous'),
                    ),
                  ElevatedButton(
                    onPressed: _nextStep,
                    child: Text(_currentStep == DataCollectionStep.environmental ? 'Submit' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
