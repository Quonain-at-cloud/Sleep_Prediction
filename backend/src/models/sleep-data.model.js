
const mongoose = require('mongoose');
// Define a separate schema for meal objects
const mealSchema = new mongoose.Schema({
  type: { type: String, required: true },
  isRegular: { type: Boolean, required: true },
  time: { type: String, required: true },
  portionSize: { type: Number, required: true },
  foodTypes: { type: [String], required: true }
}, { _id: false });

// Remove old fields no longer used in new schema
// Updated schema focuses on nested structures only
const sleepDataSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  // Nested data from the three form sections
  sleepPatterns: {
    weekdayBedtime: String,
    weekdayWakeup: String,
    weekendBedtime: String,
    weekendWakeup: String,
    sleepDuration: Number,
    awakenings: Number,
    sleepQuality: Number,
    relaxedBeforeSleep: Number,
    useElectronics: Boolean,
    stressLevel: Number
  },
  profileInfo: {
    age: Number,
    gender: String
  },
  dietaryHabits: {
    mealsPerDay: Number,
    meals: [mealSchema],
    caffeineAfterNoon: Boolean,
    alcoholBeforeBed: Boolean,
    heavyMealBeforeBed: Boolean,
    waterIntake: Number,
    mealTimingConsistent: Boolean,
    balancedMeals: Boolean,
    lateNightSnacking: Boolean
  },
  environmentalFactors: {
    lightIntensity: Number,
    temperature: Number,
    noiseLevel: Number,
    humidity: Number,
    airQuality: String
  }
}, {
  timestamps: true
});

// Index for efficient querying
sleepDataSchema.index({ userId: 1, createdAt: -1 });

module.exports = mongoose.model('SleepData', sleepDataSchema);
