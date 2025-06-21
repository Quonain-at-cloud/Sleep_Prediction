// Test script for ML prediction integration
const { mapSleepDataToMLInput } = require('./src/utils/ml-service');

// Sample test data that mimics what would come from the Flutter app
const sampleSleepData = {
  sleepDuration: 6.5,
  sleepLatency: 25,
  stressLevel: 4,
  userProfile: {
    age: 35,
    gender: 'male',
    bmi: 24.5
  },
  activities: {
    exerciseMinutes: 30,
    dailySteps: 8000,
    caffeineIntake: 200,
    screenTimeMinutes: 120
  }
};

const sampleEnvironmentalData = {
  temperature: 24,
  lightIntensity: 250,
  soundExposure: 'Moderate'
};

const sampleDietaryData = {
  isBreakfastRegular: true,
  isLunchRegular: true,
  isDinnerRegular: false,
  selectedBreakfastFoodTypes: ['Carbohydrates', 'Proteins'],
  selectedLunchFoodTypes: ['Proteins', 'Vegetables'],
  selectedDinnerFoodTypes: ['Carbohydrates', 'Fats']
};

// Test data mapping function
function testDataMapping() {
  console.log('\nTesting data mapping function...');
  console.log('==============================');
  
  try {
    const mlInputData = mapSleepDataToMLInput(
      sampleSleepData,
      sampleEnvironmentalData,
      sampleDietaryData
    );
    
    console.log('\nInput Flutter data:');
    console.log('- Sleep Data:', JSON.stringify(sampleSleepData, null, 2));
    console.log('- Environmental Data:', JSON.stringify(sampleEnvironmentalData, null, 2));
    console.log('- Dietary Data:', JSON.stringify(sampleDietaryData, null, 2));
    
    console.log('\nOutput ML input data:');
    console.log(JSON.stringify(mlInputData, null, 2));
    
    console.log('\n✅ Data mapping test completed successfully.');
    
    // Verify expected fields are present
    const expectedFields = [
      'Age', 'Gender', 'BMI Category', 'Sleep Duration', 
      'Physical Activity Level', 'Heart Rate', 'Daily Steps', 'Stress Level'
    ];
    
    const missingFields = expectedFields.filter(field => !(field in mlInputData));
    
    if (missingFields.length > 0) {
      console.log('\n⚠️ Warning: Some expected fields are missing in the mapped data:');
      console.log(missingFields.join(', '));
    } else {
      console.log('\n✅ All expected fields are present in the mapped data.');
    }
    
    // Verify the data types are correct
    console.log('\nVerifying data types:');
    expectedFields.forEach(field => {
      if (field in mlInputData) {
        const value = mlInputData[field];
        const type = typeof value;
        let isValid = true;
        
        if (['Age', 'Daily Steps'].includes(field) && !Number.isInteger(value)) {
          isValid = false;
        } else if (['Sleep Duration', 'Physical Activity Level', 'Heart Rate', 'Stress Level'].includes(field) && typeof value !== 'number') {
          isValid = false;
        } else if (['Gender', 'BMI Category'].includes(field) && typeof value !== 'string') {
          isValid = false;
        }
        
        console.log(`- ${field}: ${value} (${type}) ${isValid ? '✅' : '❌'}`);
      }
    });
    
    return true;
  } catch (error) {
    console.error('\n❌ Data mapping test failed:', error.message);
    return false;
  }
}

// Main test function
function runTests() {
  console.log('🔍 Starting Sleep Prediction Integration Tests');
  console.log('============================================');
  
  // Test data mapping (this doesn't require ML service to be running)
  const mappingResult = testDataMapping();
  
  console.log('\n📊 Test Results Summary:');
  console.log('• Data Mapping: ' + (mappingResult ? 'Successful ✅' : 'Failed ❌'));
  
  console.log('\n============================================');
  console.log('🏁 Integration Tests Completed');
  
  // Add simulation of what prediction response would look like
  console.log('\n📋 Expected ML Service Response Format:');
  console.log(JSON.stringify({
    sleepQualityScore: 72.5,
    sleepDisorderProbability: 0.28,
    normalizedScore: 0.725,
    predictedInterruptionCount: 2,
    predictedInterruptionWindows: [
      { startTime: '01:30', endTime: '02:15', probability: 0.65 },
      { startTime: '04:45', endTime: '05:30', probability: 0.72 }
    ],
    contributingFactors: {
      stress_level: 0.8,
      sleep_duration: 0.7,
      physical_activity: 0.4,
      heart_rate: 0.3,
      daily_steps: 0.2
    },
    recommendations: [
      'Practice stress reduction techniques like meditation, deep breathing, or progressive muscle relaxation before bedtime.',
      'You may not be getting enough sleep. Aim for 7-9 hours of sleep per night for optimal health.',
      'Aim for 30-60 minutes of moderate exercise daily, but try to complete your workout at least 2-3 hours before bedtime.'
    ]
  }, null, 2));
}

// Run the tests
runTests();
