import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/obd/connection_screen.dart';
import '../features/obd/dashboard_screen.dart';
import '../features/diagnosis/diagnosis_screen.dart';
import '../features/history/history_screen.dart';

class AppRouter {
  static const String home = '/';
  static const String connection = '/connection';
  static const String dashboard = '/dashboard';
  static const String diagnosis = '/diagnosis';
  static const String history = '/history';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _route(const HomeScreen());
      case connection:
        return _route(const ConnectionScreen());
      case dashboard:
        return _route(const DashboardScreen());
      case diagnosis:
        return _route(const DiagnosisScreen());
      case history:
        return _route(const HistoryScreen());
      default:
        return _route(const HomeScreen());
    }
  }

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
