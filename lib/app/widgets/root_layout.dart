import 'package:flutter/material.dart';

/// Global layout shell that ensures every route is rendered inside a
/// [Material] context and has proper background color from the theme.
class RootLayout extends StatelessWidget {
  final Widget child;

  const RootLayout({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}
