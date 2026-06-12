import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'shared/widgets/bottom_nav.dart';

void main() {
  runApp(const SafeScanApp());
}

class SafeScanApp extends StatelessWidget {
  const SafeScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeScan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      onGenerateRoute: AppRouter.generateRoute,
      home: const MainScaffold(),
    );
  }
}
