import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_form/flutter_smart_form.dart';

void main() {
  group('SmartValidators', () {
    group('email', () {
      final validate = SmartValidators.email();

      test('accepts valid emails', () {
        expect(validate('user@example.com'), isNull);
        expect(validate('test.user+tag@domain.co.uk'), isNull);
        expect(validate('name@sub.domain.com'), isNull);
      });

      test('rejects invalid emails', () {
        expect(validate(''), isNotNull);
        expect(validate(null), isNotNull);
        expect(validate('notanemail'), isNotNull);
        expect(validate('@domain.com'), isNotNull);
        expect(validate('user@'), isNotNull);
      });

      test('detects email typos', () {
        String? suggestion;
        final validateWithTypo = SmartValidators.email(
          suggestCorrection: (s) => suggestion = s,
        );

        final result = validateWithTypo('user@gmial.com');
        expect(result, contains('Did you mean'));
        expect(suggestion, equals('user@gmail.com'));
      });

      test('does not flag correct domains', () {
        String? suggestion;
        final validateWithTypo = SmartValidators.email(
          suggestCorrection: (s) => suggestion = s,
        );

        final result = validateWithTypo('user@gmail.com');
        expect(result, isNull);
        expect(suggestion, isNull);
      });
    });

    group('phone', () {
      final validate = SmartValidators.phone();

      test('accepts valid phone numbers', () {
        expect(validate('1234567890'), isNull);
        expect(validate('+1 (234) 567-8901'), isNull);
        expect(validate('123-456-7890'), isNull);
      });

      test('rejects too short numbers', () {
        expect(validate('123'), isNotNull);
        expect(validate(''), isNotNull);
        expect(validate(null), isNotNull);
      });

      test('respects minDigits and maxDigits', () {
        final strict = SmartValidators.phone(minDigits: 10, maxDigits: 10);
        expect(strict('1234567890'), isNull);
        expect(strict('123456789'), isNotNull);
        expect(strict('12345678901'), isNotNull);
      });
    });

    group('url', () {
      final validate = SmartValidators.url();

      test('accepts valid URLs', () {
        expect(validate('https://example.com'), isNull);
        expect(validate('http://sub.domain.co.uk/path'), isNull);
        expect(validate('example.com'), isNull); // auto-prepends https
      });

      test('rejects invalid URLs', () {
        expect(validate(''), isNotNull);
        expect(validate(null), isNotNull);
      });

      test('enforces HTTPS when required', () {
        final httpsOnly = SmartValidators.url(requireHttps: true);
        expect(httpsOnly('https://example.com'), isNull);
        expect(httpsOnly('http://example.com'), isNotNull);
      });
    });

    group('creditCard', () {
      final validate = SmartValidators.creditCard();

      test('accepts valid card numbers (Luhn check)', () {
        // Test Visa number
        expect(validate('4111 1111 1111 1111'), isNull);
        // Test Mastercard number
        expect(validate('5500 0000 0000 0004'), isNull);
      });

      test('rejects invalid card numbers', () {
        expect(validate('1234 5678 9012 3456'), isNotNull);
        expect(validate(''), isNotNull);
        expect(validate(null), isNotNull);
        expect(validate('abcd'), isNotNull);
      });
    });

    group('detectCardBrand', () {
      test('detects Visa', () {
        expect(SmartValidators.detectCardBrand('4111111111111111'), CardBrand.visa);
      });

      test('detects Mastercard', () {
        expect(SmartValidators.detectCardBrand('5500000000000004'), CardBrand.mastercard);
      });

      test('detects Amex', () {
        expect(SmartValidators.detectCardBrand('340000000000009'), CardBrand.amex);
      });

      test('detects Discover', () {
        expect(SmartValidators.detectCardBrand('6011000000000004'), CardBrand.discover);
      });

      test('returns unknown for unrecognized', () {
        expect(SmartValidators.detectCardBrand('9999999999999999'), CardBrand.unknown);
      });
    });

    group('numericRange', () {
      test('accepts values in range', () {
        final validate = SmartValidators.numericRange(min: 1, max: 100);
        expect(validate('50'), isNull);
        expect(validate('1'), isNull);
        expect(validate('100'), isNull);
      });

      test('rejects values out of range', () {
        final validate = SmartValidators.numericRange(min: 1, max: 100);
        expect(validate('0'), isNotNull);
        expect(validate('101'), isNotNull);
        expect(validate('abc'), isNotNull);
      });

      test('rejects decimals when not allowed', () {
        final validate = SmartValidators.numericRange(allowDecimals: false);
        expect(validate('5'), isNull);
        expect(validate('5.5'), isNotNull);
      });
    });

    group('compose', () {
      test('returns first error from composed validators', () {
        final validate = SmartValidators.compose([
          SmartValidators.required(),
          SmartValidators.minLength(length: 3),
        ]);

        expect(validate(''), isNotNull);
        expect(validate('ab'), isNotNull);
        expect(validate('abc'), isNull);
      });
    });

    group('required', () {
      final validate = SmartValidators.required();

      test('rejects empty and null', () {
        expect(validate(''), isNotNull);
        expect(validate(null), isNotNull);
        expect(validate('   '), isNotNull);
      });

      test('accepts non-empty values', () {
        expect(validate('hello'), isNull);
      });
    });
  });

  group('SmartFormController', () {
    test('tracks field registration', () {
      final controller = SmartFormController();
      final textController = TextEditingController(text: 'test');

      controller.registerField(
        'name',
        SmartFieldState(textController: textController),
      );

      expect(controller.values['name'], 'test');

      controller.dispose();
      textController.dispose();
    });

    test('validates all fields', () {
      final controller = SmartFormController();
      final textController = TextEditingController(text: '');

      controller.registerField(
        'name',
        SmartFieldState(
          textController: textController,
          validator: SmartValidators.required(),
        ),
      );

      expect(controller.validate(), isFalse);
      expect(controller.errors['name'], isNotNull);

      textController.text = 'Mordecai';
      expect(controller.validate(), isTrue);
      expect(controller.errors, isEmpty);

      controller.dispose();
      textController.dispose();
    });

    test('resets all fields', () {
      final controller = SmartFormController();
      final textController = TextEditingController(text: 'modified');

      controller.registerField(
        'name',
        SmartFieldState(
          textController: textController,
          initialValue: 'original',
        ),
      );

      expect(controller.isDirty, isTrue);

      controller.reset();
      expect(textController.text, 'original');
      expect(controller.isDirty, isFalse);

      controller.dispose();
      textController.dispose();
    });
  });
}
