const jwt = require('jsonwebtoken');
const User = require('../models/user.model');
const SleepData = require('../models/sleep-data.model');
const { sendPasswordResetOTP } = require('../services/email.service');
const logger = require('../utils/logger');
const path = require('path');
const { uploadProfileImage, profileImagesDir } = require('../utils/file-upload');

const formatUserResponse = (user) => {
  const userObj = user.toJSON();
  const formattedUser = {
    ...userObj,
    id: userObj._id.toString(),
    createdAt: userObj.createdAt ? userObj.createdAt.toISOString() : null,
    updatedAt: userObj.updatedAt ? userObj.updatedAt.toISOString() : null
  };
  
  // Only include dateOfBirth if it exists
  if (userObj.dateOfBirth) {
    formattedUser.dateOfBirth = userObj.dateOfBirth.toISOString();
  }
  
  return formattedUser;
};

const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN
  });
};

exports.register = async (req, res) => {
  try {
    console.log('Registration request body:', req.body);
    
    // Validate required fields
    if (!req.body.name || !req.body.email || !req.body.password) {
      console.error('Missing required fields');
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['name', 'email', 'password'],
        received: Object.keys(req.body)
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({ email: req.body.email });
    if (existingUser) {
      console.error('Email already registered:', req.body.email);
      return res.status(400).json({
        error: 'Email already registered'
      });
    }

    // Create user with only required fields
    const user = new User({
      name: req.body.name,
      email: req.body.email,
      password: req.body.password,
      // Additional fields will be null by default
    });
    
    // Log validation errors if any
    const validationError = user.validateSync();
    if (validationError) {
      console.error('Validation error:', validationError);
      return res.status(400).json({
        error: 'Validation error',
        details: Object.values(validationError.errors).map(err => ({
          field: err.path,
          message: err.message,
          value: err.value
        }))
      });
    }

    await user.save();
    console.log('User registered successfully:', { id: user._id, email: user.email });
    
    const token = generateToken(user._id);
    res.status(201).json({ 
      user: formatUserResponse(user), 
      token 
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(400).json({
      error: 'Registration failed',
      message: error.message,
      details: error.errors ? Object.values(error.errors).map(err => ({
        field: err.path,
        message: err.message,
        value: err.value
      })) : undefined
    });
  }
};

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });

    if (!user || !(await user.comparePassword(password))) {
      throw new Error('Invalid login credentials');
    }

    const token = generateToken(user._id);
    res.json({ 
      user: formatUserResponse(user), 
      token 
    });
  } catch (error) {
    res.status(401).json({ error: error.message });
  }
};

exports.getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    res.json(formatUserResponse(user));
  } catch (error) {
    console.error('Error getting user profile:', error);
    res.status(500).json({ error: 'Internal server error while fetching stats' });
  }
};

// Helper function to get nested property value
const getNestedValue = (obj, path) => {
  if (!path) return undefined;
  return path.split('.').reduce((acc, part) => acc && acc[part], obj);
};

// Helper function to calculate average for a numeric factor
const calculateNumericAverage = (dataEntries, path) => {
  let sum = 0;
  let count = 0;
  for (const entry of dataEntries) {
    const value = getNestedValue(entry, path);
    if (typeof value === 'number' && !isNaN(value)) {
      sum += value;
      count++;
    }
  }
  return count > 0 ? sum / count : null;
};

// Helper function to calculate frequency for a boolean factor
const calculateBooleanFrequency = (dataEntries, path) => {
  let trueCount = 0;
  let validCount = 0;
  for (const entry of dataEntries) {
    const value = getNestedValue(entry, path);
    if (typeof value === 'boolean') {
      if (value === true) {
        trueCount++;
      }
      validCount++;
    }
  }
  return validCount > 0 ? trueCount / validCount : null;
};

