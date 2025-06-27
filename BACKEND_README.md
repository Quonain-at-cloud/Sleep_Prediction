# SleepMate Backend API

A comprehensive Node.js backend for the SleepMate sleep prediction application, providing RESTful APIs for user management, sleep data collection, ML predictions, notifications, and scheduling.

## 📁 Project Structure

```
backend/
├── src/
│   ├── config/
│   │   ├── db.js                 # MongoDB connection configuration
│   │   └── email.js              # Email service configuration
│   ├── controllers/
│   │   ├── user.controller.js    # User authentication & profile management
│   │   ├── prediction.controller.js # ML prediction & recommendations
│   │   ├── sleep-data.controller.js # Sleep data CRUD operations
│   │   ├── notification.controller.js # Notification management
│   │   └── schedule.controller.js # Schedule management
│   ├── middleware/
│   │   ├── auth.middleware.js    # JWT authentication middleware
│   │   └── validation.middleware.js # Request validation
│   ├── models/
│   │   ├── User.js               # User data model
│   │   ├── SleepData.js          # Sleep data model
│   │   ├── Prediction.js         # Prediction results model
│   │   ├── Notification.js       # Notification model
│   │   └── Schedule.js           # Schedule model
│   ├── routes/
│   │   ├── user.routes.js        # User authentication routes
│   │   ├── prediction.routes.js  # Prediction API routes
│   │   ├── sleep-data.routes.js  # Sleep data routes
│   │   ├── notification.routes.js # Notification routes
│   │   └── schedule.routes.js    # Schedule routes
│   ├── services/
│   │   ├── email.service.js      # Email sending service
│   │   └── ml.service.js         # Machine learning integration
│   ├── utils/
│   │   ├── socket.js             # WebSocket configuration
│   │   ├── schedule-reminder.js  # Cron jobs for notifications
│   │   └── logger.js             # Logging utility
│   └── index.js                  # Main server entry point
├── uploads/
│   └── profile-images/           # User profile images storage
├── logs/                         # Application logs
├── package.json                  # Dependencies & scripts
├── package-lock.json             # Locked dependencies
├── ml_service.zip               # ML model file
├── API_DOCUMENTATION.md         # Detailed API documentation
├── postman_collection.json      # Postman API collection
└── README.md                    # This file
```

## 🚀 Quick Start

### Prerequisites
- Node.js (v16 or higher)
- MongoDB (v5 or higher)
- npm or yarn

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sleep_prediction/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Setup**
   Create a `.env` file in the backend directory:
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # Database
   MONGODB_URI=mongodb://localhost:27017/sleepmate
   
   # JWT Configuration
   JWT_SECRET=your_jwt_secret_key_here
   JWT_EXPIRES_IN=7d
   
   # Email Configuration (for password reset)
   EMAIL_HOST=smtp.gmail.com
   EMAIL_PORT=587
   EMAIL_USER=your_email@gmail.com
   EMAIL_PASS=your_app_password
   
   # ML Service Configuration
   ML_SERVICE_URL=http://localhost:5000
   
   # File Upload
   MAX_FILE_SIZE=5242880
   UPLOAD_PATH=./uploads
   ```

4. **Start the server**
   ```bash
   # Development mode with auto-restart
   npm run dev
   
   # Production mode
   npm start
   ```

5. **Verify installation**
   ```bash
   curl http://localhost:3000/api/health
   # Expected response: {"status":"ok","timestamp":"..."}
   ```

## 🔧 Configuration

### Base URL Configuration
The backend runs on `http://localhost:3000` by default. To change the base URL:

1. **Update environment variable:**
   ```env
   PORT=3000  # Change this to your desired port
   ```

2. **Update frontend configuration:**
   In `lib/config/api_config.dart`, update the base URLs:
   ```dart
   static const String localhostUrl = 'http://localhost:3000/api';
   static const String deviceBaseUrl = 'http://YOUR_IP:3000/api';
   ```

### Database Configuration
- **Local MongoDB:** `mongodb://localhost:27017/sleepmate`
- **MongoDB Atlas:** `mongodb+srv://username:password@cluster.mongodb.net/sleepmate`
- **Docker MongoDB:** `mongodb://mongo:27017/sleepmate`

