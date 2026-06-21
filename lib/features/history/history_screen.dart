import 'dart:convert';

import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../core/services/diagnosis_queue.dart';
import '../../core/models/diagnosis_request.dart';

class HistoryScreen extends StatelessWidget {
  final DiagnosisQueue? diagnosisQueue;
  final VoidCallback? onBackToHome;

  const HistoryScreen({super.key, this.diagnosisQueue, this.onBackToHome});

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
      body: diagnosisQueue == null
          ? const _EmptyState()
          : ListenableBuilder(
              listenable: diagnosisQueue!,
              builder: (context, _) {
                final requests = diagnosisQueue!.requests;
                if (requests.isEmpty) return const _EmptyState();
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: requests.length,
                  itemBuilder: (context, index) =>
                      _HistoryCard(request: requests[index]),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_outlined, size: 64, color: AppTheme.textHint),
          const SizedBox(height: 20),
          Text(
            'Sin diagnósticos aún',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Los diagnósticos aparecerán aquí\ndespués de escanear y diagnosticar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DiagnosisRequest request;

  const _HistoryCard({required this.request});

  Color get _statusColor {
    switch (request.status) {
      case DiagnosisStatus.pending:
        return AppTheme.severityMedium;
      case DiagnosisStatus.sending:
        return AppTheme.severityMedium;
      case DiagnosisStatus.completed:
        return AppTheme.severityLow;
      case DiagnosisStatus.failed:
        return AppTheme.severityUrgent;
    }
  }

  String get _statusLabel {
    switch (request.status) {
      case DiagnosisStatus.pending:
        return 'Pendiente';
      case DiagnosisStatus.sending:
        return 'Enviando...';
      case DiagnosisStatus.completed:
        return 'Completado';
      case DiagnosisStatus.failed:
        return 'Fallido';
    }
  }

  String get _codesSummary {
    if (request.dtcCodes.isEmpty) return 'Sin códigos';
    return request.dtcCodes.map((c) => c.code).join(', ');
  }

  String get _dateLabel {
    final d = request.createdAt;
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Ahora';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
    if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
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
                    color: _statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        request.status == DiagnosisStatus.pending
                            ? Icons.hourglass_empty_outlined
                            : request.status == DiagnosisStatus.sending
                                ? Icons.sync_outlined
                                : request.status == DiagnosisStatus.completed
                                    ? Icons.check_circle_outlined
                                    : Icons.error_outline,
                        size: 14,
                        color: _statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _statusLabel,
                        style: TextStyle(
                          fontSize: 12,
                          color: _statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _dateLabel,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppTheme.textHint),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _codesSummary,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontFamily: 'monospace',
              ),
            ),
            if (request.status == DiagnosisStatus.completed &&
                request.resultJson != null) ...[
              const SizedBox(height: 10),
              _ResultPreview(resultJson: request.resultJson!),
            ],
          ],
        ),
      ),
    );
  }
}

class _ResultPreview extends StatelessWidget {
  final String resultJson;

  const _ResultPreview({required this.resultJson});

  @override
  Widget build(BuildContext context) {
    try {
      final data = jsonDecode(resultJson) as Map<String, dynamic>;
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return const SizedBox.shrink();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: AppTheme.surfaceLight, thickness: 1),
          const SizedBox(height: 8),
          ...results.take(3).map((r) {
            final code = r['code'] as String? ?? '';
            final desc = r['description'] as String? ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    code,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.primary,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      desc,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (results.length > 3)
            Text(
              '... y ${results.length - 3} más',
              style: Theme.of(context).textTheme.labelSmall,
            ),
        ],
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
