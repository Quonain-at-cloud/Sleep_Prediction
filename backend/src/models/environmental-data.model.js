const mongoose = require('mongoose');

const environmentalDataSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  date: {
    type: Date,
    default: Date.now
  },
  temperature: {
    type: Number,
    min: -50,
    max: 50
  },
  humidity: {
    type: Number,
    min: 0,
    max: 100
  },
  lightIntensity: {
    type: Number,
    min: 0,
    max: 100
  },
  soundExposure: {
    type: String,
    enum: ['Silent', 'Quiet', 'Moderate', 'Loud', 'Very Loud']
  },
  noiseLevel: {
    type: Number,
    min: 0,
    max: 120
  },
  airQuality: {
    type: String,
    enum: ['Excellent', 'Good', 'Moderate', 'Poor', 'Very Poor']
  },
  sleepEnvironment: {
    type: String,
    enum: ['Bedroom', 'Living Room', 'Hotel', 'Other']
  },
  sleepPosition: {
    type: String,
    enum: ['Back', 'Side', 'Stomach', 'Multiple']
  },
  notes: {
    type: String,
    maxlength: 500
  }
}, {
  timestamps: true
});

// Index for faster queries
environmentalDataSchema.index({ userId: 1, date: -1 });

const EnvironmentalData = mongoose.model('EnvironmentalData', environmentalDataSchema);

module.exports = EnvironmentalData;
