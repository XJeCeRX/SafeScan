import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

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

              const SizedBox(height: 40),

              // Estado de conexión
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: AppTheme.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Sin conexión OBD',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.connection),
                      child: const Text('Conectar'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              /* Botón escanear tablero
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(
                    context, AppRouter.cameraScan),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Escanear tablero'),
              ),*/
              const SizedBox(height: 16),

              // Botón leer códigos OBD
              OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.diagnosis),
                icon: const Icon(Icons.search_outlined),
                label: const Text('Leer códigos OBD'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.textHint),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
