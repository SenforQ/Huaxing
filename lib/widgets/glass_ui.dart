import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/huaxing_theme.dart';

class GradientShellBackground extends StatelessWidget {
  const GradientShellBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF030304),
                Color(0xFF0B0C10),
                Color(0xFF060608),
              ],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kAccentYellow.withOpacity(0.09),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 120,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  kAccentYellow.withOpacity(0.05),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.blurSigma = 22,
    this.borderOpacity = 0.22,
    this.fillOpacityHigh = 0.12,
    this.fillOpacityLow = 0.04,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final double blurSigma;
  final double borderOpacity;
  final double fillOpacityHigh;
  final double fillOpacityLow;

  @override
  Widget build(BuildContext context) {
    final BorderRadius r = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: r,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: r,
            border: Border.all(color: Colors.white.withOpacity(borderOpacity)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(fillOpacityHigh),
                Colors.white.withOpacity(fillOpacityLow),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class GlassBottomNav extends StatelessWidget {
  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(left: 14, right: 14, bottom: 10),
      child: SizedBox(
        height: 68,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: kAccentYellow.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
              child: Container(
                color: Colors.white.withOpacity(0.07),
                child: Row(
                  children: [
                    _GlassNavItem(
                      index: 0,
                      currentIndex: currentIndex,
                      icon: Icons.dynamic_feed_rounded,
                      label: '动态',
                      onTap: onChanged,
                    ),
                    _GlassNavItem(
                      index: 1,
                      currentIndex: currentIndex,
                      icon: Icons.camera_alt_rounded,
                      label: '镜头',
                      onTap: onChanged,
                    ),
                    _GlassNavItem(
                      index: 2,
                      currentIndex: currentIndex,
                      icon: Icons.grid_view_rounded,
                      label: '发现',
                      onTap: onChanged,
                    ),
                    _GlassNavItem(
                      index: 3,
                      currentIndex: currentIndex,
                      icon: Icons.chat_bubble_rounded,
                      label: '消息',
                      onTap: onChanged,
                    ),
                    _GlassNavItem(
                      index: 4,
                      currentIndex: currentIndex,
                      icon: Icons.person_rounded,
                      label: '我的',
                      onTap: onChanged,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassNavItem extends StatelessWidget {
  const _GlassNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final String label;
  final ValueChanged<int> onTap;

  bool get _selected => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    final Color active = kAccentYellow;
    final Color idle = Colors.white.withOpacity(0.42);
    final Color color = _selected ? active : idle;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: kAccentYellow.withOpacity(0.12),
          highlightColor: kAccentYellow.withOpacity(0.06),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: _selected ? FontWeight.w700 : FontWeight.w500,
                  color: color,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
