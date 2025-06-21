const mongoose = require('mongoose');

const dietaryDataSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  },
  isBreakfastRegular: {
    type: Boolean,
    default: false
  },
  isLunchRegular: {
    type: Boolean,
    default: false
  },
  isDinnerRegular: {
    type: Boolean,
    default: false
  },
  selectedBreakfastFoodTypes: {
    type: [String],
    enum: ['Carbohydrates', 'Proteins', 'Fruits', 'Vegetables', 'Dairy', 'Fats', 'Sweets'],
    default: []
  },
  selectedLunchFoodTypes: {
    type: [String],
    enum: ['Carbohydrates', 'Proteins', 'Fruits', 'Vegetables', 'Dairy', 'Fats', 'Sweets'],
    default: []
  },
  selectedDinnerFoodTypes: {
    type: [String],
    enum: ['Carbohydrates', 'Proteins', 'Fruits', 'Vegetables', 'Dairy', 'Fats', 'Sweets'],
    default: []
  },
  waterIntake: {
    type: Number, // in milliliters
    min: 0,
    max: 10000
  },
  alcoholConsumption: {
    type: Number, // number of drinks
    min: 0,
    default: 0
  },
  eveningMealTime: {
    type: Date
  },
  hasCaffeineBefore: {
    type: Boolean,
    default: false
  },
  caffeineTime: {
    type: Date
  },
  notes: {
    type: String,
    maxlength: 500
  }
}, {
  timestamps: true
});

// Index for faster queries
dietaryDataSchema.index({ userId: 1, date: -1 });

const DietaryData = mongoose.model('DietaryData', dietaryDataSchema);

module.exports = DietaryData;