exports.getUserProgressReport = async (req, res) => {
  try {
    logger.info('User progress report requested');
    const userId = req.user?._id;

    if (!userId) {
      logger.error('User ID not found for progress report.');
      return res.status(401).json({ error: 'Unauthorized: User ID not found.' });
    }

    logger.info(`Fetching progress report for userId: ${userId}`);

    const sleepDataEntries = await SleepData.find({ userId })
      .sort({ createdAt: -1 })
      .limit(14); // Fetch last 14 days to compare two 7-day periods if possible, or split a 7-day period

    if (sleepDataEntries.length < 4) { // Need at least 2 data points for each period
      logger.info(`Not enough data for user ${userId} to generate progress report. Found ${sleepDataEntries.length} entries.`);
      return res.status(200).json([]); // Return empty array or a specific message
    }

    // Split data: for simplicity, compare the first half of available data with the second half
    // More robust: compare last 7 days with previous 7 days if 14 days available.
    // For now, if 4-14 days, split into two halves.
    const midPoint = Math.floor(sleepDataEntries.length / 2);
    const previousPeriodData = sleepDataEntries.slice(midPoint).reverse(); // Older data, reversed to be chronological for averaging if needed
    const currentPeriodData = sleepDataEntries.slice(0, midPoint).reverse(); // Newer data, reversed
    
    if (previousPeriodData.length === 0 || currentPeriodData.length === 0) {
        logger.info(`Cannot split data into two periods for user ${userId}. Prev: ${previousPeriodData.length}, Curr: ${currentPeriodData.length}`);
        return res.status(200).json([]);
    }

    const factorsToAnalyze = [
      { name: 'Sleep Duration', path: 'sleepPatterns.sleepDuration', unit: 'hrs', type: 'numeric', higherIsBetter: true },
      { name: 'Night Awakenings', path: 'sleepPatterns.awakenings', unit: 'times', type: 'numeric', higherIsBetter: false },
      { name: 'Stress Level', path: 'sleepPatterns.stressLevel', unit: '', type: 'numeric', higherIsBetter: false },
      { name: 'Noise Level', path: 'environmentalFactors.noiseLevel', unit: 'dB', type: 'numeric', higherIsBetter: false },
      { name: 'Sleep Quality', path: 'sleepPatterns.sleepQuality', unit: '/5', type: 'numeric', higherIsBetter: true }, 
      { name: 'Electronics Before Bed', path: 'sleepPatterns.useElectronics', unit: '% use', type: 'boolean', higherIsBetter: false },
      { name: 'Caffeine After Noon', path: 'dietaryHabits.caffeineAfterNoon', unit: '% use', type: 'boolean', higherIsBetter: false },
      { name: 'Room Temperature', path: 'environmentalFactors.temperature', unit: '°C', type: 'numeric', targetValue: 20 },
    ];

    const progressReport = [];

    for (const factor of factorsToAnalyze) {
      let avgPrevious, avgCurrent;
      let status = 'No Change';
      let changeText = 'Data maintained.';

      if (factor.type === 'numeric') {
        avgPrevious = calculateNumericAverage(previousPeriodData, factor.path);
        avgCurrent = calculateNumericAverage(currentPeriodData, factor.path);

        if (avgPrevious !== null && avgCurrent !== null) {
          const diff = avgCurrent - avgPrevious;
          const roundedDiff = Math.abs(parseFloat(diff.toFixed(1)));
          const roundedCurrent = parseFloat(avgCurrent.toFixed(1));

          if (factor.targetValue !== undefined) { // Target-based comparison (e.g., temperature)
            const diffToTargetPrev = Math.abs(avgPrevious - factor.targetValue);
            const diffToTargetCurr = Math.abs(avgCurrent - factor.targetValue);
            if (diffToTargetCurr < diffToTargetPrev) status = 'Improved';
            else if (diffToTargetCurr > diffToTargetPrev) status = 'Worsened';
            changeText = `Now ${roundedCurrent}${factor.unit} (Target: ${factor.targetValue}${factor.unit}).`;
            if (status !== 'No Change') {
                changeText = `${status === 'Improved' ? 'Closer to' : 'Further from'} target. Now ${roundedCurrent}${factor.unit}.`;
            }
          } else if (factor.higherIsBetter) {
            if (diff > 0.05) status = 'Improved'; // Using a small threshold to avoid tiny changes being 'Improved'
            else if (diff < -0.05) status = 'Worsened';
          } else { // lowerIsBetter
            if (diff < -0.05) status = 'Improved';
            else if (diff > 0.05) status = 'Worsened';
          }

          if (status !== 'No Change') {
             changeText = `${status} by ${roundedDiff}${factor.unit}. Now ${roundedCurrent}${factor.unit}.`;
          } else {
             changeText = `Maintained at ${roundedCurrent}${factor.unit}.`;
          }
        } else {
            changeText = 'Insufficient data for comparison.';
        }
      } else if (factor.type === 'boolean') {
        avgPrevious = calculateBooleanFrequency(previousPeriodData, factor.path);
        avgCurrent = calculateBooleanFrequency(currentPeriodData, factor.path);

        if (avgPrevious !== null && avgCurrent !== null) {
          const diff = avgCurrent - avgPrevious;
          const currentFreqPercent = parseFloat((avgCurrent * 100).toFixed(0));
          
          if (factor.higherIsBetter) { // True is better
            if (diff > 0.05) status = 'Improved'; 
            else if (diff < -0.05) status = 'Worsened';
          } else { // False is better
            if (diff < -0.05) status = 'Improved';
            else if (diff > 0.05) status = 'Worsened';
          }
          changeText = `${currentFreqPercent}% occurrence.`;
          if (status !== 'No Change') {
            const prevFreqPercent = parseFloat((avgPrevious * 100).toFixed(0));
            changeText = `${status}. From ${prevFreqPercent}% to ${currentFreqPercent}% occurrence.`;
          }
        } else {
            changeText = 'Insufficient data for comparison.';
        }
      }
      
      let factorDisplayName = factor.name;
      if (factor.type === 'numeric' && avgCurrent !== null) {
        factorDisplayName = `${factor.name} (${parseFloat(avgCurrent.toFixed(1))}${factor.unit})`;
      } else if (factor.type === 'boolean' && avgCurrent !== null) {
        factorDisplayName = `${factor.name} (${parseFloat((avgCurrent * 100).toFixed(0))}%)`;
      }

      progressReport.push({
        factorName: factorDisplayName,
        status: status,
        change: changeText
      });
    }

    res.status(200).json(progressReport);

  } catch (error) {
    logger.error('Error fetching user progress report:', error);
    console.error('Detailed error in getUserProgressReport:', error); // For more detailed logs during dev
    res.status(500).json({ error: 'Internal server error while fetching progress report' });
  }
};

