const { validationResult } = require('express-validator');
const Schedule = require('../models/schedule.model');

// Helper to handle validation errors
const handleValidation = (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
};

// POST /api/schedule – create a new schedule entry
exports.createSchedule = async (req, res) => {
  const validationErr = handleValidation(req, res);
  if (validationErr) return;

  try {
    const schedule = await Schedule.create(req.body);
    return res.status(201).json(schedule);
  } catch (err) {
    console.error('Error creating schedule:', err);
    return res.status(500).json({ error: 'Failed to create schedule' });
  }
};

// GET /api/schedule/:userId – fetch all schedule entries for a user
exports.getSchedulesByUser = async (req, res) => {
  try {
    const schedules = await Schedule.find({ userId: req.params.userId }).sort({ startTime: 1 });
    return res.status(200).json(schedules);
  } catch (err) {
    console.error('Error fetching schedules:', err);
    return res.status(500).json({ error: 'Failed to fetch schedules' });
  }
};

// PUT /api/schedule/:id – update a schedule entry
exports.updateSchedule = async (req, res) => {
  const validationErr = handleValidation(req, res);
  if (validationErr) return;

  try {
    // If client toggles completed, adjust color accordingly
    if (typeof req.body.completed === 'boolean') {
      req.body.color = req.body.completed ? '#F8C9E9' /* pink for done */ : '#FFF9C4' /* soft yellow for pending */;
    }
    const updated = await Schedule.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!updated) return res.status(404).json({ error: 'Schedule not found' });
    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error updating schedule:', err);
    return res.status(500).json({ error: 'Failed to update schedule' });
  }
};

// DELETE /api/schedule/:id – delete a schedule entry
exports.deleteSchedule = async (req, res) => {
  try {
    const deleted = await Schedule.findByIdAndDelete(req.params.id);
    if (!deleted) return res.status(404).json({ error: 'Schedule not found' });
    return res.status(200).json({ success: true });
  } catch (err) {
    console.error('Error deleting schedule:', err);
    return res.status(500).json({ error: 'Failed to delete schedule' });
  }
};
