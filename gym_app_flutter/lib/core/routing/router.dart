import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/routines/presentation/routines_screen.dart';
import '../../features/routines/presentation/routine_detail_screen.dart';
import '../../features/workout/presentation/workout_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'scaffold_with_nav_bar.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return ScaffoldWithNavBar(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/routines',
          name: 'routines',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: RoutinesScreen(),
          ),
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HistoryScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    // Routes outside the shell (without bottom nav)
    GoRoute(
      path: '/routines/:id',
      name: 'routine-detail',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return RoutineDetailScreen(routineId: id);
      },
    ),
    GoRoute(
      path: '/workout',
      name: 'workout',
      builder: (context, state) => const WorkoutScreen(),
    ),
  ],
);
