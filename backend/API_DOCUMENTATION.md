# SleepMate API Documentation

This document provides a comprehensive reference for all API endpoints in the SleepMate application.

## Base URL

- Development: `http://localhost:3000/api` or `http://<your-local-ip>:3000/api`
- Production: `https://api.sleepmate.com/api`

## Authentication

Most endpoints require JWT authentication. Include the token in the Authorization header:

```
Authorization: Bearer <jwt_token>
```

## Content Type

All requests should use:

```
Content-Type: application/json
```

## Response Format

All responses are in JSON format and follow this general structure:

- Success responses: Requested data or success message
- Error responses: `{ "error": "Error message" }`

---

## User Management

### Register User

**POST** `/users/register`

Creates a new user account.

**Request Body:**
```json
{
  "name": "John Doe",
  "email": "john@example.com",
  "password": "securepassword",
  "dateOfBirth": "1990-01-01T00:00:00.000Z",
  "gender": "male",
  "weight": 75,
  "height": 180
}
```

**Response (201):**
```json
{
  "user": {
    "_id": "60d5e5c6c8c1a400011a0d1e",
    "name": "John Doe",
    "email": "john@example.com",
    "dateOfBirth": "1990-01-01T00:00:00.000Z",
    "gender": "male",
    "weight": 75,
    "height": 180,
    "createdAt": "2023-01-01T00:00:00.000Z",
    "updatedAt": "2023-01-01T00:00:00.000Z"
  },
  "token": "jwt_token_here"
}
```

### Login

**POST** `/users/login`

Authenticates a user and returns a JWT token.

**Request Body:**
```json
{
  "email": "john@example.com",
  "password": "securepassword"
}
```

**Response (200):**
```json
{
  "user": {
    "_id": "60d5e5c6c8c1a400011a0d1e",
    "name": "John Doe",
    "email": "john@example.com",
    "dateOfBirth": "1990-01-01T00:00:00.000Z",
    "gender": "male"
  },
  "token": "jwt_token_here"
}
```

### Forgot Password

**POST** `/users/forgot-password`

Initiates the password reset process by sending an OTP.

**Request Body:**
```json
{
  "email": "john@example.com"
}
```

**Response (200):**
```json
{
  "message": "OTP sent to your email",
  "otp": "123456" // Note: Only included in development environment
}
```

### Verify OTP

**POST** `/users/verify-otp`

Verifies the OTP and returns a reset token.

**Request Body:**
```json
{
  "email": "john@example.com",
  "otp": "123456"
}
```

**Response (200):**
```json
{
  "message": "OTP verified successfully",
  "resetToken": "reset_token_here"
}
```

### Reset Password

**POST** `/users/reset-password`

Completes the password reset process.

**Request Body:**
```json
{
  "resetToken": "reset_token_here",
  "newPassword": "newsecurepassword"
}
```

**Response (200):**
```json
{
  "message": "Password reset successful"
}
```

### Get User Profile

**GET** `/users/profile`

Returns the authenticated user's profile.

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d1e",
  "name": "John Doe",
  "email": "john@example.com",
  "dateOfBirth": "1990-01-01T00:00:00.000Z",
  "gender": "male",
  "weight": 75,
  "height": 180,
  "healthConditions": ["asthma"],
  "createdAt": "2023-01-01T00:00:00.000Z",
  "updatedAt": "2023-01-01T00:00:00.000Z"
}
```

### Update User Profile

**PATCH** `/users/profile`

Updates the authenticated user's profile.

**Request Body:**
```json
{
  "name": "John Smith",
  "weight": 72,
  "height": 180,
  "healthConditions": ["asthma", "allergies"]
}
```

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d1e",
  "name": "John Smith",
  "email": "john@example.com",
  "weight": 72,
  "height": 180,
  "healthConditions": ["asthma", "allergies"],
  "updatedAt": "2023-01-02T00:00:00.000Z"
}
```

### Delete Account

**DELETE** `/users/account`

Deletes the authenticated user's account.

**Response (200):**
```json
{
  "message": "Account deleted successfully"
}
```

### Refresh Token

**POST** `/users/refresh-token`

Refreshes the JWT token for continued authentication.

**Response (200):**
```json
{
  "token": "new_jwt_token_here"
}
```

### Get User Stats

