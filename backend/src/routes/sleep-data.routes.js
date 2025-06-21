const express = require('express');
const { auth } = require('../middleware/auth.middleware');
const sleepDataController = require('../controllers/sleep-data.controller');
const router = express.Router();

router.use(auth); // All routes require authentication

// Basic CRUD
router.post('/', sleepDataController.createSleepData);
router.get('/', sleepDataController.getAllSleepData);
router.get('/stats', sleepDataController.getStats);
router.get('/:id', sleepDataController.getSleepData);
router.patch('/:id', sleepDataController.updateSleepData);
router.delete('/:id', sleepDataController.deleteSleepData);

// Additional routes needed by Flutter app
router.get('/latest', sleepDataController.getLatestSleepData);
router.get('/user/:userId', sleepDataController.getSleepDataByUserId);

// New endpoint to handle data submission from all screens
router.post('/submit-data', sleepDataController.submitData);

module.exports = router;
