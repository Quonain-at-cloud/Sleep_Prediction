# SleepMate - Sleep Prediction Application

A comprehensive sleep prediction and monitoring application built with Flutter (frontend) and Node.js (backend), featuring machine learning-powered sleep quality predictions, real-time notifications, and personalized recommendations.

## 🌟 Features

### 🔐 Authentication & User Management
- Secure user registration and login
- JWT-based authentication
- Password recovery with email verification
- Profile management with image upload
- Account settings and preferences

### 📊 Sleep Data Collection
- Multi-step data collection process
- Sleep quality assessment
- Sleep patterns analysis
- Dietary habits tracking
- Environmental factors monitoring
- Activity level tracking

### 🤖 Machine Learning Predictions
- Sleep quality scoring (0-100)
- Sleep interruption predictions
- Sleep disorder risk assessment
- Personalized recommendations
- Historical trend analysis
- Contributing factors identification

### 🔔 Smart Notifications
- Local push notifications
- Schedule reminders
- Prediction alerts
- Real-time updates via WebSocket
- Background notification fetching

### 📅 Schedule Management
- Sleep schedule creation and editing
- Automated reminders
- Calendar integration
- Category-based organization
- Progress tracking

### 📱 Cross-Platform Support
- **Android** - Native Android app
- **iOS** - Native iOS app
- **Web** - Progressive web app
- **Responsive Design** - Adaptive UI for all screen sizes

## 🏗️ Architecture

### Frontend (Flutter)
- **State Management**: Provider + BLoC pattern
- **HTTP Client**: Dio with automatic retry
- **Local Storage**: Hive + SharedPreferences
- **Real-time**: WebSocket integration
- **UI Framework**: Material Design 3
- **Charts**: FL Chart for data visualization

### Backend (Node.js)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT tokens
- **Real-time**: Socket.IO
- **File Upload**: Multer
- **Email**: Nodemailer
- **Scheduling**: Node-cron
- **Logging**: Winston

### Machine Learning
- **ML Service**: External Python service
- **Data Processing**: Real-time data mapping
- **Prediction Models**: Sleep quality and interruption prediction
- **Recommendation Engine**: Personalized sleep tips

## 📁 Project Structure

```
sleep_prediction/
├── lib/                          # Flutter frontend source code
│   ├── main.dart                 # App entry point
│   ├── config/                   # Configuration files
│   ├── models/                   # Data models
│   ├── screens/                  # UI screens
│   ├── services/                 # Business logic services
│   ├── providers/                # State management
│   ├── blocs/                    # BLoC pattern implementation
│   ├── widgets/                  # Reusable UI components
│   ├── utils/                    # Utility functions
│   └── background/               # Background tasks
├── backend/                      # Node.js backend
│   ├── src/                      # Source code
│   │   ├── controllers/          # API controllers
│   │   ├── routes/               # API routes
│   │   ├── models/               # Database models
│   │   ├── middleware/           # Express middleware
│   │   ├── services/             # Business services
│   │   ├── utils/                # Utility functions
│   │   └── config/               # Configuration
│   ├── uploads/                  # File uploads
│   ├── logs/                     # Application logs
│   └── package.json              # Dependencies
├── assets/                       # Static assets
│   ├── images/                   # App images
│   ├── icons/                    # App icons
│   ├── fonts/                    # Custom fonts
│   └── ml_models/                # ML model files
├── android/                      # Android-specific code
├── ios/                          # iOS-specific code
├── web/                          # Web-specific code
├── test/                         # Test files
├── pubspec.yaml                  # Flutter dependencies
├── README.md                     # This file
├── BACKEND_README.md             # Backend documentation
├── FRONTEND_README.md            # Frontend documentation
└── SETUP_GUIDE.md                # Setup instructions
```

## 🚀 Quick Start

### Prerequisites
- **Node.js** (v16 or higher)
- **Flutter SDK** (v3.0 or higher)
- **MongoDB** (v5.0 or higher)
- **Git**

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd sleep_prediction
   ```

2. **Backend Setup**
   ```bash
   cd backend
   npm install
   cp .env.example .env  # Configure environment variables
   npm run dev
   ```

3. **Frontend Setup**
   ```bash
   flutter pub get
   # Configure API endpoints in lib/config/api_config.dart
   flutter run
   ```

For detailed setup instructions, see [SETUP_GUIDE.md](SETUP_GUIDE.md)

## 📡 API Endpoints

### Authentication
- `POST /api/users/register` - User registration
- `POST /api/users/login` - User login
- `POST /api/users/forgot-password` - Password recovery
- `POST /api/users/verify-otp` - OTP verification
- `POST /api/users/reset-password` - Password reset

### User Management
- `GET /api/users/profile` - Get user profile
- `PATCH /api/users/profile` - Update profile
- `POST /api/users/profile/image` - Upload profile image

### Sleep Data
- `POST /api/sleep-data/submit-data` - Submit sleep data
- `GET /api/sleep-data` - Get all sleep data
- `GET /api/sleep-data/latest` - Get latest sleep data

### Predictions
- `GET /api/predictions/prediction` - Generate prediction
- `GET /api/predictions/history` - Get prediction history

### Schedules
- `POST /api/schedule` - Create schedule
- `GET /api/schedule/:userId` - Get user schedules
- `PUT /api/schedule/:id` - Update schedule
- `DELETE /api/schedule/:id` - Delete schedule

### Notifications
- `GET /api/notifications/test` - Test notification
- `GET /api/notifications/user/latest` - Get latest notifications

For complete API documentation, see [backend/API_DOCUMENTATION.md](backend/API_DOCUMENTATION.md)

## 🔧 Configuration

### Backend Configuration
Create a `.env` file in the backend directory:
```env
PORT=3000
MONGODB_URI=mongodb://localhost:27017/sleepmate
JWT_SECRET=your_jwt_secret
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your_email@gmail.com
EMAIL_PASS=your_app_password
```

### Frontend Configuration
Update `lib/config/api_config.dart`:
```dart
// For Android emulator
static const String emulatorBaseUrl = 'http://10.0.2.2:3000/api';

