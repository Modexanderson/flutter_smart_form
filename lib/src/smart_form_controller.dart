import 'package:flutter/widgets.dart';

/// Controls a group of smart form fields programmatically.
///
/// Provides methods to validate all fields, reset them, get/set values,
/// and listen for form-wide state changes.
///
/// ```dart
/// final controller = SmartFormController();
///
/// // Later, validate all registered fields:
/// if (controller.validate()) {
///   final data = controller.values;
///   // submit data...
/// }
/// ```
class SmartFormController extends ChangeNotifier {
  final Map<String, SmartFieldState> _fields = {};

  /// Whether all fields are currently valid.
  bool get isValid => _fields.values.every((f) => f.isValid);

  /// Whether any field has been modified from its initial value.
  bool get isDirty => _fields.values.any((f) => f.isDirty);

  /// Returns a map of all field names to their current values.
  Map<String, String> get values =>
      _fields.map((key, field) => MapEntry(key, field.value));

  /// Returns a map of all field names to their current error messages.
  /// Fields without errors are excluded.
  Map<String, String> get errors {
    final result = <String, String>{};
    for (final entry in _fields.entries) {
      if (entry.value.error != null) {
        result[entry.key] = entry.value.error!;
      }
    }
    return result;
  }

  /// Registers a field with this controller.
  void registerField(String name, SmartFieldState state) {
    _fields[name] = state;
    notifyListeners();
  }

  /// Unregisters a field from this controller.
  void unregisterField(String name) {
    _fields.remove(name);
    notifyListeners();
  }

  /// Validates all registered fields.
  /// Returns `true` if all fields are valid.
  bool validate() {
    bool allValid = true;
    for (final field in _fields.values) {
      if (!field.validate()) {
        allValid = false;
      }
    }
    notifyListeners();
    return allValid;
  }

  /// Resets all fields to their initial values and clears errors.
  void reset() {
    for (final field in _fields.values) {
      field.reset();
    }
    notifyListeners();
  }

  /// Gets the value of a specific field by name.
  String? getValue(String name) => _fields[name]?.value;

  /// Sets the value of a specific field by name.
  void setValue(String name, String value) {
    _fields[name]?.setValue(value);
    notifyListeners();
  }

  /// Notifies that a field's state has changed.
  void fieldDidChange() {
    notifyListeners();
  }

  @override
  void dispose() {
    _fields.clear();
    super.dispose();
  }
}

/// Represents the current state of a single smart form field.
class SmartFieldState {
  final TextEditingController textController;
  final String? Function(String?)? validator;
  final String _initialValue;

  String? error;

  SmartFieldState({
    required this.textController,
    this.validator,
    String? initialValue,
  }) : _initialValue = initialValue ?? '';

  /// The current value of the field.
  String get value => textController.text;

  /// Whether the field is currently valid (no error).
  bool get isValid => error == null;

  /// Whether the field value differs from its initial value.
  bool get isDirty => textController.text != _initialValue;

  /// Validates the field and returns true if valid.
  bool validate() {
    error = validator?.call(textController.text);
    return error == null;
  }

  /// Resets the field to its initial value and clears the error.
  void reset() {
    textController.text = _initialValue;
    error = null;
  }

  /// Sets the field value programmatically.
  void setValue(String value) {
    textController.text = value;
  }
}
