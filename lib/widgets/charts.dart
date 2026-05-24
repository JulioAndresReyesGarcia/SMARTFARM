import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:smartfarm_ai/models/time_series.dart';

class LineSeriesCard extends StatelessWidget {
  final String title;
  final List<TimeSeriesPoint> points;
  final String? emptyText;

  const LineSeriesCard({
    super.key,
    required this.title,
    required this.points,
    this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (points.length < 2)
              Text(
                emptyText ?? 'No hay suficientes datos para graficar.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              )
            else
              SizedBox(
                height: 220,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: true),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: true),
                    lineBarsData: [
                      LineChartBarData(
                        spots: [
                          for (var i = 0; i < points.length; i++) FlSpot(i.toDouble(), points[i].value),
                        ],
                        isCurved: true,
                        barWidth: 3,
                        color: cs.primary,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(show: true, color: cs.primary.withValues(alpha: 0.12)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class CostsVsProductionCard extends StatelessWidget {
  final String title;
  final List<DualTimeSeriesPoint> points;

  const CostsVsProductionCard({
    super.key,
    required this.title,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (points.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'No hay datos para comparar costos vs producción.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }

    final max = points.fold<double>(0, (m, p) => [m, p.a, p.b].reduce((x, y) => x > y ? x : y));
    final yMax = (max <= 0 ? 1.0 : max) * 1.2;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: yMax,
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(enabled: true),
                  barGroups: [
                    for (var i = 0; i < points.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(toY: points[i].a, color: cs.tertiary, width: 8, borderRadius: BorderRadius.circular(3)),
                          BarChartRodData(toY: points[i].b, color: cs.primary, width: 8, borderRadius: BorderRadius.circular(3)),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _LegendDot(label: 'Costos', color: cs.tertiary),
                _LegendDot(label: 'Producción', color: cs.primary),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendDot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(999))),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: cs.onSurfaceVariant)),
      ],
    );
  }
}

