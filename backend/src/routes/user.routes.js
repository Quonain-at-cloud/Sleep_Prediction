const express = require('express');
const { auth } = require('../middleware/auth.middleware');
const userController = require('../controllers/user.controller');
const router = express.Router();

// Public routes
router.post('/register', userController.register);
router.post('/login', userController.login);
router.post('/forgot-password', userController.forgotPassword);
router.post('/verify-otp', userController.verifyOTP);
router.post('/reset-password', userController.resetPassword);

// Protected routes
router.post('/refresh-token', auth, userController.refreshToken);
router.get('/profile', auth, userController.getProfile);
router.patch('/profile', auth, userController.updateProfile);
router.post('/profile/image', auth, userController.uploadProfileImage);
router.delete('/account', auth, userController.deleteAccount);
router.get('/stats', auth, userController.getUserStats);
router.get('/progress-report', auth, userController.getUserProgressReport);

module.exports = router;
