import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// On web (or when width > 800), constrains [child] to [maxWidth] and centers it.
/// Otherwise returns [child] unchanged for mobile/narrow layouts.
Widget wrapWithWebMaxWidth(
  BuildContext context, {
  required Widget child,
  double maxWidth = 800,
}) {
  if (kIsWeb || MediaQuery.sizeOf(context).width > maxWidth) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
  return child;
}
