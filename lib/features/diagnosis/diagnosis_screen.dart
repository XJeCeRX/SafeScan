import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DiagnosisScreen extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const DiagnosisScreen({super.key, this.onBackToHome});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  static const List<Map<String, dynamic>> _mockCodes = [
    {
      'code': 'P0300',
      'issue': 'Fallo en cilindros',
      'explanation':
          'Tu motor está fallando en uno o más cilindros. Puede sentirse como vibración o pérdida de potencia.',
      'severity': 'urgent',
      'recommendation': 'Ve a un taller lo antes posible.',
    },
    {
      'code': 'P0171',
      'issue': 'Mezcla de combustible pobre',
      'explanation':
          'El motor está recibiendo muy poco combustible o demasiado aire. Puede aumentar el consumo.',
      'severity': 'medium',
      'recommendation': 'Revisa el filtro de aire y los inyectores.',
    },
    {
      'code': 'P0420',
      'issue': 'Eficiencia del catalizador baja',
      'explanation':
          'El catalizador no está funcionando al 100%. No es urgente pero debe revisarse pronto.',
      'severity': 'low',
      'recommendation': 'Puedes seguir manejando, pero agenda una revisión.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    for (int i = 0; i < _mockCodes.length; i++) {
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final urgent = _mockCodes.where((c) => c['severity'] == 'urgent').length;
    final medium = _mockCodes.where((c) => c['severity'] == 'medium').length;
    final low = _mockCodes.where((c) => c['severity'] == 'low').length;

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
              widget.onBackToHome?.call();
            }
          },
        ),
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
              // Resumen de severidades
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

              const SizedBox(height: 24),

              Text(
                'Códigos detectados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),

              // Lista animada
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _mockCodes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  return SlideTransition(
                    position: _slideAnimations[index],
                    child: FadeTransition(
                      opacity: _fadeAnimations[index],
                      child: _DiagnosisCard(
                        code: _mockCodes[index]['code'],
                        issue: _mockCodes[index]['issue'],
                        explanation: _mockCodes[index]['explanation'],
                        severity: _mockCodes[index]['severity'],
                        recommendation: _mockCodes[index]['recommendation'],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
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
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
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

class _DiagnosisCard extends StatefulWidget {
  final String code;
  final String issue;
  final String explanation;
  final String severity;
  final String recommendation;

  const _DiagnosisCard({
    required this.code,
    required this.issue,
    required this.explanation,
    required this.severity,
    required this.recommendation,
  });

  @override
  State<_DiagnosisCard> createState() => _DiagnosisCardState();
}

class _DiagnosisCardState extends State<_DiagnosisCard> {
  bool _expanded = false;

  Color get _severityColor {
    switch (widget.severity) {
      case 'urgent':
        return AppTheme.severityUrgent;
      case 'medium':
        return AppTheme.severityMedium;
      default:
        return AppTheme.severityLow;
    }
  }

  String get _severityLabel {
    switch (widget.severity) {
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
                ? _severityColor.withOpacity(0.5)
                : _severityColor.withOpacity(0.2),
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
                    widget.code,
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
                    color: _severityColor.withOpacity(0.15),
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
            Text(widget.issue, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              widget.explanation,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Expandible — recomendación
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
                          widget.recommendation,
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
