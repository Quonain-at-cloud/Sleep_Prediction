const socket = require('../utils/socket');

/**
 * Handle incoming notification payloads (from ML service or other sources)
 * and broadcast them to connected WebSocket clients.
 *
 * Expected body: { 
 *   title: string, 
 *   message: string, 
 *   timestamp?: string,
 *   userId?: string, // Optional: if not provided, sends to all users
 *   targetType?: 'user' | 'all' // Optional: defaults to 'user' if userId provided, 'all' otherwise
 * }
 */
exports.sendNotification = (req, res) => {
  const { title, message, timestamp, userId, targetType } = req.body || {};

  if (!title || !message) {
    return res.status(400).json({ error: 'title and message are required' });
  }

  const payload = {
    title,
    message,
    timestamp: timestamp || new Date().toISOString(),
    userId: userId || '', // Include userId in payload
  };

  try {
    const io = socket.getIo();
    
    // Determine target type
    const shouldSendToUser = targetType === 'user' || (targetType !== 'all' && userId);
    
    if (shouldSendToUser && userId) {
      // Send to specific user
      socket.sendToUser(userId, payload);
      console.log(`Notification sent to user ${userId}:`, payload.title);
    } else {
      // Send to all users (admin notifications)
      socket.sendToAll(payload);
      console.log('Notification sent to all users:', payload.title);
    }
    
    return res.status(200).json({ 
      success: true, 
      notification: payload,
      targetType: shouldSendToUser ? 'user' : 'all'
    });
  } catch (err) {
    console.error('Socket not initialized:', err);
    return res.status(500).json({ error: 'WebSocket server not initialized' });
  }
};

/**
 * Send notification to specific user
 * Expected body: { title: string, message: string, timestamp?: string }
 * User ID is extracted from the authenticated request
 */
exports.sendUserNotification = (req, res) => {
  const { title, message, timestamp } = req.body || {};

  if (!title || !message) {
    return res.status(400).json({ error: 'title and message are required' });
  }

  const userId = req.user._id.toString();
  const payload = {
    title,
    message,
    timestamp: timestamp || new Date().toISOString(),
    userId,
  };

  try {
    socket.sendToUser(userId, payload);
    console.log(`Notification sent to user ${userId}:`, payload.title);
    
    return res.status(200).json({ 
      success: true, 
      notification: payload 
    });
  } catch (err) {
    console.error('Socket not initialized:', err);
    return res.status(500).json({ error: 'WebSocket server not initialized' });
  }
};

/**
 * Test endpoint to manually trigger a notification for the authenticated user
 * Useful for debugging notification system
 */
exports.testNotification = (req, res) => {
  const userId = req.user._id.toString();
  const payload = {
    title: 'Test Notification',
    message: 'This is a test notification from the backend',
    timestamp: new Date().toISOString(),
    userId,
  };

  try {
    socket.sendToUser(userId, payload);
    console.log(`Test notification sent to user ${userId}`);
    
    return res.status(200).json({ 
      success: true, 
      notification: payload,
      message: 'Test notification sent successfully'
    });
  } catch (err) {
    console.error('Failed to send test notification:', err);
    return res.status(500).json({ error: 'Failed to send test notification' });
  }
};
