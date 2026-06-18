import 'package:flutter/material.dart';

class ResponsiveHelper {
  /// Returns true if the screen width is 600 dp or greater (tablet threshold).
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 600;
  }

  /// Returns the screen width.
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// Returns a max width constraint on tablet, otherwise infinity (takes full width).
  static double maxContentWidth(BuildContext context, {double defaultMax = 800}) {
    return isTablet(context) ? defaultMax : double.infinity;
  }

  /// Centers the child inside a ConstrainedBox if on tablet, otherwise returns the child directly.
  static Widget centeredConstraint({
    required BuildContext context,
    required Widget child,
    double maxTabletWidth = 800,
  }) {
    if (!isTablet(context)) return child;
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxTabletWidth),
        child: child,
      ),
    );
  }
}
