import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/services/obd_manager.dart';
import 'shared/widgets/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final obdManager = ObdManager();
  obdManager.init();
  runApp(SafeScanApp(obdManager: obdManager));
}

class SafeScanApp extends StatelessWidget {
  final ObdManager obdManager;

  const SafeScanApp({super.key, required this.obdManager});

  @override
  Widget build(BuildContext context) {
    AppRouter.sharedObdManager = obdManager;
    return ListenableBuilder(
      listenable: obdManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'SafeScan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          onGenerateRoute: AppRouter.generateRoute,
          home: MainScaffold(obdManager: obdManager),
        );
      },
    );
  }
}
