import 'package:flutter/material.dart';

/// Common button widget used across multiple screens
class CommonButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isEnabled;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const CommonButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = !isEnabled || isLoading || onPressed == null;

    return SizedBox(
      width: width ?? _getButtonWidth(),
      height: height ?? _getButtonHeight(),
      child: ElevatedButton(
        onPressed: isDisabled ? null : onPressed,
        style: _getButtonStyle(isDisabled),
        child: _buildButtonContent(),
      ),
    );
  }

  Widget _buildButtonContent() {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            textColor ?? _getTextColor(),
          ),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: _getIconSize()),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: _getFontSize(),
              fontWeight: FontWeight.w600,
              color: textColor ?? _getTextColor(),
            ),
          ),
        ],
      );
    }

    return Text(
      text,
      style: TextStyle(
        fontSize: _getFontSize(),
        fontWeight: FontWeight.w600,
        color: textColor ?? _getTextColor(),
      ),
    );
  }

  ButtonStyle _getButtonStyle(bool isDisabled) {
    final baseStyle = ElevatedButton.styleFrom(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_getBorderRadius()),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _getHorizontalPadding(),
        vertical: _getVerticalPadding(),
      ),
    );

    switch (type) {
      case ButtonType.primary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return Colors.grey[300];
            return backgroundColor ?? const Color(0xFF2E7D32);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return Colors.grey[600];
            return textColor ?? Colors.white;
          }),
        );
      case ButtonType.secondary:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return Colors.grey[100];
            return backgroundColor ?? Colors.white;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return Colors.grey[600];
            return textColor ?? const Color(0xFF2E7D32);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return BorderSide(color: Colors.grey[300]!);
            return const BorderSide(color: Color(0xFF2E7D32));
          }),
        );
      case ButtonType.outline:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return Colors.grey[600];
            return textColor ?? const Color(0xFF2E7D32);
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return BorderSide(color: Colors.grey[300]!);
            return BorderSide(color: textColor ?? const Color(0xFF2E7D32));
          }),
        );
      case ButtonType.text:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (isDisabled) return Colors.grey[600];
            return textColor ?? const Color(0xFF2E7D32);
          }),
          elevation: WidgetStateProperty.all(0),
        );
    }
  }

  double _getButtonWidth() {
    switch (size) {
      case ButtonSize.small:
        return 100;
      case ButtonSize.medium:
        return 200;
      case ButtonSize.large:
        return double.infinity;
    }
  }

  double _getButtonHeight() {
    switch (size) {
      case ButtonSize.small:
        return 36;
      case ButtonSize.medium:
        return 48;
      case ButtonSize.large:
        return 56;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 14;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getIconSize() {
    switch (size) {
      case ButtonSize.small:
        return 16;
      case ButtonSize.medium:
        return 18;
      case ButtonSize.large:
        return 20;
    }
  }

  double _getBorderRadius() {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }

  double _getHorizontalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 12;
      case ButtonSize.medium:
        return 16;
      case ButtonSize.large:
        return 24;
    }
  }

  double _getVerticalPadding() {
    switch (size) {
      case ButtonSize.small:
        return 8;
      case ButtonSize.medium:
        return 12;
      case ButtonSize.large:
        return 16;
    }
  }

  Color _getTextColor() {
    switch (type) {
      case ButtonType.primary:
        return Colors.white;
      case ButtonType.secondary:
      case ButtonType.outline:
      case ButtonType.text:
        return const Color(0xFF2E7D32);
    }
  }
}

/// Button types
enum ButtonType { primary, secondary, outline, text }

/// Button sizes
enum ButtonSize { small, medium, large }

/// Loading button with built-in loading state
class LoadingButton extends StatefulWidget {
  final String text;
  final Future<void> Function()? onPressed;
  final bool isEnabled;
  final ButtonType type;
  final ButtonSize size;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;

  const LoadingButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
    this.type = ButtonType.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
  });

  @override
  State<LoadingButton> createState() => _LoadingButtonState();
}

class _LoadingButtonState extends State<LoadingButton> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return CommonButton(
      text: widget.text,
      onPressed: _isLoading ? null : _handlePress,
      isLoading: _isLoading,
      isEnabled: widget.isEnabled,
      type: widget.type,
      size: widget.size,
      icon: widget.icon,
      backgroundColor: widget.backgroundColor,
      textColor: widget.textColor,
      width: widget.width,
      height: widget.height,
    );
  }

  Future<void> _handlePress() async {
    if (widget.onPressed == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

/// Icon button with consistent styling
class CommonIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? backgroundColor;
  final double size;
  final String? tooltip;

  const CommonIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.color,
    this.backgroundColor,
    this.size = 24,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = IconButton(
      icon: Icon(icon, size: size),
      onPressed: onPressed,
      color: color,
      style: backgroundColor != null
          ? IconButton.styleFrom(backgroundColor: backgroundColor)
          : null,
    );

    if (tooltip != null) {
      return Tooltip(
        message: tooltip!,
        child: button,
      );
    }

    return button;
  }
}
