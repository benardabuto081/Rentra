import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// The one filled action on a screen.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _ButtonFrame(
      expand: expand,
      enabled: onPressed != null && !isLoading,
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _ButtonFrame(
      expand: expand,
      enabled: onPressed != null && !isLoading,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: AppColors.primary,
        ),
      ),
    );
  }
}

class AppTextButton extends StatelessWidget {
  const AppTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return _ButtonFrame(
      expand: false,
      enabled: onPressed != null && !isLoading,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: color == null
            ? null
            : TextButton.styleFrom(foregroundColor: color),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: color ?? AppColors.primary,
        ),
      ),
    );
  }
}

/// For actions that remove or end something. Pair with a confirm dialog.
class DestructiveButton extends StatelessWidget {
  const DestructiveButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    return _ButtonFrame(
      expand: expand,
      enabled: onPressed != null && !isLoading,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.error,
          side: const BorderSide(color: AppColors.error),
        ),
        child: _ButtonContent(
          label: label,
          icon: icon,
          isLoading: isLoading,
          spinnerColor: AppColors.error,
        ),
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    required this.spinnerColor,
  });

  final String label;
  final IconData? icon;
  final bool isLoading;
  final Color spinnerColor;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Semantics(
        label: label,
        child: SizedBox.square(
          dimension: AppSizes.iconInline,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: spinnerColor,
          ),
        ),
      );
    }
    final text = Text(label, textAlign: TextAlign.center);
    if (icon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconInline),
        const SizedBox(width: AppSpacing.xs),
        Flexible(child: text),
      ],
    );
  }
}

class _ButtonFrame extends StatelessWidget {
  const _ButtonFrame({
    required this.child,
    required this.expand,
    required this.enabled,
  });

  final Widget child;
  final bool expand;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scaled = PressScale(enabled: enabled, child: child);
    return expand ? SizedBox(width: double.infinity, child: scaled) : scaled;
  }
}

/// Scales its child to 0.98 while pressed.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _set(bool value) {
    if (!widget.enabled || _pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _pressed ? AppMotion.pressedScale : 1,
        duration: AppMotion.fast,
        curve: AppMotion.curve,
        child: widget.child,
      ),
    );
  }
}
