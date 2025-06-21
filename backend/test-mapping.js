// Simplified test script for data mapping function
const { mapSleepDataToMLInput } = require('./src/utils/ml-service');

// Sample test data
const sampleData = {
  sleepData: {
    sleepDuration: 6.5,
    stressLevel: 4,
    userProfile: {
      age: 35,
      gender: 'male',
      bmi: 24.5
    },
    activities: {
      exerciseMinutes: 30,
      dailySteps: 8000
    }
  },
  environmentalData: {
    temperature: 24,
    lightIntensity: 250,
    soundExposure: 'Moderate'
  },
  dietaryData: {
    isBreakfastRegular: true,
    isLunchRegular: true,
    isDinnerRegular: false,
    selectedBreakfastFoodTypes: ['Carbohydrates', 'Proteins']
  }
};

// Test the mapping function
console.log('Testing data mapping function...');
const mlInput = mapSleepDataToMLInput(
  sampleData.sleepData,
  sampleData.environmentalData,
  sampleData.dietaryData
);

console.log('\nMapped ML Input:');
console.log(JSON.stringify(mlInput, null, 2));

console.log('\nVerifying key fields:');
const keyFields = ['Age', 'Gender', 'BMI Category', 'Sleep Duration', 'Stress Level', 'Physical Activity Level'];
keyFields.forEach(field => {
  console.log(`- ${field}: ${mlInput[field] !== undefined ? 'Present' : 'Missing'}`);
});

console.log('\nTest completed.');