exports.updateProfile = async (req, res) => {
  const updates = Object.keys(req.body);
  const allowedUpdates = ['name', 'email', 'password', 'dateOfBirth', 'gender', 
                         'weight', 'height', 'healthConditions', 'profileImageUrl'];
  
  const isValidOperation = updates.every(update => allowedUpdates.includes(update));

  if (!isValidOperation) {
    return res.status(400).json({ error: 'Invalid updates' });
  }

  try {
    updates.forEach(update => req.user[update] = req.body[update]);
    await req.user.save();
    res.json(req.user);
  } catch (error) {
    res.status(400).json({ error: error.message });
  }
};

exports.deleteAccount = async (req, res) => {
  try {
    await req.user.remove();
    res.json({ message: 'Account deleted successfully' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

exports.forgotPassword = async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) {
      return res.status(400).json({ error: 'Email is required' });
    }

    logger.info(`Password reset requested for email: ${email}`);
    
    // Check if user exists
    const user = await User.findOne({ email });
    if (!user) {
      logger.warn(`Password reset attempt for non-existent email: ${email}`);
      return res.status(404).json({ 
        success: false,
        message: 'No account found with this email address.'
      });
    }

    // Generate a random 4-digit OTP
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    
    // Store OTP with expiry (15 minutes)
    user.resetPasswordOTP = otp;
    user.resetPasswordExpires = Date.now() + 15 * 60 * 1000; // 15 minutes
    
    try {
      // Save user with new OTP
      await user.save();
      
      logger.info(`Saving OTP for user ${email}: ${otp}`);
      
      // Send OTP via email
      try {
        await sendPasswordResetOTP(email, otp);
        logger.info(`Password reset OTP sent to ${email}`);
        
        // Return success response
        return res.status(200).json({ 
          success: true,
          message: 'If an account exists with this email, you will receive an OTP shortly.'
        });
        
      } catch (emailError) {
        logger.error('Failed to send password reset email:', emailError);
        return res.status(500).json({ 
          success: false,
          message: 'Failed to send password reset email. Please try again later.'
        });
      }
      
    } catch (error) {
      logger.error('Failed to process password reset:', error);
      return res.status(500).json({ 
        success: false,
        message: 'An error occurred while processing your request.'
      });
    }
  } catch (error) {
    logger.error('Unexpected error in forgotPassword:', error);
    res.status(500).json({ 
      success: false,
      error: 'An unexpected error occurred. Please try again later.'
    });
  }
};

exports.verifyOTP = async (req, res) => {
  try {
    const { email, otp } = req.body;
    
    if (!email || !otp) {
      logger.warn('Missing email or OTP in request');
      return res.status(400).json({ 
        success: false,
        error: 'Email and OTP are required' 
      });
    }

    logger.info(`Verifying OTP for email: ${email}`);
    
    // Find user by email first
    const user = await User.findOne({ email });
    
    if (!user) {
      logger.warn(`No user found with email: ${email}`);
      return res.status(200).json({ 
        success: false,
        error: 'If an account exists with this email, you will receive an OTP shortly.' 
      });
    }
    
    // Check if OTP matches and is not expired
    if (user.resetPasswordOTP !== otp || user.resetPasswordExpires < Date.now()) {
      logger.warn(`Invalid or expired OTP for email: ${email}`);
      return res.status(200).json({ 
        success: false,
        error: 'Invalid or expired OTP' 
      });
    }

    // Generate a temporary token for password reset
    const resetToken = jwt.sign(
      { 
        userId: user._id, 
        email: user.email, // Include email for additional verification
        purpose: 'reset_password' 
      },
      process.env.JWT_SECRET,
      { expiresIn: '15m' }
    );

    logger.info(`OTP verified successfully for user: ${user._id}`);
    
    res.status(200).json({ 
      success: true,
      message: 'OTP verified successfully',
      resetToken
    });
  } catch (error) {
    console.error('OTP verification error:', error);
    res.status(500).json({ error: 'Failed to verify OTP' });
  }
};

exports.resetPassword = async (req, res) => {
  try {
    const { email, resetToken, newPassword } = req.body;
    
    if (!newPassword) {
      return res.status(400).json({ 
        success: false,
        error: 'New password is required' 
      });
    }

    if (!resetToken) {
      return res.status(400).json({ 
        success: false,
        error: 'Reset token is required' 
      });
    }

    // Verify the reset token
    let decoded;
    try {
      decoded = jwt.verify(resetToken, process.env.JWT_SECRET);
      
      // Check if token was issued for password reset
      if (decoded.purpose !== 'reset_password') {
        logger.warn('Invalid token purpose for password reset');
        return res.status(400).json({ 
          success: false,
          error: 'Invalid token' 
        });
      }
    } catch (err) {
      logger.warn('Invalid or expired reset token', { error: err.message });
      return res.status(400).json({ 
        success: false,
        error: 'Invalid or expired reset token. Please request a new OTP.' 
      });
    }

    // Find user by ID from token
    const user = await User.findById(decoded.userId);
    if (!user) {
      logger.warn(`User not found for password reset: ${decoded.userId}`);
      return res.status(404).json({ 
        success: false,
        error: 'User not found' 
      });
    }

    // Optional: Verify email matches if provided
    if (email && user.email !== email) {
      logger.warn(`Email mismatch during password reset for user: ${user._id}`);
      return res.status(400).json({ 
        success: false,
        error: 'Invalid request' 
      });
    }

    try {
      // Update password and clear reset fields
      user.password = newPassword;
      user.resetPasswordOTP = undefined;
      user.resetPasswordExpires = undefined;
      await user.save();
      
      logger.info(`Password reset successful for user: ${user._id}`);
      
      res.status(200).json({ 
        success: true,
        message: 'Password reset successful' 
      });
    } catch (saveError) {
      logger.error('Error saving new password', { error: saveError.message, userId: user._id });
      throw saveError; // Will be caught by the outer catch block
    }
  } catch (error) {
    logger.error('Password reset error', { 
      error: error.message,
      stack: error.stack 
    });
    res.status(500).json({ 
      success: false,
      error: 'An error occurred while resetting your password. Please try again.' 
    });
  }
};

exports.refreshToken = async (req, res) => {
  try {
    // The auth middleware will have already verified the token and added the user to req
    const token = generateToken(req.user._id);
    const user = await User.findById(req.user._id);
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }
    
    res.json({ 
      user: formatUserResponse(user),
      token 
    });
  } catch (error) {
    console.error('Error refreshing token:', error);
    res.status(500).json({ error: 'Failed to refresh token' });
  }
};

