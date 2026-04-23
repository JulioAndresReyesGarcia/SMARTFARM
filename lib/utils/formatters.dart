import 'package:intl/intl.dart';

class Formatters {
  static final DateFormat date = DateFormat('yyyy-MM-dd');
  static final NumberFormat number = NumberFormat('#,##0.##');
  static final NumberFormat money = NumberFormat.currency(locale: 'es', symbol: r'$');
}

