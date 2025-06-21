const express = require('express');
const { auth } = require('../middleware/auth.middleware');
const predictionController = require('../controllers/prediction.controller');
const router = express.Router();

router.use(auth); // All routes require authentication

// New endpoint to retrieve predictions and recommendations
router.get('/prediction', predictionController.getPredictionWithRecommendations);

// Basic CRUD operations
router.post('/', predictionController.createPrediction);
router.get('/generate', predictionController.generatePrediction);
router.get('/latest', predictionController.getLatestPrediction);
router.get('/history', predictionController.getPredictionHistory);
router.get('/:id', predictionController.getPrediction);

// AI prediction endpoint
router.post('/predict', predictionController.predict);

// Additional routes needed by Flutter app
router.get('/user/:userId', predictionController.getPredictionsByUserId);
router.delete('/:id', predictionController.deletePrediction);
router.get('/recommendations', predictionController.getRecommendations);

module.exports = router;
