import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:safescan/core/services/obd_manager.dart';
import 'package:safescan/core/theme.dart';
import 'package:safescan/features/obd/connection_screen.dart';

void main() {
  Future<void> pumpConnectionScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: ConnectionScreen(obdManager: ObdManager()),
      ),
    );
  }

  testWidgets('does not call wifi scan plugin on unsupported platforms', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;

    try {
      await pumpConnectionScreen(tester);
      await tester.tap(find.text('Buscar redes WiFi'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Escaneo WiFi automatico'), findsOneWidget);
      expect(find.textContaining('MissingPluginException'), findsNothing);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('shows a friendly message when wifi scan plugin is missing', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    const appWifiChannel = MethodChannel('com.example.safescan/wifi');
    const wifiScanChannel = MethodChannel('wifi_scan');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(appWifiChannel, (call) async {
      switch (call.method) {
        case 'getCurrentSsid':
          return '';
        case 'requestWifiPermissions':
          return {'granted': true};
      }
      throw MissingPluginException();
    });
    messenger.setMockMethodCallHandler(wifiScanChannel, (_) async {
      throw MissingPluginException();
    });

    try {
      await pumpConnectionScreen(tester);
      await tester.tap(find.text('Buscar redes WiFi'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Escaneo WiFi automatico'), findsOneWidget);
      expect(find.textContaining('MissingPluginException'), findsNothing);
    } finally {
      messenger.setMockMethodCallHandler(appWifiChannel, null);
      messenger.setMockMethodCallHandler(wifiScanChannel, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
