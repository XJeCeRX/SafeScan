import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/obd/connection_screen.dart';
import '../features/obd/dashboard_screen.dart';
import '../features/diagnosis/diagnosis_screen.dart';
import '../features/history/history_screen.dart';
import 'services/obd_manager.dart';

class AppRouter {
  static const String home = '/';
  static const String connection = '/connection';
  static const String dashboard = '/dashboard';
  static const String diagnosis = '/diagnosis';
  static const String history = '/history';
  static ObdManager? sharedObdManager;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final obd = args is ObdManager ? args : sharedObdManager;
    switch (settings.name) {
      case home:
        return _route(HomeScreen(obdManager: obd));
      case connection:
        return _route(ConnectionScreen(obdManager: obd));
      case dashboard:
        return _route(DashboardScreen(obdManager: obd));
      case diagnosis:
        return _route(DiagnosisScreen(obdManager: obd));
      case history:
        return _route(const HistoryScreen());
      default:
        return _route(HomeScreen(obdManager: obd));
    }
  }

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
