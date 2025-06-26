# Notification System Debug Guide

## Issues Fixed

### 1. Notification Provider Initialization
- **Problem**: Notification provider was trying to initialize before user login
- **Solution**: Changed to manual initialization after user login
- **Files Modified**: `lib/providers/notification_provider.dart`, `lib/services/auth_service.dart`

### 2. Socket Connection Issues
- **Problem**: Socket service wasn't properly handling connection states
- **Solution**: Added better error handling and connection management
- **Files Modified**: `lib/services/socket_service.dart`

### 3. Schedule Reminder Event Mismatch
- **Problem**: Backend sends `new_notification` but frontend was listening for multiple events
- **Solution**: Simplified to listen only for `new_notification` event
- **Files Modified**: `lib/providers/notification_provider.dart`

### 4. Missing Error Handling
- **Problem**: Insufficient error handling in notification flow
- **Solution**: Added comprehensive error handling and logging
- **Files Modified**: Multiple files

### 5. Notification Display Issues
- **Problem**: Notification screen didn't show loading states or empty states
- **Solution**: Added proper UI states and test functionality
- **Files Modified**: `lib/screens/notification_screen.dart`

## How to Test the Fixes

### 1. Flutter App Testing

1. **Start the Flutter app**
2. **Login with your account**
3. **Navigate to the Notification screen**
4. **Click "Add Test Notification" button** to verify local notifications work
5. **Create a schedule** in the Schedule screen
6. **Wait for the scheduled time** or check if immediate notifications appear

### 2. Backend Testing

1. **Start your backend server**
2. **Run the test script**:
   ```bash
   cd backend
   npm install axios  # if not already installed
   node ../test_notifications.js
   ```
3. **Check backend logs** for schedule reminder activity
4. **Verify notifications are being sent** via WebSocket

### 3. Manual Testing Steps

#### Test 1: Local Notifications
1. Open the app
2. Go to Notification screen
3. Click "Add Test Notification"
4. Verify notification appears in the list
5. Check if OS notification appears

#### Test 2: Schedule Notifications
1. Create a schedule for 2-3 minutes from now
2. Wait for the scheduled time
3. Check if notification appears
4. Verify in backend logs that cron job is running

#### Test 3: Backend Notifications
1. Use the test script to send a notification
2. Check if it appears in the Flutter app
3. Verify WebSocket connection is working

## Debugging Commands

### Check Backend Logs
```bash
# Look for schedule reminder logs
grep "SCHEDULE-REMINDER" backend/logs/app.log

# Check for socket connection logs
grep "WebSocket" backend/logs/app.log

# Check for notification creation
grep "notification" backend/logs/app.log
```

### Check Flutter Logs
```bash
# Run Flutter app with verbose logging
flutter run --verbose

# Look for notification provider logs
flutter logs | grep "NotificationProvider"
```

### Test Backend Endpoints
```bash
# Test notification endpoint
curl -X GET "http://localhost:3000/api/notifications/test" \
  -H "Authorization: Bearer YOUR_TOKEN"

# Test schedule creation
curl -X POST "http://localhost:3000/api/schedule" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "YOUR_USER_ID",
    "title": "Test Schedule",
    "startTime": "2024-01-01T12:00:00.000Z",
    "category": "other"
  }'
```

## Common Issues and Solutions

### Issue 1: Notifications not appearing
**Possible Causes:**
- User not logged in
- Socket connection failed
- Notification provider not initialized

**Solutions:**
1. Check if user is logged in
2. Verify socket connection in logs
3. Try the test notification button

### Issue 2: Schedule notifications not working
**Possible Causes:**
- Cron job not running
- Schedule not saved properly
- Time zone issues

**Solutions:**
1. Check backend logs for cron activity
2. Verify schedule is saved in database
3. Check time zone settings

### Issue 3: Socket connection issues
**Possible Causes:**
- Backend not running
- CORS issues
- Authentication problems

**Solutions:**
1. Ensure backend is running
2. Check CORS configuration
3. Verify authentication token

## Files Modified

### Flutter App
- `lib/providers/notification_provider.dart` - Fixed initialization and error handling
- `lib/services/auth_service.dart` - Added proper notification provider initialization
- `lib/screens/notification_screen.dart` - Added loading states and test functionality
- `lib/providers/schedule_provider.dart` - Improved error handling

### Backend
- `backend/src/utils/schedule-reminder.js` - Added better logging and error handling
- `backend/src/controllers/notification.controller.js` - Added test endpoint

### Test Files
- `test_notifications.js` - Created test script for debugging
- `NOTIFICATION_DEBUG_GUIDE.md` - This guide

## Next Steps

1. **Test the fixes** using the provided test methods
2. **Monitor logs** for any remaining issues
3. **Create real schedules** and verify notifications work
4. **Report any remaining issues** with specific error messages

## Support

If you encounter any issues:
1. Check the logs for error messages
2. Use the test script to isolate the problem
3. Verify all services are running properly
4. Check network connectivity between app and backend 