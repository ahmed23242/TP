import 'package:flutter/material.dart';

class FadePageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;

  FadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class SlidePageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;
  final Offset begin;
  final Offset end;

  SlidePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.begin = const Offset(1.0, 0.0),
    this.end = Offset.zero,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }
}

class ScalePageRoute<T> extends PageRoute<T> {
  final Widget child;
  final Duration duration;
  final double begin;
  final double end;

  ScalePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.begin = 0.8,
    this.end = 1.0,
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOut,
      )),
      child: child,
    );
  }
}

class CustomAnimatedSwitcher extends StatelessWidget {
  final Widget child;
  final Duration duration;

  const CustomAnimatedSwitcher({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class CustomAnimatedContainer extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BoxDecoration? decoration;

  const CustomAnimatedContainer({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.padding,
    this.margin,
    this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: duration,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}

class CustomAnimatedOpacity extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final bool visible;

  const CustomAnimatedOpacity({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.visible = true,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: duration,
      opacity: visible ? 1.0 : 0.0,
      child: child,
    );
  }
}

class CustomAnimatedSize extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Alignment alignment;

  const CustomAnimatedSize({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.alignment = Alignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      alignment: alignment,
      child: child,
    );
  }
} 