const Schedule = require('../models/schedule.model');
const socket = require('../utils/socket');

const CATEGORY_COLORS = {
  breakfast: '#FFF8E1',
  lunch: '#E1F5FE',
  dinner: '#E8F5E9',
  snack: '#FFEBEE',
  sleepStart: '#EDE7F6',
  wakeUp: '#EDE7F6',
  exercise: '#E0F7FA',
  other: '#F5F5F5',
};

/**
 * Simple schedule generator. In production you would tailor times based on user data & ML.
 * For now we generate a single-day schedule (today) with default times.
 * @param {string} userId Mongo ObjectId string
 * @returns {Promise<void>}
 */
async function generateTodaySchedule(userId) {
  const today = new Date();
  today.setMinutes(0, 0, 0);

  // Helper to create date with time hh:mm
  const atTime = (hours, minutes = 0) => {
    const d = new Date(today);
    d.setHours(hours, minutes, 0, 0);
    return d;
  };

  const items = [
    {
      category: 'breakfast',
      title: 'Breakfast',
      startTime: atTime(8, 0),
    },
    {
      category: 'lunch',
      title: 'Lunch',
      startTime: atTime(13, 0),
    },
    {
      category: 'dinner',
      title: 'Dinner',
      startTime: atTime(19, 0),
    },
    {
      category: 'sleepStart',
      title: 'Go to bed',
      startTime: atTime(23, 0),
    },
    {
      category: 'wakeUp',
      title: 'Wake up',
      startTime: atTime(7, 0),
    },
  ];

  // Remove any existing schedule for today to avoid duplicates
  const startOfDay = new Date(today);
  startOfDay.setHours(0, 0, 0, 0);
  const endOfDay = new Date(today);
  endOfDay.setHours(23, 59, 59, 999);

  await Schedule.deleteMany({ userId, startTime: { $gte: startOfDay, $lte: endOfDay } });

  // Insert and emit events
  for (const item of items) {
    const doc = await Schedule.create({
      userId,
      title: item.title,
      category: item.category,
      startTime: item.startTime,
      color: CATEGORY_COLORS[item.category] || CATEGORY_COLORS.other,
    });

    // Notify user in real time
    socket.getIo().to(`user_${userId}`).emit('schedule_created', doc);
  }

  console.log('Generated schedule for user', userId);
}

module.exports = { generateTodaySchedule };
