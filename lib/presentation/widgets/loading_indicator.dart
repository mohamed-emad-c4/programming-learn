import 'package:flutter/material.dart';

enum LoadingStyle {
  circular,
  linear,
  shimmer,
  overlay,
}

class LoadingIndicator extends StatelessWidget {
  final LoadingStyle style;
  final String? message;
  final Color? color;
  final double size;
  final double strokeWidth;
  final bool isLoading;
  final Widget? child;

  const LoadingIndicator({
    Key? key,
    this.style = LoadingStyle.circular,
    this.message,
    this.color,
    this.size = 40.0,
    this.strokeWidth = 4.0,
    this.isLoading = true,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final indicatorColor = color ?? theme.colorScheme.primary;

    if (!isLoading && child != null) {
      return child!;
    }

    switch (style) {
      case LoadingStyle.circular:
        return _buildCircular(theme, indicatorColor);
      case LoadingStyle.linear:
        return _buildLinear(theme, indicatorColor);
      case LoadingStyle.shimmer:
        return _buildShimmer(theme, indicatorColor);
      case LoadingStyle.overlay:
        return _buildOverlay(theme, indicatorColor);
    }
  }

  Widget _buildCircular(ThemeData theme, Color indicatorColor) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
              strokeWidth: strokeWidth,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLinear(ThemeData theme, Color indicatorColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
          backgroundColor: indicatorColor.withOpacity(0.1),
          minHeight: strokeWidth,
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  Widget _buildShimmer(ThemeData theme, Color indicatorColor) {
    return Container(
      width: double.infinity,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const ShimmerEffect(),
    );
  }

  Widget _buildOverlay(ThemeData theme, Color indicatorColor) {
    return Stack(
      children: [
        if (child != null) child!,
        if (isLoading)
          Container(
            color: theme.colorScheme.surface.withOpacity(0.7),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: size,
                    height: size,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(indicatorColor),
                      strokeWidth: strokeWidth,
                    ),
                  ),
                  if (message != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      message!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class ShimmerEffect extends StatefulWidget {
  const ShimmerEffect({Key? key}) : super(key: key);

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
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
                Colors.grey.shade200,
                Colors.grey.shade100,
                Colors.grey.shade200,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(
                _animation.value - 1,
                0.0,
              ),
              end: Alignment(
                _animation.value + 1,
                0.0,
              ),
            ).createShader(bounds);
          },
          child: Container(
            color: Colors.white,
          ),
        );
      },
    );
  }
}
