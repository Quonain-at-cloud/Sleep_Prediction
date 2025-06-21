import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sleep_prediction/models/user_model.dart'; // Added for UserModel
import 'package:intl/date_symbol_data_local.dart';

import 'providers/auth_provider.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/auth/auth_event.dart';
import 'blocs/auth/auth_state.dart';
import 'blocs/sleep_data/sleep_data_bloc.dart';
import 'blocs/prediction/prediction_bloc.dart';

import 'utils/app_constants.dart';
import 'utils/app_bloc_observer.dart';
import 'services/service_locator.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/cache_service.dart';
import 'services/logger_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/notification_model.dart';
import 'providers/notification_provider.dart';
import 'providers/schedule_provider.dart';
import 'services/prediction_service.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/register_successfull.dart';
import 'screens/sleep_quality_screen.dart';
// Missing screens removed
import 'screens/dietary_habits_screen.dart';
import 'screens/environmental_factors_screen.dart';
import 'screens/sleep_patterns_screen.dart';
import 'screens/prediction_screen.dart';
import 'screens/prediction_graph_screen.dart';
import 'screens/recommendation_screen.dart';
import 'package:sleep_prediction/models/user_model.dart';
import 'screens/sleep_quality_feedback_screen.dart';
import 'screens/splash_screen1.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/account_information_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/progress_report_screen.dart';
import 'screens/schedule_screen.dart';

