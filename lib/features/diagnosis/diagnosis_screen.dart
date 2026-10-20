import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../core/services/obd_manager.dart';
import '../../core/services/diagnosis_http_service.dart';
import '../../core/models/obd_data.dart';
import '../../shared/widgets/custom_button.dart';
import '../../shared/widgets/success_banner.dart';

class DiagnosisScreen extends StatefulWidget {
  final ObdManager? obdManager;
  final DiagnosisHttpService? diagnosisService;
  final VoidCallback? onBackToHome;

  const DiagnosisScreen({super.key, this.obdManager, this.diagnosisService, this.onBackToHome});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];
  bool _scanning = false;
  bool _diagnosing = false;

  ObdManager? get _obd => widget.obdManager ?? AppRouter.sharedObdManager;
  DiagnosisHttpService? get _diagnosisService =>
      widget.diagnosisService ?? AppRouter.sharedDiagnosisHttpService;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _setupAnimations();
  }

  void _setupAnimations() {
    final codes = _obd?.dtcCodes ?? [];
    if (codes.isEmpty) {
      _controller.forward();
      return;
    }
    _slideAnimations.clear();
    _fadeAnimations.clear();
    for (int i = 0; i < codes.length; i++) {
      final start = i * 0.2;
      final end = start + 0.6;
      _slideAnimations.add(
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
      _fadeAnimations.add(
        Tween<double>(begin: 0, end: 1).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeOut),
          ),
        ),
      );
    }
    _controller.forward();
  }

  Future<void> _scanForCodes() async {
    final obd = _obd;
    if (obd == null) return;
    setState(() => _scanning = true);
    await obd.scanDtc();
    if (!mounted) return;
    setState(() => _scanning = false);
    _controller.reset();
    _setupAnimations();

    if (obd.dtcCodes.isEmpty && obd.hasScannedDtc) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Escaneo completado: no se detectaron alertas ni códigos de error.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.severityLow,
        ),
      );
    }
  }

  Future<void> _diagnose() async {
    final obd = _obd;
    final service = _diagnosisService;
    if (obd == null || service == null) return;
    final codes = obd.dtcCodes;
    if (codes.isEmpty) return;

    setState(() => _diagnosing = true);

    await service.diagnose(
      dtcCodes: codes,
      vehicleData: obd.vehicleData,
    );

    if (!mounted) return;
    setState(() => _diagnosing = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          service.online
              ? 'Diagnóstico completado. Revisa el Historial.'
              : 'Diagnóstico encolado. Se enviará cuando tengas internet.',
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: service.online
            ? AppTheme.severityLow
            : AppTheme.severityMedium,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final obd = _obd;
    if (obd == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          title: Text(
            'Diagnóstico',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        body: const Center(
          child: Text('Servicio OBD no disponible.'),
        ),
      );
    }

    return ListenableBuilder(
      listenable: obd,
      builder: (context, _) {
        final codes = obd.dtcCodes;
        final urgent = codes.where((c) => c.severity == 'urgent').length;
        final medium = codes.where((c) => c.severity == 'medium').length;
        final low = codes.where((c) => c.severity == 'low').length;
        final showBackButton =
            Navigator.canPop(context) || widget.onBackToHome != null;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppTheme.background,
            elevation: 0,
            leading: showBackButton
                ? IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_outlined),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        widget.onBackToHome?.call();
                      }
                    },
                  )
                : null,
            title: Text(
              'Diagnóstico',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (codes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Resumen del escaneo',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              _SeveritySummary(
                                count: urgent,
                                label: 'Urgente',
                                color: AppTheme.severityUrgent,
                              ),
                              const SizedBox(width: 12),
                              _SeveritySummary(
                                count: medium,
                                label: 'Moderado',
                                color: AppTheme.severityMedium,
                              ),
                              const SizedBox(width: 12),
                              _SeveritySummary(
                                count: low,
                                label: 'Leve',
                                color: AppTheme.severityLow,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (codes.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Códigos detectados',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: codes.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final animIndex = index < _slideAnimations.length
                            ? index
                            : 0;
                        if (_slideAnimations.length <= index) {
                          return const SizedBox.shrink();
                        }
                        return SlideTransition(
                          position: _slideAnimations[animIndex],
                          child: FadeTransition(
                            opacity: _fadeAnimations[animIndex],
                            child: _DiagnosisCard(code: codes[index]),
                          ),
                        );
                      },
                    ),
                  ],
                  if (codes.isEmpty && !_scanning && obd.hasScannedDtc) ...[
                    SuccessBanner(
                      title: 'Sin alertas detectadas',
                      message:
                          'El escaneo confirmó que no hay códigos de error '
                          'activos en el vehículo. Todo parece estar en orden.',
                    ),
                    const SizedBox(height: 24),
                  ],
                  if (codes.isEmpty &&
                      !_scanning &&
                      !obd.hasScannedDtc &&
                      obd.isConnected) ...[
                    const SizedBox(height: 40),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.radar_outlined,
                            color: AppTheme.primary,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Listo para escanear',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Pulsa "Escanear códigos" para verificar si hay '
                            'alertas en el vehículo.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (codes.isEmpty &&
                      !_scanning &&
                      !obd.hasScannedDtc &&
                      !obd.isConnected) ...[
                    const SizedBox(height: 60),
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.link_off_outlined,
                            color: AppTheme.textHint,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Conecta el adaptador OBD',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Conecta el sensor para poder escanear y confirmar '
                            'si hay alertas.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_scanning)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            CircularProgressIndicator(color: AppTheme.primary),
                            SizedBox(height: 12),
                            Text('Escaneando códigos...'),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  CustomButton(
                    label: _scanning ? 'Escaneando...' : 'Escanear códigos',
                    icon: Icons.refresh_outlined,
                    isOutlined: true,
                    onPressed:
                        obd.isConnected ? (_scanning ? null : _scanForCodes) : null,
                  ),
                  if (!obd.isConnected)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 14,
                            color: AppTheme.textHint,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Conecta el sensor OBD para escanear',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: AppTheme.textHint),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  if (obd.dtcCodes.isNotEmpty)
                    CustomButton(
                      label: _diagnosing
                          ? 'Diagnosticando...'
                          : 'Diagnosticar',
                      icon: Icons.biotech_outlined,
                      isOutlined: false,
                      onPressed: obd.isConnected
                          ? (_diagnosing || _scanning ? null : _diagnose)
                          : null,
                    ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SeveritySummary extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _SeveritySummary({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchDisclaimer extends StatelessWidget {
  final DtcCode code;

  const _MatchDisclaimer({required this.code});

  @override
  Widget build(BuildContext context) {
    final isFamily = code.isFamilyMatch;
    final color = isFamily ? AppTheme.severityMedium : AppTheme.textHint;
    final icon = isFamily ? Icons.info_outline_rounded : Icons.help_outline_rounded;
    final text = isFamily
        ? 'Sin ficha exacta. Orientación por familia '
            '${code.familyKey ?? ''} (${code.familyLabel ?? 'relacionada'})'
            '${code.relatedCode != null ? '. Referencia: ${code.relatedCode}' : ''}.'
        : 'Código no encontrado en la base local. La información es genérica.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagnosisCard extends StatefulWidget {
  final DtcCode code;

  const _DiagnosisCard({required this.code});

  @override
  State<_DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<_DiagnosisCard> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.code.severity) {
      case 'urgent':
        return AppTheme.severityUrgent;
      case 'medium':
        return AppTheme.severityMedium;
      default:
        return AppTheme.severityLow;
    }
  }

  String get _severityLabel {
    switch (widget.code.severity) {
      case 'urgent':
        return 'Urgente';
      case 'medium':
        return 'Moderado';
      default:
        return 'Leve';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expanded
                ? _severityColor.withValues(alpha: 0.5)
                : _severityColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.code.code,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _severityColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _severityLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _severityColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textHint,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.code.description,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (widget.code.isFamilyMatch || widget.code.isUnknownMatch) ...[
              const SizedBox(height: 10),
              _MatchDisclaimer(code: widget.code),
            ],
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Divider(color: AppTheme.surfaceLight, thickness: 1),
                  const SizedBox(height: 10),
                  if (widget.code.explanation != null &&
                      widget.code.explanation!.isNotEmpty) ...[
                    Text(
                      widget.code.explanation!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                  ],
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.recommend_outlined,
                        color: _severityColor,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.code.recommendation,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: _severityColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
