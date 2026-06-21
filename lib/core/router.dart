import 'package:flutter/material.dart';
import '../features/home/home_screen.dart';
import '../features/obd/connection_screen.dart';
import '../features/obd/dashboard_screen.dart';
import '../features/diagnosis/diagnosis_screen.dart';
import '../features/history/history_screen.dart';
import '../features/chat/chat_screen.dart';
import 'services/obd_manager.dart';
import 'services/chat_manager.dart';
import 'services/diagnosis_queue.dart';
import 'services/diagnosis_http_service.dart';

class AppRouter {
  static const String home = '/';
  static const String connection = '/connection';
  static const String dashboard = '/dashboard';
  static const String diagnosis = '/diagnosis';
  static const String history = '/history';
  static const String chat = '/chat';
  static ObdManager? sharedObdManager;
  static ChatManager? sharedChatManager;
  static DiagnosisQueue? sharedDiagnosisQueue;
  static DiagnosisHttpService? sharedDiagnosisHttpService;

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    final obd = args is ObdManager ? args : sharedObdManager;
    final chatManager = sharedChatManager;
    final diagnosisQueue = sharedDiagnosisQueue;
    final diagnosisHttp = sharedDiagnosisHttpService;
    switch (settings.name) {
      case home:
        return _route(HomeScreen(obdManager: obd));
      case connection:
        return _route(ConnectionScreen(obdManager: obd));
      case dashboard:
        return _route(DashboardScreen(obdManager: obd));
      case diagnosis:
        return _route(DiagnosisScreen(
          obdManager: obd,
          diagnosisService: diagnosisHttp,
        ));
      case history:
        return _route(HistoryScreen(
          diagnosisQueue: diagnosisQueue,
        ));
      case chat:
        if (obd != null && chatManager != null) {
          return _route(
            ChatScreen(chatManager: chatManager, obdManager: obd),
          );
        }
        return _route(HomeScreen(obdManager: obd));
      default:
        return _route(HomeScreen(obdManager: obd));
    }
  }

  static MaterialPageRoute _route(Widget page) {
    return MaterialPageRoute(builder: (_) => page);
  }
}
