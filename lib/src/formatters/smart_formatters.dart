import 'package:flutter/services.dart';

/// International phone format presets.
enum PhoneFormat {
  /// US/Canada: (123) 456-7890
  us('(###) ###-####'),

  /// UK: +44 1234 567890
  uk('+44 #### ######'),

  /// Japan: 090-1234-5678
  japan('###-####-####'),

  /// Nigeria: 0801 234 5678
  nigeria('#### ### ####'),

  /// Germany: +49 123 4567890
  germany('+49 ### #######'),

  /// India: +91 12345 67890
  india('+91 ##### #####'),

  /// Brazil: +55 (11) 91234-5678
  brazil('+55 (##) #####-####'),

  /// International with country code: +1 234 567 8901
  international('+# ### ### ####');

  final String mask;
  const PhoneFormat(this.mask);
}

/// Date format presets.
enum DateFormat {
  /// MM/DD/YYYY (US)
  mmddyyyy('##/##/####'),

  /// DD/MM/YYYY (Europe, most of the world)
  ddmmyyyy('##/##/####'),

  /// YYYY-MM-DD (ISO 8601)
  iso('####-##-##'),

  /// DD.MM.YYYY (Germany, Russia)
  ddmmyyyyDot('##.##.####'),

  /// YYYY/MM/DD (Japan, China)
  yyyymmdd('####/##/##'),

  /// MM-DD-YYYY
  mmddyyyyDash('##-##-####');

  final String mask;
  const DateFormat(this.mask);
}

/// A collection of smart input formatters for common field types.
class SmartFormatters {
  SmartFormatters._();

  /// Formats input as a credit card number: `1234 5678 9012 3456`.
  ///
  /// When [autoDetectBrand] is true, automatically switches between
  /// standard (4-4-4-4) and AMEX (4-6-5) format based on the number prefix.
  static TextInputFormatter creditCard({
    bool amexFormat = false,
    bool autoDetectBrand = false,
  }) {
    return _CreditCardFormatter(
      amexFormat: amexFormat,
      autoDetectBrand: autoDetectBrand,
    );
  }

  /// Formats input as a phone number.
  ///
  /// Default format: `(123) 456-7890` for 10-digit US numbers.
  /// Use [mask] to customize: `+# (###) ###-####`.
  /// `#` is replaced by digits.
  static TextInputFormatter phone({String mask = '(###) ###-####'}) {
    return _MaskFormatter(mask: mask);
  }

  /// Formats input as a phone number using a country preset.
  ///
  /// ```dart
  /// SmartFormatters.phoneInternational(PhoneFormat.nigeria)
  /// SmartFormatters.phoneInternational(PhoneFormat.japan)
  /// ```
  static TextInputFormatter phoneInternational(PhoneFormat format) {
    return _MaskFormatter(mask: format.mask);
  }

  /// Formats input as a date using a basic mask.
  ///
  /// Default format: `MM/DD/YYYY`. Use [mask] to customize.
  static TextInputFormatter date({String mask = '##/##/####'}) {
    return _MaskFormatter(mask: mask);
  }

  /// Formats input as a date using a preset with smart validation.
  ///
  /// Clamps month to 01–12 and day to 01–31 (adjusted per month).
  /// Invalid values are corrected as the user types.
  ///
  /// ```dart
  /// SmartFormatters.smartDate(DateFormat.ddmmyyyy)
  /// SmartFormatters.smartDate(DateFormat.iso)
  /// ```
  static TextInputFormatter smartDate(DateFormat format) {
    return _SmartDateFormatter(format: format);
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

  /// Capitalizes the first letter of each word.
  static TextInputFormatter titleCase() {
    return _TitleCaseFormatter();
  }

  /// Trims leading and trailing whitespace and collapses multiple
  /// spaces into one as the user types.
  static TextInputFormatter trimmed() {
    return _TrimmedFormatter();
  }
}

class _CreditCardFormatter extends TextInputFormatter {
  final bool amexFormat;
  final bool autoDetectBrand;

  _CreditCardFormatter({
    this.amexFormat = false,
    this.autoDetectBrand = false,
  });

