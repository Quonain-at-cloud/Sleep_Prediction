const mongoose = require('mongoose');

// Schedule schema defines a time-based item for a specific user (sleep, meal, etc.)
const scheduleSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true,
    },
    title: {
      type: String,
      required: true,
      trim: true,
    },
    description: {
      type: String,
      trim: true,
    },
    startTime: {
      type: Date,
      required: true,
    },
    endTime: {
      type: Date,
    },
    category: {
      type: String,
      enum: ['breakfast','lunch','dinner','snack','sleepStart','wakeUp','exercise','other'],
      default: 'other',
    },
    completed: {
      type: Boolean,
      default: false,
    },
    reminderSent: {
      type: Boolean,
      default: false,
    },
    nutrients: {
      calories: Number,
      carbs: Number,
      proteins: Number,
      fats: Number,
    },
    color: {
      type: String,
    },
  },
  {
    timestamps: true, // adds createdAt & updatedAt automatically
  },
);

// Enable efficient queries per-user and per-startTime
scheduleSchema.index({ userId: 1, startTime: -1 });
scheduleSchema.index({ completed: 1, reminderSent: 1, startTime: 1 });

module.exports = mongoose.model('Schedule', scheduleSchema);
