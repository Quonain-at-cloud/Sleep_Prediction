const cron = require('node-cron');
const Schedule = require('../models/schedule.model');
const socket = require('./socket');
const Notification = require('../models/notification.model');

/**
 * Starts cron jobs for schedule reminders and post-missed alerts.
 * Should be called once after Socket.IO is initialised.
 */
function start() {
  console.log('[SCHEDULE-REMINDER] Starting schedule reminder cron jobs...');
  
  // Run every minute
  cron.schedule('* * * * *', async () => {
    try {
      const now = new Date();
      const oneMinuteAgo = new Date(now.getTime() - 60 * 1000);
      const oneMinuteFromNow = new Date(now.getTime() + 60 * 1000);
      
      console.log(`[SCHEDULE-REMINDER] Checking for schedules between ${oneMinuteAgo.toISOString()} and ${oneMinuteFromNow.toISOString()}`);
      
      const upcoming = await Schedule.find({
        completed: false,
        reminderSent: false,
        startTime: { $gte: oneMinuteAgo, $lte: oneMinuteFromNow },
      });

      if (upcoming.length) {
        console.log(`[SCHEDULE-REMINDER] Found ${upcoming.length} upcoming schedule(s) at ${now.toISOString()}`);
      } else {
        console.log(`[SCHEDULE-REMINDER] No upcoming schedules found at ${now.toISOString()}`);
      }

      for (const item of upcoming) {
        try {
          const payload = {
            title: `${item.title || 'Schedule Reminder'}`,
            message: item.category ? `It's time for ${item.category}.` : 'It\'s time for your scheduled activity.',
            timestamp: new Date().toISOString(),
            userId: item.userId.toString(),
          };

          console.log(`[SCHEDULE-REMINDER] Sending notification to user ${item.userId}:`, payload);

          // Send via socket
          socket.sendToUser(item.userId.toString(), payload);
          
          // Save to database
          await Notification.create(payload);
          
          // Mark as sent
          item.reminderSent = true;
          await item.save();
          
          console.log(`[SCHEDULE-REMINDER] Successfully sent notification for schedule ${item._id}`);
        } catch (itemError) {
          console.error(`[SCHEDULE-REMINDER] Error processing schedule ${item._id}:`, itemError);
        }
      }
    } catch (err) {
      console.error('[SCHEDULE-REMINDER] Schedule reminder cron error:', err);
    }
  });

  // Missed schedule check every 30 minutes
  cron.schedule('*/30 * * * *', async () => {
    try {
      const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000);
      console.log(`[SCHEDULE-REMINDER] Checking for missed schedules before ${thirtyMinutesAgo.toISOString()}`);
      
      const missed = await Schedule.find({
        completed: false,
        startTime: { $lte: thirtyMinutesAgo },
      });

      if (missed.length) {
        console.log(`[SCHEDULE-REMINDER] Found ${missed.length} missed schedule(s)`);
      }

      for (const item of missed) {
        try {
          const payload = {
            title: 'Schedule missed',
            message: `You missed your ${item.category || 'scheduled activity'} – try to improve your routine!`,
            timestamp: new Date().toISOString(),
            userId: item.userId.toString(),
          };
          
          console.log(`[SCHEDULE-REMINDER] Sending missed notification to user ${item.userId}:`, payload);
          
          socket.sendToUser(item.userId.toString(), payload);
          await Notification.create(payload);
          
          console.log(`[SCHEDULE-REMINDER] Successfully sent missed notification for schedule ${item._id}`);
        } catch (itemError) {
          console.error(`[SCHEDULE-REMINDER] Error processing missed schedule ${item._id}:`, itemError);
        }
      }
    } catch (err) {
      console.error('[SCHEDULE-REMINDER] Missed schedule cron error:', err);
    }
  });

  console.log('[SCHEDULE-REMINDER] Schedule reminder cron jobs started successfully');
}

module.exports = { start };
