import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../core/services/obd_manager.dart';
import '../../shared/widgets/warning_banner.dart';
import '../../shared/widgets/success_banner.dart';
import '../../shared/widgets/custom_button.dart';

class DashboardScreen extends StatefulWidget {
  final ObdManager? obdManager;

  const DashboardScreen({super.key, this.obdManager});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  ObdManager get _obd => widget.obdManager!;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
    _obd.scanDtc();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _obd,
      builder: (context, _) {
        final data = _obd.vehicleData;
        final dtc = _obd.dtcCodes;
        final urgent = dtc.where((c) => c.severity == 'urgent').length;
        final total = dtc.length;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_outlined),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Dashboard',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
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
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (total > 0)
                      WarningBanner(
                        message:
                            'Se detectaron $total códigos de falla${urgent > 0 ? " ($urgent urgente${urgent > 1 ? "s" : ""})" : ""}',
                        severity: urgent > 0 ? 'urgent' : 'medium',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.diagnosis,
                          arguments: _obd,
                        ),
                      )
                    else if (_obd.hasScannedDtc)
                      SuccessBanner(
                        title: 'Sin alertas detectadas',
                        message:
                            'No se encontraron códigos de error activos en el '
                            'vehículo.',
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRouter.diagnosis,
                          arguments: _obd,
                        ),
                      ),
                    if (total > 0 || _obd.hasScannedDtc)
                      const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.speed_outlined,
                              color: AppTheme.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RPM actual',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${data.rpm}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                          color: AppTheme.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                      left: 4,
                                    ),
                                    child: Text(
                                      'rpm',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyMedium,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              _MiniIndicator(
                                label: data.rpm == 0 ? 'Detenido' : 'Normal',
                                color: data.rpm == 0
                                    ? AppTheme.textHint
                                    : AppTheme.severityLow,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.95,
                      children: [
                        _MetricCard(
                          label: 'Temperatura',
                          value: '${data.coolantTemp}',
                          unit: '°C',
                          icon: Icons.thermostat_outlined,
                          color: data.coolantTemp > 100
                              ? AppTheme.severityUrgent
                              : data.coolantTemp > 90
                              ? AppTheme.severityMedium
                              : AppTheme.primary,
                        ),
                        _MetricCard(
                          label: 'Velocidad',
                          value: '${data.speed}',
                          unit: 'km/h',
                          icon: Icons.directions_car_outlined,
                          color: AppTheme.primary,
                        ),
                        _MetricCard(
                          label: 'Batería',
                          value: data.batteryVoltage.toStringAsFixed(1),
                          unit: 'V',
                          icon: Icons.battery_full_outlined,
                          color: data.batteryVoltage < 12
                              ? AppTheme.severityUrgent
                              : data.batteryVoltage < 12.5
                              ? AppTheme.severityMedium
                              : AppTheme.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Acciones',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    CustomButton(
                      label: 'Ver códigos de falla',
                      icon: Icons.search_outlined,
                      onPressed: () => Navigator.pushNamed(
                        context,
                        AppRouter.diagnosis,
                        arguments: _obd,
                      ),
                    ),
                    const SizedBox(height: 10),
                    CustomButton(
                      label: 'Ver historial',
                      icon: Icons.history_outlined,
                      isOutlined: true,
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRouter.history),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniIndicator extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniIndicator({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(unit, style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppTheme.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
