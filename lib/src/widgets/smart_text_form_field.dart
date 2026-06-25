import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../smart_form_controller.dart';

/// A smart text form field with built-in validation feedback,
/// debounced validation, and shake-on-error animation.
///
/// ```dart
/// SmartTextFormField(
///   name: 'email',
///   labelText: 'Email',
///   validator: SmartValidators.email(
///     suggestCorrection: (suggestion) {
///       // Show suggestion to user
///     },
///   ),
///   inputFormatters: [SmartFormatters.lowercase()],
///   validationDebounce: Duration(milliseconds: 500),
///   shakeOnError: true,
/// )
/// ```
class SmartTextFormField extends StatefulWidget {
  /// A unique name identifying this field within a [SmartFormController].
  final String name;

  /// The controller for the form this field belongs to.
  final SmartFormController? formController;

  /// Optional text editing controller. One will be created if not provided.
  final TextEditingController? controller;

  /// Synchronous validator function.
  final String? Function(String?)? validator;

  /// Async validator for server-side validation or expensive checks.
  /// Runs after the sync validator passes.
  final Future<String?> Function(String?)? asyncValidator;

  /// Debounce duration for validation. Prevents excessive validation
  /// calls while the user is still typing.
  final Duration validationDebounce;

  /// Whether to play a shake animation when validation fails.
  final bool shakeOnError;

  /// Whether to validate on every change (true) or only on form submit (false).
  final bool autoValidate;

  /// Input formatters to apply to the field.
  final List<TextInputFormatter>? inputFormatters;

  /// Initial value for the field.
  final String? initialValue;

  // Pass-through TextFormField properties
  final InputDecoration? decoration;
  final String? labelText;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final bool enabled;
  final int? maxLines;
  final int? maxLength;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool readOnly;

  const SmartTextFormField({
    super.key,
    required this.name,
    this.formController,
    this.controller,
    this.validator,
    this.asyncValidator,
    this.validationDebounce = const Duration(milliseconds: 300),
    this.shakeOnError = true,
    this.autoValidate = true,
    this.inputFormatters,
    this.initialValue,
    this.decoration,
    this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.focusNode,
    this.onChanged,
    this.onEditingComplete,
    this.onFieldSubmitted,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
  });

  @override
  State<SmartTextFormField> createState() => _SmartTextFormFieldState();
}

class _SmartTextFormFieldState extends State<SmartTextFormField>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  Timer? _debounceTimer;
  String? _errorText;
  bool _isValidating = false;
  bool _hasInteracted = false;
  SmartFieldState? _fieldState;

  @override
  void initState() {
    super.initState();

    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();

    // Shake animation
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -10), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -8), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: -3), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -3, end: 0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));

    // Register with form controller
    _fieldState = SmartFieldState(
      textController: _controller,
      validator: _syncValidate,
      initialValue: widget.initialValue,
    );
    widget.formController?.registerField(widget.name, _fieldState!);

    // Listen for changes
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.formController?.unregisterField(widget.name);
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _shakeController.dispose();
    if (widget.controller == null) _controller.dispose();
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (!widget.autoValidate || !_hasInteracted) return;

    _debounceTimer?.cancel();
    _debounceTimer = Timer(widget.validationDebounce, () {
      _validate();
    });

    widget.onChanged?.call(_controller.text);
    widget.formController?.fieldDidChange();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus && !_hasInteracted) {
      _hasInteracted = true;
      _validate();
    }
  }

  String? _syncValidate(String? value) {
    return widget.validator?.call(value);
  }

  Future<void> _validate() async {
    final value = _controller.text;

    // Sync validation first
    final syncError = _syncValidate(value);
    if (syncError != null) {
      _setError(syncError);
      return;
    }

    // Async validation
    if (widget.asyncValidator != null) {
      setState(() => _isValidating = true);

      final asyncError = await widget.asyncValidator!(value);

      // Check if value hasn't changed during async validation
      if (_controller.text == value) {
        if (asyncError != null) {
          _setError(asyncError);
        } else {
          _clearError();
        }
        setState(() => _isValidating = false);
      }
    } else {
      _clearError();
    }
  }

  void _setError(String error) {
    setState(() {
      _errorText = error;
      _fieldState?.error = error;
    });

    if (widget.shakeOnError) {
      _shakeController.forward(from: 0);
    }
  }

  void _clearError() {
    setState(() {
      _errorText = null;
      _fieldState?.error = null;
    });
  }

  InputDecoration _buildDecoration() {
    if (widget.decoration != null) {
      return widget.decoration!.copyWith(
        errorText: _errorText,
        suffixIcon: _buildSuffixIcon(),
      );
    }

    return InputDecoration(
      labelText: widget.labelText,
      hintText: widget.hintText,
      prefixIcon: widget.prefixIcon,
      suffixIcon: _buildSuffixIcon(),
      errorText: _errorText,
      border: const OutlineInputBorder(),
    );
  }

  Widget? _buildSuffixIcon() {
    if (_isValidating) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (widget.suffixIcon != null) return widget.suffixIcon;

    if (_hasInteracted && _errorText == null && _controller.text.isNotEmpty) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget field = TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: _buildDecoration(),
      keyboardType: widget.keyboardType,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      inputFormatters: widget.inputFormatters,
      onEditingComplete: widget.onEditingComplete,
      onFieldSubmitted: widget.onFieldSubmitted,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      readOnly: widget.readOnly,
      validator: (value) {
        _hasInteracted = true;
        final error = _syncValidate(value);
        if (error != null && widget.shakeOnError) {
          _shakeController.forward(from: 0);
        }
        return error;
      },
    );

    if (widget.shakeOnError) {
      field = AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: child,
          );
        },
        child: field,
      );
    }

    return field;
  }
}