**GET** `/users/stats`

Returns statistics for the authenticated user.

**Response (200):**
```json
{
  "sleepData": {
    "count": 30,
    "averageDuration": 420,
    "averageQuality": 3.5
  },
  "predictions": {
    "count": 15,
    "averageScore": 0.65
  }
}
```

---

## Sleep Data Management

### Create Sleep Data

**POST** `/sleep-data`

Creates a new sleep data entry.

**Request Body:**
```json
{
  "bedTime": "2023-01-01T22:00:00.000Z",
  "wakeUpTime": "2023-01-02T06:00:00.000Z",
  "timeToFallAsleep": 15,
  "sleepDuration": 480,
  "interruptionCount": 2,
  "sleepQuality": 4,
  "stressLevel": 2,
  "notes": "Felt tired after workout"
}
```

**Response (201):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d1f",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "bedTime": "2023-01-01T22:00:00.000Z",
  "wakeUpTime": "2023-01-02T06:00:00.000Z",
  "timeToFallAsleep": 15,
  "sleepDuration": 480,
  "interruptionCount": 2,
  "sleepQuality": 4,
  "stressLevel": 2,
  "notes": "Felt tired after workout",
  "createdAt": "2023-01-02T12:00:00.000Z",
  "updatedAt": "2023-01-02T12:00:00.000Z"
}
```

### Get All Sleep Data

**GET** `/sleep-data`

Returns all sleep data entries for the authenticated user.

**Response (200):**
```json
[
  {
    "_id": "60d5e5c6c8c1a400011a0d1f",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "bedTime": "2023-01-01T22:00:00.000Z",
    "wakeUpTime": "2023-01-02T06:00:00.000Z",
    "sleepDuration": 480,
    "sleepQuality": 4
  },
  {
    "_id": "60d5e5c6c8c1a400011a0d20",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "bedTime": "2023-01-02T23:00:00.000Z",
    "wakeUpTime": "2023-01-03T07:00:00.000Z",
    "sleepDuration": 480,
    "sleepQuality": 3
  }
]
```

### Get Sleep Data By ID

**GET** `/sleep-data/:id`

Returns a specific sleep data entry.

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d1f",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "bedTime": "2023-01-01T22:00:00.000Z",
  "wakeUpTime": "2023-01-02T06:00:00.000Z",
  "timeToFallAsleep": 15,
  "sleepDuration": 480,
  "interruptionCount": 2,
  "sleepQuality": 4,
  "stressLevel": 2,
  "notes": "Felt tired after workout",
  "createdAt": "2023-01-02T12:00:00.000Z",
  "updatedAt": "2023-01-02T12:00:00.000Z"
}
```

### Update Sleep Data

**PATCH** `/sleep-data/:id`

Updates a specific sleep data entry.

**Request Body:**
```json
{
  "sleepQuality": 3,
  "notes": "Updated notes"
}
```

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d1f",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "sleepQuality": 3,
  "notes": "Updated notes",
  "updatedAt": "2023-01-02T14:00:00.000Z"
}
```

### Delete Sleep Data

**DELETE** `/sleep-data/:id`

Deletes a specific sleep data entry.

**Response (200):**
```json
{
  "message": "Sleep data deleted successfully"
}
```

### Get Latest Sleep Data

**GET** `/sleep-data/latest`

Returns the most recent sleep data entry for the authenticated user.

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d20",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "bedTime": "2023-01-02T23:00:00.000Z",
  "wakeUpTime": "2023-01-03T07:00:00.000Z",
  "sleepDuration": 480,
  "sleepQuality": 3,
  "createdAt": "2023-01-03T12:00:00.000Z"
}
```

### Get Sleep Data By User ID

**GET** `/sleep-data/user/:userId`

Returns all sleep data entries for a specific user.

**Response (200):**
```json
[
  {
    "_id": "60d5e5c6c8c1a400011a0d1f",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "bedTime": "2023-01-01T22:00:00.000Z",
    "wakeUpTime": "2023-01-02T06:00:00.000Z",
    "sleepDuration": 480,
    "sleepQuality": 4
  },
  {
    "_id": "60d5e5c6c8c1a400011a0d20",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "bedTime": "2023-01-02T23:00:00.000Z",
    "wakeUpTime": "2023-01-03T07:00:00.000Z",
    "sleepDuration": 480,
    "sleepQuality": 3
  }
]
```

