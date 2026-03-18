import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/home_screen.dart';
import '../../presentation/screens/result_screen.dart';
import '../../presentation/screens/history_screen.dart';
import '../../data/models/history_model.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/result',
      name: 'result',
      builder: (context, state) {
        // Check if we have arguments (from history)
        final detection = state.extra as DetectionHistory?;
        return ResultScreen(initialDetection: detection);
      },
    ),
    GoRoute(
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
    ),
  ],
);