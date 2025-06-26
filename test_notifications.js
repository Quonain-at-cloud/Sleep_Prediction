const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3000/api';
let authToken = '';

// Test user credentials (replace with actual test user)
const TEST_USER = {
  email: 'test@example.com',
  password: 'password123'
};

async function login() {
  try {
    console.log('🔐 Logging in...');
    const response = await axios.post(`${BASE_URL}/users/login`, TEST_USER);
    authToken = response.data.token;
    console.log('✅ Login successful');
    return true;
  } catch (error) {
    console.error('❌ Login failed:', error.response?.data || error.message);
    return false;
  }
}

async function testNotification() {
  try {
    console.log('🔔 Testing notification endpoint...');
    const response = await axios.get(`${BASE_URL}/notifications/test`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    console.log('✅ Test notification sent:', response.data);
    return true;
  } catch (error) {
    console.error('❌ Test notification failed:', error.response?.data || error.message);
    return false;
  }
}

async function createTestSchedule() {
  try {
    console.log('📅 Creating test schedule...');
    const schedule = {
      userId: 'test-user-id', // This should be the actual user ID from login
      title: 'Test Schedule',
      startTime: new Date(Date.now() + 2 * 60 * 1000).toISOString(), // 2 minutes from now
      category: 'other'
    };
    
    const response = await axios.post(`${BASE_URL}/schedule`, schedule, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    console.log('✅ Test schedule created:', response.data);
    return response.data._id;
  } catch (error) {
    console.error('❌ Create schedule failed:', error.response?.data || error.message);
    return null;
  }
}

async function getNotifications() {
  try {
    console.log('📋 Fetching notifications...');
    const response = await axios.get(`${BASE_URL}/notifications/user/latest`, {
      headers: { Authorization: `Bearer ${authToken}` }
    });
    console.log('✅ Notifications fetched:', response.data);
    return response.data.notifications;
  } catch (error) {
    console.error('❌ Fetch notifications failed:', error.response?.data || error.message);
    return [];
  }
}

async function runTests() {
  console.log('🚀 Starting notification system tests...\n');
  
  // Step 1: Login
  const loginSuccess = await login();
  if (!loginSuccess) {
    console.log('❌ Cannot proceed without login');
    return;
  }
  
  // Step 2: Test manual notification
  await testNotification();
  
  // Step 3: Create test schedule
  const scheduleId = await createTestSchedule();
  
  // Step 4: Wait a bit and check notifications
  console.log('⏳ Waiting 5 seconds...');
  await new Promise(resolve => setTimeout(resolve, 5000));
  
  // Step 5: Fetch notifications
  await getNotifications();
  
  console.log('\n✅ Test sequence completed!');
  console.log('\n📝 Next steps:');
  console.log('1. Check your Flutter app notification screen');
  console.log('2. Check backend logs for schedule reminder activity');
  console.log('3. Verify socket connections in the app');
}

// Run the tests
runTests().catch(console.error); 