### Email Configuration
For password reset functionality, configure SMTP settings:
```env
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password  # Use app-specific password
```

## 📡 API Endpoints

### Base URL
```
http://localhost:3000/api
```

### Authentication Endpoints

#### 1. User Registration
```http
POST /users/register
Content-Type: application/json

{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "password123",
  "age": 25,
  "gender": "male"
}
```

#### 2. User Login
```http
POST /users/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "user_id",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

#### 3. Forgot Password
```http
POST /users/forgot-password
Content-Type: application/json

{
  "email": "john@example.com"
}
```

#### 4. Verify OTP
```http
POST /users/verify-otp
Content-Type: application/json

{
  "email": "john@example.com",
  "otp": "123456"
}
```

#### 5. Reset Password
```http
POST /users/reset-password
Content-Type: application/json

{
  "email": "john@example.com",
  "otp": "123456",
  "newPassword": "newpassword123"
}
```

### User Profile Endpoints

#### 1. Get Profile
```http
GET /users/profile
Authorization: Bearer <token>
```

#### 2. Update Profile
```http
PATCH /users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "John Smith",
  "age": 26,
  "gender": "male"
}
```

#### 3. Upload Profile Image
```http
POST /users/profile/image
Authorization: Bearer <token>
Content-Type: multipart/form-data

{
  "image": <file>
}
```

### Sleep Data Endpoints

#### 1. Submit Sleep Data
```http
POST /sleep-data/submit-data
Authorization: Bearer <token>
Content-Type: application/json

{
  "sleepDuration": 7.5,
  "sleepLatency": 15,
  "stressLevel": 3,
  "userProfile": {
    "age": 25,
    "gender": "male",
    "bmi": 24.5
  },
  "activities": {
    "exerciseMinutes": 30,
    "dailySteps": 8000,
    "caffeineIntake": 200,
    "screenTimeMinutes": 120
  },
  "environmentalData": {
    "temperature": 24,
    "lightIntensity": 250,
    "soundExposure": "Moderate"
  },
  "dietaryData": {
    "isBreakfastRegular": true,
    "isLunchRegular": true,
    "isDinnerRegular": false,
    "selectedBreakfastFoodTypes": ["Carbohydrates", "Proteins"],
    "selectedLunchFoodTypes": ["Proteins", "Vegetables"],
    "selectedDinnerFoodTypes": ["Carbohydrates", "Fats"]
  }
}
```

#### 2. Get All Sleep Data
```http
GET /sleep-data
Authorization: Bearer <token>
```

#### 3. Get Latest Sleep Data
```http
GET /sleep-data/latest
Authorization: Bearer <token>
```

### Prediction Endpoints

#### 1. Generate Prediction
```http
GET /predictions/prediction
Authorization: Bearer <token>
```

**Response:**
```json
{
  "sleepQualityScore": 72.5,
  "sleepDisorderProbability": 0.28,
  "normalizedScore": 0.725,
  "predictedInterruptionCount": 2,
  "predictedInterruptionWindows": [
    {
      "startTime": "01:30",
      "endTime": "02:15",
      "probability": 0.65
    }
  ],
  "contributingFactors": {
    "stress_level": 0.8,
    "sleep_duration": 0.7,
    "physical_activity": 0.4
  },
  "recommendations": [
    "Practice stress reduction techniques before bedtime",
    "Aim for 7-9 hours of sleep per night",
    "Complete exercise 2-3 hours before bedtime"
  ]
}
```

#### 2. Get Prediction History
```http
GET /predictions/history
Authorization: Bearer <token>
```

### Schedule Endpoints

#### 1. Create Schedule
```http
POST /schedule
Authorization: Bearer <token>
Content-Type: application/json

