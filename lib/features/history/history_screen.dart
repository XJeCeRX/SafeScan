import 'package:flutter/material.dart';
import '../../core/theme.dart';

class HistoryScreen extends StatelessWidget {
  final VoidCallback? onBackToHome;

  const HistoryScreen({super.key, this.onBackToHome});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              onBackToHome?.call();
            }
          },
        ),
        title: Text('Historial', style: Theme.of(context).textTheme.titleLarge),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 64, color: AppTheme.textHint),
            const SizedBox(height: 20),
            Text(
              'Sin escaneos aún',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Tus diagnósticos anteriores\naparecerán aquí.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
