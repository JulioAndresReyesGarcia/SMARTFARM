class TimeSeriesPoint {
  final DateTime date;
  final double value;

  const TimeSeriesPoint({required this.date, required this.value});
}

class DualTimeSeriesPoint {
  final DateTime date;
  final double a;
  final double b;

  const DualTimeSeriesPoint({required this.date, required this.a, required this.b});
}

