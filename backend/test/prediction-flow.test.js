/**
 * Prediction Flow Test Script
 * Tests the end-to-end prediction flow with various input combinations
 */

const axios = require('axios');
const dotenv = require('dotenv');
dotenv.config();

// Configuration
const API_URL = process.env.API_URL || 'http://localhost:3000/api';
const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';
const TEST_USER = {
  name: 'Prediction Test User',
  email: 'prediction_test_' + Date.now() + '@example.com',
  password: 'TestPassword123!'
};

// Test Results Tracking
const results = {
  total: 0,
  passed: 0,
  failed: 0
};

// Store tokens and IDs across tests
const testState = {
  userId: null,
  accessToken: null,
  predictionId: null
};

// HTTP client with authorization header
const apiClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// ML Service client
const mlClient = axios.create({
  baseURL: ML_SERVICE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Update auth header
function setAuthHeader(token) {
  if (token) {
    apiClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  } else {
    delete apiClient.defaults.headers.common['Authorization'];
  }
}

// Test runner
async function runTest(name, testFn) {
  results.total++;
  console.log(`\n🧪 Running test: ${name}`);
  try {
    await testFn();
    console.log(`✅ Test passed: ${name}`);
    results.passed++;
  } catch (error) {
    console.error(`❌ Test failed: ${name}`);
    console.error('  Error:', error.message);
    if (error.response) {
      console.error('  Status:', error.response.status);
      console.error('  Data:', JSON.stringify(error.response.data, null, 2));
    }
    results.failed++;
  }
}

// Setup: Create test user and get token
async function setupTestUser() {
  try {
    // Register user
    const registerResponse = await apiClient.post('/users/register', TEST_USER);
    testState.userId = registerResponse.data.user._id;
    testState.accessToken = registerResponse.data.token;
    setAuthHeader(testState.accessToken);
    console.log('  Test user created with ID:', testState.userId);
  } catch (error) {
    console.error('Failed to create test user:', error.message);
    throw error;
  }
}

// Cleanup: Delete test user
async function cleanupTestUser() {
  try {
    await apiClient.delete('/users/account');
    console.log('  Test user deleted');
  } catch (error) {
    console.error('Failed to delete test user:', error.message);
  }
}

// Test: Check ML Service Health
async function testMLServiceHealth() {
  const response = await mlClient.get('/health');
  console.log('  ML Service health response:', response.data);
  
  if (response.data.status !== 'healthy') {
    throw new Error('ML Service is not healthy');
  }
}

// Test: Make prediction with minimal data
async function testMinimalPrediction() {
  // Basic sleep data
  const sleepData = {
    bedTime: new Date(new Date().setHours(22, 0, 0, 0)).toISOString(),
    wakeUpTime: new Date(new Date().setHours(6, 0, 0, 0)).toISOString(),
    timeToFallAsleep: 15,
    sleepDuration: 480, // 8 hours in minutes
    interruptionCount: 1,
    sleepQuality: 3,
    stressLevel: 2
  };
  
  // Basic environmental data
  const environmentalData = {
    temperature: 22.5,
    humidity: 45,
    lightIntensity: 10,
    soundExposure: 'Quiet'
  };
  
  // Basic dietary data
  const dietaryData = {
    isBreakfastRegular: true,
    isLunchRegular: true,
    isDinnerRegular: true,
    selectedBreakfastFoodTypes: ['Carbohydrates', 'Proteins'],
    selectedLunchFoodTypes: ['Proteins', 'Vegetables'],
    selectedDinnerFoodTypes: ['Proteins', 'Vegetables'],
    waterIntake: 2000
  };
  
  // Combined prediction data
  const predictionData = {
    userId: testState.userId,
    sleepData,
    environmentalData,
    dietaryData
  };
  
  const response = await apiClient.post('/predictions/predict', predictionData);
  console.log('  Prediction response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data.predictionScore || !response.data.interruptionWindows) {
    throw new Error('Invalid prediction response');
  }
  
  testState.predictionId = response.data._id;
}

// Test: Make prediction with complete data
async function testCompletePrediction() {
  // More detailed sleep data
  const sleepData = {
    bedTime: new Date(new Date().setHours(23, 15, 0, 0)).toISOString(),
    wakeUpTime: new Date(new Date().setHours(7, 30, 0, 0)).toISOString(),
    timeToFallAsleep: 25,
    sleepDuration: 470, // ~7.8 hours in minutes
    interruptionCount: 2,
    sleepQuality: 2,
    stressLevel: 4,
    // Additional user profile data
    userProfile: {
      age: 35,
      gender: 'male',
      height: 178, // cm
      weight: 75, // kg
      bmi: 23.7
    },
    // Activities data
    activities: {
      exerciseMinutes: 45,
      dailySteps: 8500,
      caffeineIntake: 200, // mg
      screenTimeMinutes: 180
    }
  };
  
  // Detailed environmental data
  const environmentalData = {
    temperature: 24.5,
    humidity: 60,
    lightIntensity: 50,
    soundExposure: 'Moderate',
    noiseLevel: 35, // dB
    airQuality: 'Good',
    sleepEnvironment: 'Bedroom',
    sleepPosition: 'Side'
  };
  
  // Detailed dietary data
  const dietaryData = {
    isBreakfastRegular: true,
    isLunchRegular: true,
    isDinnerRegular: false,
    selectedBreakfastFoodTypes: ['Carbohydrates', 'Proteins', 'Dairy'],
    selectedLunchFoodTypes: ['Proteins', 'Vegetables', 'Fruits'],
    selectedDinnerFoodTypes: ['Proteins', 'Vegetables'],
    waterIntake: 2500,
    alcoholConsumption: 1, // drinks
    eveningMealTime: new Date(new Date().setHours(19, 0, 0, 0)).toISOString(),
    hasCaffeineBefore: true,
    caffeineTime: new Date(new Date().setHours(16, 0, 0, 0)).toISOString()
  };
  
  // Combined prediction data
  const predictionData = {
    userId: testState.userId,
    sleepData,
    environmentalData,
    dietaryData
  };
  
  const response = await apiClient.post('/predictions/predict', predictionData);
  console.log('  Detailed prediction response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data.predictionScore || 
      !response.data.interruptionWindows || 
      !response.data.contributingFactors) {
    throw new Error('Invalid detailed prediction response');
  }
}

// Test: Get prediction by ID
async function testGetPredictionById() {
  if (!testState.predictionId) {
    throw new Error('No prediction ID available');
  }
  
  const response = await apiClient.get(`/predictions/${testState.predictionId}`);
  console.log('  Get prediction response:', JSON.stringify(response.data, null, 2));
  
  if (response.data._id !== testState.predictionId) {
    throw new Error('Retrieved prediction ID does not match');
  }
}

// Test: Get latest prediction
async function testGetLatestPrediction() {
  const response = await apiClient.get('/predictions/latest', {
    params: { userId: testState.userId }
  });
  console.log('  Latest prediction response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data._id) {
    throw new Error('No prediction found');
  }
}

// Test: Get recommendations
async function testGetRecommendations() {
  const response = await apiClient.get('/predictions/recommendations', {
    params: { userId: testState.userId }
  });
  console.log('  Recommendations response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data.recommendations || !Array.isArray(response.data.recommendations)) {
    throw new Error('Invalid recommendations response');
  }
}

// Test: Get predictions for date range
async function testGetPredictionsForDateRange() {
  const startDate = new Date();
  startDate.setDate(startDate.getDate() - 7); // 7 days ago
  
  const endDate = new Date(); // Now
  
  const response = await apiClient.get(`/predictions/history`, {
    params: {
      startDate: startDate.toISOString(),
      endDate: endDate.toISOString()
    }
  });
  console.log('  Date range predictions response:', JSON.stringify(response.data, null, 2));
  
  if (!Array.isArray(response.data)) {
    throw new Error('Invalid date range response');
  }
}

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting Prediction Flow Tests');
  console.log(`API URL: ${API_URL}`);
  console.log(`ML Service URL: ${ML_SERVICE_URL}`);
  
  try {
    await setupTestUser();
    
    await runTest('ML Service Health Check', testMLServiceHealth);
    await runTest('Make Minimal Prediction', testMinimalPrediction);
    await runTest('Make Complete Prediction', testCompletePrediction);
    await runTest('Get Prediction By ID', testGetPredictionById);
    await runTest('Get Latest Prediction', testGetLatestPrediction);
    await runTest('Get Recommendations', testGetRecommendations);
    await runTest('Get Predictions For Date Range', testGetPredictionsForDateRange);
  } finally {
    await cleanupTestUser();
  }
  
  // Print summary
  console.log('\n📊 Test Summary:');
  console.log(`Total: ${results.total}`);
  console.log(`Passed: ${results.passed}`);
  console.log(`Failed: ${results.failed}`);
  
  if (results.failed > 0) {
    console.log('\n❌ Some tests failed!');
    process.exit(1);
  } else {
    console.log('\n✅ All tests passed!');
  }
}

// Run the tests
runAllTests().catch(error => {
  console.error('Error running tests:', error);
  process.exit(1);
});
