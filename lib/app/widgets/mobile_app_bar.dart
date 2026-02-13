import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class MobileAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const MobileAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1E1E1E) : AppColors.surface),
      foregroundColor: foregroundColor ??
          (isDark ? AppColors.textOnPrimary : AppColors.textPrimary),
      elevation: 0,
      centerTitle: true,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: foregroundColor ??
                    (isDark ? AppColors.textOnPrimary : AppColors.textPrimary),
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ??
              (isDark ? AppColors.textOnPrimary : AppColors.textPrimary),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? null
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface,
                    AppColors.surface,
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class SliverMobileAppBar extends StatelessWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Widget? child;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const SliverMobileAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      backgroundColor: backgroundColor ??
          (isDark ? const Color(0xFF1E1E1E) : AppColors.surface),
      foregroundColor: foregroundColor ??
          (isDark ? AppColors.textOnPrimary : AppColors.textPrimary),
      elevation: 0,
      centerTitle: true,
      pinned: true,
      floating: false,
      snap: false,
      leading: showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: foregroundColor ??
                    (isDark ? AppColors.textOnPrimary : AppColors.textPrimary),
                size: 20,
              ),
              onPressed: onBackPressed ?? () => Navigator.of(context).pop(),
            )
          : null,
      title: Text(
        title,
        style: TextStyle(
          color: foregroundColor ??
              (isDark ? AppColors.textOnPrimary : AppColors.textPrimary),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      actions: actions,
      expandedHeight: child != null ? 120 : null,
      flexibleSpace: child != null
          ? FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? null
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.surface,
                            AppColors.surface,
                          ],
                        ),
                ),
                child: child,
              ),
            )
          : null,
    );
  }
}