// Error widget for initialization failure
class ErrorScreen extends StatelessWidget {
  final String message;
  const ErrorScreen({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 60),
              SizedBox(height: 16),
              Text('Initialization Failed',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Text(message, textAlign: TextAlign.center),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Try to restart the app
                  main();
                },
                child: Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> initializeApp() async {
  final logger = LoggerService();
  
  try {
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize local storage (Hive)
    await Hive.initFlutter();
    Hive.registerAdapter(NotificationModelAdapter());

    // Initialize service locator and services
    await setupServiceLocator();

    // Initialize date formatting for 'en_US' locale (and default)
    await initializeDateFormatting('en_US', null);
    await initializeDateFormatting(null, null); // For default device locale if needed
    
    // Set up BlocObserver for state management monitoring
    Bloc.observer = AppBlocObserver();
    
    // Initialize cache service
    await serviceLocator<CacheService>().initialize();
    
    // API service is initialized through service locator
    
    logger.i('App services initialized successfully');
  } catch (e, stackTrace) {
    logger.e('Error initializing app services: $e', stackTrace);
    rethrow;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await initializeApp();
    runApp(const MyApp());
  } catch (e) {
    LoggerService().e('Fatal error during app initialization: $e');
    runApp(ErrorScreen(message: e.toString()));
  }
}



class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) => serviceLocator<AuthBloc>(),
        ),
        BlocProvider<SleepDataBloc>(
          create: (_) => serviceLocator<SleepDataBloc>(),
        ),
        BlocProvider<PredictionBloc>(
          create: (_) => serviceLocator<PredictionBloc>(),
        ),
      ],
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => serviceLocator<ScheduleProvider>()),
          Provider<AuthService>(create: (_) => serviceLocator<AuthService>()),
          Provider<PredictionService>(create: (_) => serviceLocator<PredictionService>()),
          ChangeNotifierProvider(create: (_) => serviceLocator<NotificationProvider>()),
        ],
        child: MaterialApp(
          title: 'Sleep Prediction',
          theme: ThemeData(
            primaryColor: const Color(0xFF2A2438),
            scaffoldBackgroundColor: const Color(0xFF2A2438),
            textTheme: GoogleFonts.montserratAlternatesTextTheme(
              Theme.of(context).textTheme,
            ),
            // Apply Montserrat Alternates to all text styles
            useMaterial3: true,
          ),
          initialRoute: AppConstants.splashRoute,
          onGenerateRoute: (settings) {
            // Handle named routes with arguments
            switch (settings.name) {
              case AppConstants.splashRoute:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              case AppConstants.splashScreen1Route:
                return MaterialPageRoute(builder: (_) => const SplashScreen1());
              case AppConstants.welcomeRoute:
                return MaterialPageRoute(builder: (_) => const WelcomeScreen());
              case AppConstants.loginRoute:
                return MaterialPageRoute(builder: (_) => const LoginScreen());
              case AppConstants.forgotPasswordRoute:
                return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
              case AppConstants.registerRoute:
                return MaterialPageRoute(builder: (_) => const RegisterScreen());
              case AppConstants.registerSuccessRoute:
            return MaterialPageRoute(builder: (_) => const RegistrationSuccessScreen());
          case AppConstants.onboardingRoute:
                return MaterialPageRoute(builder: (_) => const OnboardingScreen());
              case AppConstants.sleepPatternsRoute:
                return MaterialPageRoute(builder: (_) => const SleepPatternsScreen());
              case AppConstants.dietaryHabitsRoute:
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => DietaryHabitsScreen(
                    sleepData: args?['sleepData'],
                  ),
                );
              case AppConstants.environmentalFactorsRoute:
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => EnvironmentalFactorsScreen(
                    sleepData: args?['sleepData'],
                    dietaryData: args?['dietaryData'],
                    profileInfo: args?['profileInfo'], // Ensure profileInfo is passed here too
                  ),
                );
              case AppConstants.predictionRoute:
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => PredictionScreen(
                    sleepData: args?['sleepData'],
                    dietaryData: args?['dietaryData'],
                    environmentalData: args?['environmentalData'],
                    profileInfo: args?['profileInfo'], // Added profileInfo
                    predictionResult: args?['predictionResult'], // Added predictionResult
                  ),
                );
              case AppConstants.homeRoute:
                // Redirect to welcome screen as home screen is not available
                return MaterialPageRoute(builder: (_) => const WelcomeScreen());
              case AppConstants.predictionGraphRoute:
                final args = settings.arguments as Map<String, dynamic>?;
                // PredictionGraphScreen expects Map<String, double>? for factors.
                // The screen's initState handles conversion if values are num.
                final factors = args?['contributingFactors'] as Map<String, dynamic>?;
                Map<String, double>? correctlyTypedFactors;
                if (factors != null) {
                  correctlyTypedFactors = factors.map((key, value) {
                    if (value is num) {
                      return MapEntry(key, value.toDouble());
                    }
                    // Attempt to parse numeric strings as double
                    final parsed = double.tryParse(value.toString());
                    return MapEntry(key, parsed ?? 0.0);
                  });
                }
                return MaterialPageRoute(
                  builder: (_) => PredictionGraphScreen(
                    contributingFactors: correctlyTypedFactors,
                  ),
                );
              case AppConstants.recommendationRoute:
                final args = settings.arguments as Map<String, dynamic>?;
                return MaterialPageRoute(
                  builder: (_) => RecommendationScreen(
                    recommendations: args?['recommendations'] as List<String>?,
                    userProfile: args?['userProfile'] as UserModel?,
                  ),
                );
              case AppConstants.sleepQualityFeedbackRoute:
                return MaterialPageRoute(builder: (_) => const SleepQualityFeedbackScreen());
              case '/settings':
                return MaterialPageRoute(builder: (_) => const SettingsScreen());
              case '/account-info':
                return MaterialPageRoute(builder: (_) => const AccountInformationScreen());
              case '/notifications':
                return MaterialPageRoute(builder: (_) => const NotificationScreen());
              case '/progress-report':
                return MaterialPageRoute(builder: (_) => const ProgressReportScreen());
              case AppConstants.scheduleRoute:
                return MaterialPageRoute(builder: (_) => const ScheduleScreen());
              default:
                return MaterialPageRoute(builder: (_) => const SplashScreen());
            }
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