exports.uploadProfileImage = (req, res) => {
  console.log('Profile image upload request received');
  uploadProfileImage(req, res, async (err) => {
    if (err) {
      console.error('Image upload error:', err.message);
      return res.status(400).json({ 
        error: 'Image upload failed', 
        message: err.message 
      });
    }
    
    if (!req.file) {
      console.error('No file uploaded');
      return res.status(400).json({ 
        error: 'Please select an image to upload' 
      });
    }
    
    try {
      console.log('File uploaded successfully:', req.file.path);
      // Create the URL for the uploaded image
      const baseUrl = `${req.protocol}://${req.get('host')}`;
      const relativePath = `/uploads/profile-images/${path.basename(req.file.path)}`;
      const imageUrl = baseUrl + relativePath;
      
      console.log('Image URL:', imageUrl);
      // Update user's profile image URL
      req.user.profileImageUrl = imageUrl;
      await req.user.save();
      
      // Return updated user
      res.json(formatUserResponse(req.user));
    } catch (error) {
      console.error('Failed to update profile image:', error);
      res.status(500).json({ 
        error: 'Failed to update profile image', 
        message: error.message 
      });
    }
  });
};

exports.getUserStats = async (req, res) => {
  try {
    const userId = req.user._id;
    
    // Import models only when needed to avoid circular dependencies
    const SleepData = require('../models/sleep-data.model');
    const Prediction = require('../models/prediction.model');
    
    // Get sleep data statistics
    const sleepDataCount = await SleepData.countDocuments({ userId });
    const sleepDataStats = await SleepData.aggregate([
      { $match: { userId: userId.toString() } },
      { $group: {
          _id: null,
          averageDuration: { $avg: '$sleepDuration' },
          averageQuality: { $avg: '$sleepQuality' },
          totalEntries: { $sum: 1 }
        }
      }
    ]);
    
    // Get prediction statistics
    const predictionCount = await Prediction.countDocuments({ userId });
    const predictionStats = await Prediction.aggregate([
      { $match: { userId: userId.toString() } },
      { $group: {
          _id: null,
          averageScore: { $avg: '$predictionScore' },
          totalEntries: { $sum: 1 }
        }
      }
    ]);
    
    // Format response
    const stats = {
      sleepData: {
        count: sleepDataCount,
        averageDuration: sleepDataStats.length > 0 ? Math.round(sleepDataStats[0].averageDuration) : 0,
        averageQuality: sleepDataStats.length > 0 ? parseFloat(sleepDataStats[0].averageQuality.toFixed(1)) : 0
      },
      predictions: {
        count: predictionCount,
        averageScore: predictionStats.length > 0 ? parseFloat(predictionStats[0].averageScore.toFixed(2)) : 0
      }
    };
    
    res.status(200).json(stats);
  } catch (error) {
    console.error('Error getting user stats:', error);
    res.status(500).json({ error: 'Failed to retrieve user statistics' });
  }
};
