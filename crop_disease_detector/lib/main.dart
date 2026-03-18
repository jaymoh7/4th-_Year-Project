import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'data/models/detection_model.dart';
import 'presentation/screens/auth/login_screen.dart';
import 'presentation/screens/auth/signup_screen.dart';
import 'presentation/screens/auth/verify_email_screen.dart';
import 'presentation/screens/home_feed_screen.dart';
import 'presentation/screens/camera_screen.dart';
import 'presentation/screens/result_screen.dart';
import 'presentation/screens/history_screen.dart';
import 'presentation/screens/profile_screen.dart';
import 'presentation/screens/detection_detail_screen.dart';
import 'presentation/screens/comments_screen.dart';
import 'presentation/viewmodels/auth_viewmodel.dart';
import 'presentation/viewmodels/detection_viewmodel.dart';
import 'presentation/viewmodels/camera_viewmodel.dart';
import 'presentation/viewmodels/history_viewmodel.dart';
import 'core/themes/app_theme.dart';
import 'core/routes/app_router.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with duplicate check
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      debugPrint('Firebase already initialized');
    }
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => DetectionViewModel()),
        ChangeNotifierProvider(create: (_) => CameraViewModel()),
        ChangeNotifierProvider(create: (_) => HistoryViewModel()),
      ],
      child: Consumer<AuthViewModel>(
        builder: (context, authVM, child) {
          return MaterialApp.router(
            title: 'Crop Disease Detector',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            routerConfig: _createRouter(authVM),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }

  GoRouter _createRouter(AuthViewModel authVM) {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        debugPrint('=== Navigation Debug ===');
        debugPrint('Current location: ${state.matchedLocation}');
        debugPrint('Is authenticated: ${authVM.isAuthenticated}');
        debugPrint('Is email verified: ${authVM.isEmailVerified}');

        final isAuthenticated = authVM.isAuthenticated;
        final isEmailVerified = authVM.isEmailVerified;
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/signup';

        if (!isAuthenticated && !isLoggingIn) {
          debugPrint('Redirecting to login (not authenticated)');
          return '/login';
        }

        if (isAuthenticated && !isEmailVerified &&
            state.matchedLocation != '/verify-email') {
          debugPrint('Redirecting to verify-email (email not verified)');
          return '/verify-email';
        }

        if (isAuthenticated && isEmailVerified &&
            (state.matchedLocation == '/login' ||
                state.matchedLocation == '/signup')) {
          debugPrint('Redirecting to home (already logged in)');
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'home',
          builder: (context, state) => const HomeFeedScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignUpScreen(),
        ),
        GoRoute(
          path: '/verify-email',
          name: 'verify-email',
          builder: (context, state) => const VerifyEmailScreen(),
        ),
        GoRoute(
          path: '/camera',
          name: 'camera',
          builder: (context, state) => const CameraScreen(),
        ),
        GoRoute(
          path: '/result',
          name: 'result',
          builder: (context, state) {
            final detection = state.extra;
            if (detection != null && detection is Detection) {
              return ResultScreen(initialDetection: detection);
            }
            return const ResultScreen();
          },
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          builder: (context, state) => const HistoryScreen(),
        ),
        GoRoute(
          path: '/profile',
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/detection-detail',
          name: 'detection-detail',
          builder: (context, state) => const DetectionDetailScreen(),
        ),
        GoRoute(
          path: '/comments',
          name: 'comments',
          builder: (context, state) => const CommentsScreen(),
        ),
      ],
    );
  }
}