import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'input_field_widget.dart';
import 'button_widget.dart';
import '../../utils/validation_utils.dart';

/// Common form widget used across multiple screens
class CommonForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final List<FormField> fields;
  final List<FormButton> buttons;
  final EdgeInsetsGeometry? padding;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisAlignment mainAxisAlignment;
  final double? spacing;

  const CommonForm({
    super.key,
    required this.formKey,
    required this.fields,
    required this.buttons,
    this.padding,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.spacing,
  });

  @override
  State<CommonForm> createState() => _CommonFormState();
}

class _CommonFormState extends State<CommonForm> {
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Padding(
        padding: widget.padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: widget.crossAxisAlignment,
          mainAxisAlignment: widget.mainAxisAlignment,
          children: _buildFormChildren(),
        ),
      ),
    );
  }

  List<Widget> _buildFormChildren() {
    final children = <Widget>[];

    for (int i = 0; i < widget.fields.length; i++) {
      children.add(widget.fields[i].build());

      if (i < widget.fields.length - 1) {
        children.add(SizedBox(height: widget.spacing ?? 16));
      }
    }

    if (widget.buttons.isNotEmpty) {
      children.add(SizedBox(height: widget.spacing ?? 24));

      for (int i = 0; i < widget.buttons.length; i++) {
        children.add(widget.buttons[i].build());

        if (i < widget.buttons.length - 1) {
          children.add(SizedBox(height: widget.spacing ?? 12));
        }
      }
    }

    return children;
  }
}

/// Form field definition
abstract class FormField {
  Widget build();
}

/// Text input form field
class TextFormFieldWidget extends FormField {
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

