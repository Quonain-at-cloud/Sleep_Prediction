require('dotenv').config();
const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const connectDB = require('./config/db');

// Import routes
const userRoutes = require('./routes/user.routes');
const sleepDataRoutes = require('./routes/sleep-data.routes');
const predictionRoutes = require('./routes/prediction.routes');
const notificationRoutes = require('./routes/notification.routes');
const scheduleRoutes = require('./routes/schedule.routes');

// WebSocket
const http = require('http');
const socket = require('./utils/socket');
const scheduleReminder = require('./utils/schedule-reminder');

// Initialize express app
const app = express();

// Create HTTP server and initialize Socket.IO
const server = http.createServer(app);
socket.init(server);
// Start cron jobs for schedule reminders
scheduleReminder.start();

// Path module for file paths
const path = require('path');

// Connect to MongoDB
connectDB();

// Initialize email service
const { initializeEmailService } = require('./services/email.service');
initializeEmailService().catch(err => {
  console.error('Failed to initialize email service:', err);
});

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(morgan('dev'));

// Serve static files from uploads directory
app.use('/uploads', express.static(path.join(__dirname, '../uploads')));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Routes
app.use('/api/users', userRoutes);
app.use('/api/sleep-data', sleepDataRoutes);
app.use('/api/predictions', predictionRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/schedule', scheduleRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on port ${PORT}`);
});