### Get Sleep Data Stats

**GET** `/sleep-data/stats`

Returns statistical data about the authenticated user's sleep patterns.

**Response (200):**
```json
{
  "totalEntries": 30,
  "averageDuration": 450,
  "averageQuality": 3.7,
  "averageInterruptions": 1.5,
  "timeToFallAsleepAvg": 18,
  "mostCommonBedTime": "22:30",
  "mostCommonWakeTime": "06:45"
}
```

---

## Predictions

### Generate Prediction

**POST** `/predictions/generate`

Generates a sleep interruption prediction based on user data.

**Request Body:**
```json
{
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "environmentalData": {
    "temperature": 22.5,
    "humidity": 45,
    "lightIntensity": 10,
    "soundExposure": "Quiet"
  },
  "dietaryData": {
    "isBreakfastRegular": true,
    "isLunchRegular": true,
    "isDinnerRegular": true,
    "selectedBreakfastFoodTypes": ["Carbohydrates", "Proteins"],
    "selectedLunchFoodTypes": ["Proteins", "Vegetables"],
    "selectedDinnerFoodTypes": ["Proteins", "Vegetables"],
    "waterIntake": 2000
  },
  "historicalSleepData": [
    {
      "date": "2023-01-01T00:00:00.000Z",
      "sleepDuration": 480,
      "interruptionCount": 1,
      "timeToFallAsleep": 15,
      "sleepQuality": 4
    }
  ]
}
```

**Response (201):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d21",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "predictionScore": 0.75,
  "interruptionWindows": [
    {
      "startTime": "2023-01-03T02:00:00.000Z",
      "endTime": "2023-01-03T03:00:00.000Z",
      "probability": 0.75
    }
  ],
  "contributingFactors": {
    "stress": 0.4,
    "temperature": 0.2,
    "caffeine": 0.1,
    "screenTime": 0.3
  },
  "recommendations": [
    "Reduce screen time before bed",
    "Practice relaxation techniques to manage stress",
    "Keep bedroom temperature between 18-22°C"
  ],
  "createdAt": "2023-01-02T18:00:00.000Z"
}
```

### Make AI Prediction

**POST** `/predictions/predict`

Makes an AI-based prediction with complete sleep, environmental, and dietary data.

**Request Body:**
```json
{
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "sleepData": {
    "bedTime": "2023-01-02T22:00:00.000Z",
    "wakeUpTime": "2023-01-03T06:00:00.000Z",
    "timeToFallAsleep": 15,
    "sleepDuration": 480,
    "interruptionCount": 1,
    "sleepQuality": 4,
    "stressLevel": 3,
    "userProfile": {
      "age": 35,
      "gender": "male",
      "height": 178,
      "weight": 75,
      "bmi": 23.7
    },
    "activities": {
      "exerciseMinutes": 45,
      "dailySteps": 8500,
      "caffeineIntake": 200,
      "screenTimeMinutes": 120
    }
  },
  "environmentalData": {
    "temperature": 22.5,
    "humidity": 45,
    "lightIntensity": 10,
    "soundExposure": "Quiet",
    "noiseLevel": 30,
    "airQuality": "Good",
    "sleepEnvironment": "Bedroom",
    "sleepPosition": "Side"
  },
  "dietaryData": {
    "isBreakfastRegular": true,
    "isLunchRegular": true,
    "isDinnerRegular": true,
    "selectedBreakfastFoodTypes": ["Carbohydrates", "Proteins"],
    "selectedLunchFoodTypes": ["Proteins", "Vegetables"],
    "selectedDinnerFoodTypes": ["Proteins", "Vegetables"],
    "waterIntake": 2000,
    "alcoholConsumption": 0,
    "eveningMealTime": "2023-01-02T19:00:00.000Z",
    "hasCaffeineBefore": false
  }
}
```

**Response (201):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d22",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "predictionScore": 0.35,
  "interruptionWindows": [
    {
      "startTime": "2023-01-03T03:30:00.000Z",
      "endTime": "2023-01-03T04:30:00.000Z",
      "probability": 0.35
    }
  ],
  "contributingFactors": {
    "stress": 0.4,
    "screenTime": 0.6
  },
  "recommendations": [
    "Reduce screen time in the evening",
    "Practice relaxation techniques before bed"
  ],
  "inputData": {
    "sleepData": "...",
    "environmentalData": "...",
    "dietaryData": "..."
  },
  "createdAt": "2023-01-02T21:00:00.000Z"
}
```

