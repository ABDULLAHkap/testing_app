import 'package:flutter/material.dart';

class AnimatedHeroImage extends StatefulWidget {
  final String asset;
  final double height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AnimatedHeroImage({
    super.key,
    required this.asset,
    required this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
  });

  @override
  State<AnimatedHeroImage> createState() => _AnimatedHeroImageState();
}

class _AnimatedHeroImageState extends State<AnimatedHeroImage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.985, end: 1.015).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget image = ScaleTransition(
      scale: _scale,
      child: Image.asset(
        widget.asset,
        height: widget.height,
        width: double.infinity,
        fit: widget.fit,
      ),
    );
    if (widget.borderRadius != null) {
      image = ClipRRect(borderRadius: widget.borderRadius!, child: image);
    }
    return SizedBox(height: widget.height, child: image);
  }
}
