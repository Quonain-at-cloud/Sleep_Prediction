const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model');

let io;

/**
 * Initialize Socket.IO server and attach to given HTTP server.
 * @param {import('http').Server} server - HTTP server instance.
 * @returns {import('socket.io').Server}
 */
function init(server) {
  io = socketIo(server, {
    cors: {
      origin: '*',
      methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
    },
  });

  // Authentication middleware for WebSocket connections
  io.use(async (socket, next) => {
    try {
      const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
      
      if (!token) {
        return next(new Error('Authentication token required'));
      }

      const decoded = jwt.verify(token, process.env.JWT_SECRET);
      const user = await User.findById(decoded.userId);
      
      if (!user) {
        return next(new Error('User not found'));
      }

      socket.userId = user._id.toString();
      socket.user = user;
      next();
    } catch (error) {
      console.error('Socket authentication error:', error.message);
      next(new Error('Authentication failed'));
    }
  });

  io.on('connection', socket => {
    console.log('WebSocket client connected:', socket.id, 'User:', socket.userId);

    // Join user-specific room
    socket.join(`user_${socket.userId}`);

    socket.on('disconnect', reason => {
      console.log('WebSocket client disconnected:', socket.id, 'User:', socket.userId, 'Reason:', reason);
    });
  });

  return io;
}

/**
 * Get initialized Socket.IO instance.
 * @throws {Error} If Socket.IO has not been initialised.
 * @returns {import('socket.io').Server}
 */
function getIo() {
  if (!io) {
    throw new Error('Socket.io not initialised! Call init(server) first.');
  }
  return io;
}

/**
 * Send notification to specific user
 * @param {string} userId - User ID to send notification to
 * @param {Object} notification - Notification payload
 */
function sendToUser(userId, notification) {
  if (!io) {
    throw new Error('Socket.io not initialised! Call init(server) first.');
  }
  io.to(`user_${userId}`).emit('new_notification', notification);
}

/**
 * Send notification to all users (admin notifications)
 * @param {Object} notification - Notification payload
 */
function sendToAll(notification) {
  if (!io) {
    throw new Error('Socket.io not initialised! Call init(server) first.');
  }
  io.emit('new_notification', notification);
}

module.exports = {
  init,
  getIo,
  sendToUser,
  sendToAll,
};
