const express = require('express');
const router = express.Router();
const { sendNotification, sendUserNotification, testNotification, getLatestNotifications } = require('../controllers/notification.controller');
const { auth } = require('../middleware/auth.middleware');

// POST /api/notifications - Send notification (can be user-specific or global)
router.post('/', sendNotification);

// POST /api/notifications/user - Send notification to authenticated user
router.post('/user', auth, sendUserNotification);

// GET /api/notifications/test - Test notification for authenticated user
// GET /api/notifications/user/latest - Fetch new notifications for user
router.get('/user/latest', auth, getLatestNotifications);

// Existing test route
router.get('/test', auth, testNotification);

module.exports = router;
