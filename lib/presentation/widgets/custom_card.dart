import 'package:flutter/material.dart';

enum CardType {
  filled,
  outlined,
  elevated,
}

class CustomCard extends StatelessWidget {
  final Widget child;
  final CardType type;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Color? color;
  final BorderRadius? borderRadius;
  final double elevation;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? selectedColor;
  final String? heroTag;

  const CustomCard({
    Key? key,
    required this.child,
    this.type = CardType.elevated,
    this.width,
    this.height,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.all(0),
    this.color,
    this.borderRadius,
    this.elevation = 2,
    this.onTap,
    this.isSelected = false,
    this.selectedColor,
    this.heroTag,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultBorderRadius = BorderRadius.circular(16);
    final cardBorderRadius = borderRadius ?? defaultBorderRadius;

    Widget cardWidget;

    // Base container with common properties
    final container = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: cardBorderRadius,
        border: type == CardType.outlined
            ? Border.all(
                color: isSelected
                    ? selectedColor ?? theme.colorScheme.primary
                    : theme.colorScheme.outline.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              )
            : null,
        color: _getCardColor(theme),
        boxShadow: type == CardType.elevated && !isSelected
            ? [
                BoxShadow(
                  color: theme.shadowColor.withOpacity(0.1),
                  blurRadius: elevation * 2,
                  offset: Offset(0, elevation),
                ),
              ]
            : isSelected && type == CardType.elevated
                ? [
                    BoxShadow(
                      color: (selectedColor ?? theme.colorScheme.primary)
                          .withOpacity(0.2),
                      blurRadius: elevation * 3,
                      offset: Offset(0, elevation),
                    ),
                  ]
                : null,
      ),
      child: child,
    );

    // If there's a hero tag, wrap in Hero widget
    if (heroTag != null) {
      cardWidget = Hero(
        tag: heroTag!,
        child: container,
      );
    } else {
      cardWidget = container;
    }

    // Add tap functionality if provided
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: cardBorderRadius,
          splashColor: theme.colorScheme.primary.withOpacity(0.1),
          highlightColor: theme.colorScheme.primary.withOpacity(0.05),
          child: cardWidget,
        ),
      );
    }

    return Padding(
      padding: margin,
      child: cardWidget,
    );
  }

  Color _getCardColor(ThemeData theme) {
    if (isSelected) {
      return selectedColor?.withOpacity(0.1) ??
          theme.colorScheme.primary.withOpacity(0.1);
    }

    switch (type) {
      case CardType.filled:
        return color ?? theme.colorScheme.surfaceContainerHighest;
      case CardType.outlined:
        return color ?? theme.colorScheme.surface;
      case CardType.elevated:
        return color ?? theme.colorScheme.surface;
    }
  }
}
