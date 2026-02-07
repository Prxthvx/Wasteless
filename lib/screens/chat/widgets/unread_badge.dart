import 'package:flutter/material.dart';

/// Badge widget to display unread message count
class UnreadBadge extends StatelessWidget {
  final int count;
  final Color? backgroundColor;
  final Color? textColor;

  const UnreadBadge({
    super.key,
    required this.count,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Icon button with badge overlay
class IconButtonWithBadge extends StatelessWidget {
  final IconData icon;
  final int badgeCount;
  final VoidCallback onPressed;
  final Color? iconColor;
  final Color? badgeColor;

  const IconButtonWithBadge({
    super.key,
    required this.icon,
    required this.badgeCount,
    required this.onPressed,
    this.iconColor,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: Icon(icon, color: iconColor),
          onPressed: onPressed,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: UnreadBadge(
              count: badgeCount,
              backgroundColor: badgeColor,
            ),
          ),
      ],
    );
  }
}
