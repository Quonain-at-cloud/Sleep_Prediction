/**
 * Authentication Flow Test Script
 * Tests the complete authentication flow including password reset
 */

const axios = require('axios');
const dotenv = require('dotenv');
dotenv.config();

// Configuration
const API_URL = process.env.API_URL || 'http://localhost:3000/api';
const TEST_USER = {
  name: 'Test User',
  email: 'test_user_' + Date.now() + '@example.com',
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
  refreshToken: null,
  resetToken: null,
  otp: null
};

// HTTP client with authorization header
const authClient = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Update auth header
function setAuthHeader(token) {
  if (token) {
    authClient.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  } else {
    delete authClient.defaults.headers.common['Authorization'];
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

// Helper to wait
function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

// Test: User Registration
async function testRegistration() {
  const response = await authClient.post('/users/register', TEST_USER);
  console.log('  Registration response:', JSON.stringify(response.data, null, 2));
  if (!response.data.user || !response.data.token) {
    throw new Error('Invalid registration response');
  }
  testState.userId = response.data.user._id;
  testState.accessToken = response.data.token;
  setAuthHeader(testState.accessToken);
}

// Test: User Login
async function testLogin() {
  const credentials = {
    email: TEST_USER.email,
    password: TEST_USER.password
  };
  
  const response = await authClient.post('/users/login', credentials);
  console.log('  Login response:', JSON.stringify(response.data, null, 2));
  if (!response.data.user || !response.data.token) {
    throw new Error('Invalid login response');
  }
  testState.accessToken = response.data.token;
  setAuthHeader(testState.accessToken);
}

// Test: Get User Profile
async function testGetProfile() {
  const response = await authClient.get('/users/profile');
  console.log('  Profile response:', JSON.stringify(response.data, null, 2));
  if (!response.data._id || response.data._id !== testState.userId) {
    throw new Error('Invalid profile response');
  }
}

// Test: Update User Profile
async function testUpdateProfile() {
  const updates = {
    name: 'Updated Test User',
    height: 175,
    weight: 70
  };
  
  const response = await authClient.patch('/users/profile', updates);
  console.log('  Update response:', JSON.stringify(response.data, null, 2));
  if (response.data.name !== updates.name) {
    throw new Error('Profile not updated correctly');
  }
}

// Test: Forgot Password
async function testForgotPassword() {
  setAuthHeader(null); // Clear auth for public endpoints
  
  const response = await authClient.post('/users/forgot-password', {
    email: TEST_USER.email
  });
  console.log('  Forgot password response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data.otp) {
    throw new Error('No OTP received');
  }
  
  testState.otp = response.data.otp;
}

// Test: Verify OTP
async function testVerifyOTP() {
  const response = await authClient.post('/users/verify-otp', {
    email: TEST_USER.email,
    otp: testState.otp
  });
  console.log('  Verify OTP response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data.resetToken) {
    throw new Error('No reset token received');
  }
  
  testState.resetToken = response.data.resetToken;
}

// Test: Reset Password
async function testResetPassword() {
  const newPassword = 'NewTestPassword456!';
  
  const response = await authClient.post('/users/reset-password', {
    resetToken: testState.resetToken,
    newPassword: newPassword
  });
  console.log('  Reset password response:', JSON.stringify(response.data, null, 2));
  
  // Test login with new password
  const loginResponse = await authClient.post('/users/login', {
    email: TEST_USER.email,
    password: newPassword
  });
  
  if (!loginResponse.data.token) {
    throw new Error('Could not login with new password');
  }
  
  testState.accessToken = loginResponse.data.token;
  setAuthHeader(testState.accessToken);
  console.log('  Successfully logged in with new password');
}

// Test: Refresh Token
async function testRefreshToken() {
  // The accessToken should be stored in testState
  const response = await authClient.post('/users/refresh-token');
  console.log('  Refresh token response:', JSON.stringify(response.data, null, 2));
  
  if (!response.data.token) {
    throw new Error('No new token received');
  }
  
  const newToken = response.data.token;
  setAuthHeader(newToken);
  
  // Verify the new token works
  const profileResponse = await authClient.get('/users/profile');
  if (!profileResponse.data._id) {
    throw new Error('New token is invalid');
  }
}

// Test: Delete Account (cleanup)
async function testDeleteAccount() {
  const response = await authClient.delete('/users/account');
  console.log('  Delete account response:', JSON.stringify(response.data, null, 2));
}

// Run all tests
async function runAllTests() {
  console.log('🚀 Starting Authentication Flow Tests');
  console.log(`API URL: ${API_URL}`);
  console.log(`Test User Email: ${TEST_USER.email}`);
  
  await runTest('User Registration', testRegistration);
  await runTest('User Login', testLogin);
  await runTest('Get User Profile', testGetProfile);
  await runTest('Update User Profile', testUpdateProfile);
  await runTest('Forgot Password', testForgotPassword);
  await runTest('Verify OTP', testVerifyOTP);
  await runTest('Reset Password', testResetPassword);
  await runTest('Refresh Token', testRefreshToken);
  await runTest('Delete Account', testDeleteAccount);
  
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
