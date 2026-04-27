import 'package:flutter/material.dart';

class PrimaryActionButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return FilledButton(
        onPressed: null,
        child: const SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(text),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      child: Text(text),
    );
  }
}