import 'package:flutter/material.dart';

/// Utility class for standardized loading indicators and state management
class LoadingUtil {
  /// Creates a full-screen loading overlay
  static Widget fullScreenLoader({
    String message = 'Loading...',
    Color? backgroundColor,
    Color? textColor,
  }) {
    return Container(
      color: backgroundColor ?? Colors.black.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                color: textColor ?? Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Creates a loading button that shows a spinner when loading
  static Widget loadingButton({
    required bool isLoading,
    required VoidCallback onPressed,
    required Widget child,
    double width = double.infinity,
    double height = 50,
    Color? backgroundColor,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(8)),
  }) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : child,
      ),
    );
  }

  /// Shows a loading dialog with a message
  static Future<void> showLoadingDialog(
    BuildContext context, {
    String message = 'Loading...',
    bool barrierDismissible = false,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Closes the loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }

  /// Wraps a Future operation with loading dialog
  static Future<T?> wrapWithLoadingDialog<T>({
    required BuildContext context,
    required Future<T> Function() future,
    String loadingMessage = 'Loading...',
    Function(T result)? onSuccess,
    Function(dynamic error)? onError,
  }) async {
    try {
      showLoadingDialog(context, message: loadingMessage);
      final result = await future();
      if (context.mounted) hideLoadingDialog(context);
      if (onSuccess != null) onSuccess(result);
      return result;
    } catch (error) {
      if (context.mounted) hideLoadingDialog(context);
      if (onError != null) onError(error);
      return null;
    }
  }

  /// Creates a loading shimmer effect for placeholders
  static Widget shimmerLoading({
    required Widget child,
    Color baseColor = const Color(0xFFEEEEEE),
    Color highlightColor = const Color(0xFFFAFAFA),
  }) {
    return ShimmerEffect(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: child,
    );
  }
}

/// Simple shimmer effect implementation
class ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;

  const ShimmerEffect({
    Key? key,
    required this.child,
    required this.baseColor,
    required this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  }) : super(key: key);

  @override
  ShimmerEffectState createState() => ShimmerEffectState();
}

class ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              tileMode: TileMode.clamp,
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