  bool _isAmex(String digits) {
    return digits.startsWith('34') || digits.startsWith('37');
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final useAmex = autoDetectBrand ? _isAmex(digits) : amexFormat;
    final maxLength = useAmex ? 15 : 16;
    final trimmed =
        digits.length > maxLength ? digits.substring(0, maxLength) : digits;

    final buffer = StringBuffer();

    if (useAmex) {
      for (int i = 0; i < trimmed.length; i++) {
        if (i == 4 || i == 10) buffer.write(' ');
        buffer.write(trimmed[i]);
      }
    } else {
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
        if (rawIndex < rawText.length &&
            RegExp(r'\d').hasMatch(rawText[rawIndex])) {
          buffer.write(rawText[rawIndex]);
          rawIndex++;
        } else {
          rawIndex++;
          i--;
        }
      } else if (maskChar == 'A') {
        if (rawIndex < rawText.length &&
            RegExp(r'[a-zA-Z]').hasMatch(rawText[rawIndex])) {
          buffer.write(rawText[rawIndex]);
          rawIndex++;
        } else {
          rawIndex++;
          i--;
        }
      } else if (maskChar == '*') {
        buffer.write(rawText[rawIndex]);
        rawIndex++;
      } else {
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

class _SmartDateFormatter extends TextInputFormatter {
  final DateFormat format;

  _SmartDateFormatter({required this.format});

  static const _daysInMonth = [0, 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    if (digits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final clamped = _clampDigits(digits);
    final masked = _applyMask(clamped);

    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }

  String _clampDigits(String digits) {
    switch (format) {
      case DateFormat.mmddyyyy:
      case DateFormat.mmddyyyyDash:
        return _clampMMDD(digits);
      case DateFormat.ddmmyyyy:
      case DateFormat.ddmmyyyyDot:
        return _clampDDMM(digits);
      case DateFormat.iso:
      case DateFormat.yyyymmdd:
        return _clampYMD(digits);
    }
  }

  String _clampMMDD(String d) {
    if (d.isEmpty) return d;
    final chars = d.split('');
    final result = <String>[];

    // Month tens: 0 or 1
    if (chars.isNotEmpty) {
      final v = int.parse(chars[0]);
      result.add(v > 1 ? '1' : chars[0]);
    }
    // Month units
    if (chars.length > 1) {
      final tens = int.parse(result[0]);
      final v = int.parse(chars[1]);
      if (tens == 0 && v == 0) {
        result.add('1');
      } else if (tens == 1 && v > 2) {
        result.add('2');
      } else {
        result.add(chars[1]);
      }
    }
    // Day: clamp as a 2-digit number when both digits available
    if (chars.length > 2 && chars.length > 3) {
      final month = int.parse(result[0] + result[1]);
      final maxDay = _daysInMonth[month.clamp(1, 12)];
      var day = int.parse(chars[2] + chars[3]);
      day = day.clamp(1, maxDay);
      final ds = day.toString().padLeft(2, '0');
      result.add(ds[0]);
      result.add(ds[1]);
    } else if (chars.length > 2) {
      final v = int.parse(chars[2]);
      result.add(v > 3 ? '3' : chars[2]);
    }
    // Year digits (4–8) pass through
    for (int i = 4; i < chars.length && i < 8; i++) {
      result.add(chars[i]);
    }

    return result.join();
  }

  String _clampDDMM(String d) {
    if (d.isEmpty) return d;
    final chars = d.split('');
    final result = <String>[];

    // Day tens: 0–3
    if (chars.isNotEmpty) {
      final v = int.parse(chars[0]);
      result.add(v > 3 ? '3' : chars[0]);
    }
    // Day units
    if (chars.length > 1) {
      final tens = int.parse(result[0]);
      final v = int.parse(chars[1]);
      if (tens == 0 && v == 0) {
        result.add('1');
      } else if (tens == 3 && v > 1) {
        result.add('1');
      } else {
        result.add(chars[1]);
      }
    }
    // Month tens: 0 or 1
    if (chars.length > 2) {
      final v = int.parse(chars[2]);
      result.add(v > 1 ? '1' : chars[2]);
    }
    // Month units
    if (chars.length > 3) {
      final tens = int.parse(result[2]);
      final v = int.parse(chars[3]);
      if (tens == 0 && v == 0) {
        result.add('1');
      } else if (tens == 1 && v > 2) {
        result.add('2');
      } else {
        result.add(chars[3]);
      }
    }
    // Year digits pass through
    for (int i = 4; i < chars.length && i < 8; i++) {
      result.add(chars[i]);
    }

    return result.join();
  }

  String _clampYMD(String d) {
    if (d.isEmpty) return d;
    final chars = d.split('');
    final result = <String>[];

    // Year: 4 digits pass through
    for (int i = 0; i < chars.length && i < 4; i++) {
      result.add(chars[i]);
    }
    // Month tens: 0 or 1
    if (chars.length > 4) {
      final v = int.parse(chars[4]);
      result.add(v > 1 ? '1' : chars[4]);
    }
    // Month units
    if (chars.length > 5) {
      final tens = int.parse(result[4]);
      final v = int.parse(chars[5]);
      if (tens == 0 && v == 0) {
        result.add('1');
      } else if (tens == 1 && v > 2) {
        result.add('2');
      } else {
        result.add(chars[5]);
      }
    }
    // Day: clamp as a 2-digit number when both digits available
    if (chars.length > 6 && chars.length > 7) {
      final month = int.parse(result[4] + result[5]);
      final maxDay = _daysInMonth[month.clamp(1, 12)];
      var day = int.parse(chars[6] + chars[7]);
      day = day.clamp(1, maxDay);
      final ds = day.toString().padLeft(2, '0');
      result.add(ds[0]);
      result.add(ds[1]);
    } else if (chars.length > 6) {
      final v = int.parse(chars[6]);
      result.add(v > 3 ? '3' : chars[6]);
    }

    return result.join();
  }

  String _applyMask(String digits) {
    final buffer = StringBuffer();
    int di = 0;

    for (int i = 0; i < format.mask.length && di < digits.length; i++) {
      if (format.mask[i] == '#') {
        buffer.write(digits[di]);
        di++;
      } else {
        buffer.write(format.mask[i]);
      }
    }

    return buffer.toString();
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

    final parts = text.split('.');
    String integerPart = parts[0];
    String? decimalPart = parts.length > 1 ? parts[1] : null;

    integerPart = integerPart.replaceFirst(RegExp(r'^0+(?=\d)'), '');

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

class _TitleCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) return newValue;

    final buffer = StringBuffer();
    bool capitalizeNext = true;

    for (int i = 0; i < text.length; i++) {
      if (text[i] == ' ') {
        buffer.write(' ');
        capitalizeNext = true;
      } else if (capitalizeNext) {
        buffer.write(text[i].toUpperCase());
        capitalizeNext = false;
      } else {
        buffer.write(text[i].toLowerCase());
      }
    }

    final formatted = buffer.toString();
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _TrimmedFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(RegExp(r' {2,}'), ' ');
    if (text == newValue.text) return newValue;

    return newValue.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
