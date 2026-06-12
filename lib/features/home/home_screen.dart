import 'package:flutter/material.dart';

import '../../core/router.dart';
import '../../shared/widgets/status_card.dart';
import '../../shared/widgets/custom_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Saludo
              Text('Hola 👋', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Tu vehículo está listo para escanear',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 32),

              // Estado de conexión
              StatusCard(
                isConnected: false,
                onConnectTap: () =>
                    Navigator.pushNamed(context, AppRouter.connection),
              ),

              const SizedBox(height: 32),

              // Botones
              CustomButton(
                label: 'Leer códigos OBD',
                icon: Icons.search_outlined,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.diagnosis),
              ),

              const SizedBox(height: 12),

              CustomButton(
                label: 'Ver historial',
                icon: Icons.history_outlined,
                isOutlined: true,
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.history),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
