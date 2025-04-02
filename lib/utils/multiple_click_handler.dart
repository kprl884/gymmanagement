import 'dart:async';
import 'package:flutter/material.dart';

/// A utility class that prevents multiple rapid clicks on buttons
class MultipleClickHandler {
  static final MultipleClickHandler _instance =
      MultipleClickHandler._internal();

  factory MultipleClickHandler() {
    return _instance;
  }

  MultipleClickHandler._internal();

  DateTime? _lastClickTime;

  /// Determines if the current click should be processed
  /// Returns true if the click should be processed, false otherwise
  bool processClick() {
    final now = DateTime.now();

    if (_lastClickTime == null) {
      _lastClickTime = now;
      return true;
    }

    // Only allow clicks that are at least 300ms apart
    if (now.difference(_lastClickTime!).inMilliseconds < 300) {
      return false;
    }

    _lastClickTime = now;
    return true;
  }

  /// Process a click action only if it passes the rapid-click prevention
  void processEvent(VoidCallback action) {
    if (processClick()) {
      action();
    }
  }
}

/// A single-click ElevatedButton that prevents multiple rapid clicks
class SingleClickElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final VoidCallback? onLongPress;

  const SingleClickElevatedButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clickHandler = MultipleClickHandler();

    return ElevatedButton(
      onPressed: () => clickHandler.processEvent(onPressed),
      onLongPress: onLongPress,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// A single-click TextButton that prevents multiple rapid clicks
class SingleClickTextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  final ButtonStyle? style;
  final FocusNode? focusNode;
  final bool autofocus;
  final Clip clipBehavior;
  final VoidCallback? onLongPress;

  const SingleClickTextButton({
    Key? key,
    required this.onPressed,
    required this.child,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.clipBehavior = Clip.none,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clickHandler = MultipleClickHandler();

    return TextButton(
      onPressed: () => clickHandler.processEvent(onPressed),
      onLongPress: onLongPress,
      style: style,
      focusNode: focusNode,
      autofocus: autofocus,
      clipBehavior: clipBehavior,
      child: child,
    );
  }
}

/// A single-click IconButton that prevents multiple rapid clicks
class SingleClickIconButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final AlignmentGeometry? alignment;
  final double? splashRadius;
  final Color? color;
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;
  final Color? disabledColor;
  final String? tooltip;
  final bool autofocus;
  final FocusNode? focusNode;
  final BoxConstraints? constraints;

  const SingleClickIconButton({
    Key? key,
    required this.onPressed,
    required this.icon,
    this.iconSize,
    this.padding,
    this.alignment,
    this.splashRadius,
    this.color,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.disabledColor,
    this.tooltip,
    this.autofocus = false,
    this.focusNode,
    this.constraints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final clickHandler = MultipleClickHandler();

    return IconButton(
      onPressed: () => clickHandler.processEvent(onPressed),
      icon: icon,
      iconSize: iconSize,
      padding: padding,
      alignment: alignment,
      splashRadius: splashRadius,
      color: color,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      splashColor: splashColor,
      disabledColor: disabledColor,
      tooltip: tooltip,
      autofocus: autofocus,
      focusNode: focusNode,
      constraints: constraints,
    );
  }
}
