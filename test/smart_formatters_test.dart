import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:formwise/formwise.dart';

TextEditingValue _format(TextInputFormatter formatter, String input) {
  return formatter.formatEditUpdate(
    TextEditingValue.empty,
    TextEditingValue(
      text: input,
      selection: TextSelection.collapsed(offset: input.length),
    ),
  );
}

void main() {
  group('SmartFormatters.creditCard', () {
    test('formats standard card as 4-4-4-4', () {
      final f = SmartFormatters.creditCard();
      expect(_format(f, '4111111111111111').text, '4111 1111 1111 1111');
    });

    test('formats AMEX as 4-6-5', () {
      final f = SmartFormatters.creditCard(amexFormat: true);
      expect(_format(f, '341234567890123').text, '3412 345678 90123');
    });

    test('auto-detects AMEX from prefix 34', () {
      final f = SmartFormatters.creditCard(autoDetectBrand: true);
      expect(_format(f, '341234567890123').text, '3412 345678 90123');
    });

    test('auto-detects AMEX from prefix 37', () {
      final f = SmartFormatters.creditCard(autoDetectBrand: true);
      expect(_format(f, '371234567890123').text, '3712 345678 90123');
    });

    test('auto-detect uses standard for non-AMEX', () {
      final f = SmartFormatters.creditCard(autoDetectBrand: true);
      expect(_format(f, '4111111111111111').text, '4111 1111 1111 1111');
    });

    test('strips non-digit characters', () {
      final f = SmartFormatters.creditCard();
      expect(_format(f, '4111-1111-1111-1111').text, '4111 1111 1111 1111');
    });

    test('truncates to 16 digits for standard', () {
      final f = SmartFormatters.creditCard();
      expect(_format(f, '41111111111111119999').text, '4111 1111 1111 1111');
    });
  });

  group('SmartFormatters.phone masks', () {
    test('US format', () {
      final f = SmartFormatters.phoneInternational(PhoneFormat.us);
      expect(_format(f, '1234567890').text, '(123) 456-7890');
    });

    test('Japan format', () {
      final f = SmartFormatters.phoneInternational(PhoneFormat.japan);
      expect(_format(f, '09012345678').text, '090-1234-5678');
    });

    test('Nigeria format', () {
      final f = SmartFormatters.phoneInternational(PhoneFormat.nigeria);
      expect(_format(f, '08012345678').text, '0801 234 5678');
    });

    test('custom mask', () {
      final f = SmartFormatters.phone(mask: '+## ### ### ####');
      expect(_format(f, '441234567890').text, '+44 123 456 7890');
    });
  });

  group('SmartFormatters.smartDate', () {
    group('MM/DD/YYYY', () {
      final f = SmartFormatters.smartDate(DateFormat.mmddyyyy);

      test('formats valid date', () {
        expect(_format(f, '12252000').text, '12/25/2000');
      });

      test('clamps month > 12', () {
        final result = _format(f, '19');
        expect(result.text, '12');
      });

      test('clamps month 00 to 01', () {
        expect(_format(f, '00').text, '01');
      });

      test('clamps day for 30-day month (April)', () {
        final result = _format(f, '0431');
        expect(result.text, '04/30');
      });

      test('allows day 31 for January', () {
        expect(_format(f, '0131').text, '01/31');
      });

      test('clamps day 00 to 01', () {
        expect(_format(f, '0100').text, '01/01');
      });

      test('clamps February day > 29', () {
        final result = _format(f, '0230');
        expect(result.text, '02/29');
      });
    });

    group('DD/MM/YYYY', () {
      final f = SmartFormatters.smartDate(DateFormat.ddmmyyyy);

      test('formats valid date', () {
        expect(_format(f, '25122000').text, '25/12/2000');
      });

      test('clamps day > 31', () {
        expect(_format(f, '32').text, '31');
      });

      test('clamps day 00 to 01', () {
        expect(_format(f, '00').text, '01');
      });

      test('clamps month > 12', () {
        expect(_format(f, '1513').text, '15/12');
      });

      test('clamps month 00 to 01', () {
        expect(_format(f, '1500').text, '15/01');
      });
    });

    group('ISO YYYY-MM-DD', () {
      final f = SmartFormatters.smartDate(DateFormat.iso);

      test('formats valid date', () {
        expect(_format(f, '20261225').text, '2026-12-25');
      });

      test('clamps month > 12', () {
        expect(_format(f, '202613').text, '2026-12');
      });

      test('clamps day for month', () {
        expect(_format(f, '20260230').text, '2026-02-29');
      });
    });

    group('DD.MM.YYYY (German)', () {
      final f = SmartFormatters.smartDate(DateFormat.ddmmyyyyDot);

      test('formats with dot separator', () {
        expect(_format(f, '25122026').text, '25.12.2026');
      });
    });
  });

  group('SmartFormatters.currency', () {
    test('adds thousand separators', () {
      final f = SmartFormatters.currency();
      expect(_format(f, '1234567').text, '\$1,234,567');
    });

    test('handles decimals', () {
      final f = SmartFormatters.currency();
      expect(_format(f, '1234.56').text, '\$1,234.56');
    });

    test('truncates excess decimal places', () {
      final f = SmartFormatters.currency();
      expect(_format(f, '100.999').text, '\$100.99');
    });

    test('custom symbol', () {
      final f = SmartFormatters.currency(symbol: '₦');
      expect(_format(f, '5000').text, '₦5,000');
    });

    test('no symbol', () {
      final f = SmartFormatters.currency(showSymbol: false);
      expect(_format(f, '5000').text, '5,000');
    });

    test('European style', () {
      final f = SmartFormatters.currency(
        symbol: '€',
        separator: '.',
        decimal: ',',
      );
      expect(_format(f, '1234.56').text, '€1.234,56');
    });
  });

  group('SmartFormatters.mask', () {
    test('SSN format', () {
      final f = SmartFormatters.mask('###-##-####');
      expect(_format(f, '123456789').text, '123-45-6789');
    });

    test('letter mask', () {
      final f = SmartFormatters.mask('AA-####');
      expect(_format(f, 'AB1234').text, 'AB-1234');
    });
  });

  group('SmartFormatters.titleCase', () {
    test('capitalizes first letter of each word', () {
      final f = SmartFormatters.titleCase();
      expect(_format(f, 'hello world').text, 'Hello World');
    });

    test('lowercases rest of word', () {
      final f = SmartFormatters.titleCase();
      expect(_format(f, 'HELLO WORLD').text, 'Hello World');
    });

    test('handles single word', () {
      final f = SmartFormatters.titleCase();
      expect(_format(f, 'test').text, 'Test');
    });
  });

  group('SmartFormatters.trimmed', () {
    test('collapses multiple spaces', () {
      final f = SmartFormatters.trimmed();
      expect(_format(f, 'hello   world').text, 'hello world');
    });

    test('leaves single spaces alone', () {
      final f = SmartFormatters.trimmed();
      expect(_format(f, 'hello world').text, 'hello world');
    });
  });
}
