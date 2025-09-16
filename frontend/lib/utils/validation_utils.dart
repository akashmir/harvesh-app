/// Common validation utilities used across multiple screens
class ValidationUtils {
  /// Email validation regex
  static final RegExp _emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  /// Phone number validation regex (Indian format)
  static final RegExp _phoneRegex = RegExp(r'^[6-9]\d{9}$');

  /// Password validation regex (at least 6 characters, 1 uppercase, 1 lowercase, 1 number)
  static final RegExp _passwordRegex =
      RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{6,}$');

  /// Validates email address
  static String? validateEmail(String? value, {bool isRequired = true}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Email is required';
    }

    if (value != null && value.isNotEmpty) {
      if (!_emailRegex.hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    return null;
  }

  /// Validates password
  static String? validatePassword(
    String? value, {
    bool isRequired = true,
    int minLength = 6,
    bool requireComplexity = false,
  }) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Password is required';
    }

    if (value != null && value.isNotEmpty) {
      if (value.length < minLength) {
        return 'Password must be at least $minLength characters';
      }

      if (requireComplexity && !_passwordRegex.hasMatch(value)) {
        return 'Password must contain at least one uppercase letter, one lowercase letter, and one number';
      }
    }

    return null;
  }

  /// Validates phone number (Indian format)
  static String? validatePhone(String? value, {bool isRequired = false}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Phone number is required';
    }

    if (value != null && value.isNotEmpty) {
      // Remove all non-digit characters
      final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');

      if (digitsOnly.length != 10) {
        return 'Please enter a valid 10-digit phone number';
      }

      if (!_phoneRegex.hasMatch(digitsOnly)) {
        return 'Phone numbers must start with 6, 7, 8, or 9';
      }
    }

    return null;
  }

  /// Validates numeric input
  static String? validateNumeric(
    String? value, {
    bool isRequired = true,
    double? minValue,
    double? maxValue,
    String? fieldName,
  }) {
    if (isRequired && (value == null || value.isEmpty)) {
      return '${fieldName ?? 'This field'} is required';
    }

    if (value != null && value.isNotEmpty) {
      final numValue = double.tryParse(value);
      if (numValue == null) {
        return 'Please enter a valid number';
      }

      if (minValue != null && numValue < minValue) {
        return '${fieldName ?? 'Value'} must be at least $minValue';
      }

      if (maxValue != null && numValue > maxValue) {
        return '${fieldName ?? 'Value'} must be at most $maxValue';
      }
    }

    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.isEmpty) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validates text length
  static String? validateLength(
    String? value, {
    int? minLength,
    int? maxLength,
    String? fieldName,
  }) {
    if (value != null && value.isNotEmpty) {
      if (minLength != null && value.length < minLength) {
        return '${fieldName ?? 'Text'} must be at least $minLength characters';
      }

      if (maxLength != null && value.length > maxLength) {
        return '${fieldName ?? 'Text'} must be at most $maxLength characters';
      }
    }

    return null;
  }

  /// Validates crop recommendation input fields
  static String? validateCropInput(
    String? value, {
    required String fieldName,
    double? minValue,
    double? maxValue,
  }) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    final numValue = double.tryParse(value);
    if (numValue == null) {
      return 'Please enter a valid number for $fieldName';
    }

    if (minValue != null && numValue < minValue) {
      return '$fieldName must be at least $minValue';
    }

    if (maxValue != null && numValue > maxValue) {
      return '$fieldName must be at most $maxValue';
    }

    return null;
  }

  /// Validates nitrogen input (0-200)
  static String? validateNitrogen(String? value) {
    return validateCropInput(
      value,
      fieldName: 'Nitrogen',
      minValue: 0,
      maxValue: 200,
    );
  }

  /// Validates phosphorus input (0-200)
  static String? validatePhosphorus(String? value) {
    return validateCropInput(
      value,
      fieldName: 'Phosphorus',
      minValue: 0,
      maxValue: 200,
    );
  }

  /// Validates potassium input (0-200)
  static String? validatePotassium(String? value) {
    return validateCropInput(
      value,
      fieldName: 'Potassium',
      minValue: 0,
      maxValue: 200,
    );
  }

  /// Validates temperature input (-50 to 60)
  static String? validateTemperature(String? value) {
    return validateCropInput(
      value,
      fieldName: 'Temperature',
      minValue: -50,
      maxValue: 60,
    );
  }

  /// Validates humidity input (0-100)
  static String? validateHumidity(String? value) {
    return validateCropInput(
      value,
      fieldName: 'Humidity',
      minValue: 0,
      maxValue: 100,
    );
  }

  /// Validates pH input (0-14)
  static String? validatePH(String? value) {
    return validateCropInput(
      value,
      fieldName: 'pH',
      minValue: 0,
      maxValue: 14,
    );
  }

  /// Validates rainfall input (0-500)
  static String? validateRainfall(String? value) {
    return validateCropInput(
      value,
      fieldName: 'Rainfall',
      minValue: 0,
      maxValue: 500,
    );
  }

  /// Validates confirm password
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }

    if (value != password) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Validates name input
  static String? validateName(String? value, {String fieldName = 'Name'}) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }

    if (value.length < 2) {
      return '$fieldName must be at least 2 characters';
    }

    if (value.length > 50) {
      return '$fieldName must be at most 50 characters';
    }

    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return '$fieldName can only contain letters, spaces, hyphens, and apostrophes';
    }

    return null;
  }

  /// Validates age input
  static String? validateAge(String? value, {bool isRequired = true}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Age is required';
    }

    if (value != null && value.isNotEmpty) {
      final age = int.tryParse(value);
      if (age == null) {
        return 'Please enter a valid age';
      }

      if (age < 0) {
        return 'Age cannot be negative';
      }

      if (age > 150) {
        return 'Please enter a valid age';
      }
    }

    return null;
  }

  /// Validates URL
  static String? validateUrl(String? value, {bool isRequired = false}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'URL is required';
    }

    if (value != null && value.isNotEmpty) {
      final uri = Uri.tryParse(value);
      if (uri == null || (!uri.hasScheme || (!uri.scheme.startsWith('http')))) {
        return 'Please enter a valid URL';
      }
    }

    return null;
  }

  /// Validates date of birth
  static String? validateDateOfBirth(String? value, {bool isRequired = true}) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Date of birth is required';
    }

    if (value != null && value.isNotEmpty) {
      final date = DateTime.tryParse(value);
      if (date == null) {
        return 'Please enter a valid date';
      }

      final now = DateTime.now();
      if (date.isAfter(now)) {
        return 'Date of birth cannot be in the future';
      }

      final age = now.year - date.year;
      if (age < 13) {
        return 'You must be at least 13 years old';
      }

      if (age > 150) {
        return 'Please enter a valid date of birth';
      }
    }

    return null;
  }
}
