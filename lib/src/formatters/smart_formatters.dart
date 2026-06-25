import 'package:flutter/services.dart';

/// A collection of smart input formatters for common field types.
class SmartFormatters {
  SmartFormatters._();

  /// Formats input as a credit card number: `1234 5678 9012 3456`.
  ///
  /// Supports AMEX format (4-6-5) when [amexFormat] is true.
  static TextInputFormatter creditCard({bool amexFormat = false}) {
    return _CreditCardFormatter(amexFormat: amexFormat);
  }

  /// Formats input as a phone number.
  ///
  /// Default format: `(123) 456-7890` for 10-digit US numbers.
  /// Use [mask] to customize: `+# (###) ###-####`.
  /// `#` is replaced by digits.
  static TextInputFormatter phone({String mask = '(###) ###-####'}) {
    return _MaskFormatter(mask: mask);
  }

  /// Formats input as a date.
  ///
  /// Default format: `MM/DD/YYYY`. Use [mask] to customize.
  static TextInputFormatter date({String mask = '##/##/####'}) {
    return _MaskFormatter(mask: mask);
  }

  /// Formats input as currency: `1,234.56`.
  static TextInputFormatter currency({
    String symbol = '\$',
    String separator = ',',
    String decimal = '.',
    int decimalPlaces = 2,
    bool showSymbol = true,
  }) {
    return _CurrencyFormatter(
      symbol: symbol,
      separator: separator,
      decimal: decimal,
      decimalPlaces: decimalPlaces,
      showSymbol: showSymbol,
    );
  }

  /// Formats input using a custom mask pattern.
  ///
  /// `#` matches any digit.
  /// `A` matches any letter.
  /// `*` matches any character.
  /// All other characters are literal separators.
  ///
  /// Example: `###-##-####` for SSN format.
  static TextInputFormatter mask(String mask) {
    return _MaskFormatter(mask: mask);
  }

  /// Restricts input to digits only.
  static TextInputFormatter digitsOnly() {
    return FilteringTextInputFormatter.digitsOnly;
  }

  /// Uppercases all input.
  static TextInputFormatter uppercase() {
    return _UppercaseFormatter();
  }

  /// Lowercases all input.
  static TextInputFormatter lowercase() {
    return _LowercaseFormatter();
  }
}

class _CreditCardFormatter extends TextInputFormatter {
  final bool amexFormat;

  _CreditCardFormatter({this.amexFormat = false});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final maxLength = amexFormat ? 15 : 16;
    final trimmed = digits.length > maxLength
        ? digits.substring(0, maxLength)
        : digits;

    final buffer = StringBuffer();

    if (amexFormat) {
      // AMEX: 4-6-5
      for (int i = 0; i < trimmed.length; i++) {
        if (i == 4 || i == 10) buffer.write(' ');
        buffer.write(trimmed[i]);
      }
    } else {
      // Standard: 4-4-4-4
      for (int i = 0; i < trimmed.length; i++) {
        if (i > 0 && i % 4 == 0) buffer.write(' ');
        buffer.write(trimmed[i]);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _MaskFormatter extends TextInputFormatter {
  final String mask;

  _MaskFormatter({required this.mask});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final rawText = newValue.text.replaceAll(RegExp(r'[^\da-zA-Z]'), '');

    if (rawText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final buffer = StringBuffer();
    int rawIndex = 0;

    for (int i = 0; i < mask.length && rawIndex < rawText.length; i++) {
      final maskChar = mask[i];

      if (maskChar == '#') {
        // Digit placeholder
        if (rawIndex < rawText.length && RegExp(r'\d').hasMatch(rawText[rawIndex])) {
          buffer.write(rawText[rawIndex]);
          rawIndex++;
        } else {
          rawIndex++;
          i--; // retry this mask position
        }
      } else if (maskChar == 'A') {
        // Letter placeholder
        if (rawIndex < rawText.length && RegExp(r'[a-zA-Z]').hasMatch(rawText[rawIndex])) {
          buffer.write(rawText[rawIndex]);
          rawIndex++;
        } else {
          rawIndex++;
          i--;
        }
      } else if (maskChar == '*') {
        // Any character
        buffer.write(rawText[rawIndex]);
        rawIndex++;
      } else {
        // Literal separator
        buffer.write(maskChar);
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _CurrencyFormatter extends TextInputFormatter {
  final String symbol;
  final String separator;
  final String decimal;
  final int decimalPlaces;
  final bool showSymbol;

  _CurrencyFormatter({
    required this.symbol,
    required this.separator,
    required this.decimal,
    required this.decimalPlaces,
    required this.showSymbol,
  });

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text.replaceAll(RegExp(r'[^\d.]'), '');

    if (text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Handle decimal part
    final parts = text.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    // Remove leading zeros (keep at least one digit)
    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

    // Add thousand separators
    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write(separator);
      }
      buffer.write(integerPart[i]);
    }

    String formatted = buffer.toString();

    if (decimalPart != null) {
      if (decimalPart.length > decimalPlaces) {
        decimalPart = decimalPart.substring(0, decimalPlaces);
      }
      formatted = '$formatted$decimal$decimalPart';
    }

    if (showSymbol) {
      formatted = '$symbol$formatted';
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _UppercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}

class _LowercaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toLowerCase());
  }
}
