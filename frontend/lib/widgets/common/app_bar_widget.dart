import 'package:flutter/material.dart';

/// Common app bar widget used across multiple screens
class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool centerTitle;
  final double elevation;
  final VoidCallback? onBackPressed;

  const CommonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.backgroundColor = const Color(0xFF2E7D32),
    this.foregroundColor = Colors.white,
    this.centerTitle = true,
    this.elevation = 0,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      leading: leading ??
          IconButton(
            icon: Icon(Icons.arrow_back, color: foregroundColor),
            onPressed: onBackPressed ?? () => Navigator.pop(context),
          ),
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// App bar with help button
class HelpAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onHelpPressed;
  final VoidCallback? onBackPressed;
  final List<Widget>? additionalActions;

  const HelpAppBar({
    super.key,
    required this.title,
    this.onHelpPressed,
    this.onBackPressed,
    this.additionalActions,
  });

  @override
  Widget build(BuildContext context) {
    return CommonAppBar(
      title: title,
      onBackPressed: onBackPressed,
      actions: [
        if (additionalActions != null) ...additionalActions!,
        IconButton(
          icon: const Icon(Icons.help_outline),
          onPressed: onHelpPressed,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
