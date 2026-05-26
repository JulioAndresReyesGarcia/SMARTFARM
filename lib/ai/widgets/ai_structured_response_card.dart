import 'package:flutter/material.dart';
import 'package:smartfarm_ai/ai/models/ai_assistant_response.dart';
import 'package:smartfarm_ai/ai/models/risk_level.dart';
import 'package:smartfarm_ai/ai/models/veterinarian_suggestion.dart';

/// Tarjeta estructurada para respuestas del asistente ganadero.
class AiStructuredResponseCard extends StatelessWidget {
  const AiStructuredResponseCard({super.key, required this.response});

  final AiAssistantResponse response;

  Color _riskColor(ColorScheme cs) => switch (response.riskLevel) {
        RiskLevel.emergencia => cs.error,
        RiskLevel.alto => Colors.deepOrange,
        RiskLevel.medio => Colors.amber.shade800,
        RiskLevel.bajo => cs.primary,
      };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(child: Text(response.intent.label, style: tt.labelLarge)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _riskColor(cs).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    response.riskLevel.label,
                    style: tt.labelSmall?.copyWith(color: _riskColor(cs), fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(response.summary, style: tt.bodyMedium),
            if (response.probableAssessment != null) ...[
              const SizedBox(height: 10),
              Text('Evaluación orientativa', style: tt.titleSmall),
              const SizedBox(height: 4),
              Text(response.probableAssessment!, style: tt.bodySmall),
            ],
            if (response.detectedSymptoms.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Síntomas detectados', style: tt.titleSmall),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: response.detectedSymptoms
                    .map(
                      (s) => Chip(
                        label: Text(s, style: tt.labelSmall),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(growable: false),
              ),
            ],
            if (response.recommendations.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Recomendaciones', style: tt.titleSmall),
              const SizedBox(height: 4),
              ...response.recommendations.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: tt.bodySmall),
                      Expanded(child: Text(r, style: tt.bodySmall)),
                    ],
                  ),
                ),
              ),
            ],
            if (response.prevention.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Prevención', style: tt.titleSmall),
              const SizedBox(height: 4),
              ...response.prevention.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                      Expanded(child: Text(p, style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant))),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.local_hospital_outlined, size: 18, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        response.whenToSeeVet,
                        style: tt.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (response.veterinarians.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Veterinarios sugeridos', style: tt.titleSmall),
              const SizedBox(height: 6),
              ...response.veterinarians.map((v) => _VetTile(vet: v)),
            ],
            const SizedBox(height: 10),
            Text(
              response.disclaimer,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
            ),
            if (!response.usedCloudAi)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: cs.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          'Modo orientativo local',
                          style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                    if (response.cloudFallbackReason != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        response.cloudFallbackReason!,
                        style: tt.labelSmall?.copyWith(color: cs.error),
                      ),
                    ],
                  ],
                ),
              )
            else if (response.usedCloudAi)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(Icons.cloud_done_outlined, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                    Text(
                      response.cloudProviderName ?? 'IA en la nube',
                      style: tt.labelSmall?.copyWith(color: cs.primary),
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

class _VetTile extends StatelessWidget {
  const _VetTile({required this.vet});

  final VeterinarianSuggestion vet;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: vet.isEmergency ? cs.errorContainer : cs.primaryContainer,
        child: Icon(
          vet.isEmergency ? Icons.emergency : Icons.person,
          color: vet.isEmergency ? cs.onErrorContainer : cs.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(vet.name, style: tt.titleSmall),
      subtitle: Text('${vet.specialty}\n${vet.location}\n${vet.phone}', style: tt.bodySmall),
      isThreeLine: true,
    );
  }
}