### Get Prediction By ID

**GET** `/predictions/:id`

Returns a specific prediction.

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d22",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "predictionScore": 0.35,
  "interruptionWindows": [
    {
      "startTime": "2023-01-03T03:30:00.000Z",
      "endTime": "2023-01-03T04:30:00.000Z",
      "probability": 0.35
    }
  ],
  "contributingFactors": {
    "stress": 0.4,
    "screenTime": 0.6
  },
  "recommendations": [
    "Reduce screen time in the evening",
    "Practice relaxation techniques before bed"
  ],
  "createdAt": "2023-01-02T21:00:00.000Z"
}
```

### Get Latest Prediction

**GET** `/predictions/latest`

Returns the most recent prediction for the authenticated user.

**Query Parameters:**
- `userId`: Optional, specify user ID

**Response (200):**
```json
{
  "_id": "60d5e5c6c8c1a400011a0d22",
  "userId": "60d5e5c6c8c1a400011a0d1e",
  "predictionScore": 0.35,
  "interruptionWindows": [
    {
      "startTime": "2023-01-03T03:30:00.000Z",
      "endTime": "2023-01-03T04:30:00.000Z",
      "probability": 0.35
    }
  ],
  "contributingFactors": {
    "stress": 0.4,
    "screenTime": 0.6
  },
  "recommendations": [
    "Reduce screen time in the evening",
    "Practice relaxation techniques before bed"
  ],
  "createdAt": "2023-01-02T21:00:00.000Z"
}
```

### Get Predictions For User

**GET** `/predictions/user/:userId`

Returns all predictions for a specific user.

**Response (200):**
```json
[
  {
    "_id": "60d5e5c6c8c1a400011a0d21",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "predictionScore": 0.75,
    "createdAt": "2023-01-02T18:00:00.000Z"
  },
  {
    "_id": "60d5e5c6c8c1a400011a0d22",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "predictionScore": 0.35,
    "createdAt": "2023-01-02T21:00:00.000Z"
  }
]
```

### Get Predictions For Date Range

**GET** `/predictions/history`

Returns predictions within a specific date range.

**Query Parameters:**
- `startDate`: ISO 8601 format
- `endDate`: ISO 8601 format

**Response (200):**
```json
[
  {
    "_id": "60d5e5c6c8c1a400011a0d21",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "predictionScore": 0.75,
    "createdAt": "2023-01-02T18:00:00.000Z"
  },
  {
    "_id": "60d5e5c6c8c1a400011a0d22",
    "userId": "60d5e5c6c8c1a400011a0d1e",
    "predictionScore": 0.35,
    "createdAt": "2023-01-02T21:00:00.000Z"
  }
]
```

### Get Recommendations

**GET** `/predictions/recommendations`

Returns personalized sleep recommendations.

**Query Parameters:**
- `userId`: Optional, specify user ID

**Response (200):**
```json
{
  "recommendations": [
    "Reduce screen time in the evening",
    "Practice relaxation techniques before bed",
    "Keep bedroom temperature between 18-22°C",
    "Avoid caffeine after 2pm"
  ],
  "contributingFactors": {
    "stress": 0.4,
    "screenTime": 0.6,
    "temperature": 0.3,
    "caffeine": 0.5
  }
}
```

### Delete Prediction

**DELETE** `/predictions/:id`

Deletes a specific prediction.

**Response (200):**
```json
{
  "message": "Prediction deleted successfully"
}
```

---

## Error Codes

- `400` - Bad Request: The request was invalid or cannot be served
- `401` - Unauthorized: Authentication is required or failed
- `403` - Forbidden: The server understood the request but refuses to authorize it
- `404` - Not Found: The requested resource could not be found
- `422` - Unprocessable Entity: The request was well-formed but contains semantic errors
- `500` - Internal Server Error: Something went wrong on the server

## Date Format

All dates should be in ISO 8601 format: `YYYY-MM-DDTHH:mm:ss.sssZ`
