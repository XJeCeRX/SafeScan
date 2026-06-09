import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
        title: Text('Dashboard', style: Theme.of(context).textTheme.titleLarge),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Conectado',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppTheme.primary),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Estado del vehículo',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 24),

              // Grid de métricas
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
                children: [
                  _MetricCard(
                    label: 'RPM',
                    value: '1,200',
                    unit: 'rpm',
                    icon: Icons.speed_outlined,
                    color: AppTheme.primary,
                  ),
                  _MetricCard(
                    label: 'Temperatura',
                    value: '87',
                    unit: '°C',
                    icon: Icons.thermostat_outlined,
                    color: AppTheme.severityMedium,
                  ),
                  _MetricCard(
                    label: 'Velocidad',
                    value: '0',
                    unit: 'km/h',
                    icon: Icons.directions_car_outlined,
                    color: AppTheme.primary,
                  ),
                  _MetricCard(
                    label: 'Batería',
                    value: '12.6',
                    unit: 'V',
                    icon: Icons.battery_full_outlined,
                    color: AppTheme.primary,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              Text(
                'Acciones rápidas',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),

              ElevatedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.diagnosis),
                icon: const Icon(Icons.search_outlined),
                label: const Text('Leer códigos de falla'),
              ),

              const SizedBox(height: 12),

              /*OutlinedButton.icon(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.cameraScan),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Escanear tablero'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: AppTheme.textHint),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      unit,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              Text(label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
        ],
      ),
    );
  }
}
