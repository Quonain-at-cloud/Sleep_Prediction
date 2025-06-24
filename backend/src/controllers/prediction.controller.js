const Prediction = require('../models/prediction.model');
const SleepData = require('../models/sleep-data.model');
const User = require('../models/user.model');
const { checkMLServiceHealth, getPrediction, mapSleepDataToMLInput } = require('../utils/ml-service');
const EnvironmentalData = require('../models/environmental-data.model');
const DietaryData = require('../models/dietary-data.model');
const axios = require('axios');
const SleepPredictionService = require('../services/sleep-prediction.service');
const notificationController = require('./notification.controller');
const { generateTodaySchedule } = require('../services/schedule-generator.service');

// Initialize the sleep prediction service
const sleepPredictionService = new SleepPredictionService();

// Utility: remove generic greeting lines such as "Dear there..." from recommendation lists
function cleanRecommendations(recData) {
  if (!recData) return [];
  let arr;
  if (Array.isArray(recData)) {
    arr = recData;
  } else if (typeof recData === 'string') {
    arr = recData.split('\n');
  } else {
    return [];
  }
  // Trim and discard empty lines
  arr = arr.map(item => (typeof item === 'string' ? item.trim() : '')).filter(Boolean);
  // Drop the first line if it starts with any greeting like "dear"
  if (arr.length && /^dear/i.test(arr[0])) {
    arr.shift();
  }
  return arr;
}

// New predict endpoint that accepts user data and returns a prediction
exports.predict = async (req, res) => {
  try {
    if (!req.body) {
      return res.status(400).json({
        error: 'Missing prediction data in request body'
      });
    }

    const { sleepData, environmentalData, dietaryData } = req.body;
    const userId = req.user?._id || req.body.userId;

    // Map the input data to the format expected by our service
    const mlInputData = mapSleepDataToMLInput(sleepData, environmentalData, dietaryData);

    // Get prediction using our local Node.js service
    const predictionResult = sleepPredictionService.analyzeSleepData(mlInputData);

    // Save prediction to DB
    const predictionDoc = new Prediction({
      userId,
      date: new Date(),
      predictionScore: predictionResult.normalizedScore || 0,
      predictionText: predictionResult.prediction,
      detailedAnalysis: predictionResult.detailedAnalysis,
      predictedInterruptionCount: predictionResult.predictedInterruptionCount || 0,
      predictedInterruptionWindows: (predictionResult.predictedInterruptionWindows || []).map(win => ({
        startTime: win.startTime ? new Date(`1970-01-01T${win.startTime}:00Z`) : new Date(),
        endTime: win.endTime ? new Date(`1970-01-01T${win.endTime}:00Z`) : new Date(),
        probability: win.probability || 0
      })),
      contributingFactors: predictionResult.contributingFactors || {},
      recommendations: predictionResult.recommendations || [],
      inputData: mlInputData
    });
    await predictionDoc.save();

    // Persist the raw data for progress reports if available
    try {
      if (typeof sleepData !== 'undefined') {
        const sleepDataDoc = new SleepData({
          userId,
          sleepPatterns: {
            weekdayBedtime: `${sleepData['Weekday Bedtime Hour'] ?? ''}:${sleepData['Weekday Bedtime Minute'] ?? ''}`,
            weekdayWakeup: `${sleepData['Weekday Wake-up Hour'] ?? ''}:${sleepData['Weekday Wake-up Minute'] ?? ''}`,
            weekendBedtime: `${sleepData['Weekend Bedtime Hour'] ?? ''}:${sleepData['Weekend Bedtime Minute'] ?? ''}`,
            weekendWakeup: `${sleepData['Weekend Wake-up Hour'] ?? ''}:${sleepData['Weekend Wake-up Minute'] ?? ''}`,
            sleepDuration: sleepData['Sleep Duration'],
            awakenings: sleepData['Awakenings During Night'],
            sleepQuality: sleepData['Rate Sleep Quality'],
            relaxedBeforeSleep: sleepData['How Relaxed Before Sleep'],
            useElectronics: sleepData['Use Electronic Devices Before Bed'],
            stressLevel: sleepData['Stress Level'] ?? sleepData['stressLevel'] ?? sleepData['Stress_Level']
          },
          dietaryHabits: (typeof dietaryData !== 'undefined') ? {
            mealsPerDay: dietaryData['No Of Meals Per Day'] ?? dietaryData['Meals Per Day'],
            meals: dietaryData.Meals || [],
            caffeineAfterNoon: dietaryData['Caffeine After Noon'],
            alcoholBeforeBed: dietaryData['Alcohol Before Bed'],
            heavyMealBeforeBed: dietaryData['Heavy Meal Before Bed'],
            waterIntake: dietaryData['Water Intake'],
            mealTimingConsistent: dietaryData['Meal Timing Consistent'],
            balancedMeals: dietaryData['Balanced Meals'],
            lateNightSnacking: dietaryData['Late Night Snacking']
          } : undefined,
          environmentalFactors: (typeof environmentalData !== 'undefined') ? {
            lightIntensity: environmentalData.lightIntensity ?? environmentalData['Light Intensity'],
            temperature: environmentalData.temperature ?? environmentalData.Temperature,
            noiseLevel: environmentalData.noiseLevel ?? environmentalData['Noise Level']
          } : undefined,
        });
        await sleepDataDoc.save();
      }
    } catch (persistErr) {
      console.error('Failed to persist SleepData:', persistErr.message);
    }

    // Generate a default schedule for today so reminders can be sent
    try {
      await generateTodaySchedule(userId.toString());
    } catch (schedErr) {
      console.error('Schedule generation failed:', schedErr.message);
    }

    // Send notification to user
    try {
      notificationController.sendNotification({
        body: {
          title: 'New Sleep Prediction',
          message: predictionResult.prediction || 'A new sleep prediction has been generated.',
          userId: userId ? userId.toString() : '',
        }
      }, { status: () => ({ json: () => {} }) }); // Dummy res for internal call
    } catch (notifyErr) {
      console.error('Failed to send notification:', notifyErr);
    }

    // Return the prediction response
    res.status(200).json(predictionResult);

  } catch (error) {
    console.error('Error in prediction:', error);
    res.status(500).json({
      error: 'Internal server error during prediction',
      details: error.message
    });
  }
};

