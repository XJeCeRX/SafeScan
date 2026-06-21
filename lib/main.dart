import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/obd_data.dart';
import 'core/services/dtc_lookup_service.dart';
import 'core/router.dart';
import 'core/theme.dart';
import 'core/services/obd_manager.dart';
import 'core/services/chat_manager.dart';
import 'core/services/diagnosis_queue.dart';
import 'core/services/diagnosis_http_service.dart';
import 'shared/widgets/bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  final dtcLookup = await DtcLookupService.load();
  DtcCode.registerResolver(dtcLookup.resolve);

  final obdManager = ObdManager();
  obdManager.init();

  final diagnosisQueue = DiagnosisQueue();
  await diagnosisQueue.init();

  final diagnosisHttpService = DiagnosisHttpService(queue: diagnosisQueue);
  await diagnosisHttpService.init();

  final chatManager = ChatManager(obdManager: obdManager);
  runApp(SafeScanApp(
    obdManager: obdManager,
    chatManager: chatManager,
    diagnosisQueue: diagnosisQueue,
    diagnosisHttpService: diagnosisHttpService,
  ));
}

class SafeScanApp extends StatelessWidget {
  final ObdManager obdManager;
  final ChatManager chatManager;
  final DiagnosisQueue diagnosisQueue;
  final DiagnosisHttpService diagnosisHttpService;

  const SafeScanApp({
    super.key,
    required this.obdManager,
    required this.chatManager,
    required this.diagnosisQueue,
    required this.diagnosisHttpService,
  });

  @override
  Widget build(BuildContext context) {
    AppRouter.sharedObdManager = obdManager;
    AppRouter.sharedChatManager = chatManager;
    AppRouter.sharedDiagnosisQueue = diagnosisQueue;
    AppRouter.sharedDiagnosisHttpService = diagnosisHttpService;
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
            diagnosisQueue: diagnosisQueue,
            diagnosisHttpService: diagnosisHttpService,
          ),
        );
      },
    );
  }
}
