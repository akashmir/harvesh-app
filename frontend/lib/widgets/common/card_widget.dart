import 'package:flutter/material.dart';

/// Common card widget used across multiple screens
class CommonCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final Border? border;
  final VoidCallback? onTap;

  const CommonCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.border,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      elevation: elevation ?? 2,
      color: backgroundColor ?? Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        side: border?.left ?? BorderSide.none,
      ),
      margin: margin ?? const EdgeInsets.all(8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        child: card,
      );
    }

    return card;
  }
}

/// Info card with icon and message
class InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const InfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      backgroundColor: backgroundColor ?? const Color(0xFFE3F2FD),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            color: iconColor ?? const Color(0xFF1976D2),
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? const Color(0xFF1976D2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 12,
                    color: textColor ?? const Color(0xFF1976D2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Error card with error information
class ErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  const ErrorCard({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.onRetry,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      backgroundColor: const Color(0xFFFFEBEE),
      border: Border.all(color: const Color(0xFFE57373)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon ?? Icons.error_outline,
                color: const Color(0xFFD32F2F),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD32F2F),
                  ),
                ),
              ),
              if (onDismiss != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  color: const Color(0xFFD32F2F),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFD32F2F),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onRetry,
                  child: const Text(
                    'Retry',
                    style: TextStyle(color: Color(0xFFD32F2F)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Success card with success information
class SuccessCard extends StatelessWidget {
  final String title;
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionText;

  const SuccessCard({
    super.key,
    required this.title,
    required this.message,
    this.icon,
    this.onAction,
    this.actionText,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      backgroundColor: const Color(0xFFE8F5E8),
      border: Border.all(color: const Color(0xFF4CAF50)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon ?? Icons.check_circle_outline,
                color: const Color(0xFF2E7D32),
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF2E7D32),
            ),
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onAction,
                  child: Text(
                    actionText!,
                    style: const TextStyle(color: Color(0xFF2E7D32)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Loading card with loading indicator
class LoadingCard extends StatelessWidget {
  final String message;
  final double? height;

  const LoadingCard({
    super.key,
    this.message = 'Loading...',
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      child: SizedBox(
        height: height ?? 100,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Offline banner card
class OfflineBanner extends StatelessWidget {
  final VoidCallback? onRetry;
  final VoidCallback? onViewCached;

  const OfflineBanner({
    super.key,
    this.onRetry,
    this.onViewCached,
  });

  @override
  Widget build(BuildContext context) {
    return CommonCard(
      backgroundColor: const Color(0xFFFFF3E0),
      border: Border.all(color: const Color(0xFFFF9800)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off,
            color: Color(0xFFFF9800),
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'You\'re offline. Some features may be limited.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFFE65100),
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: Color(0xFFE65100)),
              ),
            ),
          if (onViewCached != null)
            TextButton(
              onPressed: onViewCached,
              child: const Text(
                'View Cached',
                style: TextStyle(color: Color(0xFFE65100)),
              ),
            ),
        ],
      ),
    );
  }
}
