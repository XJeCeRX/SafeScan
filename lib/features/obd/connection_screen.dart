import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  bool _isScanning = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_outlined),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Conectar OBD',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conecta tu dispositivo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Asegúrate de que tu adaptador OBD esté enchufado al vehículo y el Bluetooth activado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const SizedBox(height: 48),

              // Ícono central
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _isScanning ? AppTheme.primary : AppTheme.textHint,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    Icons.bluetooth_searching_outlined,
                    size: 48,
                    color: _isScanning ? AppTheme.primary : AppTheme.textHint,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  _isScanning
                      ? 'Buscando dispositivos...'
                      : 'Listo para escanear',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _isScanning = !_isScanning);
                },
                icon: Icon(
                  _isScanning ? Icons.stop_outlined : Icons.bluetooth_outlined,
                ),
                label: Text(_isScanning ? 'Detener' : 'Buscar dispositivos'),
              ),

              const SizedBox(height: 16),

              // Simular conexión exitosa por ahora
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.dashboard),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Simular conexión exitosa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
