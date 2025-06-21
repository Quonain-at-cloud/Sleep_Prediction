const axios = require('axios');
const logger = require('../utils/logger');

// Use localhost for local development
const ML_SERVICE_URL = process.env.ML_SERVICE_URL || 'http://localhost:5000';

class PredictionService {
  async makePrediction(data) {
    try {
      logger.info('Making prediction request to ML service:', { data });
      
      // Check if ML service is available
      try {
        await axios.get(`${ML_SERVICE_URL}/health`);
      } catch (error) {
        logger.error('ML service health check failed:', error.message);
        throw new Error('ML service is not available');
      }

      // Make prediction request
      const response = await axios.post(`${ML_SERVICE_URL}/predict`, data, {
        timeout: 30000,
        headers: {
          'Content-Type': 'application/json'
        }
      });

      logger.info('Received prediction from ML service:', response.data);
      return response.data;

    } catch (error) {
      logger.error('Error making prediction:', error.message);
      if (error.response) {
        // The request was made and the server responded with a status code
        // that falls out of the range of 2xx
        logger.error('ML service error response:', {
          status: error.response.status,
          data: error.response.data
        });
        throw new Error(error.response.data.error || 'ML service error');
      } else if (error.request) {
        // The request was made but no response was received
        logger.error('No response from ML service');
        throw new Error('ML service is not responding');
      } else {
        // Something happened in setting up the request
        throw new Error(`Error setting up prediction request: ${error.message}`);
      }
    }
  }

  // Validate input data before sending to ML service
  validatePredictionData(data) {
    const requiredFields = [
      'age',
      'gender',
      'sleepDuration',
      'physicalActivityLevel',
      'heartRate',
      'dailySteps',
      'stressLevel',
      'bmiCategory'
    ];

    const missingFields = requiredFields.filter(field => !(field in data));
    if (missingFields.length > 0) {
      throw new Error(`Missing required fields: ${missingFields.join(', ')}`);
    }

    return true;
  }
}

module.exports = new PredictionService();