exports.createPrediction = async (req, res) => {
  try {
    const prediction = new Prediction({
      ...req.body,
      userId: req.user._id
    });
    await prediction.save();
    res.status(201).json(prediction);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getPrediction = async (req, res) => {
  try {
    const prediction = await Prediction.findOne({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!prediction) {
      return res.status(404).json({ error: 'Prediction not found' });
    }

    res.json(prediction);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getLatestPrediction = async (req, res) => {
  try {
    const prediction = await Prediction.findOne({
      userId: req.user._id
    }).sort({ date: -1 });

    if (!prediction) {
      return res.status(404).json({ error: 'No predictions found' });
    }

    res.json(prediction);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.generatePrediction = async (req, res) => {
  try {
    // Get historical sleep data
    const historicalData = await SleepData.find({
      userId: req.user._id
    })
    .sort({ date: -1 })
    .limit(30); // Last 30 days

    if (historicalData.length < 3) {
      return res.status(400).json({
        error: 'Insufficient historical data. Need at least 3 days of sleep data.'
      });
    }

    // Get most recent sleep data
    const latestSleepData = historicalData[0];
    
    // Get environmental and dietary data if available
    const environmentalData = await EnvironmentalData.findOne({ userId: req.user._id }).sort({ createdAt: -1 });
    const dietaryData = await DietaryData.findOne({ userId: req.user._id }).sort({ createdAt: -1 });
    
    // Check if ML service is available
    const isMLServiceAvailable = await checkMLServiceHealth();
    
    let predictionData;
    
    if (isMLServiceAvailable) {
      // Prepare data for ML service
      const mlInputData = mapSleepDataToMLInput(latestSleepData, environmentalData, dietaryData);
      
      // Get prediction from ML service
      const mlPrediction = await getPrediction(mlInputData);
      
      // Process interruption windows to convert string times to Date objects
      const interruptionWindows = mlPrediction.predictedInterruptionWindows.map(window => {
        const today = new Date();
        const startParts = window.startTime.split(':');
        const endParts = window.endTime.split(':');
        
        const startTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 
                                   parseInt(startParts[0]), parseInt(startParts[1]), 0, 0);
        const endTime = new Date(today.getFullYear(), today.getMonth(), today.getDate(), 
                                 parseInt(endParts[0]), parseInt(endParts[1]), 0, 0);
        
        // If end time is before start time, it's the next day
        if (endTime < startTime) {
          endTime.setDate(endTime.getDate() + 1);
        }
        
        return {
          startTime,
          endTime,
          probability: window.probability
        };
      });
      
      predictionData = {
        userId: req.user._id,
        date: new Date(),
        predictionScore: mlPrediction.normalizedScore,
        predictedInterruptionCount: mlPrediction.predictedInterruptionCount,
        predictedInterruptionWindows: interruptionWindows,
        contributingFactors: mlPrediction.contributingFactors,
        recommendations: cleanRecommendations(mlPrediction.recommendations),
        detailedAnalysis: mlPrediction.detailedAnalysis,
        predictionText: mlPrediction.prediction,
        inputData: mlInputData
      };
    } else {
      // Fallback to simple prediction if ML service is not available
      console.log('ML service not available, using fallback prediction');
      
      predictionData = {
        userId: req.user._id,
        date: new Date(),
        predictionScore: Math.random(),
        predictedInterruptionCount: Math.floor(Math.random() * 3),
        predictedInterruptionWindows: [
          {
            startTime: new Date(new Date().setHours(2, 0, 0, 0)),
            endTime: new Date(new Date().setHours(3, 0, 0, 0)),
            probability: Math.random()
          }
        ],
        contributingFactors: {
          'caffeine_intake': 0.7,
          'exercise': 0.3,
          'screen_time': 0.5
        },
        recommendations: [
          'Reduce caffeine intake after 2 PM',
          'Maintain consistent sleep schedule',
          'Exercise earlier in the day'
        ],
        inputData: {
          recentSleepQuality: latestSleepData?.sleepQuality || 0,
          averageSleepDuration: historicalData.reduce((acc, curr) => acc + curr.sleepDuration, 0) / historicalData.length
        }
      };
    }

    const prediction = new Prediction(predictionData);
    await prediction.save();
    res.status(201).json(prediction);
  } catch (error) {
    console.error('Error generating prediction:', error);
    res.status(500).json({ error: error.message });
  }
};

exports.getPredictionHistory = async (req, res) => {
  try {
    const match = { userId: req.user._id };
    const sort = { date: -1 };

    if (req.query.startDate && req.query.endDate) {
      match.date = {
        $gte: new Date(req.query.startDate),
        $lte: new Date(req.query.endDate)
      };
    }

    const predictions = await Prediction.find(match)
      .sort(sort)
      .limit(parseInt(req.query.limit) || 10)
      .skip(parseInt(req.query.skip) || 0);

    res.json(predictions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getPredictionsByUserId = async (req, res) => {
  try {
    // Check if the requesting user is an admin or the same user
    const isAuthorized = req.user.isAdmin || req.user._id.toString() === req.params.userId;
    
    if (!isAuthorized) {
      return res.status(403).json({ error: 'Not authorized to access this data' });
    }

    const match = { userId: req.params.userId };
    const sort = { date: -1 };

    // Date range filter
    if (req.query.startDate && req.query.endDate) {
      match.date = {
        $gte: new Date(req.query.startDate),
        $lte: new Date(req.query.endDate)
      };
    }

    const predictions = await Prediction.find(match)
      .sort(sort)
      .limit(parseInt(req.query.limit) || 10)
      .skip(parseInt(req.query.skip) || 0);

    res.json(predictions);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.deletePrediction = async (req, res) => {
  try {
    const prediction = await Prediction.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!prediction) {
      return res.status(404).json({ error: 'Prediction not found' });
    }

    res.json({ message: 'Prediction deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getRecommendations = async (req, res) => {
  try {
    // Get the latest prediction for the user
    const latestPrediction = await Prediction.findOne({
      userId: req.user._id
    }).sort({ date: -1 });

    if (!latestPrediction) {
      return res.status(404).json({ error: 'No predictions found' });
    }

    // If there are recommendations in the prediction, return them
    if (latestPrediction.recommendations && latestPrediction.recommendations.length > 0) {
      return res.json({
        recommendations: latestPrediction.recommendations,
        contributingFactors: latestPrediction.contributingFactors || {}
      });
    }

    // If no recommendations, generate some default ones
    const defaultRecommendations = [
      'Maintain a consistent sleep schedule',
      'Avoid caffeine and alcohol before bedtime',
      'Create a relaxing bedtime routine',
      'Ensure your bedroom is dark, quiet, and cool',
      'Limit screen time before bed'
    ];

    res.json({
      recommendations: defaultRecommendations,
      contributingFactors: {}
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// Return the latest stored prediction (if exists) otherwise generate on the fly from most recent sleep-data.
exports.getPredictionWithRecommendations = async (req, res) => {
  try {
    const userId = req.query.userId;
    if (!userId) {
      return res.status(400).json({ error: 'User ID is required' });
    }

    // 1) Check if we already have a prediction stored for this user (most recent).
    const latestPrediction = await Prediction.findOne({ userId })
                                            .sort({ createdAt: -1 });

    if (latestPrediction) {
      return res.json({
        prediction: latestPrediction.predictionText || latestPrediction.predictionScore, // Fall back if text was not stored
        detailedAnalysis: latestPrediction.detailedAnalysis || null,
        recommendations: latestPrediction.recommendations || [],
        contributingFactors: Object.fromEntries(latestPrediction.contributingFactors || [])
      });
    }

    // 2) If no stored prediction, fallback to generating one using latest sleep-data.
    // Retrieve the latest data for the user
    const latestData = await SleepData.findOne({ userId }).sort({ createdAt: -1 }); // Changed timestamp to createdAt
    if (!latestData) {
      return res.status(404).json({ error: 'No data found for the user' });
    }

    // Prepare data for ML service by mapping to model input format
    const mlInputData = mapSleepDataToMLInput(
      latestData.sleepPatterns || {},
      latestData.environmentalFactors || {},
      latestData.dietaryHabits || {}
    );

    // Call the ML service
    const response = await axios.post('http://localhost:5000/predict', mlInputData);
    console.log('DEBUG: ML Service Raw Response Data:', JSON.stringify(response.data, null, 2));

    // Persist the new prediction for history & quicker subsequent fetches
    try {
      const predictionDoc = new Prediction({
        userId,
        date: new Date(),
        predictionScore: response.data.normalizedScore || 0,
        predictionText: response.data.prediction,
        detailedAnalysis: response.data.detailedAnalysis,
        predictedInterruptionCount: response.data.predictedInterruptionCount || 0,
        predictedInterruptionWindows: (response.data.predictedInterruptionWindows || []).map(win => ({
          startTime: new Date(`1970-01-01T${win.startTime}:00Z`),
          endTime: new Date(`1970-01-01T${win.endTime}:00Z`),
          probability: win.probability
        })),
        contributingFactors: response.data.contributingFactors || {},
        recommendations: cleanRecommendations(response.data.recommendations),
        inputData: mlInputData
      });
      await predictionDoc.save();

    // Persist the raw data for progress reports if available
    try {
      if (typeof sleepData !== 'undefined') {
        const sleepDataDoc = new SleepData({
          userId,
          sleepPatterns: {
            weekdayBedtime: `${sleepData['Weekday Bedtime Hour'] ?? ''}:${sleepData['Weekday Bedtime Minute'] ?? ''}`,
            weekdayWakeup: `${sleepData['Weekday Wake-up Hour'] ?? ''}:${sleepData['Weekday Wake-up Minute'] ?? ''}`,
            weekendBedtime: `${sleepData['Weekend Bedtime Hour'] ?? ''}:${sleepData['Weekend Bedtime Minute'] ?? ''}`,
            weekendWakeup: `${sleepData['Weekend Wake-up Hour'] ?? ''}:${sleepData['Weekend Wake-up Minute'] ?? ''}`,
            sleepDuration: sleepData['Sleep Duration'],
            awakenings: sleepData['Awakenings During Night'],
            sleepQuality: sleepData['Rate Sleep Quality'],
            relaxedBeforeSleep: sleepData['How Relaxed Before Sleep'],
            useElectronics: sleepData['Use Electronic Devices Before Bed'],
            stressLevel: sleepData['Stress Level'] ?? sleepData['stressLevel'] ?? sleepData['Stress_Level']
          },
          dietaryHabits: (typeof dietaryData !== 'undefined') ? {
            mealsPerDay: dietaryData['No Of Meals Per Day'] ?? dietaryData['Meals Per Day'],
            meals: dietaryData.Meals || [],
            caffeineAfterNoon: dietaryData['Caffeine After Noon'],
            alcoholBeforeBed: dietaryData['Alcohol Before Bed'],
            heavyMealBeforeBed: dietaryData['Heavy Meal Before Bed'],
            waterIntake: dietaryData['Water Intake'],
            mealTimingConsistent: dietaryData['Meal Timing Consistent'],
            balancedMeals: dietaryData['Balanced Meals'],
            lateNightSnacking: dietaryData['Late Night Snacking']
          } : undefined,
          environmentalFactors: (typeof environmentalData !== 'undefined') ? {
            lightIntensity: environmentalData.lightIntensity ?? environmentalData['Light Intensity'],
            temperature: environmentalData.temperature ?? environmentalData.Temperature,
            noiseLevel: environmentalData.noiseLevel ?? environmentalData['Noise Level']
          } : undefined,
        });
        await sleepDataDoc.save();
      }
    } catch (persistErr) {
      console.error('Failed to persist SleepData:', persistErr.message);
    }

    // Generate a default schedule for today so reminders can be sent
    try {
      await generateTodaySchedule(userId.toString());
    } catch (schedErr) {
      console.error('Schedule generation failed:', schedErr.message);
    }
    } catch (persistErr) {
      console.error('Failed to persist newly generated prediction:', persistErr);
    }

    // Return the prediction and recommendations
    res.json({
      // Also persist this prediction for future quick retrieval
      prediction: response.data.prediction,
      detailedAnalysis: response.data.detailedAnalysis, // Added this line
      recommendations: cleanRecommendations(response.data.recommendations),
      contributingFactors: response.data.contributingFactors
    });
  } catch (error) {
    // Enhanced error logging
    console.error('Error in getPredictionWithRecommendations:', error); // Log the full error object
    let errorMessage = 'An unexpected error occurred.';
    if (error.message) {
      errorMessage = error.message;
    } else if (error.response && error.response.data && error.response.data.error) {
      // Attempt to get error message from Axios response
      errorMessage = error.response.data.error;
    } else if (typeof error === 'string') {
      errorMessage = error;
    }
    res.status(500).json({ error: errorMessage });
  }
};
