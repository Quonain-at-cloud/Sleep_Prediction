const SleepData = require('../models/sleep-data.model');

exports.createSleepData = async (req, res) => {
  try {
    const sleepData = new SleepData({
      ...req.body,
      userId: req.user._id
    });
    await sleepData.save();
    res.status(201).json(sleepData);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.getSleepData = async (req, res) => {
  try {
    const sleepData = await SleepData.findOne({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!sleepData) {
      return res.status(404).json({ error: 'Sleep data not found' });
    }

    res.json(sleepData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getAllSleepData = async (req, res) => {
  try {
    const match = { userId: req.user._id };
    const sort = { date: -1 };

    // Date range filter
    if (req.query.startDate && req.query.endDate) {
      match.date = {
        $gte: new Date(req.query.startDate),
        $lte: new Date(req.query.endDate)
      };
    }

    const sleepData = await SleepData.find(match)
      .sort(sort)
      .limit(parseInt(req.query.limit) || 10)
      .skip(parseInt(req.query.skip) || 0);

    res.json(sleepData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.updateSleepData = async (req, res) => {
  const updates = Object.keys(req.body);
  const allowedUpdates = [
    'date', 'bedTime', 'wakeUpTime', 'sleepDuration',
    'timeToFallAsleep', 'interruptionCount', 'interruptionTimes',
    'sleepQuality', 'notes', 'environmentalData', 'dietaryData'
  ];

  const isValidOperation = updates.every(update => allowedUpdates.includes(update));

  if (!isValidOperation) {
    return res.status(400).json({ error: 'Invalid updates' });
  }

  try {
    const sleepData = await SleepData.findOne({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!sleepData) {
      return res.status(404).json({ error: 'Sleep data not found' });
    }

    updates.forEach(update => sleepData[update] = req.body[update]);
    await sleepData.save();
    res.json(sleepData);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteSleepData = async (req, res) => {
  try {
    const sleepData = await SleepData.findOneAndDelete({
      _id: req.params.id,
      userId: req.user._id
    });

    if (!sleepData) {
      return res.status(404).json({ error: 'Sleep data not found' });
    }

    res.json({ message: 'Sleep data deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getStats = async (req, res) => {
  try {
    const startDate = new Date(req.query.startDate || new Date().setDate(new Date().getDate() - 30));
    const endDate = new Date(req.query.endDate || new Date());

    const stats = await SleepData.aggregate([
      {
        $match: {
          userId: req.user._id,
          date: { $gte: startDate, $lte: endDate }
        }
      },
      {
        $group: {
          _id: null,
          avgSleepDuration: { $avg: '$sleepDuration' },
          avgSleepQuality: { $avg: '$sleepQuality' },
          avgTimeToFallAsleep: { $avg: '$timeToFallAsleep' },
          totalInterruptions: { $sum: '$interruptionCount' },
          count: { $sum: 1 }
        }
      }
    ]);

    res.json(stats[0] || {});
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getLatestSleepData = async (req, res) => {
  try {
    const latestSleepData = await SleepData.findOne({
      userId: req.user._id
    }).sort({ date: -1 });

    if (!latestSleepData) {
      return res.status(404).json({ error: 'No sleep data found' });
    }

    res.json(latestSleepData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.getSleepDataByUserId = async (req, res) => {
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

    const sleepData = await SleepData.find(match)
      .sort(sort)
      .limit(parseInt(req.query.limit) || 10)
      .skip(parseInt(req.query.skip) || 0);

    res.json(sleepData);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.submitData = async (req, res) => {
  try {
    const { sleepPatterns, profileInfo, dietaryHabits, environmentalFactors } = req.body;
    const userId = req.user._id;

    // Create a new document combining all data
    const newData = new SleepData({
      userId,
      sleepPatterns,
      profileInfo,
      dietaryHabits,
      environmentalFactors,
      timestamp: new Date()
    });

    await newData.save();
    res.status(201).json({ message: 'Data submitted successfully', data: newData });
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};