// For physical device
static const String deviceBaseUrl = 'http://YOUR_IP:3000/api';

// For production
static const String prodBaseUrl = 'http://your-server.com/api';
```

## 🧪 Testing

### Backend Testing
```bash
cd backend
npm test
```

### Frontend Testing
```bash
flutter test
```

### API Testing
Import `backend/postman_collection.json` into Postman for API testing.

## 📱 Screenshots

### Authentication Flow
- Welcome screen with app introduction
- User registration with validation
- Login with secure authentication
- Password recovery with email verification

### Data Collection
- Multi-step data collection process
- Sleep quality assessment
- Dietary habits tracking
- Environmental factors monitoring

### Predictions & Analytics
- Sleep quality score display
- Prediction charts and graphs
- Personalized recommendations
- Historical trend analysis

### Schedule Management
- Calendar-based schedule view
- Schedule creation and editing
- Reminder notifications
- Progress tracking

## 🔒 Security Features

### Authentication
- JWT token-based authentication
- Secure password hashing with bcrypt
- Token refresh mechanism
- Session management

### Data Protection
- HTTPS communication
- Input validation and sanitization
- SQL injection prevention
- XSS protection

### Privacy
- Local data storage for sensitive information
- Minimal permission requirements
- Data encryption
- Secure API communication

## 🚀 Deployment

### Backend Deployment
1. Set production environment variables
2. Configure production database
3. Set up SSL certificates
4. Deploy to cloud platform (Heroku, AWS, etc.)

### Frontend Deployment
1. Configure production API endpoints
2. Build release versions
3. Deploy to app stores (Google Play, App Store)
4. Deploy web version to hosting platform

## 📊 Performance Optimization

### Frontend
- Lazy loading of data
- Image caching and compression
- Widget rebuilding optimization
- Background processing

### Backend
- Database connection pooling
- Request caching
- File compression
- Rate limiting

## 🔄 Development Workflow

### Git Workflow
- Feature branch development
- Pull request reviews
- Automated testing
- Semantic versioning

### Code Quality
- ESLint for JavaScript/Node.js
- Flutter lints for Dart
- Automated formatting
- Comprehensive testing

## 📈 Monitoring & Analytics

### Backend Monitoring
- Request logging with Morgan
- Error tracking with Winston
- Performance metrics
- Health check endpoints

### Frontend Analytics
- User behavior tracking
- Performance monitoring
- Error reporting
- Usage statistics

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 📞 Support

### Documentation
- [Backend Documentation](backend/README.md)
- [Frontend Documentation](FRONTEND_README.md)
- [Setup Guide](SETUP_GUIDE.md)
- [API Documentation](backend/API_DOCUMENTATION.md)

### Getting Help
1. Check the documentation
2. Review the logs for error messages
3. Test individual components
4. Check network connectivity
5. Verify configuration settings

### Useful Commands
```bash
# Check system status
flutter doctor
node --version
npm --version

# Run development servers
cd backend && npm run dev
flutter run

# Check logs
tail -f backend/logs/app.log
flutter logs
```

## 🎯 Roadmap

### Upcoming Features
- [ ] Advanced sleep analytics
- [ ] Integration with wearable devices
- [ ] Social features and sharing
- [ ] Advanced ML models
- [ ] Multi-language support
- [ ] Dark/light theme toggle
- [ ] Offline mode support
- [ ] Voice commands
- [ ] Sleep coaching sessions
- [ ] Integration with smart home devices

### Technical Improvements
- [ ] Performance optimization
- [ ] Enhanced security features
- [ ] Better error handling
- [ ] Comprehensive testing
- [ ] CI/CD pipeline
- [ ] Docker containerization
- [ ] Microservices architecture
- [ ] Real-time analytics dashboard

---

**SleepMate** - Your personal sleep companion powered by AI 🤖💤
