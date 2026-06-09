import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DiagnosisScreen extends StatelessWidget {
  const DiagnosisScreen({super.key});

  // Mock de códigos OBD — cuando llegue la API esto viene de ai_service.dart
  static const List<Map<String, dynamic>> _mockCodes = [
    {
      'code': 'P0300',
      'issue': 'Fallo en cilindros',
      'explanation':
          'Tu motor está fallando en uno o más cilindros. Puede sentirse como vibración o pérdida de potencia.',
      'severity': 'urgent',
    },
    {
      'code': 'P0171',
      'issue': 'Mezcla de combustible pobre',
      'explanation':
          'El motor está recibiendo muy poco combustible o demasiado aire. Puede aumentar el consumo.',
      'severity': 'medium',
    },
    {
      'code': 'P0420',
      'issue': 'Eficiencia del catalizador baja',
      'explanation':
          'El catalizador no está funcionando al 100%. No es urgente pero debe revisarse pronto.',
      'severity': 'low',
    },
  ];

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
          'Diagnóstico',
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
                'Códigos detectados',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Se encontraron ${_mockCodes.length} problemas en tu vehículo',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),

              Expanded(
                child: ListView.separated(
                  itemCount: _mockCodes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = _mockCodes[index];
                    return _DiagnosisCard(
                      code: item['code'],
                      issue: item['issue'],
                      explanation: item['explanation'],
                      severity: item['severity'],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  final String code;
  final String issue;
  final String explanation;
  final String severity;

  const _DiagnosisCard({
    required this.code,
    required this.issue,
    required this.explanation,
    required this.severity,
  });

  Color get _severityColor {
    switch (severity) {
      case 'urgent':
        return AppTheme.severityUrgent;
      case 'medium':
        return AppTheme.severityMedium;
      default:
        return AppTheme.severityLow;
    }
  }

  String get _severityLabel {
    switch (severity) {
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _severityColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Código OBD
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
                  code,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Spacer(),
              // Badge de severidad
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
            ],
          ),
          const SizedBox(height: 12),
          Text(issue, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(explanation, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
