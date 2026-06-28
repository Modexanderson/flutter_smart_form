# formwise

Smart form fields for Flutter with built-in validation, auto-formatting, typo detection, and animated error feedback.

[![CI](https://github.com/modexanderson/formwise/actions/workflows/ci.yml/badge.svg)](https://github.com/modexanderson/formwise/actions)
[![pub package](https://img.shields.io/pub/v/formwise.svg)](https://pub.dev/packages/formwise)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](https://opensource.org/licenses/MIT)

## Features

- **Smart Validators** — Email (with typo detection: `gmial.com` → `gmail.com`), phone, URL, credit card (Luhn algorithm), numeric range, pattern, and composable validators.
- **Auto-Formatters** — Credit card (`4111 1111 1111 1111`), phone (`(234) 567-8901`), date, currency (`$1,234.56`), custom mask patterns, uppercase/lowercase.
- **SmartTextFormField** — Drop-in replacement for `TextFormField` with debounced validation, async validation, shake-on-error animation, and success indicators.
- **SmartFormController** — Manage multiple fields: validate all, reset, get/set values, track dirty state.
- **Card Brand Detection** — Automatically detect Visa, Mastercard, Amex, Discover from the card number.

## Installation

```yaml
dependencies:
  formwise: ^1.0.0
```

```bash
flutter pub add formwise
```

## Usage

### Basic Email Field with Typo Detection

```dart
import 'package:formwise/formwise.dart';

SmartTextFormField(
  name: 'email',
  labelText: 'Email Address',
  keyboardType: TextInputType.emailAddress,
  validator: SmartValidators.email(
    suggestCorrection: (suggestion) {
      // suggestion = "user@gmail.com" when user types "user@gmial.com"
    },
  ),
  inputFormatters: [SmartFormatters.lowercase()],
)
```

### Credit Card Field with Auto-Formatting

```dart
SmartTextFormField(
  name: 'card',
  labelText: 'Card Number',
  keyboardType: TextInputType.number,
  validator: SmartValidators.creditCard(),
  inputFormatters: [SmartFormatters.creditCard()],
)

// Detect the card brand:
final brand = SmartValidators.detectCardBrand('4111111111111111');
// brand == CardBrand.visa
```

### Phone Number Field

```dart
SmartTextFormField(
  name: 'phone',
  labelText: 'Phone Number',
  keyboardType: TextInputType.phone,
  validator: SmartValidators.phone(minDigits: 10, maxDigits: 10),
  inputFormatters: [SmartFormatters.phone(mask: '(###) ###-####')],
)
```

### Form Controller

```dart
final controller = SmartFormController();

// In your widget tree:
SmartTextFormField(
  name: 'email',
  formController: controller,
  validator: SmartValidators.email(),
  // ...
),
SmartTextFormField(
  name: 'name',
  formController: controller,
  validator: SmartValidators.required(),
  // ...
),

// Validate all fields:
if (controller.validate()) {
  final data = controller.values; // {'email': '...', 'name': '...'}
  // Submit data
}

// Reset all fields:
controller.reset();

// Check state:
controller.isValid;  // true if all fields pass validation
controller.isDirty;  // true if any field was modified
controller.errors;   // {'email': 'Invalid email'} — only fields with errors
```

### Composing Validators

```dart
SmartTextFormField(
  name: 'password',
  labelText: 'Password',
  obscureText: true,
  validator: SmartValidators.compose([
    SmartValidators.required(),
    SmartValidators.minLength(length: 8),
    SmartValidators.pattern(
      regex: RegExp(r'[A-Z]'),
      errorMessage: 'Must contain at least one uppercase letter',
    ),
  ]),
)
```

### Custom Mask Formatting

```dart
// SSN format
SmartFormatters.mask('###-##-####')

// Date format
SmartFormatters.date(mask: '##/##/####')

// Currency
SmartFormatters.currency(symbol: '₦', separator: ',', decimalPlaces: 2)
```

### Async Validation

```dart
SmartTextFormField(
  name: 'username',
  labelText: 'Username',
  asyncValidator: (value) async {
    // Check if username is available on your server
    final available = await api.checkUsername(value!);
    return available ? null : 'Username is already taken';
  },
  validationDebounce: Duration(milliseconds: 500),
)
```

## API Reference

### SmartValidators

| Validator | Description |
|-----------|-------------|
| `email()` | Email with typo detection |
| `phone()` | Phone number with configurable digit range |
| `url()` | URL with optional HTTPS enforcement |
| `creditCard()` | Credit card via Luhn algorithm |
| `numericRange()` | Number within min/max bounds |
| `pattern()` | Custom regex pattern |
| `required()` | Non-empty check |
| `minLength()` | Minimum character count |
| `maxLength()` | Maximum character count |
| `compose()` | Combine multiple validators |

### SmartFormatters

| Formatter | Description |
|-----------|-------------|
| `creditCard()` | `1234 5678 9012 3456` format |
| `phone()` | Configurable mask, default `(###) ###-####` |
| `date()` | Configurable mask, default `##/##/####` |
| `currency()` | `$1,234.56` with configurable symbol/separators |
| `mask()` | Custom mask: `#`=digit, `A`=letter, `*`=any |
| `digitsOnly()` | Restrict to digits |
| `uppercase()` | Force uppercase |
| `lowercase()` | Force lowercase |

## License

MIT License — see [LICENSE](LICENSE) for details.