  TextFormFieldWidget({
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
  Widget build() {
    return CommonInputField(
      controller: controller,
      label: label,
      hintText: hintText,
      icon: icon,
      keyboardType: keyboardType,
      isPassword: isPassword,
      isRequired: isRequired,
      validator: validator,
      inputFormatters: inputFormatters,
      prefixText: prefixText,
      suffixText: suffixText,
      suffixIcon: suffixIcon,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      onTap: onTap,
      onChanged: onChanged,
      focusNode: focusNode,
    );
  }
}

/// Email form field
class EmailFormField extends FormField {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isRequired;
  final ValueChanged<String>? onChanged;

  EmailFormField({
    required this.controller,
    this.label = 'Email Address',
    this.hintText,
    this.isRequired = true,
    this.onChanged,
  });

  @override
  Widget build() {
    return EmailInputField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
}

/// Password form field
class PasswordFormField extends FormField {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final bool isRequired;
  final int minLength;
  final ValueChanged<String>? onChanged;

  PasswordFormField({
    required this.controller,
    this.label = 'Password',
    this.hintText,
    this.isRequired = true,
    this.minLength = 6,
    this.onChanged,
  });

  @override
  Widget build() {
    return PasswordInputField(
      controller: controller,
      label: label,
      hintText: hintText,
      isRequired: isRequired,
      minLength: minLength,
      onChanged: onChanged,
    );
  }
}

/// Numeric form field
class NumericFormField extends FormField {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData? icon;
  final double? minValue;
  final double? maxValue;
  final String? unit;
  final bool isRequired;
  final ValueChanged<String>? onChanged;

  NumericFormField({
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
  Widget build() {
    return NumericInputField(
      controller: controller,
      label: label,
      hintText: hintText,
      icon: icon,
      minValue: minValue,
      maxValue: maxValue,
      unit: unit,
      isRequired: isRequired,
      onChanged: onChanged,
    );
  }
}

/// Form button definition
abstract class FormButton {
  Widget build();
}

/// Primary form button
class PrimaryFormButton extends FormButton {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;

  PrimaryFormButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build() {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      type: ButtonType.primary,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

/// Secondary form button
class SecondaryFormButton extends FormButton {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;

  SecondaryFormButton({
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build() {
    return CommonButton(
      text: text,
      onPressed: onPressed,
      isLoading: isLoading,
      isEnabled: isEnabled,
      type: ButtonType.secondary,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

/// Loading form button
class LoadingFormButton extends FormButton {
  final String text;
  final Future<void> Function()? onPressed;
  final bool isEnabled;
  final IconData? icon;
  final double? width;
  final double? height;

  LoadingFormButton({
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build() {
    return LoadingButton(
      text: text,
      onPressed: onPressed,
      isEnabled: isEnabled,
      icon: icon,
      width: width,
      height: height,
    );
  }
}

/// Crop recommendation form with predefined fields
class CropRecommendationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final bool isEnabled;

  const CropRecommendationForm({
    super.key,
    required this.formKey,
    required this.controllers,
    this.onSubmit,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CommonForm(
      formKey: formKey,
      fields: [
        NumericFormField(
          controller: controllers['nitrogen']!,
          label: 'Nitrogen (N)',
          hintText: 'Enter nitrogen content',
          icon: Icons.science,
          minValue: 0,
          maxValue: 200,
          unit: ' ppm',
        ),
        NumericFormField(
          controller: controllers['phosphorus']!,
          label: 'Phosphorus (P)',
          hintText: 'Enter phosphorus content',
          icon: Icons.science,
          minValue: 0,
          maxValue: 200,
          unit: ' ppm',
        ),
        NumericFormField(
          controller: controllers['potassium']!,
          label: 'Potassium (K)',
          hintText: 'Enter potassium content',
          icon: Icons.science,
          minValue: 0,
          maxValue: 200,
          unit: ' ppm',
        ),
        NumericFormField(
          controller: controllers['temperature']!,
          label: 'Temperature',
          hintText: 'Enter temperature',
          icon: Icons.thermostat,
          minValue: -50,
          maxValue: 60,
          unit: '°C',
        ),
        NumericFormField(
          controller: controllers['humidity']!,
          label: 'Humidity',
          hintText: 'Enter humidity percentage',
          icon: Icons.water_drop,
          minValue: 0,
          maxValue: 100,
          unit: '%',
        ),
        NumericFormField(
          controller: controllers['ph']!,
          label: 'pH Level',
          hintText: 'Enter pH level',
          icon: Icons.analytics,
          minValue: 0,
          maxValue: 14,
        ),
        NumericFormField(
          controller: controllers['rainfall']!,
          label: 'Rainfall',
          hintText: 'Enter rainfall amount',
          icon: Icons.cloud,
          minValue: 0,
          maxValue: 500,
          unit: ' mm',
        ),
      ],
      buttons: [
        PrimaryFormButton(
          text: 'Get Recommendation',
          onPressed: isEnabled ? onSubmit : null,
          isLoading: isLoading,
          isEnabled: isEnabled,
          icon: Icons.eco,
        ),
      ],
    );
  }
}

/// Login form with predefined fields
class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final bool isEnabled;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    this.onSubmit,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CommonForm(
      formKey: formKey,
      fields: [
        EmailFormField(
          controller: emailController,
          label: 'Email Address',
          hintText: 'Enter your email address',
        ),
        PasswordFormField(
          controller: passwordController,
          label: 'Password',
          hintText: 'Enter your password',
        ),
      ],
      buttons: [
        PrimaryFormButton(
          text: 'Sign In',
          onPressed: isEnabled ? onSubmit : null,
          isLoading: isLoading,
          isEnabled: isEnabled,
          icon: Icons.login,
        ),
      ],
    );
  }
}

/// Registration form with predefined fields
class RegistrationForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final Map<String, TextEditingController> controllers;
  final VoidCallback? onSubmit;
  final bool isLoading;
  final bool isEnabled;

  const RegistrationForm({
    super.key,
    required this.formKey,
    required this.controllers,
    this.onSubmit,
    this.isLoading = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return CommonForm(
      formKey: formKey,
      fields: [
        TextFormFieldWidget(
          controller: controllers['fullName']!,
          label: 'Full Name',
          hintText: 'Enter your full name',
          icon: Icons.person,
          validator: (value) =>
              ValidationUtils.validateName(value, fieldName: 'Full Name'),
        ),
        EmailFormField(
          controller: controllers['email']!,
          label: 'Email Address',
          hintText: 'Enter your email address',
        ),
        TextFormFieldWidget(
          controller: controllers['phone']!,
          label: 'Phone Number (Optional)',
          hintText: 'Enter your phone number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          prefixText: '+91 ',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          validator: (value) =>
              ValidationUtils.validatePhone(value, isRequired: false),
        ),
        PasswordFormField(
          controller: controllers['password']!,
          label: 'Password',
          hintText: 'Enter your password',
        ),
        PasswordFormField(
          controller: controllers['confirmPassword']!,
          label: 'Confirm Password',
          hintText: 'Confirm your password',
        ),
      ],
      buttons: [
        PrimaryFormButton(
          text: 'Create Account',
          onPressed: isEnabled ? onSubmit : null,
          isLoading: isLoading,
          isEnabled: isEnabled,
          icon: Icons.person_add,
        ),
      ],
    );
  }
}
