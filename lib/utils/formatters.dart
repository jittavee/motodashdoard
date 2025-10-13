import 'package:intl/intl.dart';

class Formatters {
  // Number Formatters
  static String formatNumber(double number, {int decimals = 0}) {
    return number.toStringAsFixed(decimals);
  }

  static String formatWithComma(double number, {int decimals = 0}) {
    final formatter = NumberFormat('#,##0.${'0' * decimals}');
    return formatter.format(number);
  }

  // Speed Formatters
  static String formatSpeed(double speed, {bool showUnit = true}) {
    final formatted = formatNumber(speed, decimals: 0);
    return showUnit ? '$formatted km/h' : formatted;
  }

  // RPM Formatters
  static String formatRPM(double rpm, {bool showUnit = true}) {
    final formatted = formatWithComma(rpm, decimals: 0);
    return showUnit ? '$formatted RPM' : formatted;
  }

  // Temperature Formatters
  static String formatTemperature(double temp, {bool showUnit = true}) {
    final formatted = formatNumber(temp, decimals: 1);
    return showUnit ? '$formatted°C' : formatted;
  }

  // Pressure Formatters
  static String formatPressure(double pressure, {bool showUnit = true}) {
    final formatted = formatNumber(pressure, decimals: 2);
    return showUnit ? '$formatted bar' : formatted;
  }

  // Time Formatters
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  static String formatTime(Duration duration, {bool showMilliseconds = true}) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60);
    final milliseconds = duration.inMilliseconds.remainder(1000);

    if (showMilliseconds) {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}.${(milliseconds ~/ 10).toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // Date & Time Formatters
  static String formatDate(DateTime date, {String format = 'dd/MM/yyyy'}) {
    return DateFormat(format).format(date);
  }

  static String formatDateTime(DateTime dateTime,
      {String format = 'dd/MM/yyyy HH:mm:ss'}) {
    return DateFormat(format).format(dateTime);
  }

  static String formatTimeOfDay(DateTime time, {String format = 'HH:mm'}) {
    return DateFormat(format).format(time);
  }

  // Distance Formatters
  static String formatDistance(double meters, {bool showUnit = true}) {
    if (meters >= 1000) {
      final km = meters / 1000;
      final formatted = formatNumber(km, decimals: 2);
      return showUnit ? '$formatted km' : formatted;
    } else {
      final formatted = formatNumber(meters, decimals: 0);
      return showUnit ? '$formatted m' : formatted;
    }
  }

  // Percentage Formatters
  static String formatPercentage(double value, {int decimals = 0}) {
    final formatted = formatNumber(value, decimals: decimals);
    return '$formatted%';
  }

  // Bluetooth MAC Address Formatter
  static String formatMacAddress(String address) {
    if (address.length != 12) return address;
    return address.replaceAllMapped(
      RegExp(r'.{2}'),
      (match) => '${match.group(0)}:',
    ).substring(0, 17);
  }

  // File Size Formatter
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${formatNumber(bytes / 1024, decimals: 2)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${formatNumber(bytes / (1024 * 1024), decimals: 2)} MB';
    }
    return '${formatNumber(bytes / (1024 * 1024 * 1024), decimals: 2)} GB';
  }
}
