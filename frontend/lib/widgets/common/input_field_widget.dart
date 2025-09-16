import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Common input field widget used across multiple screens
class CommonInputField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool isPassword;
  final bool isRequired;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final String? suffixText;
  final Widget? suffixIcon;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  const CommonInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.isPassword = false,
    this.isRequired = true,
    this.validator,
    this.inputFormatters,
    this.prefixText,
    this.suffixText,
    this.suffixIcon,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.onTap,
    this.onChanged,
    this.focusNode,
  });

  @override
  State<CommonInputField> createState() => _CommonInputFieldState();
}

class _CommonInputFieldState extends State<CommonInputField> {
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF212121),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: widget.keyboardType,
          obscureText: widget.isPassword && !_isPasswordVisible,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          maxLength: widget.maxLength,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator ?? _defaultValidator,
          onTap: widget.onTap,
          onChanged: widget.onChanged,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText,
            prefixText: widget.prefixText,
            suffixText: widget.suffixText,
            prefixIcon: widget.icon != null
                ? Icon(
                    widget.icon,
                    color: Colors.grey[600],
                    size: 20,
                  )
                : null,
            suffixIcon: _buildSuffixIcon(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffixIcon() {
    if (widget.isPassword) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
        ),
        onPressed: () {
          setState(() {
            _isPasswordVisible = !_isPasswordVisible;
          });
        },
      );
    }
    return widget.suffixIcon;
  }

  String? _defaultValidator(String? value) {
    if (widget.isRequired && (value == null || value.isEmpty)) {
      return '${widget.label} is required';
    }
    return null;
  }
}

/// Specialized input field for numeric values with validation
class NumericInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final double? minValue;
  final double? maxValue;
  final String? unit;
  final bool isRequired;
  final ValueChanged<String>? onChanged;

  const NumericInputField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.icon,
    this.minValue,
    this.maxValue,
    this.unit,
    this.isRequired = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CommonInputField(
      controller: controller,
      label: label,
      hintText: hintText,
      icon: icon,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
      validator: _validateNumericValue,
      onChanged: onChanged,
    );
  }

  String? _validateNumericValue(String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return '$label is required';
    }

    if (value != null && value.isNotEmpty) {
      final numValue = double.tryParse(value);
      if (numValue == null) {
        return 'Please enter a valid number';
      }

      if (minValue != null && numValue < minValue!) {
        return '$label must be at least $minValue${unit ?? ''}';
      }

      if (maxValue != null && numValue > maxValue!) {
        return '$label must be at most $maxValue${unit ?? ''}';
      }
    }

    return null;
  }
}

/// Input field for email with validation
class EmailInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isRequired;
  final ValueChanged<String>? onChanged;

  const EmailInputField({
    super.key,
    required this.controller,
    this.label = 'Email Address',
    this.hintText,
    this.isRequired = true,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CommonInputField(
      controller: controller,
      label: label,
      hintText: hintText ?? 'Enter your email address',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
      validator: _validateEmail,
      onChanged: onChanged,
    );
  }

  String? _validateEmail(String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Email is required';
    }

    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
        return 'Please enter a valid email address';
      }
    }

    return null;
  }
}

/// Input field for password with validation
class PasswordInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isRequired;
  final int minLength;
  final ValueChanged<String>? onChanged;

  const PasswordInputField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hintText,
    this.isRequired = true,
    this.minLength = 6,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CommonInputField(
      controller: controller,
      label: label,
      hintText: hintText ?? 'Enter your password',
      icon: Icons.lock_outline,
      isPassword: true,
      validator: _validatePassword,
      onChanged: onChanged,
    );
  }

  String? _validatePassword(String? value) {
    if (isRequired && (value == null || value.isEmpty)) {
      return 'Password is required';
    }

    if (value != null && value.isNotEmpty) {
      if (value.length < minLength) {
        return 'Password must be at least $minLength characters';
      }
    }

    return null;
  }
}
