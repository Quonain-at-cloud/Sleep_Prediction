const nodemailer = require('nodemailer');
const logger = require('../utils/logger');

// Email configuration validation
const validateEmailConfig = () => {
  // In development with mock emails, skip validation
  if (process.env.NODE_ENV === 'development' && process.env.MOCK_EMAIL === 'true') {
    return;
  }

  const requiredVars = ['EMAIL_USER', 'EMAIL_APP_PASSWORD', 'EMAIL_SERVICE'];
  const missing = requiredVars.filter(key => !process.env[key]);
  
  if (missing.length > 0) {
    throw new Error(`Missing required email configuration: ${missing.join(', ')}`);
  }
};

// Create transporter based on environment
let transporter;

if (process.env.NODE_ENV === 'development' && process.env.MOCK_EMAIL === 'true') {
  // In development with mock emails enabled, log to console
  transporter = {
    sendMail: async (mailOptions) => {
      logger.info('Email would be sent in production:');
      logger.info(`To: ${mailOptions.to}`);
      logger.info(`Subject: ${mailOptions.subject}`);
      logger.info('Body:', mailOptions.html || mailOptions.text);
      return { messageId: 'test-message-id' };
    }
  };
} else {
  // Validate email configuration
  validateEmailConfig();
  
    logger.info('Initializing email service with config:', {
    service: process.env.EMAIL_SERVICE,
    user: process.env.EMAIL_USER,
    mock: process.env.MOCK_EMAIL
  });

  // Create real email transporter with Gmail SMTP settings
  transporter = nodemailer.createTransport({
    host: 'smtp.gmail.com',
    port: 465,
    secure: true, // true for 465, false for other ports
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_APP_PASSWORD,
    },
    // Add debug logging
    debug: true,
    logger: true
  });
}

// Verify transporter connection
const verifyTransporter = async () => {
  if (process.env.MOCK_EMAIL !== 'true') {
    try {
      await transporter.verify();
      logger.info('Email service connection verified successfully');
    } catch (error) {
      logger.error('Email service connection failed:', error);
      throw new Error('Failed to connect to email service');
    }
  } else {
    logger.info('Email service in mock mode - skipping verification');
  }
};

// Initialize email service
const initializeEmailService = async () => {
  await verifyTransporter();
};

/**
 * Send password reset OTP email
 * @param {string} to - Recipient email address
 * @param {string} otp - The OTP to send
 * @returns {Promise<boolean>} - True if email was sent successfully
 */
const sendPasswordResetOTP = async (to, otp) => {
  logger.info(`Attempting to send OTP to: ${to}`);
  try {
    const mailOptions = {
      from: `"SleepMate" <${process.env.EMAIL_USER}>`,
      to,
      subject: '🔑 Password Reset OTP - SleepMate',
      html: `
        <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; color: #333; border-radius: 10px; overflow: hidden; box-shadow: 0 4px 8px rgba(0,0,0,0.1);">
          <!-- Header with Logo -->
          <div style="background: linear-gradient(135deg, #352F44 0%, #2A2438 100%); padding: 30px 20px; text-align: center;">
            <img src="https://i.imgur.com/QpUQjJR.png" alt="SleepMate Logo" style="width: 80px; height: auto; margin-bottom: 10px;">
            <h1 style="color: #fff; margin: 0; font-weight: 500; font-size: 28px;">SleepMate</h1>
            <p style="color: #B9B4C7; margin: 5px 0 0 0; font-size: 14px;">Your Sleep Prediction Partner</p>
          </div>
          
          <!-- Main Content -->
          <div style="background-color: #fff; padding: 30px; border-radius: 0 0 10px 10px;">
            <h2 style="color: #352F44; margin-top: 0; font-weight: 600; text-align: center;">Verification Code</h2>
            <p style="color: #5C5470; font-size: 16px; line-height: 1.5; margin-bottom: 20px; text-align: center;">We received a request to reset your password. Use the verification code below to complete the process:</p>
            
            <!-- OTP Box -->
            <div style="background: linear-gradient(to right, #F4F2F7, #EAE7F1); padding: 20px; margin: 25px auto; text-align: center; font-size: 32px; letter-spacing: 8px; color: #352F44; font-weight: bold; border-radius: 10px; max-width: 280px; border: 1px dashed #B9B4C7;">
              ${otp}
            </div>
            
            <!-- Instructions -->
            <div style="background-color: #F8F7FA; border-left: 4px solid #5C5470; padding: 15px; margin: 20px 0; border-radius: 4px;">
              <p style="margin: 0; color: #5C5470; font-size: 14px;">• This code will expire in <strong>15 minutes</strong></p>
              <p style="margin: 8px 0 0 0; color: #5C5470; font-size: 14px;">• If you didn't request this code, you can safely ignore this email</p>
            </div>
            
            <p style="color: #5C5470; font-size: 16px; line-height: 1.5; margin: 25px 0 15px 0; text-align: center;">Need help? Contact our support team at <a href="mailto:support@sleepmate.com" style="color: #5C5470; text-decoration: underline;">support@sleepmate.com</a></p>
            
            <!-- Button -->
            <div style="text-align: center; margin: 30px 0;">
              <a href="#" style="background-color: #352F44; color: white; padding: 12px 30px; text-decoration: none; border-radius: 50px; font-weight: 500; display: inline-block; font-size: 16px; transition: background-color 0.3s;">Back to SleepMate</a>
            </div>
            
            <!-- Footer -->
            <div style="margin-top: 30px; padding-top: 20px; border-top: 1px solid #EAE7F1; font-size: 12px; color: #B9B4C7; text-align: center;">
              <p>This is an automated message, please do not reply directly to this email.</p>
              <div style="margin: 15px 0;">
                <a href="#" style="color: #5C5470; margin: 0 10px; text-decoration: none;">Privacy Policy</a>
                <a href="#" style="color: #5C5470; margin: 0 10px; text-decoration: none;">Terms of Service</a>
                <a href="#" style="color: #5C5470; margin: 0 10px; text-decoration: none;">Contact Us</a>
              </div>
              <p style="margin-top: 15px;">© ${new Date().getFullYear()} SleepMate. All rights reserved.</p>
            </div>
          </div>
        </div>
      `,
    };

    logger.info('Sending email with options:', {
      from: mailOptions.from,
      to: mailOptions.to,
      subject: mailOptions.subject
    });
    
    const info = await transporter.sendMail(mailOptions);
    logger.info(`Password reset OTP sent to ${to}`, { 
      messageId: info.messageId,
      response: info.response 
    });
    return true;
  } catch (error) {
    logger.error('Error sending password reset email:', error);
    throw new Error('Failed to send password reset email. Please try again later.');
  }
};

module.exports = {
  sendPasswordResetOTP,
  initializeEmailService,
};
