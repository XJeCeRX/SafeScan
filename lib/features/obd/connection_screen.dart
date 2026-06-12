import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

class ConnectionScreen extends StatefulWidget {
  const ConnectionScreen({super.key});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen>
    with TickerProviderStateMixin {
  bool _isScanning = false;
  late AnimationController _pulseController;
  late AnimationController _rippleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rippleAnimation;
  late Animation<double> _rippleOpacity;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rippleAnimation = Tween<double>(begin: 1.0, end: 2.2).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    _rippleOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
  }

  void _toggleScan() {
    setState(() => _isScanning = !_isScanning);
    if (_isScanning) {
      _pulseController.repeat(reverse: true);
      _rippleController.repeat();
    } else {
      _pulseController.stop();
      _pulseController.reset();
      _rippleController.stop();
      _rippleController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

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
                'Asegúrate de que tu adaptador OBD esté enchufado y el Bluetooth activado.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),

              const Spacer(),

              // Efecto Shazam
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _pulseController,
                    _rippleController,
                  ]),
                  builder: (context, child) {
                    return SizedBox(
                      width: 220,
                      height: 220,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Ripple exterior
                          if (_isScanning)
                            Transform.scale(
                              scale: _rippleAnimation.value,
                              child: Opacity(
                                opacity: _rippleOpacity.value,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                          // Segundo ripple desfasado
                          if (_isScanning)
                            Transform.scale(
                              scale: _rippleAnimation.value * 0.7,
                              child: Opacity(
                                opacity: _rippleOpacity.value * 0.5,
                                child: Container(
                                  width: 120,
                                  height: 120,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme.primary.withOpacity(0.1),
                                  ),
                                ),
                              ),
                            ),

                          // Círculo principal con pulso
                          Transform.scale(
                            scale: _isScanning ? _pulseAnimation.value : 1.0,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isScanning
                                    ? AppTheme.primary.withOpacity(0.15)
                                    : AppTheme.surface,
                                border: Border.all(
                                  color: _isScanning
                                      ? AppTheme.primary
                                      : AppTheme.textHint,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.bluetooth_searching_outlined,
                                size: 48,
                                color: _isScanning
                                    ? AppTheme.primary
                                    : AppTheme.textHint,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _isScanning
                        ? 'Buscando dispositivos...'
                        : 'Listo para escanear',
                    key: ValueKey(_isScanning),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: _toggleScan,
                icon: Icon(
                  _isScanning ? Icons.stop_outlined : Icons.bluetooth_outlined,
                ),
                label: Text(
                  _isScanning ? 'Detener búsqueda' : 'Buscar dispositivos',
                ),
              ),

              const SizedBox(height: 12),

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
