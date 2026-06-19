import 'package:flutter/material.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/services/obd_manager.dart';
import 'core/services/chat_manager.dart';
import 'shared/widgets/bottom_nav.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final obdManager = ObdManager();
  obdManager.init();
  final chatManager = ChatManager(obdManager: obdManager);
  runApp(SafeScanApp(obdManager: obdManager, chatManager: chatManager));
}

class SafeScanApp extends StatelessWidget {
  final ObdManager obdManager;
  final ChatManager chatManager;

  const SafeScanApp({
    super.key,
    required this.obdManager,
    required this.chatManager,
  });

  @override
  Widget build(BuildContext context) {
    AppRouter.sharedObdManager = obdManager;
    AppRouter.sharedChatManager = chatManager;
    return ListenableBuilder(
      listenable: obdManager,
      builder: (context, _) {
        return MaterialApp(
          title: 'SafeScan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.darkTheme,
          onGenerateRoute: AppRouter.generateRoute,
          home: MainScaffold(
            obdManager: obdManager,
            chatManager: chatManager,
          ),
        );
      },
    );
  }
}
