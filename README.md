# Sleep Prediction App

A cross-platform mobile application that predicts overnight sleep interruptions by integrating user data (sleep patterns, dietary habits) with real-time environmental inputs (noise, light, temperature).

## Overview

This Flutter application uses machine learning to predict sleep interruptions and provide personalized recommendations for improving sleep quality. The app integrates with Firebase for authentication and data storage, and uses external APIs to collect environmental data.

## Features

- **User Authentication**: Secure login/registration with Firebase Authentication
- **Sleep Tracking**: Record sleep patterns including duration, quality, and interruptions
- **Prediction Engine**: Machine learning model to predict sleep interruptions
- **Personalized Recommendations**: Receive tailored advice to improve sleep quality
- **Environmental Data Integration**: Collect and analyze environmental factors affecting sleep
- **Visual Insights**: Charts and graphs to visualize sleep patterns and predictions

## Architecture

The app follows a layered architecture with clear separation of concerns:

- **UI Layer**: Flutter widgets and screens
- **Business Logic Layer**: Services and providers
- **Data Layer**: Models and repositories

Key design patterns used:
- **MVC Pattern**: For organizing UI and logic
- **Repository Pattern**: For data access
- **Provider Pattern**: For state management
- **Singleton Pattern**: For service instances

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── user_model.dart
│   ├── sleep_data_model.dart
│   └── prediction_model.dart
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── register_screen.dart
│   └── home_screen.dart
├── services/                 # Business logic
│   ├── auth_service.dart
│   ├── sleep_data_service.dart
│   └── prediction_service.dart
├── utils/                    # Utility classes
│   ├── app_constants.dart
│   ├── formatters.dart
│   ├── validators.dart
│   └── ml_helper.dart
└── widgets/                  # Reusable widgets
    ├── custom_button.dart
    ├── custom_input_field.dart
    ├── sleep_card.dart
    └── prediction_card.dart
```

## Setup Instructions

1. **Prerequisites**:
   - Flutter SDK (version 3.0.0 or higher)
   - Dart SDK (version 2.17.0 or higher)
   - Android Studio or VS Code with Flutter extensions
   - Firebase project (for authentication and database)

2. **Installation**:
   ```bash
   # Clone the repository
   git clone https://github.com/yourusername/sleep_prediction.git
   
   # Navigate to project directory
   cd sleep_prediction
   
   # Install dependencies
   flutter pub get
   
   # Run the app
   flutter run
   ```

3. **Firebase Configuration**:
   - Create a Firebase project in the Firebase Console
   - Add Android and iOS apps to your Firebase project
   - Download and add the configuration files (google-services.json and GoogleService-Info.plist)
   - Enable Authentication and Firestore in the Firebase Console

## Machine Learning Model

The app uses a TensorFlow Lite model to predict sleep interruptions based on:
- Historical sleep data
- User-specific factors (age, weight, health conditions)
- Environmental conditions (temperature, humidity, noise, light)
- Dietary habits (caffeine, alcohol, meal timing)

For demo purposes, the app currently uses simulated ML predictions, but can be extended to include a real TensorFlow model.

## Future Enhancements

- Integration with wearable devices for real-time sleep monitoring
- Advanced analytics dashboard with more detailed insights
- Multilingual support
- Social features for comparing sleep patterns with friends or family
- Additional machine learning models for more accurate predictions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contact

For any inquiries, please contact [your-email@example.com].
