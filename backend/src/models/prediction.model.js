const mongoose = require('mongoose');

const predictionSchema = new mongoose.Schema({
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  date: {
    type: Date,
    required: true
  },
  predictionScore: {
    type: Number,
    required: true,
    min: 0,
    max: 1
  },
  // Textual summary of prediction returned by ML service
  predictionText: {
    type: String
  },
  // Detailed analysis string returned by ML service
  detailedAnalysis: {
    type: String
  },
  predictedInterruptionCount: {
    type: Number,
    required: true,
    min: 0
  },
  predictedInterruptionWindows: [{
    startTime: {
      type: Date,
      required: true
    },
    endTime: {
      type: Date,
      required: true
    },
    probability: {
      type: Number,
      required: true,
      min: 0,
      max: 1
    }
  }],
  contributingFactors: {
    type: Map,
    of: Number
  },
  recommendations: [{
    type: String
  }],
  inputData: {
    type: Map,
    of: mongoose.Schema.Types.Mixed
  }
}, {
  timestamps: true
});

// Index for efficient querying
predictionSchema.index({ userId: 1, date: -1 });

module.exports = mongoose.model('Prediction', predictionSchema);
