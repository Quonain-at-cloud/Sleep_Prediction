const cron = require('node-cron');
const Schedule = require('../models/schedule.model');
const socket = require('./socket');
const Notification = require('../models/notification.model');

/**
 * Starts cron jobs for schedule reminders and post-missed alerts.
 * Should be called once after Socket.IO is initialised.
 */
function start() {
  // Run every minute
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      const upcoming = await Schedule.find({
        completed: false,
        reminderSent: false,
        startTime: { $lte: new Date(now.getTime() + 60 * 1000) },
      });

      for (const item of upcoming) {
        const payload = {
          title: `${item.title} time!`,
          message: `It's time for ${item.category}.`,
          timestamp: new Date().toISOString(),
          userId: item.userId.toString(),
        };

        socket.sendToUser(item.userId.toString(), payload);
        await Notification.create(payload);
        item.reminderSent = true;
        await item.save();
      }
    } catch (err) {
      console.error('Schedule reminder cron error:', err);
    }
  });

  // Missed schedule check every 30 minutes
  cron.schedule('*/30 * * * *', async () => {
    try {
      const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
      const missed = await Schedule.find({
        completed: false,
        startTime: { $lte: thirtyMinutesAgo },
      });

      for (const item of missed) {
        const payload = {
          title: 'Schedule missed',
          message: `You missed your ${item.category} – try to improve your routine!`,
          timestamp: new Date().toISOString(),
          userId: item.userId.toString(),
        };
        socket.sendToUser(item.userId.toString(), payload);
        await Notification.create(payload);
      }
    } catch (err) {
      console.error('Missed schedule cron error:', err);
    }
  });

  console.log('Schedule reminder cron jobs started');
}

module.exports = { start };
