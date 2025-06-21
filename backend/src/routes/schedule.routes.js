const express = require('express');
const { auth } = require('../middleware/auth.middleware');
const { body } = require('express-validator');
const scheduleController = require('../controllers/schedule.controller');

const router = express.Router();

router.use(auth); // All endpoints require authentication

// Validation rules used for create & update
const scheduleValidation = [
  body('userId').notEmpty().withMessage('userId is required'),
  body('title').notEmpty().withMessage('title is required'),
  body('startTime').notEmpty().withMessage('startTime is required').isISO8601().withMessage('startTime must be ISO 8601 date'),
  body('endTime').optional().isISO8601().withMessage('endTime must be ISO 8601 date'),
];

router.post('/', scheduleValidation, scheduleController.createSchedule);
router.get('/:userId', scheduleController.getSchedulesByUser);
router.put('/:id', scheduleValidation, scheduleController.updateSchedule);
router.delete('/:id', scheduleController.deleteSchedule);

module.exports = router;
