# SleepMate Backend

This is the backend server for the SleepMate sleep prediction application. It provides REST APIs for user management, sleep data tracking, and sleep quality predictions.

## Features

- User authentication with JWT
- Sleep data tracking and management
- Sleep quality predictions
- Environmental and dietary factors tracking
- Statistical analysis of sleep patterns

## Tech Stack

- Node.js
- Express.js
- MongoDB with Mongoose
- JWT for authentication
- Express Validator for input validation
- Morgan for logging
- CORS enabled

## Prerequisites

- Node.js (v14 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   npm install
   ```
3. Create a .env file in the root directory with the following variables:
   ```
   PORT=3000
   MONGODB_URI=mongodb://localhost:27017/sleepmate
   JWT_SECRET=your-super-secret-jwt-key-change-in-production
   JWT_EXPIRES_IN=7d
   ```

## Running the Server

Development mode:
```bash
npm run dev
```

Production mode:
```bash
npm start
```

## API Documentation

A complete Postman collection is included in the repository. Import `postman_collection.json` into Postman to test the APIs.

### Main Endpoints

#### User Management
- POST /api/users/register - Register new user
- POST /api/users/login - User login
- GET /api/users/profile - Get user profile
- PATCH /api/users/profile - Update user profile

#### Sleep Data
- POST /api/sleep-data - Create sleep record
- GET /api/sleep-data - Get all sleep records
- GET /api/sleep-data/:id - Get specific sleep record
- PATCH /api/sleep-data/:id - Update sleep record
- DELETE /api/sleep-data/:id - Delete sleep record
- GET /api/sleep-data/stats - Get sleep statistics

#### Predictions
- POST /api/predictions/generate - Generate new prediction
- GET /api/predictions/latest - Get latest prediction
- GET /api/predictions/history - Get prediction history

## Security

- All endpoints (except login and register) require JWT authentication
- Passwords are hashed using bcrypt
- Environment variables for sensitive data
- Input validation and sanitization
- CORS enabled for frontend communication

## Error Handling

The API uses standard HTTP status codes and returns error messages in JSON format:

```json
{
  "error": "Error message here"
}
```

## Data Models

### User
- name (String)
- email (String, unique)
- password (String, hashed)
- dateOfBirth (Date)
- gender (String)
- weight (Number)
- height (Number)
- healthConditions (Array)
- isAdmin (Boolean)
- profileImageUrl (String)

### Sleep Data
- userId (ObjectId)
- date (Date)
- bedTime (Date)
- wakeUpTime (Date)
- sleepDuration (Number)
- timeToFallAsleep (Number)
- interruptionCount (Number)
- interruptionTimes (Array)
- sleepQuality (Number)
- notes (String)
- environmentalData (Object)
- dietaryData (Object)

### Prediction
- userId (ObjectId)
- date (Date)
- predictionScore (Number)
- predictedInterruptionCount (Number)
- predictedInterruptionWindows (Array)
- contributingFactors (Map)
- recommendations (Array)
- inputData (Map)