{
  "userId": "user_id",
  "title": "Sleep Schedule",
  "startTime": "2024-01-01T22:00:00.000Z",
  "endTime": "2024-01-02T06:00:00.000Z",
  "category": "sleep"
}
```

#### 2. Get User Schedules
```http
GET /schedule/:userId
Authorization: Bearer <token>
```

#### 3. Update Schedule
```http
PUT /schedule/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "title": "Updated Sleep Schedule",
  "startTime": "2024-01-01T21:30:00.000Z"
}
```

#### 4. Delete Schedule
```http
DELETE /schedule/:id
Authorization: Bearer <token>
```

### Notification Endpoints

#### 1. Send Test Notification
```http
GET /notifications/test
Authorization: Bearer <token>
```

#### 2. Get Latest Notifications
```http
GET /notifications/user/latest
Authorization: Bearer <token>
```

## 🔐 Authentication

All protected endpoints require a JWT token in the Authorization header:
```http
Authorization: Bearer <your_jwt_token>
```

### Token Format
- **Access Token:** Valid for 7 days
- **Refresh Token:** Used to get new access tokens

## 📊 Database Models

### User Model
```javascript
{
  name: String,
  email: String (unique),
  password: String (hashed),
  age: Number,
  gender: String,
  profileImage: String,
  createdAt: Date,
  updatedAt: Date
}
```

### Sleep Data Model
```javascript
{
  userId: ObjectId,
  sleepDuration: Number,
  sleepLatency: Number,
  stressLevel: Number,
  userProfile: {
    age: Number,
    gender: String,
    bmi: Number
  },
  activities: {
    exerciseMinutes: Number,
    dailySteps: Number,
    caffeineIntake: Number,
    screenTimeMinutes: Number
  },
  environmentalData: {
    temperature: Number,
    lightIntensity: Number,
    soundExposure: String
  },
  dietaryData: {
    isBreakfastRegular: Boolean,
    isLunchRegular: Boolean,
    isDinnerRegular: Boolean,
    selectedBreakfastFoodTypes: [String],
    selectedLunchFoodTypes: [String],
    selectedDinnerFoodTypes: [String]
  },
  createdAt: Date
}
```

### Prediction Model
```javascript
{
  userId: ObjectId,
  sleepQualityScore: Number,
  sleepDisorderProbability: Number,
  normalizedScore: Number,
  predictedInterruptionCount: Number,
  predictedInterruptionWindows: [{
    startTime: String,
    endTime: String,
    probability: Number
  }],
  contributingFactors: Object,
  recommendations: [String],
  createdAt: Date
}
```

## 🔧 Technologies Used

### Core Dependencies
- **Express.js** - Web framework
- **MongoDB** - Database
- **Mongoose** - ODM for MongoDB
- **JWT** - Authentication
- **bcryptjs** - Password hashing
- **multer** - File uploads
- **nodemailer** - Email service
- **socket.io** - Real-time communication
- **node-cron** - Scheduled tasks
- **winston** - Logging
- **express-validator** - Request validation
- **cors** - Cross-origin resource sharing

### Development Dependencies
- **nodemon** - Auto-restart on file changes
- **jest** - Testing framework
- **supertest** - API testing

## 🚀 Deployment

### Local Development
```bash
npm run dev
```

### Production Deployment
1. **Set environment variables**
2. **Build the application**
3. **Start the server**
   ```bash
   npm start
   ```

### Docker Deployment
```dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

## 📝 Logging

The application uses Winston for logging:
- **Console logs** - Development
- **File logs** - Production (stored in `logs/` directory)
- **Error tracking** - All errors are logged with stack traces

## 🔄 Background Jobs

### Schedule Reminders
- **Cron job** runs every minute
- **Checks for upcoming schedules**
- **Sends notifications** via WebSocket and push notifications

### Email Notifications
- **Password reset emails**
- **Account verification emails**
- **Schedule reminders**

## 🧪 Testing

### Run Tests
```bash
npm test
```

### API Testing
Use the provided Postman collection:
```bash
# Import postman_collection.json into Postman
```

## 📞 Support

For issues and questions:
1. Check the logs in `logs/` directory
2. Review API documentation in `API_DOCUMENTATION.md`
3. Test endpoints using Postman collection
4. Check environment configuration

## 🔄 API Versioning

Current API version: **v1**
- Base URL: `/api`
- All endpoints are under `/api` prefix
- Backward compatibility maintained

## 📈 Performance

### Optimization Features
- **Connection pooling** for MongoDB
- **Request caching** for frequently accessed data
- **File compression** for responses
- **Rate limiting** for API endpoints
- **Request validation** to prevent invalid data

### Monitoring
- **Health check endpoint** at `/api/health`
- **Request logging** with morgan
- **Error tracking** with detailed stack traces
- **Performance metrics** in logs 