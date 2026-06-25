/// A collection of smart validators that go beyond simple regex matching.
///
/// Each validator returns `null` if valid, or an error message string if invalid.
class SmartValidators {
  SmartValidators._();

  /// Common email domain typos and their corrections.
  static const Map<String, String> _emailTypos = {
    'gmial.com': 'gmail.com',
    'gmal.com': 'gmail.com',
    'gmaill.com': 'gmail.com',
    'gamil.com': 'gmail.com',
    'gnail.com': 'gmail.com',
    'gmail.co': 'gmail.com',
    'gmail.con': 'gmail.com',
    'gmail.cm': 'gmail.com',
    'gmai.com': 'gmail.com',
    'gmil.com': 'gmail.com',
    'yahooo.com': 'yahoo.com',
    'yaho.com': 'yahoo.com',
    'yahoo.co': 'yahoo.com',
    'yahoo.con': 'yahoo.com',
    'yhaoo.com': 'yahoo.com',
    'hotmal.com': 'hotmail.com',
    'hotmai.com': 'hotmail.com',
    'hotmial.com': 'hotmail.com',
    'hotmail.co': 'hotmail.com',
    'hotmail.con': 'hotmail.com',
    'outlok.com': 'outlook.com',
    'outloo.com': 'outlook.com',
    'outlook.co': 'outlook.com',
    'outlook.con': 'outlook.com',
    'iclod.com': 'icloud.com',
    'icloud.co': 'icloud.com',
    'icoud.com': 'icloud.com',
    'protonmal.com': 'protonmail.com',
    'protonmai.com': 'protonmail.com',
  };

  /// Validates an email address with optional typo detection.
  ///
  /// When [suggestCorrection] is provided, it will be called with the
  /// suggested domain correction if a typo is detected.
  static String? Function(String?) email({
    String errorMessage = 'Please enter a valid email address',
    String typoMessage = 'Did you mean',
    void Function(String suggestion)? suggestCorrection,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;

      final trimmed = value.trim().toLowerCase();

      // Basic structure check
      final emailRegex = RegExp(
        r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,253}[a-zA-Z0-9])?)*$',
      );

      if (!emailRegex.hasMatch(trimmed)) return errorMessage;

      // Check for domain typos
      final atIndex = trimmed.indexOf('@');
      if (atIndex == -1) return errorMessage;

      final domain = trimmed.substring(atIndex + 1);
      final correction = _emailTypos[domain];

      if (correction != null) {
        final suggested = '${trimmed.substring(0, atIndex + 1)}$correction';
        suggestCorrection?.call(suggested);
        return '$typoMessage $suggested?';
      }

      return null;
    };
  }

  /// Validates a phone number with configurable length and country code.
  static String? Function(String?) phone({
    String errorMessage = 'Please enter a valid phone number',
    int minDigits = 7,
    int maxDigits = 15,
    bool allowCountryCode = true,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;

      // Strip everything except digits and leading +
      final cleaned = value.trim();
      final hasCountryCode = cleaned.startsWith('+');
      final digits = cleaned.replaceAll(RegExp(r'[^\d]'), '');

      if (digits.length < minDigits || digits.length > maxDigits) {
        return errorMessage;
      }

      if (hasCountryCode && !allowCountryCode) {
        return errorMessage;
      }

      return null;
    };
  }

  /// Validates a URL.
  static String? Function(String?) url({
    String errorMessage = 'Please enter a valid URL',
    bool requireHttps = false,
    List<String>? allowedSchemes,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;

      final trimmed = value.trim();

      // Auto-prepend https:// if no scheme
      final withScheme = trimmed.contains('://') ? trimmed : 'https://$trimmed';

      final uri = Uri.tryParse(withScheme);
      if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
        return errorMessage;
      }

      if (requireHttps && uri.scheme != 'https') {
        return errorMessage;
      }

      if (allowedSchemes != null && !allowedSchemes.contains(uri.scheme)) {
        return errorMessage;
      }

      // Must have at least one dot in the host (unless localhost)
      if (!uri.host.contains('.') && uri.host != 'localhost') {
        return errorMessage;
      }

      return null;
    };
  }

  /// Validates a credit card number using the Luhn algorithm.
  static String? Function(String?) creditCard({
    String errorMessage = 'Please enter a valid card number',
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;

      final digits = value.replaceAll(RegExp(r'[\s-]'), '');

      if (!RegExp(r'^\d+$').hasMatch(digits)) return errorMessage;
      if (digits.length < 13 || digits.length > 19) return errorMessage;

      // Luhn algorithm
      if (!_luhnCheck(digits)) return errorMessage;

      return null;
    };
  }

  /// Detects the credit card brand from the number.
  static CardBrand detectCardBrand(String number) {
    final digits = number.replaceAll(RegExp(r'[\s-]'), '');

    if (digits.startsWith('4')) return CardBrand.visa;
    if (RegExp(r'^5[1-5]').hasMatch(digits) ||
        RegExp(r'^2[2-7]').hasMatch(digits)) {
      return CardBrand.mastercard;
    }
    if (digits.startsWith('34') || digits.startsWith('37')) {
      return CardBrand.amex;
    }
    if (digits.startsWith('6011') ||
        digits.startsWith('65') ||
        digits.startsWith('644') ||
        digits.startsWith('645') ||
        digits.startsWith('646') ||
        digits.startsWith('647') ||
        digits.startsWith('648') ||
        digits.startsWith('649')) {
      return CardBrand.discover;
    }

    return CardBrand.unknown;
  }

  /// Validates that a value falls within a numeric range.
  static String? Function(String?) numericRange({
    String errorMessage = 'Value is out of range',
    double? min,
    double? max,
    bool allowDecimals = true,
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;

      final number = double.tryParse(value.trim());
      if (number == null) return errorMessage;

      if (!allowDecimals && number != number.roundToDouble()) {
        return errorMessage;
      }

      if (min != null && number < min) {
        return '$errorMessage (minimum: $min)';
      }

      if (max != null && number > max) {
        return '$errorMessage (maximum: $max)';
      }

      return null;
    };
  }

  /// Validates against a custom regex pattern.
  static String? Function(String?) pattern({
    required RegExp regex,
    String errorMessage = 'Invalid format',
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;
      if (!regex.hasMatch(value.trim())) return errorMessage;
      return null;
    };
  }

  /// Validates that the value is not empty.
  static String? Function(String?) required({
    String errorMessage = 'This field is required',
  }) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) return errorMessage;
      return null;
    };
  }

  /// Validates minimum length.
  static String? Function(String?) minLength({
    required int length,
    String? errorMessage,
  }) {
    return (String? value) {
      if (value == null || value.trim().length < length) {
        return errorMessage ?? 'Must be at least $length characters';
      }
      return null;
    };
  }

  /// Validates maximum length.
  static String? Function(String?) maxLength({
    required int length,
    String? errorMessage,
  }) {
    return (String? value) {
      if (value != null && value.trim().length > length) {
        return errorMessage ?? 'Must be at most $length characters';
      }
      return null;
    };
  }

  /// Combines multiple validators. Returns the first error found.
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (String? value) {
      for (final validator in validators) {
        final error = validator(value);
        if (error != null) return error;
      }
      return null;
    };
  }

  /// Luhn algorithm implementation.
  static bool _luhnCheck(String number) {
    int sum = 0;
    bool alternate = false;

    for (int i = number.length - 1; i >= 0; i--) {
      int digit = int.parse(number[i]);

      if (alternate) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }

      sum += digit;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}

/// Known credit card brands.
enum CardBrand {
  visa,
  mastercard,
  amex,
  discover,
  unknown,
}
