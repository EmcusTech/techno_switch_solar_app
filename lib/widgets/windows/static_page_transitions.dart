import 'package:flutter/material.dart';

/// Shows the next route immediately, with no zoom or slide.
class StaticPageTransitionsBuilder extends PageTransitionsBuilder {
  const StaticPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}
