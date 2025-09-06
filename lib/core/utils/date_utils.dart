import 'package:intl/intl.dart';

class AppDateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
  
  static String formatDateRange(DateTime startDate, DateTime endDate) {
    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }
  
  static int calculateDaysDifference(DateTime startDate, DateTime endDate) {
    return endDate.difference(startDate).inDays;
  }
}


















