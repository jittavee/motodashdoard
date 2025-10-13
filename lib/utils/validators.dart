class Validators {
  // Email Validation
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Phone Number Validation (Thai format)
  static bool isValidThaiPhone(String phone) {
    final phoneRegex = RegExp(r'^0[0-9]{9}$');
    return phoneRegex.hasMatch(phone);
  }

  // Number Validation
  static bool isValidNumber(String value) {
    return double.tryParse(value) != null;
  }

  // Positive Number Validation
  static bool isPositiveNumber(String value) {
    final number = double.tryParse(value);
    return number != null && number > 0;
  }

  // Range Validation
  static bool isInRange(double value, double min, double max) {
    return value >= min && value <= max;
  }

  // Empty String Validation
  static bool isNotEmpty(String? value) {
    return value != null && value.trim().isNotEmpty;
  }

  // Min Length Validation
  static bool hasMinLength(String value, int minLength) {
    return value.length >= minLength;
  }

  // Max Length Validation
  static bool hasMaxLength(String value, int maxLength) {
    return value.length <= maxLength;
  }

  // Bluetooth Device Name Validation
  static bool isValidDeviceName(String name) {
    return isNotEmpty(name) && name.length <= 50;
  }

  // Speed Validation (0-400 km/h)
  static bool isValidSpeed(double speed) {
    return isInRange(speed, 0, 400);
  }

  // RPM Validation (0-10000)
  static bool isValidRPM(double rpm) {
    return isInRange(rpm, 0, 10000);
  }

  // Temperature Validation (-50 to 200 Celsius)
  static bool isValidTemperature(double temp) {
    return isInRange(temp, -50, 200);
  }

  // Pressure Validation (0-100 bar)
  static bool isValidPressure(double pressure) {
    return isInRange(pressure, 0, 100);
  }
}
